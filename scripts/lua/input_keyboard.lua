--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/event_manager'
require 'scripts/lua/utilities'

KeyboardController = class(KeyboardController) or {}

function KeyboardController:init()

	self.keyBinds = {}
	self.repeatedKeyBinds = {}
	self.movement = Vector3Box()
	self.shift = false
	self.ctrl = false
	
	--Add key binds here. The key will trigger the associated event
	--Example:
	--
	self.keyBinds['p']	= "SwitchCamMode"
	self.keyBinds['c']	= "ReactivateCurrentCharacter"
	self.keyBinds['n']	= "PassTurn"


	--self.keyBinds['esc']	= {"LoadScene", {"main_menu"}}
end

function KeyboardController:on_level_shutdown(level)
	
end

function KeyboardController:shutdown()
	
end

function KeyboardController:update(dt)
	if not Utils.is_pc() then return end
	
	--Automatic key binds to the event system
	local b
	for k,v in pairs(self.keyBinds) do
		b = Keyboard.button_index(k)
		if b and Keyboard.pressed(b) then
			if type(v) == "table" then
				EventManager.raise_event(v[1], unpack(v[2]))
			else
				EventManager.raise_event(v)
			end
		end
	end
	for k,v in pairs(self.repeatedKeyBinds) do
		b = Keyboard.button_index(k)
		if b and Keyboard.button(b) > 0.01 then
			if type(v) == "table" then
				EventManager.raise_event(v[1], unpack(v[2]))
			else
				EventManager.raise_event(v)
			end
		end
	end
	-------------------------------------

	self.shift = ( Keyboard.button(Keyboard.button_index("left shift")) + Keyboard.button(Keyboard.button_index("right shift")) ) > 0.001
	self.ctrl = ( Keyboard.button(Keyboard.button_index("left ctrl")) + Keyboard.button(Keyboard.button_index("right ctrl")) ) > 0.001
		
	--WASD + Arrow key movements
	local x = Keyboard.button(Keyboard.button_index("right")) - Keyboard.button(Keyboard.button_index("left"))
	x = x + Keyboard.button(Keyboard.button_index("d")) - Keyboard.button(Keyboard.button_index("a"))
	local y = Keyboard.button(Keyboard.button_index("up")) - Keyboard.button(Keyboard.button_index("down"))
	y = y + Keyboard.button(Keyboard.button_index("w")) - Keyboard.button(Keyboard.button_index("s"))
	local z = Keyboard.button(Keyboard.button_index("page up")) - Keyboard.button(Keyboard.button_index("page down"))
	z = z + Keyboard.button(Keyboard.button_index("q")) - Keyboard.button(Keyboard.button_index("e"))

	self.movement:store(Vector3 (x, y, z))
	-----------------------------------------------
end

function KeyboardController:get_movement()
	return self.movement:unbox()
end
