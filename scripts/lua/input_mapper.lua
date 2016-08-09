--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--
--[[
	A Basic Input controller with controls for move and pan.
	Can be extended or inherited from to add additional functionality.
]]--

require 'scripts/lua/utilities'
require 'scripts/lua/class'

InputMapper = class(InputMapper) or {}

function InputMapper:init()
	self.input = {
		pan = Vector3Box(Vector3(0, 0, 0)),
		move = Vector3Box(Vector3(0, 0, 0))
	}

	self.touch_state = {
		-- Contact id for pan controller
		pan_id = nil,
		-- Contact id for move controller
		move_id = nil,
		pan_ref = Vector3Box(0, 0, 0)
	}
end

function InputMapper:get_motion_input()
	local input = self.input
	return {move = input.move:unbox(), pan = input.pan:unbox()}
end

local function update_button_input(self)
	local move = Vector3(0, 0, 0)
	local pan = Vector3(0, 0, 0)
	local input = self.input
	if Utils.is_pc() then
		pan = stingray.Mouse.axis(stingray.Mouse.axis_index("mouse"))
		move = Vector3(
			Keyboard.button(Keyboard.button_index("d")) -
			Keyboard.button(Keyboard.button_index("a")),
			Keyboard.button(Keyboard.button_index("w")) -
			Keyboard.button(Keyboard.button_index("s")),
			0
		)

		input.jump = Keyboard.pressed(Keyboard.button_index("space"))
		input.crouch = Keyboard.pressed(Keyboard.button_index("left ctrl"))
		input.run = Keyboard.button(Keyboard.button_index("left shift")) > 0
	--Todo: multiple controller support
	elseif Application.platform() == "xb1" or Application.platform() == "ps4" then
		pan = stingray.Pad1.axis(stingray.Pad1.axis_index("right")) * 10
		Vector3.set_y(pan, -pan.y)
		move = stingray.Pad1.axis(stingray.Pad1.axis_index("left"))

		input.jump = stingray.Pad1.pressed(stingray.Pad1.button_index(Utils.plat(nil, "a", nil, "cross")))
		input.crouch = stingray.Pad1.pressed(stingray.Pad1.button_index(Utils.plat(nil, "b", nil, "circle")))
		input.run = stingray.Pad1.button(stingray.Pad1.button_index(Utils.plat(nil, "x", nil, "square" ))) > 0
	end

	input.move:store(Vector3.normalize(move))
	input.pan:store(pan)
end

local function update_touch_input(self)
	local move = Vector3(0, 0, 0)
	local pan = Vector3(0, 0, 0)
	local input = self.input
	local state = self.touch_state
	local touch = Utils.touch_interface()
	local has_pan_contact = state.pan_id and touch.has_contact(state.pan_id)
	local has_move_contact = state.move_id and touch.has_contact(state.move_id)

	-- Remove lifted sticks and handle tapping
	if state.pan_id and (not has_pan_contact or touch.is_touch_up(state.pan_id)) then
		local dt = Application.time_since_launch() - state.pan_t
		if has_pan_contact then
			local delta = Utils.location(touch, state.pan_id) - state.pan_ref:unbox()
			if dt < 0.5 and Vector3.length(delta) < 5 then
				input.jump = true
			end
		end
		state.pan_id = nil
	end
	if state.move_id and (not has_move_contact or touch.is_touch_up(state.move_id)) then
		local dt = Application.time_since_launch() - state.move_t
		if has_move_contact then
			local delta = Utils.location(touch, state.move_id) - state.move_ref:unbox()
			if dt < 0.5 and Vector3.length(delta) < 5 then
				input.crouch = true
			end
		end
		state.move_id = nil
	end

	-- Handle new touches
	local contacts = {touch.contacts()}
	for _, id in ipairs(contacts) do
		if touch.is_touch_down(id) then
			local pos = Utils.location(touch, id)
			local w, h = stingray.Gui.resolution()
			if pos.x > w / 2 and pos.y < h / 2 and not state.move_id then
				state.move_id = id
				state.move_ref = Vector3Box(pos)
				state.move_t = Application.time_since_launch()
			elseif pos.x < w / 2 and pos.y < h / 2 and not state.pan_id then
				state.pan_id = id
				state.pan_ref:store(pos)
				state.pan_t = Application.time_since_launch()
			end
		end
	end

	-- Track pan and move
	if state.move_id then
		local delta = Utils.location(touch, state.move_id) - state.move_ref:unbox()
		delta = delta / 100
		move = delta
	end
	if state.pan_id then
		local delta = Utils.location(touch, state.pan_id) - state.pan_ref:unbox()
		delta = delta / 50
		delta.y = -delta.y / 4
		pan = delta
	end

	input.move:store(Vector3.normalize(move))
	input.pan:store(pan)
end

-- Updates the cached input state
function InputMapper:update(dt)
	if Utils.use_touch() then
		update_touch_input(self)
	else
		update_button_input(self)
	end
end
