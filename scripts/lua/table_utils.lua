--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/string_builder'

local table_utils = table_utils or {}

function table_utils.is_table(obj)
    return type(obj) == 'table'
end

function table_utils.ripairs(t)
    -- Try not to use break when using this function;
    -- it may cause the array to be left with empty slots
    local ci = 0
    local remove = function()
        t[ci] = nil
    end
    return function(t, i)
        --print("I", table.concat(array, ','))
        i = i+1
        ci = i
        local v = t[i]
        if v == nil then
            local rj = 0
            for ri = 1, i-1 do
                if t[ri] ~= nil then
                    rj = rj+1
                    t[rj] = t[ri]
                    --print("R", table.concat(array, ','))
                end
            end
            for ri = rj+1, i do
                t[ri] = nil
            end
            return
        end
        return i, v, remove
    end, t, ci
end

function table_utils._toString (tbl, indent, sb)
    local tindent = string.rep("  ", indent)
    sb:write(tindent .. "{\n")
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent+1) .. k .. " = "
        if type(v) == "table" then            
            sb:write(formatting)
            table_utils._toString(v, indent+1, sb)
        elseif type(v) == 'boolean' then            
            sb:write(formatting .. tostring(v) .. "\n")
        else            
            sb:write(formatting .. v .. "\n")
        end
    end
    sb:write(tindent .. "}\n")
end

function table_utils.toString (tbl, sb)
    if sb == nil then sb = StringBuilder() end    
    table_utils._toString(tbl, 0, sb)
    return sb:toString()
end

function table_utils.print (tbl)
    local sb = StringBuilder()
    sb.write("\n")
    print(table_utils.toString(tbl, sb))
end

return table_utils
