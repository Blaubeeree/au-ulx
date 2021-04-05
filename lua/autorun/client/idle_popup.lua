-- copied from ttt gamemode
local function IdlePopup()
	local w, h = 300, 180
	local dframe = vgui.Create("DFrame")
	dframe:SetSize(w, h)
	dframe:Center()
	dframe:SetTitle("Idle")
	dframe:SetVisible(true)
	dframe:SetMouseInputEnabled(true)
	local inner = vgui.Create("DPanel", dframe)
	inner:StretchToParent(5, 25, 5, 45)
	local text = vgui.Create("DLabel", inner)
	text:SetWrap(true)
	text:SetText("You were moved into Spectator-only mode. While you are in this mode, you will not spawn when a new round starts.\n\nYou can toggle Spectator-only mode at any time by pressing F1 and unchecking the box in the Settings tab. You can also choose to disable it right now.")
	text:SetDark(true)
	text:StretchToParent(10, 5, 10, 5)
	local bw, bh = 75, 25
	local cancel = vgui.Create("DButton", dframe)
	cancel:SetPos(10, h - 40)
	cancel:SetSize(bw, bh)
	cancel:SetText("Do nothing")

	cancel.DoClick = function()
		dframe:Close()
	end

	local disable = vgui.Create("DButton", dframe)
	disable:SetPos(w - 185, h - 40)
	disable:SetSize(175, bh)
	disable:SetText("Disable Spectator-only mode now")

	disable.DoClick = function()
		RunConsoleCommand("au_spectator_mode", "0")
		dframe:Close()
	end

	dframe:MakePopup()
end

concommand.Add("au_cl_idlepopup", IdlePopup)