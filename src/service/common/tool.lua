local random = math.random

local module = {}

function module.split(s, p)
    if (s == nil) then
        return nil
    end
    if (p == nil) then
        return s
    end
    local rt = {}
    -- s = tosting(s)
    string.gsub(
        s,
        "[^" .. p .. "]+",
        function(w)
            table.insert(rt, w)
        end
    )

    return rt
end

function module.guid()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(
        template,
        "[xy]",
        function(c)
            local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
            return string.format("%x", v)
        end
    )
end

return module
