StringBuilder = class()

function StringBuilder:init()
    self.t = {}
    self.len = 0
end

function StringBuilder:reset()
    table.clear(self.t)
    self.len = 0
end

function StringBuilder:write(...)
    local args = {...}
    for i = 1, #args do        
        local s = tostring(args[i])
        self.t[#self.t+1] = s
        self.len = self.len + string.len(s)
    end
end

function StringBuilder:writeln(...)
    self:write(...)
    self:write("\n")
end

function StringBuilder:length()
    return self.len
end

function StringBuilder:toString()
    local s = table.concat(self.t)    
    return s
end