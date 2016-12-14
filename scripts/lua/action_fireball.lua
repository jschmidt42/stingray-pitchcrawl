--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

require 'scripts/lua/event_manager'
require 'scripts/lua/action_base'

FireballAction = class(FireballAction, BaseAction) or {}

local AttackStates = {
	WaitFlicking = 1,
	InitializeFlicking = 2,
	Aim = 3,
	Shoot = 4,
	Moving = 5,
	WaitBurn = 6,
	Done = 7
}

function FireballAction:init()
    BaseAction.init(self, 'fireball')
    self.flicking_orientation = QuaternionBox()
end

function FireballAction:activate()
	self.state = AttackStates.WaitFlicking
	self.angle = math.pi/2
	self.force = self.character.strength / 2.5
end

function FireballAction:update(dt)

	local world = Game.world
	local flicking_gizmo = Game.game_manager.unit_selector
	local arrow_bone_node_idx = Unit.node(flicking_gizmo, "joint2")

	if self.state == AttackStates.InitializeFlicking then

		-- Show flicking arrow on the unit
		Unit.set_visibility(flicking_gizmo, "arrow", true)

		Unit.animation_event(self.character.unit, "FlickAttack")

		Window.set_clip_cursor(true)

		self.state = AttackStates.Aim
	elseif self.state == AttackStates.Aim then

		local character_pos = Unit.world_position(self.character.unit, 1)
		local game_cam = Game.navigation_manager.game_cam.camera_wrapper.camera
		local start_pos = Camera.world_to_screen(game_cam, character_pos)
		start_pos.y = start_pos.z
		start_pos.z = 0
		local flick_vector = Mouse.axis(2) - start_pos
		local flick_angle = math.atan2(flick_vector.y, flick_vector.x) - math.pi/2 + Game.navigation_manager.game_cam.angle
		local flick_orientation = Quaternion(Vector3(0,0,1), flick_angle)

		self.force = Vector3.length(flick_vector) / 50
		if self.force > self.character.strength then
			self.force = self.character.strength
		elseif self.force < 1 then
			self.force = 1
		end

		local chr_pos_fixed = Unit.local_position(flicking_gizmo, 1)
		Vector3.set_z(chr_pos_fixed, 0.7)
		Unit.set_local_position(flicking_gizmo, 1, chr_pos_fixed)

		local q_gizmo = Quaternion.multiply(flick_orientation, Quaternion(Vector3(1,0,0), -math.pi/2))
		Unit.set_local_rotation(flicking_gizmo, 1, q_gizmo)
		Unit.set_local_position(flicking_gizmo, arrow_bone_node_idx, Vector3(self.force, 0, 0))

		-- Apply flicking direction to unit
		local actor = Unit.actor(self.character.unit, 1)
		Actor.teleport_rotation(actor, flick_orientation)
		self.flicking_orientation:store(flick_orientation)

	elseif self.state == AttackStates.Shoot then
		-- Hide the flicking arrow
		Unit.set_visibility(flicking_gizmo, "arrow", false)

		Unit.animation_event(self.character.unit, "AttackHit")

		local character_pos = Unit.world_position(self.character.unit, 1)

		-- spawn fireball and add impulse to it
		local flick_orientation = self.flicking_orientation:unbox()
		local flick_vector = Quaternion.forward(flick_orientation)
		local fireball = world:spawn_unit("units/dungeon/barrel_01", character_pos + Vector3.multiply(flick_vector, 2))
		self.fireball = fireball
		local fireball_actor = Unit.actor(fireball, 1)
		Actor.add_impulse(fireball_actor, Vector3.multiply(flick_vector, self.force * 60))

		Window.set_show_cursor(true)
		Window.set_clip_cursor(false)

		self.state = AttackStates.Moving
		Game.game_manager:hide_unit_selector()

	elseif self.state == AttackStates.Moving then

		-- check if unit's mover has stabilized
		local actor = Unit.actor(self.fireball, 1)

		if Vector3.length(Actor.velocity(actor)) < 0.2 then
			self.state = AttackStates.WaitBurn
			self.wait = 2
		end

	elseif self.state == AttackStates.WaitBurn then

		if self.wait < 0 then
			self.state = AttackStates.Done
		else
			self.wait = self.wait - dt
		end

	elseif self.state == AttackStates.Done then
		self:action_done(true)
	end

end

function FireballAction:mouse_down(data)
	if Game.input.mouse.down.left and self.state == AttackStates.WaitFlicking then
		self.state = AttackStates.InitializeFlicking
	end
end

function FireballAction:mouse_up(button, pos)
	if Game.input.mouse.up.left and self.state == AttackStates.Aim then
		self.state = AttackStates.Shoot
	end
end

function FireballAction:on_level_shutdown(level)
end

function FireballAction:shutdown()
end
