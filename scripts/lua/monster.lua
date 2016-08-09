--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

require 'scripts/lua/character'
require 'scripts/lua/event_manager'

Monster = class(Monster, Character) or {}

function Monster:init(unit)
    Character.init(self, unit)
end

function Monster:activate()
    Character.activate(self)

    Unit.flow_event(self.unit, "MonsterActivated")
end

function Monster:update(dt)
    Character.update(self, dt)
end

function Monster:on_level_shutdown(level)
end

function Monster:shutdown()
end
