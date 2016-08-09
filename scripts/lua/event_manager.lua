--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

EventManager = EventManager or {}

function EventManager.init()
	EventManager.events = {}
	EventManager.event_queue = {}
	EventManager.event_id = 0
end

function EventManager.shutdown()
	EventManager.events = {}
	EventManager.event_queue = {}
	EventManager.event_id = 0
end

--[[ 
TODO-FH: Remove the automatically created table, 
so that event typo would raise an error??
--]]
local function get_event(event)
	local e = EventManager.events[event]
	if e == nil then
		EventManager.events[event] = {}
		e = EventManager.events[event]
	end
	return e
end

function EventManager.subscribe(event, callback, object)
	table.insert(get_event(event), { o = object, cb = callback })
end

local function compare_sub(sub1, sub2)
	local identical = true
	for k,v in pairs(sub1) do
		identical = identical and v == sub2[k]
	end
	return identical
end

function EventManager.unsubscribe(event, callback, object)
	local sub_data = { o = object, cb = callback }
	local e = get_event(event)
	for i,v in ipairs(e) do
		if compare_sub(sub_data, v) then
			e[i] = nil
			return true
		end
	end
	return false
end

function EventManager.raise_event(event, ...)
	for _, sub in ipairs(get_event(event)) do
		-- TODO-FH: double check calling convention
		if sub.o ~= nil then
			sub.cb(sub.o, ...)
		else
			sub.cb(...)
		end
	end
end

function EventManager.raise_timed_event(event, seconds, ...)
	local event_id = EventManager.event_id + 1
	EventManager.event_id = event_id
	EventManager.event_queue[event_id] = { e = event, expiration = Game.managed_world.world:time() + seconds, time_interval = seconds, remaining_iterations = 1, args = {...} }
	return event_id
end

--For an infinitely recurring event use amount = -1
function EventManager.raise_recurring_event(event, seconds, amount, ...)
	local event_id = EventManager.event_id + 1
	EventManager.event_id = event_id
	EventManager.event_queue[event_id] = {e = event, expiration = Game.managed_world.world:time() + seconds, time_interval = seconds, remaining_iterations = amount, args = {...} }
	return event_id
end

function EventManager.cancel_timed_event(event_id)
	if event_id then EventManager.event_queue[event_id] = nil end
end

function EventManager.event_remaining_time(event_id)
	local queued_event = EventManager.event_queue[event_id]
	return queued_event and (queued_event.expiration - Game.managed_world.world:time()) or 0
end

function EventManager.reset_timed_event(event_id, seconds)
	local queued_event = EventManager.event_queue[event_id]
	queued_event.expiration = Game.managed_world.world:time() + seconds
end
-- Use a coroutine for this?
function EventManager.consume_queued_events()
	local time = Game.managed_world.world:time()
	local event_queue = EventManager.event_queue
	for i,event in pairs(event_queue) do
		if event.expiration < time then
			EventManager.raise_event(event.e, unpack(event.args))
			event.remaining_iterations = event.remaining_iterations > 0 and event.remaining_iterations - 1 or event.remaining_iterations
			if event.remaining_iterations == 0 then
				event_queue[i] = nil
			else
				event.expiration = event.expiration + event.time_interval
			end
		end
	end
end
