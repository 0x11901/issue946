local skynet = require "skynet"

local max_client = 1024

skynet.start(function()
    local gateConf = {
        port = 8001,
        maxclient = max_client,
        nodelay = true,
    }
    skynet.error("Server start")
    if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
    skynet.newservice("debug_console",7000)
    local watchdog = skynet.newservice("wswatchdog")
    skynet.call(watchdog, "lua", "start", gateConf)
    skynet.exit()
end)