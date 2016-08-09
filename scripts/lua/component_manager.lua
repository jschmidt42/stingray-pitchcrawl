--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--
-- The Component Manager provides automatic component calls to update, render, 
-- shutdown, etc and also allows for component-based aggregation of behaviors 
-- using an arbitrary lua object shared among related components.

require 'scripts/lua/class'

ComponentManager = class(ComponentManager) or {}

local managers = {}

ComponentManager.update_pre_world = 1
ComponentManager.update_post_world = 2

--------------------------------------------------------------------------------
-- Internals

-- Called when a world is ticked.
-- Handler function signature: on_update(object, dt)
local update_handlers = {}

-- Called when the app is shutdown.
-- Handler function signature: on_shutdown(object)
local shutdown_handlers = {}

-- Called when a level is being destroyed, befor it is destroyed.
-- Handler function signature: on_level_shutdown(object, level)
local level_shutdown_handlers = {}

--------------------------------------------------------------------------------
-- This Lua ComponentManager is temp system which will be replaced by the 
-- entity system

--------------------------------------------------------------------------------
-- Instance functionality

function ComponentManager:init(update_priority)
	update_priority = update_priority or ComponentManager.update_pre_world

	managers[#managers + 1] = self
	self.components = {}

	ComponentManager.add_update_handler(self, self.on_update, update_priority)
	ComponentManager.add_shutdown_handler(self, self.on_shutdown)
	ComponentManager.add_level_shutdown_handler(self, self.on_level_shutdown)
end

-- Call to add a component to an entity. An entity can be anything, 
-- e.g. an empty table that represents an object, but must be unique.
-- If owning_level is passed, then component will receive an on_level_shutdown() callback 
-- and will be removed from the component manager immediately before the level is destroyed
function ComponentManager:add_component(entity, component, owning_level)
	self.components[entity] = {component, owning_level}
end

-- Gets the component for the given entity or nil if this manager does not 
-- have a component for the given entity. Max one component per entity per manager.
function ComponentManager:get(entity)
	local component_wrapper = self.components[entity]
	if not component_wrapper then return nil end
	return component_wrapper[1]
end

function ComponentManager:on_update(dt)
	for entity, component_wrapper in pairs(self.components) do
		component_wrapper[1]:update(dt)
	end
end

function ComponentManager:on_level_shutdown(level)
	local components = self.components
	for entity, component_wrapper in pairs(components) do
		if component_wrapper[2] == level then component_wrapper[1]:on_level_shutdown(level) end
		components[entity] = nil
	end
end

function ComponentManager:on_shutdown()
	local components = self.components
	for entity, component_wrapper in pairs(components) do
		component_wrapper[1]:shutdown()
	end
	components = {}
end

--------------------------------------------------------------------------------
-- ComponentManager Global functionality

-- Call this on an entity to unregister all of its components from their managers 
-- and to call shutdown on each component.
function ComponentManager.remove_components(entity)
	for _, manager in ipairs(managers) do
		local component_wrapper = manager.components[entity]
		if component_wrapper then
			local component = component_wrapper[1]
			if component.shutdown then
				component:shutdown()
			end
			manager.components[entity] = nil
		end
	end
end

function ComponentManager.update_managers(dt, priority)
	local handler_group = update_handlers[priority]
	if not handler_group then return end

	for _, handler in ipairs(handler_group) do
		handler[1](handler[2], dt)
	end
end

function ComponentManager.shutdown_managers()
	for _, handler in ipairs(shutdown_handlers) do
		handler[1](handler[2])
	end
end

function ComponentManager.notify_managers_level_shutdown(level)
	for _, handler in ipairs(level_shutdown_handlers) do
		handler[1](handler[2], level)
	end
end

function ComponentManager.add_level_shutdown_handler(object, callback)
	level_shutdown_handlers[#level_shutdown_handlers + 1] = {callback, object}
end

function ComponentManager.remove_level_shutdown_handler(object, callback)
	local handler
	for i = #level_shutdown_handlers, 1, -1 do
		handler = level_shutdown_handlers[i]
		if (handler[1] == callback and handler[2] == object) then
			table.remove(level_shutdown_handlers, i)
		end
	end
end

function ComponentManager.add_shutdown_handler(object, callback)
	shutdown_handlers[#shutdown_handlers + 1] = {callback, object}
end

function ComponentManager.remove_shutdown_handler(object, callback)
	local handler
	for i = #shutdown_handlers, 1, -1 do
		handler = shutdown_handlers[i]
		if (handler[1] == callback and handler[2] == object) then
			table.remove(shutdown_handlers, i)
		end
	end
end

-- Priority in descending order starting from 1. For example all 
-- handlers with priority 1 will update before all handlers with priority > 1.
function ComponentManager.add_update_handler(object, callback, priority)
	priority = priority or 1
	local handler_group = update_handlers[priority]
	if not handler_group then
		handler_group = {}
		update_handlers[priority] = handler_group
	end
	handler_group[#handler_group + 1] = {callback, object}
end

function ComponentManager.remove_update_handler(object, callback)
	local handler_group
	local handler
	for i = #update_handlers, 1, -1 do
		handler_group = update_handlers[i]
		for j = #handler_group, 1, -1 do
			handler = handler_group[j]
			if handler[1] == callback and handler[2] == object then
				table.remove(handler_group, j)
			end
		end
		if next(handler_group) == nil then table.remove(update_handlers, i) end
	end
end
