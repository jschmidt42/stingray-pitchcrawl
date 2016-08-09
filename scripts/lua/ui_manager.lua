--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

require 'scripts/lua/component_manager'

UIManager = class(UIManager, ComponentManager)

function UIManager:init(proj_name, proj_path)
	ComponentManager.init(self)
end

function UIManager:shutdown()
end

function UIManager:add_scene(name)
	
end

function UIManager:on_update(dt)
	ComponentManager.on_update(self)
end
