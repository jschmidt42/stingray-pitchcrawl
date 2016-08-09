--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

require 'scripts/lua/action_base'

HealAction = class(HealAction, BaseAction) or {}

function HealAction:init()
    BaseAction.init(self, 'heal')
end

function HealAction:update(dt)
    
end

function HealAction:on_level_shutdown(level)
    
end

function HealAction:shutdown()
end


return HealAction
