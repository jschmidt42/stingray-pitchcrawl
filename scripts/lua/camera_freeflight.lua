--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/math'
require 'scripts/lua/navigation_mode'

FreeFlight = class(FreeFlight, NavigationMode)

local FreeFlightSettings = FreeFlightSettings or {}
FreeFlightSettings.inverted = false
FreeFlightSettings.horizontal_speed = 0.1
FreeFlightSettings.vertical_speed = 0.1
FreeFlightSettings.move_speed = 2.0
FreeFlightSettings.min_angle = -80
FreeFlightSettings.max_angle = 80

function FreeFlight:init()
	self.name = "FreeFlight"
	NavigationMode.init(self)
end

function FreeFlight:check_dependencies()
	--Requires mouse+keyboard input component
	if not Game.input.mouse or not Game.input.keyboard then
		return false
	end
	return NavigationMode.check_dependencies(self)
end

function FreeFlight:get_starting_pose()
	return shared_cam_pos:unbox(), shared_cam_rot:unbox(), 45
end

function FreeFlight:activate()

	NavigationMode.activate(self)

	Window.set_show_cursor(false)
	Window.set_mouse_focus(true)
end

function FreeFlight:shutdown()
	
end

function FreeFlight:update(dt)
	if not self.active then return end
	
	local input_movement = Game.input.keyboard:get_movement()
	local look_at = Quaternion.forward( self.camera_wrapper:local_rotation() )
	local strafe_at = Quaternion.right( self.camera_wrapper:local_rotation() )
	local move = look_at*input_movement.y*dt*FreeFlightSettings.move_speed + strafe_at*input_movement.x*dt*FreeFlightSettings.move_speed
	
	if Game.input.keyboard.shift then
		move = move*2
	end
	
	self.camera_wrapper:move(move, dt)

	local pan = Game.input.mouse.delta_position
	local XPan = pan.x*dt*FreeFlightSettings.horizontal_speed
	local YPan = pan.y*dt*FreeFlightSettings.vertical_speed
	if FreeFlightSettings.inverted then
		YPan = -YPan
	end
	self.camera_wrapper:rotate(XPan, YPan, FreeFlightSettings.min_angle, FreeFlightSettings.max_angle)
	
	NavigationMode.update(self, dt)
end
