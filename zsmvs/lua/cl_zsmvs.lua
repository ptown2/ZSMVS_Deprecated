include("util_zsmvs.lua")

local w, h = ScrW(), ScrH()
local maplist, mapsplayed = {}, {}
local timercalls = 1
local totalvote = 0
local minvotenum = GetConVarNumber("zsmvs_svotepower") or 2
local maxvotenum = GetConVarNumber("zsmvs_mvotepower") or 100
local VotePanel = nil
local MapAdmin = nil

local VoteClick = function(me)
	surface.PlaySound("buttons/button3.wav")
	RunConsoleCommand("zsmvs_votefor", me["ID"])
end

local function UpdateFooBars(number)
	totalvote = 0
	for k, _ in pairs(maplist) do
		totalvote = totalvote + maplist[k]["Votes"]
	end
	if totalvote < number then totalvote = number end
	
	if not foobar then return end
	for k, v in pairs(foobar) do
		if IsValid(v["VB"]) and IsValid(v["VP"]) then
			
			local x, y = v["VB"]:GetPos()
			v["VB"]:SetFraction(maplist[k]["Votes"]/totalvote)
			v["VP"]:SetText(math.Round((maplist[k]["Votes"]/totalvote)*100).."% ("..math.Round(maplist[k]["Votes"])..")")
			v["VP"]:SizeToContents()
			v["VP"]:SetPos(v["VB"]:GetWide() - v["VP"]:GetWide() - (v["VB"]:GetWide() * 0.05), y - (v["VP"]:GetTall() * 2))
		end
	end
end

net.Receive("UpdateClVotes", function()
	local t = string.Explode(" ", net.ReadString())
	t[1], t[2] = tonumber(t[1]), tonumber(t[2])

	timer.Create(timercalls .."votesslide".. t[1], 0, 100, function()
		maplist[t[1]]["Votes"] = math.max(math.Approach(maplist[t[1]]["Votes"], t[2], (t[2]*0.01)), 0) --Dedicated Server Fix
		UpdateFooBars(t[2])
	end)
	timercalls = timercalls + 1
end)
	
net.Receive("RecieveMaps", function()
	local data = net.ReadTable()
	maplist = data[1]
	mapsplayed = data[2]
end)

function adminmenu()
	if not LocalPlayer():IsSuperAdmin()  then
		Derma_Message("You don't have permission to open the admin menu.", "Warning")
		return
	end

	if IsValid(MapAdmin) then return end

	MapAdmin = vgui.Create("DFrame")
	MapAdmin:SetSize(800, 400)
	MapAdmin:Center()
	MapAdmin:SetTitle("ZSMVS Map Management Menu")
	MapAdmin:SetVisible(true)
	MapAdmin:SetDraggable(true)
	MapAdmin:ShowCloseButton(true)
	MapAdmin:MakePopup()

	local PanelList = vgui.Create("DPanelList", MapAdmin)
	PanelList:EnableVerticalScrollbar()
	PanelList:SetSpacing(8)
	PanelList:SetSize(780, 330)
	PanelList:SetPos(MapAdmin:GetWide() - PanelList:GetWide() - 8, MapAdmin:GetTall() - PanelList:GetTall() - 8)

	for k, v in pairs(maplist) do
		local MapPanel = vgui.Create("DPanel", PanelList)
		MapPanel:SetSize(PanelList:GetWide() - 12, 32)
		PanelList:AddItem(MapPanel)

		local MapName = EasyLabel(MapPanel, maplist[k]["Mapname"], "TextBold", C_WHITE)
		MapName:SetPos(6, 8)
	end
	
	local AddMap = vgui.Create("DButton", MapAdmin)
	AddMap:SetText("Add a new map")
	AddMap:SetSize(156, 20)
	AddMap:SetPos(12, 32)
	
	local AddMap = vgui.Create("DButton", MapAdmin)
	AddMap:SetText("Do nothing")
	AddMap:SetSize(156, 20)
	AddMap:SetPos(MapAdmin:GetWide() - AddMap:GetWide() - 12, 32)
end
 
function vmenu()
	if IsValid(VotePanel) then return end

	foobar = {}
	
	VotePanel = vgui.Create("DFrame")
	VotePanel:SetSize(w * 0.9, h * 0.8)
	VotePanel:Center()
	VotePanel:SetTitle(" ")
	VotePanel:SetVisible(true)
	VotePanel:SetDraggable(true)
	VotePanel:ShowCloseButton(true)
	VotePanel:MakePopup()
	
	local VotePName = EasyLabel(VotePanel, "Vote for the next map!", "VoteTitle", C_WHITE)
	VotePName:Center()
	local x, y = VotePName:GetPos()
	VotePName:SetPos(x, VotePName:GetTall() * 0.5)
	
	local PanelList = vgui.Create("DPanelList", VotePanel)
	PanelList:EnableVerticalScrollbar()
	PanelList:EnableHorizontal(true)
	PanelList:SetSpacing(8)
	PanelList:SetSize(VotePanel:GetWide() * 0.98, VotePanel:GetTall() * 0.85)
	PanelList:SetPos(VotePanel:GetWide() - PanelList:GetWide() - (VotePanel:GetWide() * 0.0095), VotePanel:GetTall() - PanelList:GetTall() - (VotePanel:GetTall() * 0.01))
	
	totalvote = 0
	for k, _ in pairs(maplist) do
		totalvote = totalvote + maplist[k]["Votes"]
	end
	if totalvote < minvotenum then totalvote = minvotenum end
	
	for k, v in pairs(maplist) do
		local MapPanel = vgui.Create("DButton", MapCollap)
		MapPanel:SetSize((PanelList:GetWide() - 4) * 0.49, 64)
		MapPanel["ID"] = k
		MapPanel["Pos"] = math.random(9999)
		MapPanel["Votes"] = maplist[k]["Votes"]
		MapPanel["Locked"] = maplist[k]["Locked"]
		MapPanel:SetText(" ")
		MapPanel.DoClick = VoteClick
		MapPanel.Paint = function()
			surface.SetDrawColor(Color(60, 60, 60, 255)) --Default Color
			for g, _ in pairs(mapsplayed) do
				if mapsplayed[g] == string.lower(maplist[k]["Mapname"]) then
					surface.SetDrawColor(C_RED) --Sets it to red
				end
			end

			if string.lower(game.GetMap()) == string.lower(maplist[k]["Mapname"]) then
				surface.SetDrawColor(C_GREEN) --Sets it to green if same map you're playing on.
			end
			surface.DrawRect(0, 0, MapPanel:GetWide(), MapPanel:GetTall()) -- Draw the rect
		end
		
		if maplist[k]["Desc"] and maplist[k]["Desc"] ~= "" then
			MapPanel:SetTooltip(maplist[k]["Desc"])
		end

		PanelList:AddItem(MapPanel)

		if maplist[k]["Name"] and maplist[k]["Name"] ~= "" then
			local MapName = EasyLabel(MapPanel, maplist[k]["Name"], "VoteTextBold", C_WHITE)
			MapName:SetPos(6, 6)
		else
			local MapName = EasyLabel(MapPanel, maplist[k]["Mapname"], "VoteTextBold", C_WHITE)
			MapName:SetPos(6, 6)
		end

		if maplist[k]["Author"] and maplist[k]["Author"] ~= "" then
			local AuthorName = EasyLabel(MapPanel, "Map made by "..maplist[k]["Author"], "VoteTextBold", C_WHITE)
			AuthorName:SetPos(MapPanel:GetWide() - AuthorName:GetWide() - 6, 6)
		end

		local VoteBar = vgui.Create("DProgress", MapPanel)
		VoteBar:SetSize(MapPanel:GetWide() * 0.95, 20)
		VoteBar:Center()
		local x, y = VoteBar:GetPos()
		VoteBar:SetPos(x, MapPanel:GetTall() - VoteBar:GetTall() - 6)
		VoteBar:SetFraction(maplist[k]["Votes"]/totalvote)

		totalvote = totalvote == 0 and 1 or totalvote
		local VotePer = EasyLabel(VoteBar, math.Round((maplist[k]["Votes"]/totalvote)*100).."% ("..math.Round(maplist[k]["Votes"])..")", "VoteTextBold", C_BLACK)
		VotePer:SetPos(VoteBar:GetWide() - VotePer:GetWide() - (VoteBar:GetWide() * 0.05), y - VotePer:GetTall() - 3)
		
		table.insert(foobar, {["VB"] = VoteBar, ["VP"] = VotePer, ["MP"] = MapPanel})
	end

	PanelList:SortByMember("Pos", false)
	PanelList:SortByMember("Locked", false)

	UpdateFooBars(totalvote)
end

concommand.Add("zsmvs_open", vmenu)
concommand.Add("zsmvs_mapmanagement", adminmenu)