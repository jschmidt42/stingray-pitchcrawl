--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

--[[
		Helper function to implement object oriented class structures.
]]--

function class(class_obj, super)
	--For hot swapping if no class exists, one will be created
	--otherwise the existing class will be updated.
	if not class_obj then
		class_obj = {}
		
		--Object constructor
		local meta = {}
		meta.__call = function(self, ...)
			local object = {}
			setmetatable(object, class_obj)
			if object.init then object:init(...) end
			return object
		end
		setmetatable(class_obj, meta)
	end
	
	--Deep copy the super class functions onto the new class 
	--so that they can be overriden later.
	if super then
		for k,v in pairs(super) do
			class_obj[k] = v
		end
	end
	
	--Keep a copy of the base class to simplify 
	--calling the parent functionality when overriding functions.
	class_obj.Super = super
	
	class_obj.__index = class_obj
	
	return class_obj
end
