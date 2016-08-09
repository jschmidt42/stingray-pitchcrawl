--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/component_manager'
require 'scripts/lua/event_manager'
require "scripts/lua/input_keyboard"
require "scripts/lua/input_mouse"

InputManager = class(InputManager, ComponentManager)

function InputManager:init()
	ComponentManager.init(self)

	------------------------------------------
	--Add all inputs to be supported
	------------------------------------------
	local keyboard_entity = {}
	self.keyboard = KeyboardController()
	self:add_component(keyboard_entity, self.keyboard)

	local mouse_entity = {}
	self.mouse = MouseController()
	self:add_component(mouse_entity, self.mouse)

end
