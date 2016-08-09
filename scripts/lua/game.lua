--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--
--[[
	Customized functions for controlling what happens for a particular loaded level.
	These classes should define any  of

	init(level)
	start(level)
	update(level, dt)
	shutdown(level)
	render(level)
]]--

require 'scripts/lua/event_manager'
require 'scripts/lua/input_manager'
require 'scripts/lua/navigation_manager'
require 'scripts/lua/action_manager'
require 'scripts/lua/game_manager'
require 'scripts/lua/input_mapper'
require 'scripts/lua/debug_scrollbox'

Game = Game or {}

Game.level_names = {
	basic = "levels/level_00"
}

-- Game global configurations
Game.config = {
	standalone_init_level_name = Game.level_names.basic,
	camera_unit = "core/appkit/units/camera/camera",
	camera_index = 0,
	exit_standalone_with_esc_key = false,
	stop_world_sounds_on_level_change = true,
}

-- These high level engine objects are created during Game.init() and
-- can be referenced by the user project to extend behavior.
Game.world = Game.world or nil
Game.level = Game.level or nil
Game.level_name = Game.level_name or nil
Game.camera_unit = Game.camera_unit or nil
Game.input_mapper = Game.input_mapper or nil
Game.was_setup = Game.was_setup or false
Game.enabled_cameras = Game.enabled_cameras or {}

-- Access to Editor's Test Level name. Will be nil if not currently running an
-- Editor Test Level or Game.setup_application() was not called.
Game.test_level_initialize = Game.test_level_initialize or false
Game.test_level_name = Game.test_level_name or nil
Game.test_level_resource_name = Game.test_level_resource_name or nil

-- Setup the game in test mode or not.
function Game.setup_application()
	-- Window does not exist on some platforms
	if Window and Utils.use_touch() then
		Window.set_show_cursor(true)
	end

	Game.input_mapper = InputMapper()

	--Support for the Editor Test Level
	if LEVEL_EDITOR_TEST then
		Game.test_level_resource_name = "__level_editor_test"
		Game.test_level_name = Application.get_data([[LevelEditing]], [[level_resource_name]])
		if not Game.test_level_name then
			Game.test_level_name = "" -- untitled, unsaved level
		end

		Application.autoload_resource_package(Game.test_level_resource_name)
	else
		if Window then
			Window.set_focus()
			Window.set_mouse_focus(true)
		end
	end

	Game.was_setup = true
end

function Game.init()

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then
		print("Waiting for test level initialization...")
		return
	end

	local config = Game.config

	-- Set load_level and unload_level overrides. This is needed so that the
	-- Game Change Level flow node can properly init and shutdown the levels.
	Game.setup_application()

	local world = Application.new_world()
	Game.world = world
	Game.debug_scrollbox = DebugScrollbox(world)
	Game.viewport = Application.create_viewport(world, "default")
	Game.gui = World.create_screen_gui(world, "immediate")

	-- Create a default camera. This can be retrieved and manipulated
	-- by flow or lua. It is also given to the Player in change_level.
	local camera_unit = World.spawn_unit(world, config.camera_unit)
	Game.camera_unit = camera_unit
	-- We need the default camera to render the world to draw levels or 2d UI.
	Game.set_camera_enabled(Unit.camera(camera_unit, 1), camera_unit, true)

	-- Support Test Level and standalone initial level load. The Editor Test Level
	-- is saved as a temporary file named "__level_editor_test". The actual original
	-- level name is stored in lua Application sript data for reference. The
	-- Game stores the original name in Game.test_level_name and the temp resource
	-- name in Game.test_level_resource_name during Game.setup_application().
	-- Note that an untitled/unsaved level will have a Game.test_level_name of "".
	local standalone_init_level_name = config.standalone_init_level_name
	local level_resource_name = Game.test_level_resource_name or standalone_init_level_name
	if level_resource_name then
		Game.load_level(level_resource_name, Game.test_level_name)
	else
		print "Game.init: No level to load."
	end
end

-- Called after loading level.
function Game.start()
	Window.set_show_cursor(true)
	Window.set_mouse_focus(true)

	-- Create main systems
	Game.component_manager = ComponentManager(ComponentManager.update_post_world)
	Game.input = InputManager()
	Game.navigation_manager = NavigationManager()
	Game.action_manager = ActionManager()
	Game.game_manager = GameManager(Game.world)
end

function Game.update(dt)

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then return end

	if not Game.test_level_initialize and LEVEL_EDITOR_TEST then
		Window.set_show_cursor(true)
		Window.set_mouse_focus(true)
		Game.test_level_initialize = true
	end

	-- Update editor Test Level support
	local f5_pressed = Keyboard.pressed(Keyboard.button_index('f5'))
	local esc_pressed = Keyboard.pressed(Keyboard.button_index('esc'))
	if f5_pressed or esc_pressed or Window.is_closing() then
		print("Stopping test level.");
		Application.console_send { type = 'stop_testing' }
		return
	end

	Game.input_mapper:update(dt)

	ComponentManager.update_managers(dt, ComponentManager.update_pre_world)

	Game.debug_scrollbox:update(dt)
	Game.world:update(dt)

	ComponentManager.update_managers(dt, ComponentManager.update_post_world)

	Level.trigger_level_update(Game.level)
	Game.game_manager:update(dt)

	if Game.config.exit_standalone_with_esc_key and Keyboard.pressed(Keyboard.button_index('esc')) and Game.is_standalone() then
		shutdown()
		Application.quit()
	end
end

function Game.render()

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then return end

	ShadingEnvironment.apply(Game.level_shading_environment)
	for camera, _ in pairs(Game.enabled_cameras) do
		Application.render_world(Game.world, camera, Game.viewport, Game.level_shading_environment)
	end

end

function Game.shutdown()

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then return end

	if Window then
		Window.set_show_cursor(false)
	end

	ComponentManager.shutdown_managers()

	local world = Game.world
	if world == nil then
		print "Error in Game.shutdown. No world."
		return
	else
		if Game.level then
			World.destroy_level(world, Game.level)
			Game.level = nil
		end

		Application.release_world(world) -- destroying the world destroys its units as well
		Game.world = nil
	end
	Game.camera_unit = nil
end

function Game.load_shading_environment(level, world)

	-- Load the shading environment for the level if there is one.
	local env_name = nil

	if Level.has_data(level, "shading_environment") then
		env_name = Level.get_data(level, "shading_environment")
	end

	if env_name == nil or string.len(env_name) == 0 then
		print "Warning: No shading envirnoment set in Level, applying default"
		local default_shading_environment_new = "core/stingray_renderer/environments/midday/midday"
		local default_shading_environment_old = "core/rendering/default_outdoor"
		if Application.can_get("shading_environment", default_shading_environment_new) then
			env_name = default_shading_environment_new
		else
			env_name = default_shading_environment_old
		end
	end

	local shading_environment = World.create_shading_environment(world, env_name)
	World.set_shading_environment(world, shading_environment, env_name)

	return shading_environment
end

-- level_name is optional. It is needed if the level_name is not the
-- same as the resource_name, as is the case for the editor Test Level.
function Game.load_level(resource_name, level_name)

	if not resource_name then
		print "Error in Game.load_level: no level resource name."
		return
	end

	local world = Game.world
	level = World.load_level(world, resource_name)
	if not level then
		print ("Error in Game.load_level. Failed to load level ", resource_name)
		return
	end

	Game.level = level
	Game.level_name = level_name or resource_name

	Level.spawn_background(level)
	Game.level_shading_environment = Game.load_shading_environment(level, world)

	if stingray.Application.can_get("baked_lighting", Game.level_name) then
		print ("Loading baked_lighting for", Game.level_name)
		stingray.BakedLighting.map(world, Game.level_name)
	end

	EventManager.init()
	Game.start()

	-- The typical use case is to trigger the intiial flow Level Loaded node
	-- after lua project initialization is complete.
	Level.trigger_level_loaded(level)
end

function Game.unload_level(level)
	if not level then return end

	local config = Game.config
	if stingray.Wwise and (config.stop_world_sounds_on_level_change == nil or config.stop_world_sounds_on_level_change == true) then
		stingray.WwiseWorld.stop_all(stingray.Wwise.wwise_world(Game.world))
	end

	Game.on_level_shutdown_post_flow()

	local world = Game.world
	World.destroy_level(world, level)
	Game.level = nil
	Game.level_name = nil
end

function Game.is_standalone()
	return LEVEL_EDITOR_TEST == nil
end

-- The Unit is required because at the momet the unit is necessary for things
-- like Camera Flow Nodes so we need to track and make it accessible.
-- unit parameter is optional when disabling camera.
function Game.set_camera_enabled(camera, unit, enabled)
	if not camera then return end

	if enabled == true then
		Game.enabled_cameras[camera] = unit
	else
		Game.enabled_cameras[camera] = nil
	end
end

-- Returns two values: camera, camera_unit
-- Todo: improve. If there are multiple enabled cameras then this arbitrarily
-- returns one of them.
function Game.get_enabled_camera()
	return next(Game.enabled_cameras)
end

function Game.debug_display_text(text, color)
	Game.debug_scrollbox:add_line(text, label, color)
end
