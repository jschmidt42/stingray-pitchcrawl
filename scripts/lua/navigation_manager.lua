--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/event_manager'
require 'scripts/lua/component_manager'
require 'scripts/lua/camera_freeflight'
require 'scripts/lua/camera_gameplay'

NavigationManager = class(NavigationManager, ComponentManager)

shared_cam_pos = shared_cam_pos or Vector3Box(Vector3.zero())
shared_cam_rot = shared_cam_pos or QuaternionBox(Quaternion.identity())

function NavigationManager:init()
	
	ComponentManager.init(self)
	
	--Disable the default level camera
	Game.set_camera_enabled(Game.get_enabled_camera(), false)
	
	------------------------------------------
	--Add all navigation mode to be supported
	------------------------------------------
	
	local freeflight_entity = {}
	self:add_component(freeflight_entity, FreeFlight())
	
	local gamer_entity = {}
	self.game_cam = GameCam()
	self:add_component(gamer_entity, self.game_cam)
	-----------------------------------------------
	
	self:activate("GameCam")

	EventManager.subscribe("SwitchCamMode", self.toggle_cam_mode, self)
end

function NavigationManager:toggle_cam_mode()
	if self.cam_mode == "FreeFlight" then
		self:activate("GameCam")
	else
		self:activate("FreeFlight")
	end
end

function NavigationManager:activate(mode)
	for entity, tab in pairs(self.components) do
		self.cam_mode = mode
		local component = tab[1] --components are added like this: self.components[entity] = {component, owning_level}
		if component.name == mode then
			component:activate()
		else
			component:deactivate()
		end
	end
end
