--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/character'
require 'scripts/lua/event_manager'

Hero = class(Hero, Character) or {}

function Hero:init(unit)
    Character.init(self, unit)
end

function Hero:shutdown()
    
end

function Hero:update(dt)
    Character.update(self, dt)

end

function Hero:activate()
    Character.activate(self)
    self:set_action("attack")
end

function Hero:on_level_shutdown(level)
end
