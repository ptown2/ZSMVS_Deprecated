--AddCSLuaFile("autorun/l_zsmvs.lua")
--AddCSLuaFile("maplist.lua")
AddCSLuaFile("cl_zsmvs.lua")
AddCSLuaFile("util_zsmvs.lua")
AddCSLuaFile("sh_zsmvs.lua")
AddCSLuaFile("serial_zsmvs.lua")
AddCSLuaFile("func_zsmvs.lua")

include("sh_zsmvs.lua")
--include("maplist.lua")

--Todo: Do something with WriteTable(), its messy and buggy.
--Todo: Live mapcycle updating.

-- Addon stops working if there is no maps added. Prevents the hook mapvote override.
if #maplist <= 0 then
	Error("No maps were found on the ".. mapcycle ..", it is required to add some few maps!\n\n")
end

local function UpdateClientsVotes(str)
	net.Start("UpdateClVotes")
		net.WriteString(str)
	net.Broadcast()
end

local function GetPlayerCount()
	local curplayers = #player.GetAll()
	if curplayers >= (maxplayers or 0) then
		maxplayers = curplayers
	end
	return maxplayers
end

function ChattoPlayers(str)
	for _, v in pairs(player.GetAll()) do
		v:ChatPrint(str)
	end
end

function MapVote(key, vote)
	maplist[key]["Votes"] = maplist[key]["Votes"] + vote
	UpdateClientsVotes(tostring(key).." "..tostring(vote))
end

function GetPlayerVote(pl)
	local kills, brains = pl.ZombiesKilled or 1, pl.BrainsEaten or 1

	local votes = kills * 0.125 + brains

	if pl.SurvivalTime then
		votes = votes + pl.SurvivalTime * 0.125
	end

	if ROUNDWINNER and ROUNDWINNER == TEAM_UNDEAD and GAMEMODE.StartingZombie[pl:UniqueID()] then
		votes = votes + math.max(0, (900 - CurTime()) * 0.025)
	end

	return math.max(SVOTEPOWER, math.ceil(votes * 2))
end

function CheckMapThreshold()
	for k, _ in pairs(maplist) do
		for g, _ in pairs(mapsplayed) do
			if string.lower(maplist[k]["Mapname"]) == mapsplayed[g] then
				maplist[k]["Locked"] = 1
			end
		end
	end
	
	local mapl, mape = #maplist or 0, #mapsplayed or 0
	MsgN("Maps Eliminated: ".. math.ceil(mape) .."\nLimit to reset: ".. math.ceil(mapl * MAPLOCKTHRESHOLD))
	if mape >= math.ceil(mapl * MAPLOCKTHRESHOLD) then
		file.Delete(recentmaps)
		file.Write(recentmaps, "")
		mapsplayed = {}
		MsgN("\nLimit reached! Resetting the recent map history.")
	end
end
hook.Add("InitPostEntity", "MapReset", CheckMapThreshold)
	
function SendMaps(pl)
	pl.Voted = pl.Voted or nil
	pl.VoteDelay = 0
	pl.VotePower = pl.VotePower or SVOTEPOWER
	GetPlayerCount()
	net.Start("RecieveMaps")
		net.WriteTable({maplist, mapsplayed})
	net.Send(pl)
end
hook.Add("PlayerInitialSpawn", "SendMaps", SendMaps)

function ClearVote(pl)
	if pl.Voted then
		MapVote(pl.Voted, -pl.VotePower)
	end
end
hook.Add("PlayerDisconnected", "ClearVote", ClearVote)

function AddVote(pl, cmd, args)
	local mapnum = tonumber(args[1])

	if pl.VoteDelay > CurTime() then
		return
	elseif string.lower(game.GetMap()) == string.lower(maplist[mapnum]["Mapname"]) then
		pl:ChatPrint("You cannot vote for the map that you're currently playing.") 
		pl.VoteDelay = tonumber(CurTime() + VOTEDELAY)
		return
	elseif not mapnum or not maplist[mapnum] then 
		pl:ChatPrint("The map id you've placed is removed or invalid.") 
		pl.VoteDelay = tonumber(CurTime() + VOTEDELAY)
		return
	elseif maplist[mapnum]["MinPlayers"] and maplist[mapnum]["MinPlayers"] >= GetPlayerCount() then 
		pl:ChatPrint("That map requires "..maplist[mapnum]["MinPlayers"].." or more players.") 
		pl.VoteDelay = tonumber(CurTime() + VOTEDELAY)
		return
	end

	for k, _ in pairs(mapsplayed) do
		if mapsplayed[k] == string.lower(maplist[mapnum]["Mapname"]) then
			pl:ChatPrint("That map was recently played.") 
			pl.VoteDelay = tonumber(CurTime() + VOTEDELAY)
			return
		end
	end

	local VPS = GetPlayerVote(pl) --2 --pl:Frags() * 5 --Don't do anything until I find a way to count the votes via kills, brains, etc.
	if MVOTEPOWER >= 0 then
		VPS = math.min(VPS, MVOTEPOWER)
	end

	if not pl.Voted then
	
		if pl.VotePower < VPS then pl.VotePower = VPS end
		MapVote(mapnum, pl.VotePower)

		pl.Voted = mapnum
		pl.VoteDelay = tonumber(CurTime() + VOTEDELAY)
		
	elseif pl.Voted then
	
		if maplist[mapnum] == maplist[pl.Voted] then
			if pl.VotePower < VPS then
				MapVote(pl.Voted, -pl.VotePower)
				MapVote(pl.Voted, VPS)
				pl.VotePower = VPS
				pl.VoteDelay = tonumber(CurTime() + VOTEDELAY)
			end

			return
		end

		MapVote(pl.Voted, -pl.VotePower)
		if pl.VotePower < VPS then pl.VotePower = VPS end
		MapVote(mapnum, pl.VotePower)

		pl.Voted = mapnum
		pl.VoteDelay = tonumber(CurTime() + VOTEDELAY)
		
	end
	
	if maplist[mapnum]["Name"] and maplist[mapnum]["Name"] ~= "" then
		ChattoPlayers(pl:Name().." has voted " ..maplist[mapnum]["Name"].. " for " ..pl.VotePower.. " votepoints.")
	else
		ChattoPlayers(pl:Name().." has voted " ..maplist[mapnum]["Mapname"].. " for " ..pl.VotePower.. " votepoints.")
	end
end
concommand.Add("zsmvs_votefor", AddVote)

function AddToRecentMaps(map)
	local mapexists = false
	local mapisinlist = false
	for k, _ in pairs(mapsplayed) do
		if mapsplayed[k] == map then
			mapexists = true
			break
		end
	end
	for k, _ in pairs(maplist) do
		if string.lower(maplist[k]["Mapname"]) == map then
			mapisinlist = true
			break
		end
	end
	if not mapexists and mapisinlist then
		file.Append(recentmaps, map.."\n")
	end
end

function CheckWinner()
	local votes = {}
	for k, v in pairs(maplist) do
		table.insert(votes, maplist[k]["Votes"])
	end
	
	return table.GetWinningKey(votes)
end

function CheckUnlockedWinner()
	local maplists = table.Copy(maplist)

	repeat
		noemptyleft = true
		for k, _ in pairs(maplists) do
			for g, _ in pairs(mapsplayed) do
				if string.lower(maplists[k]["Mapname"]) == mapsplayed[g] or string.lower(maplists[k]["Mapname"]) == string.lower(game.GetMap()) then
					table.remove(maplists, k)
					noemptyleft = false
				end
			end
		end
	until noemptyleft
	
	if #maplists <= 0 then
		MsgN("\n\nAll maps were locked! Selected a random map from the original list!")
		return maplist[math.random(1, #maplist)]["Mapname"]
	end
	
	local nextmap = math.random(1, #maplists)
	
	MsgN("\n\nThe winner is: "..maplists[nextmap]["Mapname"])
	return maplists[nextmap]["Mapname"]
end

function StartVote()
	local rndl, rndc, tml = GAMEMODE.RoundLimit or 0, GAMEMODE.CurrentRound or 0, GAMEMODE.TimeLimit or 0
	if tml == -1 or rndl == -1 then return end
	if tml > 0 and CurTime() >= tml or rndl > 0 and rndc >= rndl then
		timer.Simple(8, function()
			for _, v in pairs(player.GetAll()) do
				if #maplist > 0 then
					v:ConCommand("zsmvs_open")
				end
			end
		end)
	end
end

function DoVote()
	nextmap = maplist[CheckWinner()]["Mapname"]
	AddToRecentMaps(string.lower(game.GetMap()))
	if nextmap and maplist[CheckWinner()]["Votes"] > 0 then
		RunConsoleCommand("changelevel", nextmap)
	else
		RunConsoleCommand("changelevel", CheckUnlockedWinner())
	end
	
	return true
end

function PlayerSaid(pl, text, all)
	if not pl:IsPlayer() and pl:IsConnected() then return end
	if text == "/votemap" or text == "/zsmap" then
		pl:ConCommand("zsmvs_open")
		return ""
	elseif text == "nextmap" or text == "!nextmap" or text == "/nextmap" then
		map = "nil"
		if maplist[CheckWinner()]["Votes"] > 0 then
			if maplist[CheckWinner()]["Name"] and maplist[CheckWinner()]["Name"] ~= "" then
				map = maplist[CheckWinner()]["Name"]
			else
				map = maplist[CheckWinner()]["Mapname"]			
			end
		end
		ChattoPlayers(pl:Name().. ", the next map is " ..map)
		return
	end
end

hook.Add("EndRound", "ZSMVS_EndRound", StartVote)
if #maplist > 0 then
	hook.Add("LoadNextMap", "ZSMVS_LoadNextMap", DoVote)
end
hook.Add("PlayerSay", "ZSMVS_PlayerSay", PlayerSaid)