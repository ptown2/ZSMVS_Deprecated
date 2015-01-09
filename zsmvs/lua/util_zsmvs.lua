--[[
	ClientSided Utilities by JetBoom
]]

if SERVER then return end

C_BLACK = Color(0, 0, 0, 255)
C_WHITE = Color(255, 255, 255, 255)
C_RED = Color(180, 0, 0, 255)
C_BLUE = Color(0, 0, 180, 255)
C_GREEN = Color(0, 180, 0, 255)

function BetterScreenScale()
	return math.max(0.6, math.min(1, ScrH() / 1080))
end

function WordBox(parent, text, font, textcolor)
	local cpanel = vgui.Create("DPanel", parent)
	local label = EasyLabel(cpanel, text, font, textcolor)
	local tsizex, tsizey = label:GetSize()
	cpanel:SetSize(tsizex + 16, tsizey + 8)
	label:SetPos(8, (tsizey + 8) * 0.5 - tsizey * 0.5)
	cpanel:SetVisible(true)
	cpanel:SetMouseInputEnabled(false)
	cpanel:SetKeyboardInputEnabled(false)

	return cpanel
end

function EasyLabel(parent, text, font, textcolor)
	local dpanel = vgui.Create("DLabel", parent)
	if font then
		dpanel:SetFont(font or "Default")
	end
	dpanel:SetText(text)
	dpanel:SizeToContents()
	if textcolor then
		dpanel:SetTextColor(textcolor)
	end
	dpanel:SetKeyboardInputEnabled(false)
	dpanel:SetMouseInputEnabled(false)

	return dpanel
end

function EasyButton(parent, text, xpadding, ypadding)
	local dpanel = vgui.Create("DButton", parent)
	if textcolor then
		dpanel:SetFGColor(textcolor or color_white)
	end
	if text then
		dpanel:SetText(text)
	end
	dpanel:SizeToContents()

	if xpadding then
		dpanel:SetWide(dpanel:GetWide() + xpadding * 2)
	end

	if ypadding then
		dpanel:SetTall(dpanel:GetTall() + ypadding * 2)
	end

	return dpanel
end

-- Surface Fonts
surface.CreateFont("TextBold", {
	font 	= "Tahoma",
	size 	= 16,
	weight	= 1000
})

surface.CreateFont("VoteTextBold", {
	font 	= "Tahoma",
	size 	= 20,
	weight	= 1500
})

surface.CreateFont("VoteTitle", {
	font 	= "Tahoma",
	size 	= BetterScreenScale() * 52,
	weight	= 1000
})