--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

require 'scripts/lua/class'

DebugScrollbox = class(DebugScrollbox)

local is_dev_build = Application.build() == "dev" or Application.build() == "debug"
local font = 'core/performance_hud/debug'
local font_material = 'core/performance_hud/debug'
local default_text_color = {255, 255, 255, 255} -- argb
local line_count_max = 10
local text_length_max = 128
local draw_lifetime = 5

-- positioning and sizing: these are the basline values for a y screen resolutin 
-- of 720 pixels and are scaled to device.
local scale_res_y_baseline = 720 -- font will be font_size_default when screen resolution y is this value, and scales with the y resolution as it increases/decreases
local box_top_offset_x_default = 160
local box_top_offset_y_default = 65
local font_size_default = 16
local line_spacing_default = 8
local initial_box_text_length = 50 -- default visual box to a small size, only expand if larger text encountered
local border_buffer_default = 5

function DebugScrollbox:init(world)
	local is_enabled = is_dev_build and line_count_max > 0
	self.is_enabled = is_enabled
	if is_enabled == false then return end

	self.world = world
	self.gui = stingray.World.create_screen_gui(world, "immediate")

	-- preallocates a list and will treat it like a ring buffer
	self.line_index = 0
	local lines = {}
	for i = 1, line_count_max do
		lines[i] = {
				text = "",
				time_added = -draw_lifetime,
				color = {default_text_color[1], default_text_color[2], default_text_color[3], default_text_color[4]}
			}
	end
	self.lines = lines
	self.is_visible = false
end

-- optional color must be nil or table with a, r, g, b values, e.g. {255, 255, 255, 255}
function DebugScrollbox:add_line(text, optional_color)
	if self.is_enabled == false then return end

	local color = {default_text_color[1], default_text_color[2], default_text_color[3], default_text_color[4]}
	if optional_color then color = {optional_color[1], optional_color[2], optional_color[3], optional_color[4]} end

	local line_index = self.line_index + 1
	local lines = self.lines
	if line_index > #lines then line_index = 1 end
	self.line_index = line_index
	local line = lines[line_index]

	if string.len(text) > text_length_max then text = string.sub(text, 1, text_length_max) end
	line.text = text
	line.time_added = World.time(self.world)
	line.color = color
	self.is_visible = true
end

local function fade_value(current_time, time_added)
	local x = (current_time - time_added) / draw_lifetime
	return 1 - (-x) ^ 20
end

function DebugScrollbox:update(dt)
	if self.is_enabled == false then return end
	if self.is_visible == false then return end

	-- box positioning
	local w, h = Application.back_buffer_size()
	local scale_factor = (h / scale_res_y_baseline)
	local start_x = math.floor(box_top_offset_x_default * scale_factor)
	local start_y = h - math.floor(box_top_offset_y_default * scale_factor)
	local draw_pos = Vector2(start_x, start_y)

	local gui = self.gui

	-- draw text
	local line_spacing = math.floor(line_spacing_default * scale_factor)
	local font_size = math.floor(scale_factor * font_size_default)
	local lines_drawn = 0
	local text
	local text_height = 0
	local longest_text_len = 0
	local text_color = {0, 0, 0} -- worker
	local current_time = World.time(self.world)
	local start_index = self.line_index
	local end_index = start_index + 1
	local lines = self.lines
	if end_index > #lines then end_index = 1 end
	local i = start_index
	repeat
		local line = lines[i]
		local time_added = line.time_added
		if (current_time - line.time_added) < draw_lifetime then
			text = line.text
			text_color = line.color
			local fade = fade_value(current_time, time_added)
			local color = Color(text_color[1] * fade, text_color[2], text_color[3], text_color[4])
			local len = string.len(text)
			if len > longest_text_len then longest_text_len = len end
			Gui.text(gui, text, font, font_size, font_material, draw_pos, color)
			if text_height == 0 then
				local min, max = stingray.Gui.text_extents(gui, text, font, font_size)
				text_height = max.y
			end
			lines_drawn = lines_drawn + 1
		else
			break
		end
		draw_pos.y = draw_pos.y - text_height - line_spacing
		i = i - 1
		if i == 0 then i = #lines end
	until i == end_index

	-- draw background
	if lines_drawn > 0 then
		local border_buffer = math.floor(border_buffer_default * scale_factor)
		local back_color = Color(25, 40, 30, 230)
		local text_len = initial_box_text_length
		if longest_text_len > text_len then text_len = longest_text_len end
		local draw_extents = Vector2(
			(text_len * font_size / 2) + (border_buffer * 2), -- using font_size is an approximation for max font width
			-(((text_height + line_spacing) * lines_drawn) + (border_buffer * 2)) + line_spacing
		)
		Gui.rect(
			gui,
			Vector3(
				start_x - border_buffer,
				start_y + border_buffer + text_height,
				-10
			),
			draw_extents,
			back_color
		)
	end

	self.is_visible = lines_drawn > 0
end
