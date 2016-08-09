--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

-- Include Stingray namespaces
Application = stingray.Application
Unit = stingray.Unit
Actor = stingray.Actor
Window = stingray.Window
World = stingray.World
Level = stingray.Level
Gui = stingray.Gui
Color = stingray.Color
Keyboard = stingray.Keyboard
Mouse = stingray.Mouse
Camera = stingray.Camera
Material = stingray.Material
Quaternion = stingray.Quaternion
QuaternionBox = stingray.QuaternionBox
Vector2 = stingray.Vector2
Vector3 = stingray.Vector3
Vector3Box = stingray.Vector3Box
Matrix4x4 = stingray.Matrix4x4
ShadingEnvironment = stingray.ShadingEnvironment

require 'scripts/lua/game'
require 'scripts/lua/flow_callbacks'

function init()
	Game.init()
end

function shutdown()
	Game.shutdown()
end

function update(dt)
	Game.update(dt)
end

function render()
	Game.render()
end
