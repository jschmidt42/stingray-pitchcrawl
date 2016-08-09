--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

local Picking = Picking or {}

function Picking.unscaled_box(unit)
	-- Returns the unscaled bounding box of a non-parented unit.
	local scaled_pose, unscaled_radius = Unit.box(unit)
	local scale = Matrix4x4.scale(scaled_pose)
	local unscaled_position = Matrix4x4.translation(scaled_pose)
	local unscaled_rotation = Unit.local_rotation(unit, 0)
	local unscaled_pose = Matrix4x4.from_quaternion_position(unscaled_rotation, unscaled_position)
	local scaled_radius = Vector3.multiply_elements(unscaled_radius, scale)
	return unscaled_pose, scaled_radius
end

function Picking.raycast(unit, ray_start, ray_dir, ray_length)
	local pose, radius = Picking.unscaled_box(unit)
	local is_ray_origin_inside_box = Math.point_in_box(ray_start, pose, radius)
	if is_ray_origin_inside_box then return nil, nil end

	local distance_along_ray = Math.ray_box_intersection(ray_start, ray_dir, pose, radius)
	local is_box_missed_by_ray = distance_along_ray < 0
	if is_box_missed_by_ray then return nil, nil end

	if distance_along_ray < ray_length then
		return distance_along_ray, -ray_dir
	else
		return nil, nil
	end
end

function Picking.camera_ray(camera, x, y, window)
	local v = Vector3(x, 0, y)
	local cam = Camera.screen_to_world(camera, v, window)
	local dir = Vector3.normalize(Camera.screen_to_world(camera, Vector3(x, 1, y), window) - cam)
	return cam, dir
end

function Picking.is_hit(pos, size, hit_point)
	if hit_point.x < pos.x then return false end
	if hit_point.x > pos.x + size.x then return false end
	if hit_point.y < pos.y then return false end
	if hit_point.y > pos.y + size.y then return false end
	return true
end

return Picking
