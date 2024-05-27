local MaxArmor = 98
local LoadedTextures = {}

-- do not touch anything at below
local set_ped_armor = SetPedArmour
local add_ped_armor = AddArmourToPed
local set_entity_health = SetEntityHealth
local set_entity_coords = SetEntityCoords
local set_entity_coords_no_offset = SetEntityCoordsNoOffset
local set_ped_coords_keep_vehicle = SetPedCoordsKeepVehicle
local add_blip_entity = AddBlipForEntity
local set_entity_visible = SetEntityVisible
local clear_ped_tasks = ClearPedTasks
local resurrect_player = NetworkResurrectLocalPlayer
local set_entity_alpha = SetEntityAlpha
local set_player_model = SetPlayerModel
local set_player_invincible = SetPlayerInvincible
local set_entity_invincible = SetEntityInvincible
local request_streamed_texture = RequestStreamedTextureDict
local set_run_sprint = SetRunSprintMultiplierForPlayer
local draw_sprite = DrawSprite
local set_focus_area = SetFocusArea
local set_cam_root = SetCamRot
local render_script_cams = RenderScriptCams

SetFocusArea = function(...)
	exports['HUNK-AC']:DontCheckFreeCam()
	return set_focus_area(...)
end

SetCamRot = function(...)
	exports['HUNK-AC']:DontCheckFreeCam()
	return set_cam_root(...)
end

RenderScriptCams = function(render, ...)
	if render == 1 or render == true then
		exports['HUNK-AC']:DontCheckFreeCam()
	elseif render == 0 or render == false then
		exports['HUNK-AC']:StartCheckFreeCam()
	end
	
	return render_script_cams(render, ...)
end

local lastSpeed = {}
SetRunSprintMultiplierForPlayer = function(pedid, speed)
	if lastSpeed[tostring(pedid)] == nil then
		lastSpeed[tostring(pedid)] = speed
	end
	
	if speed ~= lastSpeed[tostring(pedid)] then
		lastSpeed[tostring(pedid)] = speed
		exports['HUNK-AC']:SetRunSprint(speed)
	end
	return set_run_sprint(pedid, speed)
end


DrawSprite = function(textureDict, ...)
	
	if LoadedTextures[string.lower(textureDict)] == nil then
		LoadedTextures[string.lower(textureDict)] = true
		
		Citizen.CreateThread(function()
			for i = 1, 3, 1 do
				exports['HUNK-AC']:StreamedTexture(string.lower(textureDict))
				Wait(2000)
			end
		end)
	end

	return draw_sprite(textureDict, ...)
end

RequestStreamedTextureDict = function(dict, flag)
	if LoadedTextures[string.lower(dict)] == nil then
		LoadedTextures[string.lower(dict)] = true
		
		while not NetworkIsSessionStarted() do 
			Citizen.Wait(0)
		end
		Citizen.CreateThread(function()
			for i = 1, 3, 1 do
				exports['HUNK-AC']:StreamedTexture(string.lower(dict))
				Wait(2000)
			end
		end)
		
	end
	
	return request_streamed_texture(dict, flag)
end

AddArmourToPed = function(ped, amount)
	if IsPedAPlayer(ped) then
		local currentArmour = GetPedArmour(PlayerPedId())
		if (currentArmour + amount) > MaxArmor then
			return set_ped_armor(ped, (currentArmour + amount) - ((currentArmour + amount) - MaxArmor))
		else
			return add_ped_armor(ped, amount)
		end
	else
		return add_ped_armor(ped, amount)
	end
end

SetPedArmour = function(ped, amount)
	if IsPedAPlayer(ped) then
		if amount > MaxArmor then
			return set_ped_armor(ped, MaxArmor)
		else
			return set_ped_armor(ped, amount)
		end
	else
		return set_ped_armor(ped, amount)
	end
end

local lastInvincible = {}
SetEntityInvincible = function(entity, toggle)
	if IsEntityAPed(entity) and IsPedAPlayer(entity) then
		if lastInvincible[tostring(entity)] == nil then
			lastInvincible[tostring(entity)] = toggle
			if toggle then
				exports['HUNK-AC']:DontCheckGodMode()
			else
				exports['HUNK-AC']:StartCheckGodMode()
			end
		else
			if lastInvincible[tostring(entity)] ~= toggle then
				lastInvincible[tostring(entity)] = toggle
				if toggle then
					exports['HUNK-AC']:DontCheckGodMode()
				else
					exports['HUNK-AC']:StartCheckGodMode()
				end
			end
		end
	end

	return set_entity_invincible(entity, toggle)
end

local lastInvincible2 = {}
SetPlayerInvincible = function(player, toggle)

	if lastInvincible2[tostring(player)] == nil then
		lastInvincible2[tostring(player)] = toggle
		if toggle then
			exports['HUNK-AC']:DontCheckGodMode()
		else
			exports['HUNK-AC']:StartCheckGodMode()
		end
	else
		if lastInvincible[tostring(player)] ~= toggle then
			lastInvincible[tostring(player)] = toggle
			if toggle then
				exports['HUNK-AC']:DontCheckGodMode()
			else
				exports['HUNK-AC']:StartCheckGodMode()
			end
		end
	end	

	return set_player_invincible(player, toggle)
end

SetPlayerModel = function(player, model)
	exports['HUNK-AC']:PlayerPedChanged()

	return set_player_model(player, model)
end

local lastHealth = {}
SetEntityHealth = function(ped, amount)

	if IsPedAPlayer(ped) then
		if lastHealth[tostring(ped)] == nil then
			lastHealth[tostring(ped)] = amount
			if amount > GetEntityHealth(ped) then
				exports['HUNK-AC']:PlayerHealedByServer()
			end
		else
			if GetEntityHealth(ped) ~= lastHealth[tostring(ped)] then
				lastHealth[tostring(ped)] = GetEntityHealth(ped)
			end
			if amount > lastHealth[tostring(ped)] then
				exports['HUNK-AC']:PlayerHealedByServer()
			end
			
			lastHealth[tostring(ped)] = amount
		end	
	end

	return set_entity_health(ped, amount)
end

local lastAlpha = {}

SetEntityAlpha = function(ped, amount, skin)

	if lastAlpha[tostring(ped)] == nil then
		lastAlpha[tostring(ped)] = amount
	end

	if lastAlpha[tostring(ped)] ~= amount and IsPedAPlayer(ped) then
		lastAlpha[tostring(ped)] = amount
		if amount < 50 then
			exports['HUNK-AC']:DontCheckAlpha()
		else
			exports['HUNK-AC']:StartCheckAlpha()
		end
	end
	
	return set_entity_alpha(ped, amount, skin)
end

NetworkResurrectLocalPlayer = function(...)
	exports['HUNK-AC']:PlayerHealedByServer()
	exports['HUNK-AC']:DontCheckTeleport()
	return resurrect_player(...)
end

SetEntityCoords = function(target, ...)
	if IsEntityAPed(target) and IsPedAPlayer(target) then
		exports['HUNK-AC']:DontCheckTeleport()
	end
	
	return set_entity_coords(target, ...)
end

SetEntityCoordsNoOffset = function(target, ...)
	if IsEntityAPed(target) and IsPedAPlayer(target) then
		exports['HUNK-AC']:DontCheckTeleport()
	end
	
	return set_entity_coords_no_offset(target, ...)
end

SetPedCoordsKeepVehicle = function(target, ...)
	if IsEntityAPed(target) and IsPedAPlayer(target) then
		exports['HUNK-AC']:DontCheckTeleport()
	end
	
	return set_ped_coords_keep_vehicle(target, ...)
end




AddBlipForEntity = function(target)
	if IsEntityAPed(target) and IsPedAPlayer(target) then
		exports['HUNK-AC']:DontCheckBlip()
	end
	
	return add_blip_entity(target)
end

local lastVisible = {}
SetEntityVisible = function(target, flag)
	if IsEntityAPed(target) and IsPedAPlayer(target) then
		if lastVisible[tostring(target)] == nil then
			lastVisible[tostring(target)] = flag
		end
		
		if lastVisible[tostring(target)] ~= flag and flag == false then
			exports['HUNK-AC']:DontCheckInvis()
		elseif lastVisible[tostring(target)] ~= flag and flag then
			exports['HUNK-AC']:StartCheckInvis()
		end
	end	
	
	return set_entity_visible(target, flag)
end

ClearPedTasksImmediately = function(target)
	return clear_ped_tasks(target)
end

