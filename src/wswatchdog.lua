local skynet = require "skynet"
local netpack = require "skynet.websocketnetpack"
local socket = require "skynet.socket"
local cluster = require "skynet.cluster"
local servicepool = require "servicepool"
local mc = require "skynet.multicast"
local dc = require "skynet.datacenter"
require "skynet.manager"

local CMD = {}
local SOCKET = {}
local gate
local agents = {}  ---当前在使用中的agent key为socket value：agent
local agentPool    ---用户agent 协程池
local channels = {}    ---multicast


function SOCKET.open(fd, addr)
    local agent = agentPool.getservice("agent")
    local channel = channels["MCBROADCAST"]
    skynet.send(agent, "lua", "start", { gate = gate, client = fd, watchdog = skynet.self(), channel = channel.channel})
    agents[fd] = agent
end

-- 广播本connector的消息
function CMD.broadcast(msg)
    -- print('CMD.broadcast', msg)
    local channel = channels["MCBROADCAST"]
    channel:publish(msg)
end

local function close_agent(fd)
    local a = agents[fd]
    agents[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end
    agentPool.recycleservice(a)
end

function SOCKET.close(fd)
    skynet.error("socket close", fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    skynet.error("socket error", fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    skynet.error("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
    skynet.error("i am wswatchdog.... data")
end

-- 启动的时候，由wsmain 调用
function CMD.start(conf)
    skynet.call(gate, "lua", "open", conf)
    agentPool = servicepool.new("agent", 512)
    local channel = mc.new()
    channels["MCBROADCAST"] = channel    
end


skynet.start(function()
    -- init agent pool
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
            local f = SOCKET[subcmd]
            f(...)
        else
            local f = assert(CMD[cmd])
            skynet.ret(skynet.pack(f(subcmd, ...)))
        end
    end)

    -- 获取cluster的节点名称
    local clusterNodeName = assert(skynet.getenv('clusterNodeName'))
    local service = "." .. clusterNodeName .. "Service"
    -- print('clusterNodeName', clusterNodeName, "Service", service)

    cluster.open(clusterNodeName)
    skynet.register(service)

    gate = skynet.newservice("wsgate")
end)
