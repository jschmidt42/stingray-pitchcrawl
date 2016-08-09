--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/math'
require 'scripts/lua/navigation_mode'

GameCam = class(GameCam, NavigationMode)

function GameCam:init()

	local world = Game.world

	self.name = "GameCam"
	self.target = world:unit_by_name("micro_knight")

	self.angle = 0
	self.pan = Vector3Box(Vector3.zero())
	self.pitch_angle = 70
	self.height = 9
	self.radius = -1 --influences the margin between the hero and the screen border (when focused)
	self.lerp_ratio = 1

	self.height_min = 5
	self.height_max = 14

	self.rotate_speed = 0.2
	self.key_rotate_speed = 0.2
	self.pan_speed = 4
	self.zoom_speed = 1
	self.lerp_speed = 2

	self.last_position = Vector3Box(Vector3.zero())
	self.last_rotation = QuaternionBox(Quaternion.identity())

	NavigationMode.init(self)
end

function GameCam:check_dependencies()
	--Requires mouse+keyboard input component
	if not Game.input.mouse or not Game.input.keyboard then
		return false
	end
	return NavigationMode.check_dependencies(self)
end

function GameCam:get_starting_pose()
	return Vector3.zero(), Quaternion.identity(), 45
end

function GameCam:shutdown()

end

function GameCam:activate()

	NavigationMode.activate(self)

	Window.set_show_cursor(true)
	Window.set_mouse_focus(true)
end

function GameCam:focus_current_character()
	self.target = Game.game_manager:current_character().unit
	self:focus()
end

function GameCam:focus()
	-- Setup lerp
	self.last_position:store(self.camera_wrapper:local_position())
	self.last_rotation:store(self.camera_wrapper:local_rotation())
	self.lerp_ratio = 0

	-- Set camera angle to see in front of unit
	local forward_vector = nil
	local actor = Unit.actor(self.target, 1)
	if actor then
		forward_vector = Quaternion.forward(Actor.rotation(actor))
	else
		forward_vector = Quaternion.forward(Unit.world_rotation(self.target, 2))
	end
	self.angle = math.atan2(forward_vector.y, forward_vector.x) - math.pi/2

	self.pan = Vector3Box(Vector3.zero())
end

function GameCam:update(dt)
	if not self.active then return end

	-- Get unit of interest
	local unit = self.target
	if unit == nil then return end

	local input = Game.input

	-- Mouse input
	local mouse = input.mouse
	local delta_mouse = input.mouse.delta_position
	if input.mouse.down.right then
		Window.set_clip_cursor(true)
	end
	if input.mouse.up.right then
		Window.set_clip_cursor(false)
	end
	if input.mouse.hold.right then
    	local dx = delta_mouse.x * dt * self.rotate_speed
    	self.angle = self.angle + dx
	end
	if Keyboard.button(Keyboard.button_index("q")) > 0 then
		self.angle = self.angle + self.key_rotate_speed
	end
	if Keyboard.button(Keyboard.button_index("e")) > 0 then
		self.angle = self.angle - self.key_rotate_speed
	end

	-- Move to actor position (with offset)
	local unit_p = Unit.world_position(unit, 2)
	local rev_angle = self.angle + math.pi/2
	local cam_p_x = unit_p.x + self.radius*math.cos(rev_angle)
	local cam_p_y = unit_p.y + self.radius*math.sin(rev_angle)
	local new_cam_p = Vector3(cam_p_x, cam_p_y, unit_p.z + self.height)
	local lerped_position = Vector3.lerp(self.last_position:unbox(), new_cam_p, self.lerp_ratio)
	self.camera_wrapper:set_local_position(lerped_position)

	-- Zoom
	self.height = self.height + input.mouse.zoom * self.zoom_speed
	self.height = math.max(math.min(self.height, self.height_max), self.height_min)

	-- Rotate
	local q_yaw = Quaternion(Vector3(0,0,1), self.angle)
	local q_down = Quaternion(Vector3(1,0,0), -math.rad(self.pitch_angle))
	local q_new = Quaternion.multiply(q_yaw, q_down)
	local lerped_rotation = Quaternion.lerp(self.last_rotation:unbox(), q_new, self.lerp_ratio)
	self.camera_wrapper:set_local_rotation(lerped_rotation)

	-- Pan
	local input_movement = input.keyboard:get_movement()
	local pan = self.pan:unbox()
	pan = pan + Quaternion.right(q_yaw) * input_movement.x*dt*self.pan_speed
	pan = pan + Quaternion.forward(q_yaw) * input_movement.y*dt*self.pan_speed
	self.camera_wrapper:move(pan)
	self.pan:store(pan)

	-- Focus
	local keys = Keyboard.keystrokes()
	if keys[#keys] == "f" then
		self:focus()
	end

	-- Lerp ratio
	if self.lerp_ratio < 0.99 then
		self.lerp_ratio = math.min(self.lerp_ratio + self.lerp_speed * dt, 1)
	end

	shared_cam_pos = Vector3Box(self.camera_wrapper:local_position())
	shared_cam_rot = QuaternionBox(self.camera_wrapper:local_rotation())

	NavigationMode.update(self, dt)
end
