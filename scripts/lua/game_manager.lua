--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

require 'scripts/lua/character'
require 'scripts/lua/hero'
require 'scripts/lua/monster'
require 'scripts/lua/event_manager'

local table_utils = require 'scripts/lua/table_utils'
local Picking = require 'scripts/lua/picking'

GameManager = class(GameManager) or {}

----------------------------------------------------------------------------
local GameState = class(GameState)

function GameState:init(manager)
    self.manager = manager
    self.parent_state = nil
end

function GameState:update(dt) end
function GameState:enter() end
function GameState:exit() end

----------------------------------------------------------------------------
-- Game states
local GameInit = class(GameInit, GameState)
local GamePlay = class(GamePlay, GameState)

----------------------------------------------------------------------------
function GameInit:update(dt)
    self.manager:transition_to(GamePlay)
end

-----------------------------------------------------------------------------

function GamePlay:init(manager)
    GameState.init(self, manager)
    self.elapsed_time = 0
end

function GamePlay:enter()
    Entity.spawn(self.manager.world, 'entities/fireball', Vector3(1.4, -5, 0))
end

function GamePlay:update(dt)
    self.elapsed_time = self.elapsed_time + dt
    if self.elapsed_time > 1 then
        print "playing..."
        self.elapsed_time = self.elapsed_time - 1
    end
end

-----------------------------------------------------------------------------

function GameManager:init()
    self.all_characters = {}
    self.heroes = {}
    self.monsters = {}
    self.waiting_characters = {}
    self.ready_characters = {}
    self.state = GameInit(self)

    local world = Game.world
    local units = Level.units(Game.level)

    -- Spawn the unit selector
    self.unit_selector = World.spawn_unit(world, "units/ring/ring")
    Unit.set_local_position(self.unit_selector, 1, Vector3(-10000, -10000, -10000))

    -- Parse level for all units that are pitch (hero and monster, possibly props)
    for _, u in pairs(units) do
        if Unit.has_data(u,"PitchType") then
            local pitch_type = Unit.get_data(u,"PitchType")
            if pitch_type == "hero" then
                local hero_entity = {}
                local hero_component = Hero(u)
                -- self:add_component(hero_entity, hero_component)

                table.insert(self.all_characters, hero_component)
                table.insert(self.heroes, hero_component)
                table.insert(self.waiting_characters, hero_component)

            elseif pitch_type == "monster" then
                local monster_entity = {}
                local monster_component = Monster(u)
                -- self:add_component(monster_entity, monster_component)

                table.insert(self.all_characters, monster_component)
                table.insert(self.monsters, monster_component)
                table.insert(self.waiting_characters, monster_component)
            end
        end
    end

    self.world = world
    self.gui = World.create_screen_gui(self.world, "immediate")
    self.img_mat = Gui.material(self.gui, "materials/image")

    self.materials = {}

    self.action_size = {x = 75, y = 75}
    self.init_size = {x = 75, y = 75}
    self.init_bar = {}
    self.action_bar = {}

    self.game_cam = Game.navigation_manager.game_cam.camera_wrapper.camera

    EventManager.subscribe("PassTurn", self.character_passes, self)
    EventManager.subscribe("ReactivateCurrentCharacter", self.activate_current_character, self)
    EventManager.subscribe("MouseDown", self.mouse_down, self)
    EventManager.subscribe("MouseUp", self.mouse_up, self)
end

function GameManager:transition_to(NextState)
    self.state:exit()
    self.state = NextState(self)
    self.state:enter()
    return self.state
end

function GameManager:push_state(NextState)
    local new_state = NextState(self)
    new_state.parent = self.state
    self.state = new_state
    self.state:enter()
    return self.state
end

function GameManager:pop_state()
    self.state:exit()
    self.state = self.parent
end

function GameManager:update(dt)
    if self:game_over() then
        return
    end
    
    -- Evaluate state machine
    self.state:update(dt)

    -- We have a current character selected, pass input to it.
    if table.getn(self.ready_characters) > 0 then
        self.ready_characters[1]:update(dt)
    else
        -- Wait until we have a character ready for action
        self:time_passes()
    end

    -- Check if a character died by falling
    for i, c in table_utils.ripairs(self.waiting_characters) do
        local chr_pos = Unit.world_position(c.unit, 1)

        if chr_pos.z < -0.1 or c.hp <= 0 then
            -- Play die animation
            Unit.animation_event(c.unit, "Die")
            -- Remove from lists
            table.remove(self.waiting_characters, i)
            self:remove_character_in_list(c, self.all_characters)
            self:remove_character_in_list(c, self.ready_characters)
            self:remove_character_in_list(c, self.monsters)
            self:remove_character_in_list(c, self.heroes)
            self:build_init_bar()
        end
    end
    -- If not check for winning conditions
end

function GameManager:game_over()
    if table.getn(self.heroes) == 0 or table.getn(self.monsters) == 0 then
        local w, h = Application.back_buffer_size()
        local pos = Vector3(w/2, h/2, 0)
        if table.getn(self.heroes) == 0 then
            self:draw_text("Monsters win!!", pos)
        elseif table.getn(self.monsters) == 0 then
            self:draw_text("Heroes win!!", pos)
        end

        return true
    end

    return false
end

function GameManager:remove_character_in_list(character, list)
    for i, c in table_utils.ripairs(list) do
        if c == character then
            table.remove(list, i)
            break
        end
    end
end

function GameManager:render()
    self:draw_init_sequence()
    self:draw_current_character_actions()
    self:draw_health_bars()
end

function GameManager:get_character_from_unit(unit)
    for i, character in pairs(self.all_characters) do
        if character.unit == unit then
            return character
        end
    end

    return nil
end

function GameManager:handle_collision(data)
    -- Impulse = "vector3"
    -- Position = "vector3"
    -- Normal = "vector3"
    -- SeparationDistance = "float"
    -- TouchingUnit = "unit"
    -- TouchedActor = "actor"
    -- TouchingActor = "actor"
    if data == nil then
        return
    end

    local touched_unit = Actor.unit(data.TouchedActor)
    local touched_character = self:get_character_from_unit(touched_unit)

    local touching_character = self:get_character_from_unit(data.TouchingUnit)

    if touched_character == self:current_character()  and touching_character ~= nil then
        self:apply_damage(touching_character, touched_character.strength)
    end
end

function GameManager:apply_damage(character, dmg)
    character.hp = character.hp - dmg
end

function GameManager:is_click_on_action(button, pos)
    for i, desc in pairs(self.action_bar) do
        if Picking.is_hit(desc.pos, self.action_size, pos) then
            return desc
        end
    end

    return nil
end

function GameManager:is_click_on_init(button, pos)
    for i, desc in pairs(self.init_bar) do
        if Picking.is_hit(desc.pos, self.init_size, pos) then
            return desc
        end
    end

    return nil
end

function GameManager:mouse_up(button, pos)
    local current_character = self:current_character()
    local mouse_pos = Mouse.axis(2)
    local action_desc = self:is_click_on_action(button, mouse_pos)

    if action_desc ~= nil and current_character ~= nil then
        current_character:set_action(action_desc.name)
        self:build_action_bar()
        return
    end

    local init_desc = self:is_click_on_init(button, mouse_pos)
    if init_desc ~= nil then
        return
    end

    if current_character ~= nil then
        current_character:mouse_up(button, mouse_pos)
    end
end

function GameManager:mouse_down(button, pos)
    local current_character = self:current_character()
    local mouse_pos = Mouse.axis(2)
    local action_desc = self:is_click_on_action(button, mouse_pos)

    if action_desc ~= nil then
        return
    end

    local init_desc = self:is_click_on_init(button, mouse_pos)
    if init_desc ~= nil then
        return
    end

    if current_character ~= nil then
        current_character:mouse_down(button, mouse_pos)
    end
end

function GameManager:draw_init_sequence()
    local w, h = Application.back_buffer_size()

    local pos = Vector3(10, h - 10 - self.init_size.y, 0)
    local color = Color(128, 20, 20, 20)
    local current_color = Color(128, 20, 100, 20)
    local text_pos = Vector3(20, h - 10 - self.init_size.y, 10)
    local size = Vector2(self.init_size.x, self.init_size.y)

    for i, desc in ipairs(self.init_bar) do
        pos.x = desc.pos.x
        pos.y = desc.pos.y

        if desc.is_current then
            local selected_pos = Vector3(pos.x -5, pos.y - 5, -1)
            local selected_size = Vector2(self.init_size.x + 10, self.init_size.y + 10)
            Gui.rect(self.gui, selected_pos, selected_size, current_color)
        end

        self:draw_sprite(desc.id, pos, size)

        text_pos.y = pos.y + 5

        local text = desc.name
        if not desc.is_ready then
            text = text .. " : " .. desc.fatigue
        end

        self:draw_text(text, text_pos)
    end
end

function GameManager:draw_current_character_actions()
    local c = self:current_character()
    if c == nil then
        return
    end

    local selected_color = Color(128, 0, 250, 0)
    local color = Color(128, 20, 20, 20)
    local text_pos = Vector3(20, 10 + self.action_size.y / 2 - 30, 10)

    for i, action_desc in ipairs(self.action_bar) do
        local pos = Vector3(action_desc.pos.x, action_desc.pos.y, 0)
        local size = Vector2(self.action_size.x, self.action_size.y)

        if action_desc.is_current then
            local selected_pos = Vector3(pos.x -5, pos.y - 5, -1)
            local selected_size = Vector2(self.action_size.x + 10, self.action_size.y + 10)
            Gui.rect(self.gui, selected_pos, selected_size, selected_color)
        end

        self:draw_sprite(action_desc.name, pos, size)

        text_pos.x = pos.x + 10
        self:draw_text(action_desc.name, text_pos)
    end
end

function GameManager:draw_health_bars()
    local color = Color(128, 200, 20, 20)
    local size = Vector2(75, 10)

    for i, c in ipairs(self.all_characters) do
        if c.hp > 0 then
            local character_pos = Unit.world_position(c.unit, 1)
            local mat, extents = Unit.box(c.unit)
            local cam_screen_pos = Camera.world_to_screen(self.game_cam, character_pos)
            local screen_pos = Vector3(cam_screen_pos.x - size.x / 2, cam_screen_pos.z + 20, 0)

            local health_ratio = c.hp / c.start_hp
            size.x = size.x * health_ratio

            Gui.rect(self.gui, screen_pos, size, color)
        end

    end
end

function GameManager:draw_text(text, pos)
    Gui.text(self.gui, text, "gui/fonts/open_sans_16", 16, "gui/fonts/open_sans_16", pos)
end

function GameManager:test_gui()
    Gui.text(self.gui, "YO!!", "gui/fonts/open_sans_16", 16, "gui/fonts/open_sans_16", Vector3(100, 100, 0))

    local pos = Vector3(200, 200, 0)
    local size = Vector2(200, 200)
    local color = Color(255, 0, 0)
    Gui.rect(self.gui, pos, size, color)

    local material = 'materials/image'
    Material.set_texture(self.img_mat, "thumbnail_slot", "gui/hud/Block")
    Gui.bitmap(self.gui, material, Vector3(0, 0, 0), Vector3(100, 100, 0))

    Material.set_texture(self.img_mat, "thumbnail_slot", "gui/hud/Bash")
    Gui.bitmap(self.gui, material, Vector3(500, 500, 0), Vector3(100, 100, 0))
end

function GameManager:current_character()
    if table.getn(self.ready_characters) > 0 then
        return self.ready_characters[1];
    end

    return nil
end

function GameManager:action_done(character)
    assert(character == self:current_character())
    self:character_passes()
end

function GameManager:time_passes()
    repeat
        -- Each character fatigue is decremented. Character with 0 fatigue are ready for actions:
        for i = table.getn(self.waiting_characters), 1, -1 do
            local c = self.waiting_characters[i]
            c.fatigue = c.fatigue - 1
            if c.fatigue == 0 then
                table.insert(self.ready_characters, c)
                table.remove(self.waiting_characters, i)
            end
        end
    until self:current_character() ~= nil

    --self:print_character_sequence_info()
    self:activate_current_character()
    Game.navigation_manager.game_cam:focus_current_character()
    self:show_unit_selector()
end


function GameManager:print_character_sequence_info()
    print("Waiting: \n")
    for i = table.getn(self.waiting_characters), 1, -1 do
        local c = self.waiting_characters[i]
        print("     " .. c.name .. "  fatigue: " .. c.fatigue)
    end

    print("Ready: \n")
    for i = table.getn(self.ready_characters), 1, -1 do
        local c = self.ready_characters[i]
        print("     " .. c.name)
    end
end

function GameManager:character_passes()
    -- Character is not active anymore.
    local current = self:current_character()
    table.remove(self.ready_characters, 1)
    -- Currently add fatigue to hte user so it shifts in the initiative queue
    current:rest()
    table.insert(self.waiting_characters, current)

    -- find the next suitable character
    self:time_passes()
end

function GameManager:activate_current_character()
    assert(self:current_character() ~= nil)
    self:current_character():activate()
    print('Current character is ' .. self:current_character().name)

    self:build_action_bar()
    self:build_init_bar()
end

function GameManager:build_action_bar()
    local c = self:current_character()
    if c == nil then
        return
    end

    local w, h = Application.back_buffer_size()
    local pos = Vector3(150, 10, 0)

    self.action_bar = {}

    for name, action in pairs(c.actions) do
        -- if material doesn't exist, create it in material table
        self:init_sprite(name)

        local action_desc = {
            pos = {x = pos.x, y = pos.y},
            action = action,
            name = name,
            is_current = c.current_action ~= nil and name == c.current_action.name
        }
        table.insert(self.action_bar, action_desc)
        pos.x = pos.x + self.action_size.x + 10
    end
end

function reverse_table(t)
    local reversedTable = {}
    local itemCount = #t
    for k, v in ipairs(t) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end

function GameManager:get_init_sequence()
    local init_sequence = {}

    for i = 1, table.getn(self.waiting_characters) do
        local c = self.waiting_characters[i]
        local desc = {
            character = c,
            name = c.name,
            id = c.id,
            is_ready = false,
            is_current = false,
            fatigue = c.fatigue
        }

        table.insert(init_sequence, desc)
    end

    table.sort(init_sequence, function (a,b) return a.fatigue > b.fatigue end)

    for i = table.getn(self.ready_characters), 1, -1 do
        local c = self.ready_characters[i]
        local desc = {
            character = c,
            name = c.name,
            id = c.id,
            is_ready = true,
            is_current = i == 1
        }

        table.insert(init_sequence, desc)
    end

    return reverse_table(init_sequence)
end

function GameManager:build_init_bar()
    self.init_bar = self:get_init_sequence()

    local w, h = Application.back_buffer_size()
    local pos = Vector3(10, h - 10 - self.init_size.y, 0)

    for i = 1, table.getn(self.init_bar) do
        local desc = self.init_bar[i]

        self:init_sprite(desc.id)

        desc.pos = {x = pos.x, y = pos.y}
        pos.y = pos.y - self.init_size.y - 10
    end
end

function GameManager:init_sprite(id)
    if self.materials[id] == nil then
        self.materials[id] = Gui.material(self.gui, "gui/hud/" .. id)
        Material.set_texture(self.materials[id], "thumbnail_slot", "gui/hud/" .. id)
    end
end

function GameManager:draw_sprite(id, pos, size)
    Gui.bitmap(self.gui, "gui/hud/" .. id, pos, size)
end

function GameManager:show_unit_selector()
    Unit.set_visibility(Game.game_manager.unit_selector, "all", true)
    Unit.set_visibility(Game.game_manager.unit_selector, "arrow", false)
end

function GameManager:hide_unit_selector()
    Unit.set_visibility(Game.game_manager.unit_selector, "all", false)
end
