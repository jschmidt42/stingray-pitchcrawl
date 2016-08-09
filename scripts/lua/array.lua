require 'scripts/lua/string_builder'

Array = class() or {}



local table_utils = require 'scripts/lua/table_utils'

function Array:init(t)	
    if t == nil then
        self.data = {}
    else    	
        self.data = t
    end
end

function Array:length()
    return #self.data
end

function Array:indexOf()
    return #self.data
end

function Array:join()
end

function Array:push()
end

function Array:pop()
end

function Array:reverse()
end

function Array:sort()
end

function Array:concat()
end

function Array:removeAt()
end

function Array:insertAt()
end

function Array:forEach(func)
	for i, v in ipairs(self.data) do
		func(i, v)
	end
end

function Array:forEachReverse(func)
	for i, v in table_utils.ripairs(self.data) do
		func(i, v)
	end
end

function Array:toString()
	local sb = StringBuilder()
	sb:write("{")
	
	for i, v in ipairs(self.data) do
		sb:write(tostring(v))
		if i < self:length() then
			s = sb:write(",")
		end
	end
	sb:write("}")
	return sb:toString()
end

function Array.tests()
	print("==========================================================")
	print("Array Tests")

	local t = {10,20,30,40,50}
	print(tostring(t))

	local a1 = Array(t)

	print("=== toString ===")
	print(a1:toString())

	print("=== forEach ===")
	a1:forEach(function (i, v) 
		print(i, v)
	end)

	print("=== forEachReverse ===")
	a1:forEachReverse(function (i, v) 
		print(i, v)
	end)

	print("=== table_print ===")
	table_utils.print(a1.data)

	print("=== table_print2 ===")
	table_utils.print({a = 1, b = 34, c = {d = 390, e = 30}, f = 230})

    print("success")
    print("==========================================================")
end