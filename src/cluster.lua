local skynet = require "skynet"
local cluster = require "skynet.cluster"
local snax = require "skynet.snax"

local dirName = assert(skynet.getenv("dirName"))
local initModule = require(dirName .. ".init")

local tool = require "common.tool"

require "skynet.manager"

local CMD = {} --消息表
function CMD.enterScene(cmd, data)
    cluster.call("wsCluster1", ".wsCluster1Service", "broadcast", "cluster1Sever respone")
end

function CMD.request(cmd, data)
    
    -- area.handler.resource.loadResource

    -- area->handler->resource-> loadResource function

    -- split by
    local splitCmd = tool.split(cmd,'.')
    local method = splitCmd[#splitCmd];
    local className = table.concat(splitCmd,".",1,#splitCmd-1) 
    -- print('接收到路由',method, className)
    local handler = require(className)
    local f = handler[method]
    -- local returnMsg
    -- if f then
    --     returnMsg = f(data)
    -- end
    -- if returnMsg then
    --     -- print("集群返回值:",returnMsg)
    --     return returnMsg
    --     --cluster.send()
    --     --print("handler has deal finished...........")
    -- end
    --skynet.error(string.format("[cluste1 MSG] cluster1Sever get a request: %s", str))
    cluster.send("authCluster2", ".authCluster2Service", "request", "cluster1Sever respone")
end

function CMD.move(requestObj)
    cluster.send("wsCluster1", ".wsCluster1Service", "broadcast", "cluster1Sever respone")
end


skynet.start(function()

    initModule.init()

    -- 获取cluster的节点名称
    local clusterNodeName = assert(skynet.getenv('clusterNodeName'))

    --让当前节点监听一个端口
    cluster.open(clusterNodeName)

    -- 处理结果响应到前端
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        -- print('cmd:', cmd, ...)
        skynet.retpack(f(...))
    end)
    local clusterNodeName = skynet.getenv("clusterNodeName")
    print('clusterNodeName', clusterNodeName)
    -- 必须以点开头？ in upvalue 'globalname'
    --在当前节点上为一个服务起一个字符串名字，之后可以用这个名字取代地址。
    skynet.register("." .. clusterNodeName .. "Service")
end)