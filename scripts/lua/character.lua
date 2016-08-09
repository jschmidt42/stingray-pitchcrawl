--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/event_manager'

local PitchDb = require 'scripts/lua/database'

Character = class(Character) or {}

function Character:init(unit)
    self.unit = unit
    self.type = Unit.get_data(unit,"PitchType")
    self.id = Unit.get_data(unit,"PitchId")

    local entry = PitchDb[self.type][self.id]
    local stats = entry.stats

    self.start_hp = stats.hp
    self.start_mp = stats.mp
    self.start_strength = stats.strength
    self.start_intelligence = stats.intelligence
    self.start_fatigue = stats.fatigue

    self.hp = stats.hp
    self.mp = stats.mp
    self.strength = stats.strength
    self.intelligence = stats.intelligence
    self.fatigue = stats.fatigue

    self.name = entry.name

    self.actions = {}
    assert(entry.actions ~= nil)
    for i, action in pairs(entry.actions) do
        local action_desc = { handler = nil, options = {} }
        action_desc.handler = Game.action_manager:get_action(action.name)
        action_desc.options = action
        self.actions[action.name] = action_desc
    end

    self.skills = {}
    if entry.skills ~= nil then
        for skill_name, options in pairs(entry.skills) do
            local skill_desc = { handler = nil, options = {} }
            skill_desc.handler = Game.action_manager:get_skill(skill_name)
            skill_desc.options = options
            self.skills[action_name] = skill_desc
        end
    end

    self.current_action = nil
end

function Character:rest()
    self.fatigue = self.start_fatigue
end

function Character:mouse_up(button, pos)
    if self.current_action ~= nil then
        self.current_action:mouse_up(data)
    end
end

function Character:mouse_down(button, pos)
    if self.current_action ~= nil then
        self.current_action:mouse_down(data)
    end
end

function Character:set_action(action_name)
    self.current_action = self.actions[action_name].handler
    self.current_action:bind(self, self.actions[action_name].options)
end

function Character:activate()
    local unit_selector = Game.game_manager.unit_selector
    Unit.set_local_position(unit_selector, 1, Unit.world_position(self.unit, 1))
    Unit.set_visibility(unit_selector, "arrow", false)

    Game.debug_display_text("Charater "..self.id.." turn", {255, 0, 0, 255})
end

function Character:action_done(action, executed)
    if executed then
        Game.game_manager:action_done(self, executed)
    else
        -- action is cancelled
    end
end

function Character:update(dt)

    if self.current_action ~= nil then
        -- We have a current action selected, allows this action to handle user input
        self.current_action:update(dt)
    end

    local unit_selector = Game.game_manager.unit_selector
    local chr_pos = Unit.world_position(self.unit, 1)
    local chr_pos_fixed = chr_pos
    Vector3.set_z(chr_pos_fixed, 0.1)
    Unit.set_local_position(unit_selector, 1, chr_pos_fixed)
end

function Character:shutdown()
    
end

function Character:on_level_shutdown(level)
    
end

function Character:pass_turn()
    Game.game_manager:action_done(self)
end
