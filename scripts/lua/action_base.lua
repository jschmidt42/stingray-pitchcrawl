--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

BaseAction = class(BaseAction) or {}

function BaseAction:init(name)
    self.name = name
end

function BaseAction:bind(character, options)
    self.character = character
    self.options = options

    self:activate()
end

function BaseAction:activate()
end

function BaseAction:update(dt)
    
end

function BaseAction:mouse_up(button, pos)
    
end

function BaseAction:mouse_down(button, pos)
    
end

function BaseAction:action_done(executed)
    self.character:action_done(self, executed)
end

function BaseAction:shutdown()
end

function BaseAction:on_level_shutdown(level)
    
end

return BaseAction
