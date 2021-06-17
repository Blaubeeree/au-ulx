local CATEGORY_NAME = "AU Admin"
local gamemode_error = "The current gamemode is not among us!"

--[Global Helper Functions][Used by more than one command.]------------------------------------
--[[send_messages][Sends messages to player(s)]
@param  {[PlayerObject]} v       [The player(s) to send the message to.]
@param  {[String]}       message [The message that will be sent.]
--]]
local function send_messages(v, message)
	if type(v) == "Players" then
		v:ChatPrint(message)
	elseif type(v) == "table" then
		for i = 1, #v do
			v[i]:ChatPrint(message)
		end
	end
end

--[[corpse_find][Finds the corpse of a given player.]
@param  {[PlayerObject]} v [The player that to find the corpse for.]
--]]
local function corpse_find(v)
	v = v:GetAUPlayerTable()

	for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
		if ent:GetDTInt(15) == v.id and IsValid(ent) then return ent or false end
	end
end

--[[player_respawn][Respawns a given player.]
@param  {[PlayerObject]} v [The player to respawn.]
--]]
local function player_respawn(v)
	local corpse = corpse_find(v)

	if corpse then
		corpse:Remove()
	end

	local plyTable = v:GetAUPlayerTable()

	if not plyTable then
		error("Can't respawn that " .. v.Nick())
	end

	local point = ents.FindByClass("info_player_start")[1]
	plyTable.entity:Spawn()

	if point then
		plyTable.entity:SetPos(point:GetPos())
		plyTable.entity:SetAngles(point:GetAngles())
		plyTable.entity:SetEyeAngles(point:GetAngles())
	end

	plyTable.entity:SetRenderMode(RENDERMODE_NORMAL)
	plyTable.entity:SetMoveType(MOVETYPE_WALK)
	plyTable.entity:UnSpectate()
	GAMEMODE:Player_Unhide(plyTable.entity)
	GAMEMODE.GameData.DeadPlayers[plyTable] = nil
	GAMEMODE:Net_BroadcastDeadToGhosts()
end

--[Slay next round]---------------------------------------------------------------------------------
--[[ulx.slaynr][Slays < target(s) > at the start of the next round.]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
@param  {[Number]}			 num_slay			 [The count how many rounds the player(s) should be slayed]
@param  {[String]}			 reason 			 [The reason why the player will be slayed]
--]]
function ulx.slaynr(calling_ply, target_ply, num_slay, reason)
	if GetConVar("gamemode"):GetString() ~= "amongus" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		if ulx.getExclusive(target_ply, calling_ply) then
			ULib.tsayError(calling_ply, ulx.getExclusive(target_ply, calling_ply), true)
		elseif num_slay < 0 then
			ULib.tsayError(calling_ply, "Invalid integer:\"" .. num_slay .. "\" specified.", true)
		else
			if num_slay > 0 then
				target_ply:SetPData("slaynr_slays", num_slay)
				target_ply:SetPData("slaynr_reason", reason)
				GAMEMODE:Player_MarkCrew(target_ply)
			else
				target_ply:RemovePData("slaynr_slays")
				target_ply:RemovePData("slaynr_reason")
			end

			local chat_message = ""

			if num_slay == 0 then
				chat_message = "#T will not be slain next round."
			elseif num_slay == 1 then
				chat_message = "#A will slay #T next round for #s."
			elseif num_slay > 1 then
				chat_message = "#A will slay #T for the next " .. tostring(num_slay) .. " rounds for #s."
			end

			ulx.fancyLogAdmin(calling_ply, chat_message, target_ply, reason)
		end
	end
end

local slaynr = ulx.command(CATEGORY_NAME, "ulx slaynr", ulx.slaynr, "!slaynr")

slaynr:addParam{
	type = ULib.cmds.PlayerArg
}

slaynr:addParam{
	type = ULib.cmds.NumArg,
	max = 100,
	default = 1,
	hint = "rounds",
	ULib.cmds.optional, ULib.cmds.round
}

slaynr:addParam{
	type = ULib.cmds.StringArg,
	hint = "reason",
	ULib.cmds.optional
}

slaynr:defaultAccess(ULib.ACCESS_ADMIN)
slaynr:help("Slays target(s) for a number of rounds")

--[Helper Functions]---------------------------------------------------------------------------
hook.Add("GMAU GameStart", "SlayPlayersNextRound", function()
	local slayedPlayers = {}

	for _, v in pairs(player.GetAll()) do
		local slays_left = tonumber(v:GetPData("slaynr_slays")) or 0

		if slays_left > 0 then
			local slays_left2 = slays_left - 1

			if slays_left2 == 0 then
				v:RemovePData("slaynr_slays")
				v:RemovePData("slaynr_reason")
			else
				v:SetPData("slaynr_slays", slays_left2)
				GAMEMODE:Player_MarkCrew(v)
			end

			GAMEMODE:Player_SetDead(v)
			table.insert(slayedPlayers, v)
		end
	end

	local slay_message

	for i = 1, #slayedPlayers do
		local v = slayedPlayers[i]
		local string_inbetween

		if i > 1 and #slayedPlayers == i then
			string_inbetween = " and "
		elseif i > 1 then
			string_inbetween = ", "
		end

		string_inbetween = string_inbetween or ""
		slay_message = (slay_message or "") .. string_inbetween
		slay_message = (slay_message or "") .. v:Nick()
	end

	local slay_message_context

	if #slayedPlayers == 1 then
		slay_message_context = "was"
	else
		slay_message_context = "were"
	end

	if #slayedPlayers ~= 0 then
		ULib.tsay(nil, slay_message .. " " .. slay_message_context .. " slain.")
	end
end)

hook.Add("PlayerSpawn", "Inform", function(ply)
	local slays_left = tonumber(ply:GetPData("slaynr_slays")) or 0
	local slay_reason = ply:GetPData("slaynr_reason")

	if not ply:IsDead() and slays_left > 0 then
		local chat_message = ""

		if slays_left > 0 then
			chat_message = chat_message .. "You will be slain this round"
		end

		if slays_left > 1 then
			chat_message = chat_message .. " and " .. (slays_left - 1) .. " round(s) after the current round"
		end

		if slay_reason then
			chat_message = chat_message .. " for \"" .. slay_reason .. "\"."
		else
			chat_message = chat_message .. "."
		end

		ply:ChatPrint(chat_message)
	end
end)

--[Force role]---------------------------------------------------------------------------------
--[[ulx.force][Forces < target(s) > to become a specified role.]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
@param  {[String]}       target_role   [The role that target player(s) will have there role set to.]
@param  {[Boolean]}      should_silent [Hidden, determines weather the output will be silent or not.]
--]]
function ulx.force(calling_ply, target_plys, target_role, should_silent)
	if GetConVar("gamemode"):GetString() ~= "amongus" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		local imposter = target_role == "imposter"
		local affected_plys = {}

		for i = 1, #target_plys do
			local v = target_plys[i]

			if ulx.getExclusive(v, calling_ply) then
				ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
			elseif not GAMEMODE:IsGameInProgress() then
				ULib.tsayError(calling_ply, "The round has not begun!", true)
			elseif v:IsDead() then
				ULib.tsayError(calling_ply, v:Nick() .. " is dead!", true)
			elseif v:IsImposter() == imposter then
				ULib.tsayError(calling_ply, v:Nick() .. " is already " .. target_role, true)
			else
				local plyTable = v:GetAUPlayerTable()
				local imposters = {}
        GAMEMODE.GameData.Imposters[plyTable] = imposter or nil
        GAMEMODE:Player_RefreshKillCooldown(plyTable)

        for ply, IsImposter in pairs(GAMEMODE.GameData.Imposters) do
          table.insert(imposters, ply.entity)
        end

				for _, ply in ipairs(player.GetAll()) do
					net.Start("UpdateImposters")
					net.WriteTable(ply:IsImposter() and imposters or {})
					net.Send(ply)
				end

				table.insert(affected_plys, v)
			end
		end

		ulx.fancyLogAdmin(calling_ply, should_silent, "#A forced #T to become #s.", affected_plys, target_role)
		send_messages(affected_plys, "Your role has been set to " .. target_role .. ".")
	end
end

local force = ulx.command(CATEGORY_NAME, "ulx force", ulx.force, "!force")

force:addParam{
	type = ULib.cmds.PlayersArg
}

force:addParam{
	type = ULib.cmds.StringArg,
	completes = {"imposter", "crewmate"},
	hint = "- Select Role -",
	ULib.cmds.restrictToCompletes
}

force:addParam{
	type = ULib.cmds.BoolArg,
	invisible = true
}

force:defaultAccess(ULib.ACCESS_SUPERADMIN)

force:setOpposite("ulx sforce", {nil, nil, nil, true}, "!sforce", true)

force:help("Force <target(s)> to become a specified role.")

--[Helper Functions]---------------------------------------------------------------------------
if SERVER then
	util.AddNetworkString("UpdateImposters")
else
	net.Receive("UpdateImposters", function()
		GAMEMODE.GameData.Imposters = {}

    for _, ply in ipairs(net.ReadTable()) do
      GAMEMODE.GameData.Imposters[ply:GetAUPlayerTable()] = true
    end

		local imposter = LocalPlayer():IsImposter()
		GAMEMODE:HUD_Reset()
		GAMEMODE.Hud:SetupButtons(GAMEMODE.GameState.Playing, imposter)

    if imposter then
      GAMEMODE:HUD_InitializeImposterMap()
    end
	end)
end

--[Respawn]------------------------------------------------------------------------------------
--[[ulx.respawn][Respawns < target(s) > ]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
@param  {[Boolean]}      should_silent [Hidden, determines weather the output will be silent or not.]
--]]
function ulx.respawn(calling_ply, target_plys, should_silent)
	if GetConVar("gamemode"):GetString() ~= "amongus" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		local affected_plys = {}

		for i = 1, #target_plys do
			local v = target_plys[i]

			if ulx.getExclusive(v, calling_ply) then
				ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
			elseif GAMEMODE:SetGameCommencing() then
				ULib.tsayError(calling_ply, "Waiting for players!", true)
			elseif not v:GetAUPlayerTable() then
				ULib.tsayError(calling_ply, "Can't respawn a spectator!", true)
			elseif not v:IsDead() then
				ULib.tsayError(calling_ply, v:Nick() .. " is already alive!", true)
			else
				player_respawn(v)
				table.insert(affected_plys, v)
				ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned #T!", affected_plys)
				send_messages(affected_plys, "You have been respawned.")
			end
		end
	end
end

local respawn = ulx.command(CATEGORY_NAME, "ulx respawn", ulx.respawn, "!respawn")

respawn:addParam{
	type = ULib.cmds.PlayersArg
}

respawn:addParam{
	type = ULib.cmds.BoolArg,
	invisible = true
}

respawn:defaultAccess(ULib.ACCESS_SUPERADMIN)

respawn:setOpposite("ulx srespawn", {nil, nil, true}, "!srespawn", true)

respawn:help("Respawns <target(s)>.")

--[Respawn teleport]---------------------------------------------------------------------------
--[[ulx.respawntp][Respawns < target(s) > ]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_ply    [The player who will have the effects of the command applied to them.]
@param  {[Boolean]}      should_silent [Hidden, determines weather the output will be silent or not.]
--]]
function ulx.respawntp(calling_ply, target_ply, should_silent)
	if GetConVar("gamemode"):GetString() ~= "amongus" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		local affected_ply = {}

		if not calling_ply:IsValid() then
			Msg("You are the console, you can't teleport or teleport others since you can't see the world!\n")

			return
		elseif ulx.getExclusive(target_ply, calling_ply) then
			ULib.tsayError(calling_ply, ulx.getExclusive(target_ply, calling_ply), true)
		elseif GAMEMODE:SetGameCommencing() then
			ULib.tsayError(calling_ply, "Waiting for players!", true)
		elseif not target_ply:GetAUPlayerTable() then
			ULib.tsayError(calling_ply, "Can't respawn a spectator!", true)
		elseif not target_ply:IsDead() then
			ULib.tsayError(calling_ply, target_ply:Nick() .. " is already alive!", true)
		else
			local t = {}
			t.start = calling_ply:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
			t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
			t.filter = target_ply

			if target_ply ~= calling_ply then
				t.filter = {target_ply, calling_ply}
			end

			local tr = util.TraceEntity(t, target_ply)
			local pos = tr.HitPos
			player_respawn(target_ply)
			target_ply:SetPos(pos)
			table.insert(affected_ply, target_ply)
			ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned and teleported #T!", affected_ply)
			send_messages(target_ply, "You have been respawned and teleported.")
		end
	end
end

local respawntp = ulx.command(CATEGORY_NAME, "ulx respawntp", ulx.respawntp, "!respawntp")

respawntp:addParam{
	type = ULib.cmds.PlayerArg
}

respawntp:addParam{
	type = ULib.cmds.BoolArg,
	invisible = true
}

respawntp:defaultAccess(ULib.ACCESS_SUPERADMIN)

respawntp:setOpposite("ulx srespawntp", {nil, nil, true}, "!srespawntp", true)

respawntp:help("Respawns <target> to a specific location.")

--[Toggle spectator]---------------------------------------------------------------------------
--[[ulx.spec][Forces < target(s) > to and from spectator.]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
--]]
function ulx.spec(calling_ply, target_plys, should_unspec)
	if GetConVar("gamemode"):GetString() ~= "amongus" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		for i = 1, #target_plys do
			local v = target_plys[i]

			if should_unspec then
				v:ConCommand("au_spectator_mode 0")
			else
				v:Kill()
				v:ConCommand("au_spectator_mode 1")
				v:ConCommand("au_cl_idlepopup")
			end
		end

		if should_unspec then
			ulx.fancyLogAdmin(calling_ply, "#A has forced #T to join the world of the living next round.", target_plys)
		else
			ulx.fancyLogAdmin(calling_ply, "#A has forced #T to spectate.", target_plys)
		end
	end
end

local spec = ulx.command(CATEGORY_NAME, "ulx fspec", ulx.spec, "!fspec")

spec:addParam{
	type = ULib.cmds.PlayersArg
}

spec:addParam{
	type = ULib.cmds.BoolArg,
	invisible = true
}

spec:defaultAccess(ULib.ACCESS_ADMIN)

spec:setOpposite("ulx unspec", {nil, nil, true}, "!unspec")

spec:help("Forces the <target(s)> to/from spectator.")

--[Force next round]-------------------------------------------------------------------------
--[[ulx.spec][Forces < target(s) > to and from spectator.]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
@param  {[String]}       next_round    [The role that target player(s) will have there role set to.]
--]]
function ulx.forcenr(calling_ply, target_plys, next_round)
	if GetConVar("gamemode"):GetString() ~= "amongus" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		local affected_plys = {}

		for i = 1, #target_plys do
			local v = target_plys[i]
			local id = v:SteamID()

			if next_round == "imposter" then
				if GAMEMODE.PlayersMarkedForImposter[id] then
					ULib.tsayError(calling_ply, "That player is already marked for the next round", true)
				else
					GAMEMODE:Player_UnMark(v)
					GAMEMODE:Player_MarkImposter(v)
					table.insert(affected_plys, v)
				end
			elseif next_round == "crewmate" then
				if GAMEMODE.PlayersMarkedForCrew[id] then
					ULib.tsayError(calling_ply, "That player is already marked for the next round!", true)
				else
					GAMEMODE:Player_UnMark(v)
					GAMEMODE:Player_MarkCrew(v)
					table.insert(affected_plys, v)
				end
			elseif next_round == "unmark" then
				GAMEMODE:Player_UnMark(v)
				table.insert(affected_plys, v)
			end
		end

		if next_round == "unmark" then
			ulx.fancyLogAdmin(calling_ply, true, "#A has unmarked #T ", affected_plys)
		else
			ulx.fancyLogAdmin(calling_ply, true, "#A marked #T to be #s next round.", affected_plys, next_round)
		end
	end
end

local fnr = ulx.command(CATEGORY_NAME, "ulx forcenr", ulx.forcenr, "!nr")

fnr:addParam{
	type = ULib.cmds.PlayersArg
}

fnr:addParam{
	type = ULib.cmds.StringArg,
	completes = {"imposter", "crewmate", "unmark"},
	hint = "- Select Role -",
	error = "invalid role \"%s\" specified",
	ULib.cmds.restrictToCompletes
}

fnr:defaultAccess(ULib.ACCESS_SUPERADMIN)
fnr:help("Forces the target to be a special role in the following round. Doesn't overwrite the imposter count and therefor will be ignored if too many players are marked.")

--[Round Restart]-------------------------------------------------------------------------
--[[ulx.roundrestart][Restarts the current round]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[String]}			 winner			   [The team that should win.]
--]]
function ulx.roundrestart(calling_ply, winner)
	if GetConVar("gamemode"):GetString() ~= "amongus" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		GAMEMODE:Game_GameOver(GAMEMODE.GameOverReason[winner])
		ulx.fancyLogAdmin(calling_ply, "#A has restarted the round.")
	end
end

hook.Add("OnGamemodeLoaded", "AddRoundrestartCommand", function()
	local restartround = ulx.command(CATEGORY_NAME, "ulx roundrestart", ulx.roundrestart)

	restartround:addParam{
		type = ULib.cmds.StringArg,
		completes = table.GetKeys(GAMEMODE.GameOverReason),
		hint = "- Select Winner -",
		error = "invalid winner \"%s\" specified",
		ULib.cmds.restrictToCompletes
	}

	restartround:defaultAccess(ULib.ACCESS_SUPERADMIN)
	restartround:help("Restarts the round.")
end)