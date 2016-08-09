--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

require 'scripts/lua/action_base'

MoveAction = class(MoveAction, BaseAction) or {}

function MoveAction:init()
    BaseAction.init(self, 'move')
end

function MoveAction:update(dt)
    
end

function MoveAction:on_level_shutdown(level)
    
end

function MoveAction:shutdown()
end
