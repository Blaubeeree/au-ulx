local CATEGORY_NAME = "Voting"
local gamemode_error = "The current gamemode is not among us!"

---[Next Round Slay Voting]----------------------------------------------------------------------------
local function voteslaynrDone2(t, target, time, ply, reason)
  local shouldslaynr = false

  if t.results[1] and t.results[1] > 0 then
    shouldslaynr = true

    if reason then
      ulx.fancyLogAdmin(ply, "#A will allow #T to be slain next round for (#s)", target, reason)
    else
      ulx.fancyLogAdmin(ply, "#A will allow #T to be slain next round", target)
    end
  else
    ulx.fancyLogAdmin(ply, "#A will not allow the slay of #T next round", target)
  end

  if shouldslaynr then
    if GetConVar("gamemode"):GetString() ~= "amongus" then
      ULib.tsayError(ply, gamemode_error, true)
    else
      target:SetPData("slaynr_slays", target:GetPData("slaynr_slays", 0) + 1) --add the new slays

      if not target:GetPData("slaynr_reason") then
        target:SetPData("slaynr_reason", reason)
      end

      GAMEMODE:Player_MarkCrew(target)
      target:ChatPrint("Based on a vote, you will be slain next round")
    end
  end
end

local function voteslaynrDone(t, target, time, ply, reason)
  local results = t.results
  local winner
  local winnernum = 0

  for id, numvotes in pairs(results) do
    if numvotes > winnernum then
      winner = id
      winnernum = numvotes
    end
  end

  local ratioNeeded = GetConVar("ulx_voteslaynrSuccessratio"):GetInt()
  local minVotes = GetConVar("ulx_voteslaynrMinvotes"):GetInt()
  local str

  if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
    str = "Vote results: User will live next round. (" .. (results[1] or "0") .. "/" .. t.voters .. ")"
  else
    str = "Vote results: User will be slain next round, pending approval. (" .. winnernum .. "/" .. t.voters .. ")"

    ulx.doVote("Accept result and slay " .. target:Nick() .. "?", {"Yes", "No"}, voteslaynrDone2, 30000, {ply}, true, target, time, ply, reason)
  end

  ULib.tsay(_, str)
  ulx.logString(str)

  if game.IsDedicated() then
    Msg(str .. "\n")
  end
end

function ulx.voteslaynr(calling_ply, target_ply, reason)
  if voteInProgress then
    ULib.tsayError(calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true)

    return
  end

  local msg = "Slay " .. target_ply:Nick() .. " next round?"

  if reason and reason ~= "" then
    msg = msg .. " (" .. reason .. ")"
  end

  ulx.doVote(msg, {"Yes", "No"}, voteslaynrDone, nil, nil, nil, target_ply, nil, calling_ply, reason)

  ulx.fancyLogAdmin(calling_ply, "#A wants to have #T slain next round", target_ply)
end

local voteslaynr = ulx.command(CATEGORY_NAME, "ulx votesnr", ulx.voteslaynr, "!votesnr")

voteslaynr:addParam{
  type = ULib.cmds.PlayerArg
}

voteslaynr:addParam{
  type = ULib.cmds.StringArg,
  hint = "Reason",
  ULib.cmds.optional, ULib.cmds.takeRestOfLine
}

voteslaynr:defaultAccess(ULib.ACCESS_ADMIN)
voteslaynr:help("Starts a vote to have the target slain the next round.")

if SERVER then
  ulx.convar("voteslaynrSuccessratio", "0.6", nil, ULib.ACCESS_ADMIN) -- The ratio needed for a voteslaynr to succeed
end

if SERVER then
  ulx.convar("voteslaynrMinvotes", "1", nil, ULib.ACCESS_ADMIN) -- Minimum votes needed for voteslaynr
end

---[Spectator Voting]----------------------------------------------------------------------------
local function votefsDone2(t, target, time, ply, reason)
  local shouldfs = false

  if t.results[1] and t.results[1] > 0 then
    shouldfs = true
    ulx.fancyLogAdmin(ply, "#A will allow #T to be forced to spectate.", target)
  else
    ulx.fancyLogAdmin(ply, "#A will not allow #T to be forced to spectate.", target)
  end

  if shouldfs then
    if GetConVar("gamemode"):GetString() ~= "amongus" then
      ULib.tsayError(ply, gamemode_error, true)
    else
      target:Kill()
      target:ConCommand("au_spectator_mode 1")
      target:ConCommand("au_cl_idlepopup")
    end
  end
end

local function votefsDone(t, target, time, ply, reason)
  local results = t.results
  local winner
  local winnernum = 0

  for id, numvotes in pairs(results) do
    if numvotes > winnernum then
      winner = id
      winnernum = numvotes
    end
  end

  local ratioNeeded = GetConVar("ulx_votefsSuccessratio"):GetInt()
  local minVotes = GetConVar("ulx_votefsMinvotes"):GetInt()
  local str

  if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
    str = "Vote results: User will be sent to spectator. (" .. (results[1] or "0") .. "/" .. t.voters .. ")"
  else
    str = "Vote results: User will be sent to spectator, pending approval. (" .. winnernum .. "/" .. t.voters .. ")"

    ulx.doVote("Accept result and send " .. target:Nick() .. " to spectator?", {"Yes", "No"}, votefsDone2, 30000, {ply}, true, target, time, ply, reason)
  end

  ULib.tsay(nil, str) -- TODO, color?
  ulx.logString(str)

  if game.IsDedicated() then
    Msg(str .. "\n")
  end
end

function ulx.votefs(calling_ply, target_ply, reason)
  if voteInProgress then
    ULib.tsayError(calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true)

    return
  end

  local msg = "Force " .. target_ply:Nick() .. " to spectator?"

  if reason and reason ~= "" then
    msg = msg .. " (" .. reason .. ")"
  end

  ulx.doVote(msg, {"Yes", "No"}, votefsDone, nil, nil, nil, target_ply, time, calling_ply, reason)

  ulx.fancyLogAdmin(calling_ply, "#A wants to have #T moved to spectator.", target_ply)
end

local votefs = ulx.command(CATEGORY_NAME, "ulx votefs", ulx.votefs, "!votefs")

votefs:addParam{
  type = ULib.cmds.PlayerArg
}

votefs:addParam{
  type = ULib.cmds.StringArg,
  hint = "Reason",
  ULib.cmds.optional, ULib.cmds.takeRestOfLine
}

votefs:defaultAccess(ULib.ACCESS_ADMIN)
votefs:help("Starts a vote to have the target forced into spectator mode.")

if SERVER then
  ulx.convar("votefsSuccessratio", "0.6", nil, ULib.ACCESS_ADMIN) -- The ratio needed for a votefs to succeed
end

if SERVER then
  ulx.convar("votefsMinvotes", "1", nil, ULib.ACCESS_ADMIN) -- Minimum votes needed for votefs
end