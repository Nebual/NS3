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
		-- Make a new resource entry for each new resource plz
		Resources = {Energy = {0,1}, Oxygen = {0,1}, Hydrogen = {0,1}, CarbonDioxide = {0,1}, Nitrogen = {0,1}, LiquidNitrogen = {0,1}, Water = {0,1}, Fuel = {0,1}},
		Planets = {},
		Stars = {},
		Environments = {}, // Just Planets + stars
		AirRegulators = {},
		TemperatureRegulators = {},
		TrackedEnts = {},
		Space = {IsSpace = true, Name = "Space", Temperature = 14, Pressure = 0, Atmosphere = 0, Gravity = 0, GetTemperature = function() return 14 end, Priority = 0, Radius = 0, Max = 317332591, Resources = {Empty = 314159265}, ObjectsIn = {}},
		//SpaceEnvironment = {
	}
	for k,_ in pairs(NS3.Resources) do NS3.Space.Resources[k] = 0 end

	if !ConVarExists("ns3_spacenoclip") then CreateConVar("ns3_spacenoclip", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_suit") then CreateConVar("ns3_suit", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_suitmax") then CreateConVar("ns3_suitmax", 600, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_staticenvironments") then CreateConVar("ns3_staticenvironments", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_god") then CreateConVar("ns3_god", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
	if !ConVarExists("ns3_spacedamage") then CreateConVar("ns3_spacedamage", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}) end
end

if SERVER then
	include("sv_ns3.lua")
	include("ns3_planets.lua")
	include("nebsupport_hijacking.lua")
	AddCSLuaFile()
	AddCSLuaFile("cl_ns3.lua")
else
	include("cl_ns3.lua")
end

// MODEL DECLARATION
-- models/props_crates/static_crate_(40, 48, 64).mdl are great "ammo" crates
-- models/Slyfo/barrel_orange.mdl perfect for fuel or maybe water
NS3.StorageModels = {
	Oxygen = {"models/props_wasteland/laundry_washer001a.mdl",
		"models/XQM/podremake.mdl",
		"models/props_c17/canister_propane01a.mdl",
		"models/props_c17/FurnitureBoiler001a.mdl",
		"models/props_borealis/bluebarrel001.mdl",
		"models/props_c17/canister01a.mdl",},
	Hydrogen = {"models/props_wasteland/laundry_washer001a.mdl",
		"models/props_c17/canister_propane01a.mdl",
		"models/props_c17/FurnitureBoiler001a.mdl",
		"models/props_borealis/bluebarrel001.mdl",
		"models/props_c17/canister01a.mdl",},
	Nitrogen = {"models/props_wasteland/laundry_washer001a.mdl",
		"models/props_c17/canister_propane01a.mdl",
		"models/props_c17/FurnitureBoiler001a.mdl",
		"models/props_borealis/bluebarrel001.mdl",
		"models/props_c17/canister01a.mdl",},
	CarbonDioxide = {"models/props_wasteland/laundry_washer001a.mdl",
		"models/props_c17/canister_propane01a.mdl",
		"models/props_c17/FurnitureBoiler001a.mdl",
		"models/props_borealis/bluebarrel001.mdl",
		"models/props_c17/canister01a.mdl",},
	Water = {"models/props_wasteland/laundry_washer001a.mdl",
		"models/props_industrial/oil_storage.mdl",
		"models/props_c17/FurnitureBoiler001a.mdl",
		"models/Slyfo/crate_watersmall.mdl",
		"models/props_fortifications/fueldrum.mdl", -- Good for liquids
		"models/props_borealis/bluebarrel001.mdl",
		"models/props_c17/canister_propane01a.mdl",},
	LiquidNitrogen = {"models/props_wasteland/laundry_washer001a.mdl",
		"models/props_industrial/oil_storage.mdl",
		"models/props_c17/FurnitureBoiler001a.mdl",
		"models/Slyfo/crate_watersmall.mdl",
		"models/props_fortifications/fueldrum.mdl", -- Good for liquids
		"models/props_borealis/bluebarrel001.mdl",
		"models/props_c17/canister_propane01a.mdl",},
	Energy = {"models/props_industrial/oil_storage.mdl",
		"models/Slyfo/pallet_battery.mdl",
		"models/Items/car_battery01.mdl",},
	Fuel = {"models/props_industrial/oil_storage.mdl","models/props_junk/gascan001a.mdl",},
}
NS3.GeneratorModels = {
	Oxygen = {"models/props_wasteland/horizontalcoolingtank04.mdl", "models/props_outland/generator_static01a.mdl", "models/props_wasteland/laundry_washer003.mdl", "models/XQM/podremake.mdl"},
	Hydrogen = {"models/props_wasteland/horizontalcoolingtank04.mdl", "models/props_outland/generator_static01a.mdl", "models/props_wasteland/laundry_washer003.mdl", "models/XQM/podremake.mdl"},
	Nitrogen = {"models/props_wasteland/horizontalcoolingtank04.mdl", "models/props_outland/generator_static01a.mdl", "models/props_wasteland/laundry_washer003.mdl", "models/XQM/podremake.mdl"},
	CarbonDioxide = {"models/props_wasteland/horizontalcoolingtank04.mdl", "models/props_outland/generator_static01a.mdl", "models/props_wasteland/laundry_washer003.mdl", "models/XQM/podremake.mdl"},
	LiquidNitrogen = {"models/props_wasteland/horizontalcoolingtank04.mdl", "models/props_outland/generator_static01a.mdl", "models/props_wasteland/laundry_washer003.mdl", "models/XQM/podremake.mdl"},
	Water_Pump = {"models/props_wasteland/horizontalcoolingtank04.mdl", "models/props_outland/generator_static01a.mdl", "models/props_wasteland/laundry_washer003.mdl", "models/XQM/podremake.mdl"},
	Water_Condenser = {"models/slyfo/moisture_condenser.mdl",},
	Energy_Solar = {"models/slyfo_2/miscequipmentfieldgen.mdl","models/Squad/sf_plates/sf_plate8x8.mdl","models/Squad/sf_plates/sf_plate4x8.mdl","models/Squad/sf_plates/sf_plate4x4.mdl","models/Squad/sf_plates/sf_plate2x4.mdl","models/Squad/sf_plates/sf_plate1x4.mdl","models/Squad/sf_plates/sf_plate2x2.mdl",},
	Energy_Coal = {"models/props_vehicles/generator.mdl"},
	Energy_NaturalGas = {"models/props_vehicles/generator.mdl"},
	Energy_Hydro = {"models/props_outland/generator_static01a.mdl","models/XQM/podremake.mdl"},
	Energy_Wind = {"models/props_citizen_tech/windmill_blade002a.mdl"},
	Energy_Kinetic = {"models/props/de_prodigy/fanoff.mdl"},
	Fuel_Pump = {"models/props_vehicles/generator.mdl"},
	Plant = {"models/props/cs_office/plant01.mdl","models/props/de_inferno/potted_plant3.mdl","models/props/de_inferno/potted_plant2.mdl","models/props/de_inferno/potted_plant1.mdl",},
}
for k,v in pairs(NS3.GeneratorModels.Energy_Solar) do NS3.EntMaterials[v] = "models/XQM/BoxFull_diffuse" end
NS3.UtilityModels = {
	Air_Regulator = {"models/props_combine/combine_light001a.mdl", "models/props_combine/combine_light001b.mdl","models/props/cs_assault/wall_vent.mdl","models/props_c17/furnitureradiator001a.mdl","models/props/cs_militia/vent01.mdl","models/props/cs_assault/ventilationduct01.mdl","models/props_spytech/vent_system_vent01.mdl","models/props/de_train/acunit2.mdl","models/sbep_community/d12airscrubber.mdl",},
	Heat_Regulator = {"models/props_c17/utilityconnecter006c.mdl", "models/props_c17/substation_transformer01d.mdl","models/props/cs_assault/wall_vent.mdl","models/props_c17/furnitureradiator001a.mdl","models/props/cs_militia/vent01.mdl","models/props/cs_assault/ventilationduct01.mdl","models/props_spytech/vent_system_vent01.mdl","models/props/de_train/acunit2.mdl",},
	Suit_Recharger = {"models/props_combine/breenPod.mdl","models/props_combine/health_charger001.mdl","models/props_combine/combine_intwallunit.mdl","models/props_combine/combine_emitter01.mdl","models/props_combine/suit_charger001.mdl","models/buildables/dispenser_light.mdl",},
	Planetary_Probe = {"models/Slyfo/swordrecondrone.mdl", "models/Slyfo/probe1.mdl", "models/Slyfo/probe2.mdl"},
	Gravity_Regulator = {"models/Slyfo/drillbase_basic.mdl","models/slyfo/sat_rfg.mdl","models/sbep_community/d12shieldemitter.mdl",},
	Resource_Pump = {"models/props_lab/tpplugholder_single.mdl","models/props_wasteland/gaspump001a.mdl",},
	Resource_Counter = {"models/Slyfo/swordrecondrone.mdl", "models/Slyfo/probe1.mdl", "models/Slyfo/probe2.mdl"},
}

NS3.RegulatorModels = {
	["models/props/cs_assault/wall_vent.mdl"] = 400,
	["models/props_c17/utilityconnecter006c.mdl"] = 400,
	["models/props_combine/combine_light001a.mdl"] = 400,
	["models/props_c17/substation_transformer01d.mdl"] = 750,
	["models/props_combine/combine_light001b.mdl"] = 750,
}

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
