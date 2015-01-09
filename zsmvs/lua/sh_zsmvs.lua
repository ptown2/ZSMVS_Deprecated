include("serial_zsmvs.lua")
include("func_zsmvs.lua")

local version = "1.4.1"
mapcycle = file.Exists("mapcycle_zombiesurvival.txt", "GAME") and "mapcycle_zombiesurvival.txt" or "mapcycle.txt"
mapcycledata = "zsmvs_mapcycledata_".. version ..".txt"
recentmaps = "zsmvs_recentmaps_".. version ..".txt"

-- Start doing the files automatically
CreateFile(mapcycledata)
CreateFile(recentmaps)
DeleteLegacyFiles("zsmvs_recentmaps_*.txt", recentmaps)
DeleteLegacyFiles("zsmvs_mapcycledata_*.txt", mapcycledata)

-- Constant shared values, DO NOT CHANGE ANYTHING BELOW!
MAPLOCKTHRESHOLD = math.floor(100 * CreateConVar("zsmvs_maplockthreshold", "0.25", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Percentage number of maps that required to be played until list refresh."):GetFloat()) * 0.01
cvars.AddChangeCallback("zsmvs_maplockthreshold", function(cvar, oldvalue, newvalue)
	MAPLOCKTHRESHOLD = math.floor(100 * (tonumber(newvalue) or 1)) * 0.01
end)

SVOTEPOWER = CreateConVar("zsmvs_svotepower", 2, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Minimum vote power for the players."):GetInt()
cvars.AddChangeCallback("zsmvs_svotepower", function(cvar, oldvalue, newvalue)
	SVOTEPOWER = tonumber(newvalue)
end)

MVOTEPOWER = CreateConVar("zsmvs_mvotepower", 100, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum vote power for the players. Set -1 or 0 to disable."):GetInt()
cvars.AddChangeCallback("zsmvs_mvotepower", function(cvar, oldvalue, newvalue)
	MVOTEPOWER = tonumber(newvalue)
end)

VOTEDELAY = CreateConVar("zsmvs_votedelay", 2, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Vote delay between votes made by the player, to prevent spam (in seconds)."):GetInt()
cvars.AddChangeCallback("zsmvs_votedelay", function(cvar, oldvalue, newvalue)
	VOTEDELAY = tonumber(newvalue)
end)

-- Global Variables (sorta)
maplist = {}
mapcyclelist = DeleteEmptyTable(string.Explode("\n", file.Read(mapcycle, "GAME")))
mapsplayed = DeleteEmptyTable(string.Explode("\n", file.Read(recentmaps)))
nextmap = nil
maxplayers = 0

-- Checks if the data for that map is there

-- Add in the maps
for k, _ in pairs(mapcyclelist) do
	AddZSMap(mapcyclelist[k], "", "", "", 0)
end

util.AddNetworkString("RecieveMaps")
util.AddNetworkString("UpdateClVotes")