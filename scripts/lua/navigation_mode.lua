--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/camera_wrapper'
require 'scripts/lua/event_manager'

NavigationMode = class(NavigationMode)

function NavigationMode:init()
	self.camera_wrapper_entity = {}-- stub entity
	local world = Game.world
	local unit = World.spawn_unit(world, "core/appkit/units/camera/camera")
	self.camera_wrapper = CameraWrapper(self.camera_wrapper_entity, unit, "camera")
	
	self.has_all_dependencies = self:check_dependencies()
	
	self.active = false
end

function NavigationMode:update(dt)
	self.camera_wrapper:update(dt)
end

function NavigationMode:on_level_shutdown(level)

end

function NavigationMode:check_dependencies()
	--These functions need to be implemented
	if not self.name then
		print("ERROR: Navigation mode has no name.")
		return false
	elseif not self.get_starting_pose then
		print("ERROR: Navigation mode "..self.name.." should implement function get_starting_pose().")
		return false
	end
	return true
end

function NavigationMode:activate()
	if self.has_all_dependencies then
		local pos, rot, fov = self:get_starting_pose()
		self.camera_wrapper:enable()
		self:transition(pos, rot, fov)
		return true
	end
	return false
end

function NavigationMode:deactivate()
	self.active = false
	self.camera_wrapper:disable()
end

function NavigationMode:transition(pos, rot, fov)
	self.camera_wrapper:set_local_position(pos)
	self.camera_wrapper:set_local_rotation(rot)
	self.camera_wrapper:set_vertical_fov(fov)
	self.active = true
end
