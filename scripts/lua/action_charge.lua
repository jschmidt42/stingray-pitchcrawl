--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/action_base'

ChargeAction = class(ChargeAction, BaseAction) or {}

function ChargeAction:init()
    BaseAction.init(self, 'charge')
end

function ChargeAction:update(dt)
    
end

function ChargeAction:on_level_shutdown(level)
    
end

function ChargeAction:shutdown()
end
