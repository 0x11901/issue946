local skynet = require "skynet"
local socket = require "skynet.socket"
local netpack = require "skynet.websocketnetpack"
local cluster = require "skynet.cluster"
local cmdConfig = require "config/cmd"
local cjson = require "cjson"
local mc = require "skynet.multicast"
local tool = require "common.tool"

local WATCHDOG

local CMD = {}
local client_fd
local channel
local channelId
local nodeNames = {} --area[多个] shop chat mail task login connector order
local entryHandler = {} ---TOOD后续可以放倒其他文件

local function registerMulticast()
    channel = mc.new {
        channel = channelId ,
        dispatch = function (channel, source, message)
            CMD.send(message)
        end
    }
    channel:subscribe()
end


-- socket连接后第一次交互
function entryHandler.entry(routers, requestObj)
    -- print("entryHandler.entry")
    CMD.send("init")
    registerMulticast()

    ----用户登录可以知道用
    nodeNames['area'] = "areaCluster1"
end

local function request(routers, requestObj)
    local node = nodeNames[routers[1]]
    local service = "." .. node .. "Service"
    local method = routers[3]
    -- print("cluster's nodeName:", node, "cluster's service:", service, "method:", method)
    if node then
        cluster.send(node, service, method, requestObj)
    end
end

local function parseRouter(cmd)
    local splitCmd = tool.split(cmd, '.')
    local router = table.concat(splitCmd, "", 1, #splitCmd)
    local mapRouter = cmdConfig[router]
    return tool.split(mapRouter, '.')
end

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function(msg, sz)
        local requestString = skynet.tostring(msg, sz)
        local requestObj = cjson.decode(requestString)
        local routers = tool.split(requestObj.cmd, '.')
        return routers, requestObj
    end,
    dispatch = function(fd, _,  routers, data, ...)
        -- assert(fd == client_fd)    -- You can use fd to reply message
        skynet.ignoreret()    -- session is fd, don't call skynet.ret
        if routers[1] ~= "connector" 
        then
            request(routers, data, ...)
            -- pcall(request, routers, data, ...)
            -- if channel then
            --     channel:publish(requestString)
            -- end
        else
            pcall(entryHandler[routers[3]], routers, data, ...)            
        end
        -- print('-------------------------')
    end
}

function CMD.start(conf)
    local fd = conf.client
    local gate = conf.gate
    WATCHDOG = conf.watchdog

    client_fd = fd
    skynet.call(gate, "lua", "forward", fd)
    channelId = conf.channel
end

function CMD.disconnect()
    -- todo: do something before exit
    skynet.error("call CMD disconnect")
    CMD.clear()
end


function CMD.send(msg)
    -- print('agent send', msg)
    -- send_frame(true, 0x1, msg)
    socket.lwrite(client_fd, netpack.packText(msg))
    -- socket.lwrite(client_fd, msg)
end

function CMD.clear()
    WATCHDOG = nil
    client_fd = nil
    if channel then
        channel:unsubscribe()
        channel = nil
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, type, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
