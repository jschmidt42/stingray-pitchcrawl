--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/event_manager'
require 'scripts/lua/utilities'

MouseController = class(MouseController) or {}

local InputSettings = {}
InputSettings.double_click_time_threshold = 0.25
InputSettings.click_movement_threshold = 10

function MouseController:init()
	self.mouse_is_not_over_ui = true

	self.movement = Vector3Box()
	self.last_position = Vector3Box(0,0,0)
	self.time_since_last_click = 0

	self.repeatedKeyBinds = {}
	self.keyBinds = {}

	self:reset()

	EventManager.subscribe("ActivateInput", self.start_input, self)
	EventManager.subscribe("DeactivateInput", self.stop_input, self)
end

function MouseController:on_level_shutdown(level)

end

function MouseController:shutdown()
	EventManager.unsubscribe("ActivateInput", self.start_input, self)
	EventManager.unsubscribe("DeactivateInput", self.stop_input, self)
end

function MouseController:update(dt)
	if not Utils.is_pc() then return end

	self.time_since_last_click = self.time_since_last_click + dt

	if self.mouse_is_not_over_ui then
		self:update_input(dt)
		self:process_derived_input(dt)
	else
		self:reset()
	end
end

function MouseController:reset()
	self.position = Vector3Box(0,0,0)
	self.delta_position = Vector3(0,0,0)

	self.click = {}
	self.last_click_position = {}
	self.will_click = {}
	self.double_click = {}
	self.down = {}
	self.up = {}
	self.hold = {}
	self.hold_duration = {}
	self.hold_movement = {}
	self.zoom = 0

	  --Touch-specific
	self.has_position = false --The position doesn't exist if there is no touch
	self.contacts = {}

	self.buttons = {"left", "right", "middle"}
	for buttonCount = 1,3 do
		local button = self.buttons[buttonCount]
		self.click[button] = false
		self.last_click_position[button] = Vector3Box()
		self.double_click[button] = false
		self.down[button] = false
		self.up[button] = false
		self.hold[button] = false
		self.hold_duration[button] = 0.0
		self.hold_movement[button] = Vector3Box(0.0,0.0,0.0)
	end

	self.shift = false
	self.ctrl = false
end

function MouseController:stop_input()
	self.input_is_not_over_ui = false
end

function MouseController:start_input()
	self.input_is_not_over_ui = true
end

function MouseController:update_input()
	self.delta_position = Vector3(0.0,0.0,0.0)
	self.zoom = 0;

	self.delta_position = -Mouse.axis(Mouse.axis_index("mouse"))

	for _, button in ipairs(self.buttons) do
		self.down[button] = Mouse.pressed(Mouse.button_index(button))
		self.up[button] = Mouse.released(Mouse.button_index(button))
		self.hold[button] = Mouse.button(Mouse.button_index(button)) > 0.001

		if self.down[button] then
			EventManager.raise_event("MouseDown", button, self.position:unbox())
		end
		if self.up[button] then
			EventManager.raise_event("MouseUp", button, self.position:unbox())
		end
	end

	self.zoom = -Mouse.axis(Mouse.axis_index("wheel")).y
	if math.abs(self.zoom) > 0.001 then
		EventManager.raise_event("MouseWheel", self.zoom)
	end
end

--Derived input includes everything we can deduce from the direct input. For example, from mouse-up & down event, we can deduce how long we hold a button down
function MouseController:process_derived_input(dt)
	for _, button in ipairs(self.buttons) do

		if self.time_since_last_click < InputSettings.double_click_time_threshold
				and Vector3.length(self.hold_movement[button]:unbox()) <= InputSettings.click_movement_threshold then
			self.time_since_last_click = 0
			self.double_click[button] = true
			self.will_click[button] = false
			EventManager.raise_event("DoubleClick", button, self.position:unbox() )
			EventManager.cancel_timed_event(self.click_timer_id)
		else
			self.click[button] = false
			self.double_click[button] = false
		end

		if self.hold[button] then
			self.hold_duration[button] = self.hold_duration[button] + dt
			self.hold_movement[button]:store( self.hold_movement[button]:unbox() + self.delta_position )
		else
			self.hold_duration[button] = 0.0
			self.hold_movement[button]:store(Vector3(0.0,0.0,0.0))
		end

	end
end
