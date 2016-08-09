--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/action_attack'
require 'scripts/lua/action_charge'
require 'scripts/lua/action_heal'
require 'scripts/lua/action_fireball'
require 'scripts/lua/action_move'

ActionManager = class(ActionManager) or {}

function ActionManager:init()
    self.action_handlers = {}
    self.skills = {}
    
    -- Hack register action explicitly
    self:register_action(AttackAction())
    self:register_action(MoveAction())
    self:register_action(ChargeAction())
    self:register_action(HealAction())
    self:register_action(FireballAction())
end

function ActionManager:register_action(action)
    self.action_handlers[action.name] = action
end

function ActionManager:register_skills(skill)
    self.skills[skill.name] = skill
end

function ActionManager:get_skill(name)
    assert(self.skills[name] ~= nil)
    return self.skills[name]
end

function ActionManager:get_action(name)
    assert(self.action_handlers[name] ~= nil)
    return self.action_handlers[name]
end
