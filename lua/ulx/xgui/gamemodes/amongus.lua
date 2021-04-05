-- Defines ttt cvar limits and ttt specific settings for the among us gamemode.
local gmau_settings = xlib.makepanel{
	parent = xgui.null
}

xlib.makelabel{
	x = 5,
	y = 5,
	w = 600,
	wordwrap = true,
	label = "Among Us ULX Commands XGUI module Created by: Blaubeeree",
	parent = gmau_settings
}

xlib.makelabel{
	x = 2,
	y = 345,
	w = 600,
	wordwrap = true,
	label = "The settings above WILL SAVE. So pay attention while editing them!",
	parent = gmau_settings
}

xlib.makelabel{
	x = 5,
	y = 250,
	w = 160,
	wordwrap = true,
	label = "Note to server owners: to restrict this panel allow or deny permission to xgui_gmsettings.",
	parent = gmau_settings
}

xlib.makelabel{
	x = 5,
	y = 325,
	w = 160,
	wordwrap = true,
	label = "Not all settings echo to chat.",
	parent = gmau_settings
}

gmau_settings.panel = xlib.makepanel{
	x = 160,
	y = 25,
	w = 420,
	h = 318,
	parent = gmau_settings
}

gmau_settings.catList = xlib.makelistview{
	x = 5,
	y = 25,
	w = 150,
	h = 217,
	parent = gmau_settings
}

gmau_settings.catList:AddColumn("Among Us Settings")
gmau_settings.catList.Columns[1].DoClick = function() end

gmau_settings.catList.OnRowSelected = function(self, LineID, Line)
	local nPanel = xgui.modules.submodule[Line:GetValue(2)].panel

	if nPanel ~= gmau_settings.curPanel then
		nPanel:SetZPos(0)

		xlib.addToAnimQueue("pnlSlide", {
			panel = nPanel,
			startx = -435,
			starty = 0,
			endx = 0,
			endy = 0,
			setvisible = true
		})

		if gmau_settings.curPanel then
			gmau_settings.curPanel:SetZPos(-1)
			xlib.addToAnimQueue(gmau_settings.curPanel.SetVisible, gmau_settings.curPanel, false)
		end

		xlib.animQueue_start()
		gmau_settings.curPanel = nPanel
	else
		xlib.addToAnimQueue("pnlSlide", {
			panel = nPanel,
			startx = 0,
			starty = 0,
			endx = -435,
			endy = 0,
			setvisible = false
		})

		self:ClearSelection()
		gmau_settings.curPanel = nil
		xlib.animQueue_start()
	end

	-- If the panel has it, call a function when it's opened
	if nPanel.onOpen then
		nPanel.onOpen()
	end
end

-- Process modular settings
function gmau_settings.processModules()
	gmau_settings.catList:Clear()

	for i, module in ipairs(xgui.modules.submodule) do
		if module.mtype == "gmau_settings" and (not module.access or LocalPlayer():query(module.access)) then
			local w, h = module.panel:GetSize()

			if w == h and h == 0 then
				module.panel:SetSize(275, 322)
			end

			--For DListLayouts
			if module.panel.scroll then
				module.panel.scroll.panel = module.panel
				module.panel = module.panel.scroll
			end

			module.panel:SetParent(gmau_settings.panel)
			local line = gmau_settings.catList:AddLine(module.name, i)

			if module.panel == gmau_settings.curPanel then
				gmau_settings.curPanel = nil
				gmau_settings.catList:SelectItem(line)
			else
				module.panel:SetVisible(false)
			end
		end
	end

	gmau_settings.catList:SortByColumn(1, false)
end

gmau_settings.processModules()
xgui.hookEvent("onProcessModules", nil, gmau_settings.processModules)
xgui.addModule("Among Us", gmau_settings, "icon16/gmau.png", "xgui_gmsettings")

-----------------------------------------------------------------
-------------------- MODULE: Game ----------------------------
-----------------------------------------------------------------
local gpnl = xlib.makelistlayout{
	w = 415,
	h = 318,
	parent = xgui.null
}

local glst = vgui.Create("DPanelList", gpnl)
glst:Dock(FILL)
glst:SetSpacing(5)

glst:AddItem(xlib.makeslider{
	label = "au_max_imposters (def. 1)",
	min = 1,
	max = 10,
	decimal = 0,
	repconvar = "rep_au_max_imposters",
	parent = glst
})

glst:AddItem(xlib.makeslider{
	label = "au_kill_cooldown (def. 20)",
	min = 1,
	max = 60,
	decimal = 0,
	repconvar = "rep_au_kill_cooldown",
	parent = glst
})

glst:AddItem(xlib.makeslider{
	label = "au_time_limit (def. 600)",
	min = 0,
	max = 1200,
	decimal = 0,
	repconvar = "rep_au_time_limit",
	parent = glst
})

glst:AddItem(xlib.makeslider{
	label = "au_killdistance_mod (def. 1)",
	min = 1,
	max = 3,
	decimal = 2,
	repconvar = "rep_au_killdistance_mod",
	parent = glst
})

glst:AddItem(xlib.makeslider{
	label = "au_player_speed_mod (def. 1)",
	min = 0.5,
	max = 3,
	decimal = 2,
	repconvar = "rep_au_player_speed_mod",
	parent = glst
})

glst:AddItem(xlib.makecheckbox{
	label = "sv_alltalk (def. 0)",
	repconvar = "rep_sv_alltalk",
	parent = rsrllst
})

glst:AddItem(xlib.makelabel{
	label = "au_taskbar_updates (def. 0)",
	parent = rsrllst
})

glst:AddItem(xlib.makecombobox{
	choices = {"0 = Always", "1 = Meetings", "2 = Never"},
	numOffset = 0,
	repconvar = "rep_au_taskbar_updates",
	parent = glst
})

xgui.hookEvent("onProcessModules", nil, gpnl.processModules)
xgui.addSubModule("Game", gpnl, nil, "gmau_settings")

-------------------------------------------------------
-------------------- MODULE: Meeting ------------------
-------------------------------------------------------
local mpnl = xlib.makelistlayout{
	w = 415,
	h = 318,
	parent = xgui.null
}

local mlst = vgui.Create("DPanelList", mpnl)
mlst:Dock(FILL)
mlst:SetSpacing(5)

mlst:AddItem(xlib.makeslider{
	label = "au_meeting_available (def. 2)",
	min = 1,
	max = 5,
	decimal = 0,
	repconvar = "rep_au_meeting_available",
	parent = mlst
})

mlst:AddItem(xlib.makeslider{
	label = "au_meeting_cooldown (def. 20)",
	min = 1,
	max = 60,
	decimal = 0,
	repconvar = "rep_au_meeting_cooldown",
	parent = mlst
})

mlst:AddItem(xlib.makeslider{
	label = "au_meeting_vote_time (def. 30)",
	min = 1,
	max = 90,
	decimal = 0,
	repconvar = "rep_au_meeting_vote_time",
	parent = mlst
})

mlst:AddItem(xlib.makeslider{
	label = "au_meeting_vote_pre_time (def. 15)",
	min = 1,
	max = 60,
	decimal = 0,
	repconvar = "rep_au_meeting_vote_pre_time",
	parent = mlst
})

mlst:AddItem(xlib.makeslider{
	label = "au_meeting_vote_post_time (def. 5)",
	min = 1,
	max = 20,
	decimal = 0,
	repconvar = "rep_au_meeting_vote_post_time",
	parent = mlst
})

mlst:AddItem(xlib.makecheckbox{
	label = "au_confirm_ejects (def. 1)",
	repconvar = "rep_au_confirm_ejects",
	parent = mlst
})

mlst:AddItem(xlib.makecheckbox{
	label = "au_meeting_anonymous (def. 0)",
	repconvar = "rep_au_meeting_anonymous",
	parent = mlst
})

xgui.hookEvent("onProcessModules", nil, mpnl.processModules)
xgui.addSubModule("Meetings", mpnl, nil, "gmau_settings")

-------------------------------------------------------
-------------------- MODULE: Tasks --------------------
-------------------------------------------------------
local tpnl = xlib.makelistlayout{
	w = 415,
	h = 318,
	parent = xgui.null
}

local tlst = vgui.Create("DPanelList", tpnl)
tlst:Dock(FILL)
tlst:SetSpacing(5)

tlst:AddItem(xlib.makeslider{
	label = "au_tasks_short (def. 2)",
	min = 0,
	max = 5,
	decimal = 0,
	repconvar = "rep_au_tasks_short",
	parent = tlst
})

tlst:AddItem(xlib.makeslider{
	label = "au_tasks_long (def. 1)",
	min = 0,
	max = 5,
	decimal = 0,
	repconvar = "rep_au_tasks_long",
	parent = tlst
})

tlst:AddItem(xlib.makeslider{
	label = "au_tasks_common (def. 1)",
	min = 0,
	max = 5,
	decimal = 0,
	repconvar = "rep_au_tasks_common",
	parent = tlst
})

tlst:AddItem(xlib.makecheckbox{
	label = "au_tasks_enable_visual (def. 0)",
	repconvar = "rep_au_tasks_enable_visual",
	parent = tlst
})

xgui.hookEvent("onProcessModules", nil, tpnl.processModules)
xgui.addSubModule("Tasks", tpnl, nil, "gmau_settings")

-------------------------------------------------------
-------------------- MODULE: Other --------------------
-------------------------------------------------------
local opnl = xlib.makelistlayout{
	w = 415,
	h = 318,
	parent = xgui.null
}

local olst = vgui.Create("DPanelList", opnl)
olst:Dock(FILL)
olst:SetSpacing(5)

olst:AddItem(xlib.makeslider{
	label = "au_min_players (def. 3)",
	min = 3,
	max = 20,
	decimal = 0,
	repconvar = "rep_au_min_players",
	parent = olst
})

olst:AddItem(xlib.makeslider{
	label = "au_countdown (def. 5)",
	min = 1,
	max = 10,
	decimal = 0,
	repconvar = "rep_au_countdown",
	parent = olst
})

olst:AddItem(xlib.makeslider{
	label = "au_warmup_time (def. 60)",
	min = 0,
	max = 120,
	decimal = 0,
	repconvar = "rep_au_warmup_time",
	parent = olst
})

olst:AddItem(xlib.makecheckbox{
	label = "au_warmup_force_auto (def. 0)",
	repconvar = "rep_au_warmup_force_auto",
	parent = olst
})

xgui.hookEvent("onProcessModules", nil, opnl.processModules)
xgui.addSubModule("Other", opnl, nil, "gmau_settings")
hook.Run("GMAU UlxModifySettings", "gmau_settings")