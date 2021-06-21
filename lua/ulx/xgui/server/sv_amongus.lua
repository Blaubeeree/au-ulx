local function AutoReplicateConVar(name, type)
  local cv = GetConVar(name)
  if not cv then return end
  local cv_value

  if type == "int" then
    cv_value = cv:GetInt()
  elseif type == "float" then
    cv_value = cv:GetFloat()
  elseif type == "bool" then
    cv_value = cv:GetBool()
  end

  ULib.replicatedWritableCvar(name, "rep_" .. name, cv_value, true, true, "xgui_gmsettings")
end

local function init()
  if GetConVar("gamemode"):GetString() ~= "amongus" then return end
  -- game settings
  AutoReplicateConVar("au_max_imposters", "int")
  AutoReplicateConVar("au_kill_cooldown", "int")
  AutoReplicateConVar("au_time_limit", "int")
  AutoReplicateConVar("au_killdistance_mod", "float")
  AutoReplicateConVar("sv_alltalk", "bool")
  AutoReplicateConVar("au_taskbar_updates", "int")
  AutoReplicateConVar("au_player_speed_mod", "float")
  -- meeting
  AutoReplicateConVar("au_meeting_available", "int")
  AutoReplicateConVar("au_meeting_cooldown", "int")
  AutoReplicateConVar("au_meeting_vote_time", "int")
  AutoReplicateConVar("au_meeting_vote_pre_time", "int")
  AutoReplicateConVar("au_meeting_vote_post_time", "int")
  AutoReplicateConVar("au_confirm_ejects", "bool")
  AutoReplicateConVar("au_meeting_anonymous", "bool")
  -- tasks
  AutoReplicateConVar("au_tasks_short", "int")
  AutoReplicateConVar("au_tasks_long", "int")
  AutoReplicateConVar("au_tasks_common", "int")
  AutoReplicateConVar("au_tasks_enable_visual", "bool")
  -- other
  AutoReplicateConVar("au_min_players", "int")
  AutoReplicateConVar("au_countdown", "int")
  AutoReplicateConVar("au_warmup_time", "int")
  AutoReplicateConVar("au_warmup_force_auto", "bool")
  hook.Run("GMAU UlxInitCustomCVar", "xgui_gmsettings")
end

xgui.addSVModule("amongus", init)