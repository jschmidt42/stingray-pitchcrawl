--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

Flow = Flow or {}

function Flow.GetMonsterStrength(params)
	local m_unit = params.Unit

	local monsters = Game.game_manager.monsters
	for _, m in pairs(monsters) do
		if m.unit == m_unit then
			params.Str = m.strength
			return params
		end
	end

	assert(false)
	return params
end

function Flow.UnitMux(params)
	local index = math.floor(params.Index)
	if index < 0 or index > 7 then
		print("Index out of range: " .. index)
		return params
	end

	if index == 0 then
		params.Unit = params.Unit1
	end
	if index == 1 then
		params.Unit = params.Unit2
	end
	if index == 2 then
		params.Unit = params.Unit3
	end
	if index == 3 then
		params.Unit = params.Unit4
	end
	if index == 4 then
		params.Unit = params.Unit5
	end
	if index == 5 then
		params.Unit = params.Unit6
	end
	if index == 6 then
		params.Unit = params.Unit7
	end
	if index == 7 then
		params.Unit = params.Unit8
	end

	return params
end

function Flow.GetCurrentCharacter(params)
	local currentCharacter = Game.game_manager:current_character()
	params.Unit = currentCharacter.unit
	return params
end

function Flow.EnemyActionDone(params)
	local currentCharacter = Game.game_manager:current_character()
	currentCharacter:action_done(nil, true)
	return params
end

function Flow.SwitchNumeric1(params)
	params.Value = params.Value1
	return params
end

function Flow.SwitchNumeric2(params)
	params.Value = params.Value2
	return params
end

function Flow.SelectUnitBasedOnThreatLevel(params)
	local units = {params.Unit1, params.Unit2, params.Unit3}
	local threats = {params.Threat1, params.Threat2, params.Threat3}

	if threats[1] <= 0 and threats[2] <= 0 and threats[3] <= 0 then
		params.Unit = nil
		params.Threat = 0
		params.Found = false
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

	params.Unit = maxUnit
	params.Threat = maxThreat
	params.Found = true
	return params
end

function Flow.DistanceThreatFunction(params)
	local distance = params.Distance
	assert(distance > 0)
	params.Threat = 1.5 / math.log(distance + 1.0)
	return params
end

function Flow.GetCharacterByName(params)
	local charName = params.Name

	local heroes = Game.game_manager.heroes
	for _, h in pairs(heroes) do
		if h.id == charName then
			params.Unit = h.unit
			return params
		end
	end

	params.Unit = nil
	return params
end

function Flow.GetCharacterStats(params)
	local current_unit = params.Name

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
