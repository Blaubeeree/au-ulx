local gmau_addon_settings = xlib.makepanel{parent = xgui.null}

xlib.makelabel{
	x = 5,
	y = 5,
	w = 600,
	wordwrap = true,
	label = "Settings of Addons that support ULX.",
	parent = gmau_addon_settings
}

gmau_addon_settings.panel = xlib.makepanel{
	x = 160,
	y = 25,
	w = 420,
	h = 333,
	parent = gmau_addon_settings
}

gmau_addon_settings.catList = xlib.makelistview{
	x = 5,
	y = 25,
	w = 150,
	h = 333,
	parent = gmau_addon_settings
}

gmau_addon_settings.catList:AddColumn("Addon Settings")

gmau_addon_settings.catList.Columns[1].DoClick = function()

end

gmau_addon_settings.catList.OnRowSelected = function(self, LineID, Line)
	local nPanel = xgui.modules.submodule[Line:GetValue(2)].panel

	if nPanel ~= gmau_addon_settings.curPanel then
		nPanel:SetZPos(0)

		xlib.addToAnimQueue("pnlSlide", {
			panel = nPanel,
			startx = -435,
			starty = 0,
			endx = 0,
			endy = 0,
			setvisible = true
		})

		if gmau_addon_settings.curPanel then
			gmau_addon_settings.curPanel:SetZPos(-1)
			xlib.addToAnimQueue(gmau_addon_settings.curPanel.SetVisible, gmau_addon_settings.curPanel, false)
		end

		xlib.animQueue_start()

		gmau_addon_settings.curPanel = nPanel
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

		gmau_addon_settings.curPanel = nil

		xlib.animQueue_start()
	end

	-- If the panel has it, call a function when it's opened
	if nPanel.onOpen then
		nPanel.onOpen()
	end
end

-- Process modular settings
function gmau_addon_settings.processModules()
	gmau_addon_settings.catList:Clear()

	for i, module in ipairs(xgui.modules.submodule) do
		if module.mtype == "gmau_addon_settings" and (not module.access or LocalPlayer():query(module.access)) then
			local w, h = module.panel:GetSize()

			if w == h and h == 0 then
				module.panel:SetSize(275, 322)
			end

			if module.panel.scroll then --For DListLayouts
				module.panel.scroll.panel = module.panel
				module.panel = module.panel.scroll
			end

			module.panel:SetParent(gmau_addon_settings.panel)

			local line = gmau_addon_settings.catList:AddLine(module.name, i)

			if module.panel == gmau_addon_settings.curPanel then
				gmau_addon_settings.curPanel = nil
				gmau_addon_settings.catList:SelectItem(line)
			else
				module.panel:SetVisible(false)
			end
		end
	end

	gmau_addon_settings.catList:SortByColumn(1, false)
end

gmau_addon_settings.processModules()

xgui.hookEvent("onProcessModules", nil, gmau_addon_settings.processModules)
xgui.addModule("Addons", gmau_addon_settings, "icon16/addons.png", "xgui_gmsettings")

hook.Run("GMAU UlxModifyAddonSettings", "gmau_addon_settings")
