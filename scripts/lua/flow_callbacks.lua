--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

Flow = Flow or {}

function Flow.GetMonsterStrength(params)
	local m_unit = params.unit
	
	local monsters = Game.game_manager.monsters
	for _, m in pairs(monsters) do
		if m.unit == m_unit then
			params.str = m.strength
			return params
		end
	end
	
	assert(false)
	return params
end

function Flow.UnitMux(params)
	local index = math.floor(params.index)
	if index < 0 or index > 7 then
		print("Index out of range: " .. index)
		return params
	end
	
	if index == 0 then
		params.unit = params.unit1
	end
	if index == 1 then
		params.unit = params.unit2
	end
	if index == 2 then
		params.unit = params.unit3
	end
	if index == 3 then
		params.unit = params.unit4
	end
	if index == 4 then
		params.unit = params.unit5
	end
	if index == 5 then
		params.unit = params.unit6
	end
	if index == 6 then
		params.unit = params.unit7
	end
	if index == 7 then
		params.unit = params.unit8
	end
	
	return params
end

function Flow.GetCurrentCharacter(params)
	local currentCharacter = Game.game_manager:current_character()
	params.unit = currentCharacter.unit
	return params
end

function Flow.EnemyActionDone(params)
	local currentCharacter = Game.game_manager:current_character()
	currentCharacter:action_done(nil, true)
	return params
end

function Flow.SwitchNumeric1(params)
	params.value = params.value1
	return params
end

function Flow.SwitchNumeric2(params)
	params.value = params.value2
	return params
end

function Flow.SelectUnitBasedOnThreatLevel(params)
	local units = {params.unit1, params.unit2, params.unit3}
	local threats = {params.threat1, params.threat2, params.threat3}
	
	if threats[1] <= 0 and threats[2] <= 0 and threats[3] <= 0 then
		params.unit = nil
		params.threat = 0
		params.found = false
		return params
	end
	
	local maxThreat = 0
	local maxUnit = nil
	
	for i = 1,3 do
		if threats[i] > maxThreat then
			maxThreat = threats[i]
			maxUnit = units[i]
		end
	end
	
	params.unit = maxUnit
	params.threat = maxThreat
	params.found = true
	return params
end

function Flow.DistanceThreatFunction(params)
	local distance = params.distance
	
	params.threat = 1.5 / math.log(distance + 1.0)
	
	return params
end

function Flow.GetCharacterByName(params)
	local charName = params.name
	
	local heroes = Game.game_manager.heroes
	for _, h in pairs(heroes) do
		if h.id == charName then
			params.unit = h.unit
			return params
		end
	end
	
	params.unit = nil
	return params
end

function Flow.GetCharacterStats(params)
	local current_unit = params.name
	
	local characters = Game.game_manager.all_characters
	for _, c in pairs(characters) do
		if c.unit == current_unit then
			params.hp = c.hp
			params.is_alive = c.hp > 0
			return params
		end
	end
	
	params.hp = 0
	params.is_alive = false
	return params
end

function Flow.ForwardCollision(params)
    Game.game_manager:handle_collision(params)
    return params
end
