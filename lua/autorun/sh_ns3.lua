-- Nebual 2010 (nebual@nebtown.info) presents:
-- NebSupport3 - Nebcorp's Life Support and Resources mod
--bonk
if !NS3 then
	-- Stuff in here will only ever be run once per serverload
	NS3 = {
		EntMaterials = {}, -- Added at end of NS3 = {}, in for loop
		// FOR FUSION: models/Punisher239/punisher239_reactor_small.mdl & big
		// For something with hydro-water models/Slyfo/electrolysis_gen.mdl


		//GeneratorVoltages = {"models/props_vehicles/generator.mdl" = 120},
		Resources = {},
		Planets = {},
		Stars = {},
		Environments = {}, // Just Planets + stars
		AirRegulators = {},
		TemperatureRegulators = {},
		TrackedEnts = {},
		Space = {IsSpace = true, Name = "Space", Temperature = 14, Pressure = 0, Atmosphere = 0, Gravity = 0, GetTemperature = function() return 14 end, Priority = 0, Radius = 0, Max = 317332591, Resources = {Empty = 314159265}, ObjectsIn = {}},
		//SpaceEnvironment = {
	}

	if !ConVarExists("ns3_spacenoclip") then CreateConVar("ns3_spacenoclip", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_suit") then CreateConVar("ns3_suit", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_suitmax") then CreateConVar("ns3_suitmax", 600, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_staticenvironments") then CreateConVar("ns3_staticenvironments", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_god") then CreateConVar("ns3_god", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_spacedamage") then CreateConVar("ns3_spacedamage", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
end
include("ResourceDatabase.lua")

if SERVER then
	include("sv_ns3.lua")
	include("ns3_planets.lua")
	include("nebsupport_hijacking.lua")
	AddCSLuaFile()
	AddCSLuaFile("cl_ns3.lua")
else
	include("cl_ns3.lua")
end

timer.Create("NS3.AddNoclipHook",15,1,function()
	if CLIENT then
		if NS3.Suit.Name != "kelp" then
			-- We're on a SB map with environments!
			hook.Add("PlayerNoClip","NS3.PlayerNoClip",function(ply,on)
				if !on and NS3.Suit.Name == "Space" then return false end
			end)
		end
	else
		if NS3.HasPlanets then
			-- We're on a SB map with environments!
			hook.Add("PlayerNoClip","NS3.PlayerNoClip",function(ply,on)
				if !on and !ply.Environment or ply.Environment.IsSpace then return false end
			end)
		end
	end
end)

print("[NS3 Shared - Nebcorp's Life Support and Resources Mod Loaded]")
