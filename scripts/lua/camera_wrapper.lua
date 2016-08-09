--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'
require 'scripts/lua/component_manager'

CameraWrapper = class(CameraWrapper) or {}

--Check for if listeners/observers are available

local USE_WWISE = false
if stingray.Wwise then USE_WWISE = true end

local USE_SCATTER_SYSTEM = false
if stingray.ScatterSystem then USE_SCATTER_SYSTEM = true end

local USE_TERRAIN_DECORATOR = false
-- 3/10/2015 disabled: crash when removing terrain observer and no terrain at the moment.
--if stingray.TerrainDecoration  then USE_TERRAIN_DECORATOR = true end

local function update_observers(self, pose)
	local tw = stingray.Unit.world(self.unit):timpani_world()
	tw:set_listener(1, pose)
	tw:set_listener_mode(1, stingray.TimpaniWorld.LISTENER_3D)

	if USE_WWISE then
		local wwise_world = stingray.Wwise.wwise_world(stingray.Application.main_world())
		stingray.WwiseWorld.set_listener(wwise_world, 1, pose)
	end

	if USE_TERRAIN_DECORATOR and self.terrain_decorator then
		local pos = stingray.Camera.world_position(camera)
		stingray.TerrainDecoration.move_observer(self.world, self.terrain_decorator, pos )
	end

	if USE_SCATTER_SYSTEM and self.scatter_observer then
		local pos = stingray.Camera.world_position(camera)
		stingray.ScatterSystem.move_observer(self.scatter_system, self.scatter_observer, pos)
	end
end

local function destroy(self)
	if USE_TERRAIN_DECORATOR and self.terrain_decorator then
		stingray.TerrainDecoration.destroy_observer(self.world, self.terrain_decorator)
		self.terrain_decorator = nil
	end

	if USE_SCATTER_SYSTEM and self.scatter_observer then
		stingray.ScatterSystem.destroy_observer(self.scatter_system, self.scatter_observer)
		self.scatter_observer = nil
	end
end

function CameraWrapper:init(entity, unit, camera_index)
	self.entity = entity -- object this component is associated with, can be used to access other components
	self.unit = unit
	self.camera = Unit.camera(unit, camera_index)
	self.world = Unit.world(unit)

	self.is_enabled = false

	 --Terrain decorator Observer
	 if USE_TERRAIN_DECORATOR then
		self.terrain_decorator = nil
		if self.world then
	 		self.terrain_decorator = stingray.TerrainDecoration.create_observer(self.world, stingray.Vector3(0,0,0))
	 	end
	 end

	--Scatter Observer
	if USE_SCATTER_SYSTEM then
		self.scatter_system = scatter_system
		self.scatter_observer = nil
		if self.scatter_system then
			self.scatter_observer = stingray.ScatterSystem.make_observer(self.scatter_system, stingray.Vector3(0,0,0))
		end
	end

	Game.component_manager:add_component(entity, self, Unit.level(unit))
end

function CameraWrapper:enable()
	if self.enabled == true then return end

	Game.set_camera_enabled(self.camera, self.unit, true)
	self.is_enabled = true
end

function CameraWrapper:disable()
	if self.enabled == false then return end

	local world_wrapper = Game.managed_world
	if world_wrapper and world_wrapper.world == self.world then
		world_wrapper:set_camera_enabled(self.camera, self.unit, false)
	end
	self.is_enabled = false
end

function CameraWrapper:get_camera()
	return self.camera
end

function CameraWrapper:world_pose()
	return Camera.world_pose(self.camera, self.unit)
end

function CameraWrapper:world_position()
	return Camera.world_position(self.camera, self.unit)
end

function CameraWrapper:world_rotation()
	return Camera.world_rotation(self.camera, self.unit)
end

function CameraWrapper:set_local_pose(pose)
	Unit.set_local_pose(self.unit, 1, pose)
	Camera.set_local_pose(self.camera, self.unit, pose)
end

function CameraWrapper:set_local_position(position)
	Unit.set_local_position(self.unit, 1, position)
	Camera.set_local_position(self.camera, self.unit, position)
end

function CameraWrapper:local_rotation()
	return Camera.local_rotation(self.camera, self.unit)
end

function CameraWrapper:set_local_rotation(rotation)
	Camera.set_local_rotation(self.camera, self.unit, rotation)
end

function CameraWrapper:local_pose()
	return Camera.local_pose(self.camera, self.unit)
end

function CameraWrapper:local_position()
	return Camera.local_position(self.camera, self.unit)
end

-- component callback
function CameraWrapper:update(dt)
	if not self.is_enabled then return end

	Camera.set_local_pose(self.camera, self.unit, Unit.local_pose(self.unit, 1))

	update_observers(self, Unit.world_pose(self.unit, 1))
end

-- component callback
function CameraWrapper:on_level_shutdown()
end

-- component callback
function CameraWrapper:shutdown()
	destroy(self)
end

function CameraWrapper:look_at(look_at_pos)
	local pos = Unit.local_position(self.unit, 1)
	local rot = Quaternion.look(look_at_pos - pos, Vector3(0,0,1))
	Unit.set_local_rotation(self.unit, 1, rot)
end

function CameraWrapper:move(move)
	self:set_local_position(self:local_position() + move)
end

function CameraWrapper:rotate(yaw, pitch, min_angle, max_angle)
	local q_original = Unit.local_rotation(self.unit, 1)
	local m_original = Matrix4x4.from_quaternion(q_original)

	local look_at = Quaternion.forward(q_original)
	local dot = Vector3.dot(Vector3(0,0,1), look_at)
	local next_pitch_degrees = (dot*90 + pitch*180/math.pi)
	if next_pitch_degrees > max_angle then
		pitch = math.pi*(max_angle-dot*90)/180
	elseif next_pitch_degrees < min_angle then
		pitch = math.pi*(min_angle-dot*90)/180
	end
	
	local q_yaw = Quaternion(Vector3(0,0,1), yaw)
	local q_pitch = Quaternion(Matrix4x4.x(m_original), pitch)
	
	local q_frame = Quaternion.multiply(q_yaw, q_pitch)
	local q_new = Quaternion.multiply(q_frame, q_original)
	
	self:set_local_rotation(q_new)
end

function CameraWrapper:get_horizontal_look_at_direction()
	local rot = self:local_rotation()
	local look_at = Quaternion.forward(rot)
	look_at.z = 0
	look_at = Vector3.normalize(look_at)
	return look_at
end

function CameraWrapper:vertical_fov()
	return Camera.vertical_fov(self.camera)*180/math.pi
end

function CameraWrapper:set_vertical_fov(fov)
	Camera.set_vertical_fov(self.camera, fov*math.pi/180)
end

function CameraWrapper.refresh_enabled_cameras()
	-- making use of component manager list.
	for _, component_wrapper in pairs(Game.component_manager.components) do
		local camera_wrapper = component_wrapper[1]
		if camera_wrapper.is_enabled == true then
			local world_wrapper = Game.managed_world
			if world_wrapper and world_wrapper.world == camera_wrapper.world then
				world_wrapper:set_camera_enabled(camera_wrapper.camera, camera_wrapper.unit, true)
			end
		end
	end
end
