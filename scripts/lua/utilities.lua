--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

Utils = Utils or {}

function Utils.load_module(name)
	return require (name)
end

function Utils.try_load_module(name)
	local success, loaded_module = pcall(Utility.load_module, name)
	if success then
		return loaded_module
	else
		return nil
	end
end

function Utils.is_pc()
	return stingray.Application.platform() == stingray.Application.WIN32
			or stingray.Application.platform() == stingray.Application.MACOSX
end

function Utils.use_touch()
	local p = stingray.Application.source_platform()
	return p == stingray.Application.ANDROID or p == stingray.Application.IOS
end

function Utils.touch_interface()
	if Util.use_touch() and stingray.Application.platform() == stingray.Application.WIN32 then
		return stingray.SimulatedTouchPanel
	else
		return stingray.TouchPanel1
	end
end

--Returns whatever argument is appropriate for the current platform.
function Utils.plat(pc, xb1, touch, ps4)
	if Util.use_touch() then return touch end

	local p = stingray.Application.platform()
	if p == stingray.Application.XB1 then return xb1 end
	if p == stingray.Application.PS4 then return ps4 end
	return pc
end

function Utils.location(touch, id)
	-- Scale the touch input to the back buffer size.
	local back_buffer_w, back_buffer_h = stingray.Application.back_buffer_size()
	local touch_resolution = touch.resolution()
	local scale = stingray.Vector3(back_buffer_w / touch_resolution.x, back_buffer_h / touch_resolution.y, 1.0)
	local scaled_coordinates = stingray.Vector3.multiply_elements(touch.location(id), scale)
	return scaled_coordinates
end
