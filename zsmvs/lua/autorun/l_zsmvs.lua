local modename = GetConVar("gamemode"):GetString()

if modename == "zombiesurvival" then
	if SERVER then
		include("sv_zsmvs.lua")

		--Well, fuck me garry...

		--[[local tags = GetConVar("sv_tags"):GetString()

		if not string.find(tags, "ZSMVS") then
			RunConsoleCommand("sv_tags", tags .. ",ZSMVS")
		end]]
	end

	if CLIENT then
		include("cl_zsmvs.lua")
	end
else
	Error("The add-on has halted because the gamemode \"zombiesurvival\" isn't selected in this server.\n\n")
end