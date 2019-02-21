local skynet = require "skynet"

local pool = {}


local createService 


function pool.new(name, num)
    skynet.error("service new name ", name, num)
    local self = {
        reusePool = {},
        usingPool = {},
        name = name,
        initNum = num,
    }
 
    for i = 0, num do
        table.insert(self.reusePool, skynet.newservice(name))
    end

    function self.getservice() 
        local service = nil
        local len = #self.reusePool
        -- skynet.error("pool:getService reusePool", #self.reusePool, "usingPool", #self.usingPool)
        if len > 0 then
            service = self.reusePool[len - 1]
            table.remove(self.reusePool)
            table.insert(self.usingPool, service)
        else
            service = skynet.newservice(self.name)
            table.insert(self.usingPool, service)
        end
        skynet.error("Servicepool reusePool", #self.reusePool, "usingPool", #self.usingPool)

        return service
    end
    
    function self.recycleservice(service)
        pcall(skynet.call, service, "lua", "clear")
        table.insert(self.reusePool, service)

        for j = 0, #self.usingPool do 
            if self.usingPool[j] == service then
                table.remove(self.usingPool, j)
                break
            end
        end 
    end

    return self
end

return pool