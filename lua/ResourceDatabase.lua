
-- Old resources
--Resources = {Energy = 0, Oxygen = 0, Hydrogen = 0, CarbonDioxide = 0, Nitrogen = 0, LiquidNitrogen = 0, Water = 0, Fuel = 0},
NS3.ResourceMeta = {
	Energy = {
		Equivalent = {
			DC = 1,
			AC = 5,
			Quantum = 25,
		},
		Abstract = true
	},
	DC = {
		Name = "DC Electricity",
		Equivalent = {
			AC = 5,
			Quantum = 25,
		}
	},
	AC = {
		Name = "AC Electricity",
		Equivalent = {
			Quantum = 25
		}
	},
	Quantum = {
		Name = "Quantum Energy",
	},
	Coolant = {
		Equivalent = {
			Water = 1,
			LiquidNitrogen = 25
		},
		Abstract = true,
	},
	Heating = {
		Equivalent = {
			Energy = 1
		},
		Abstract = true
	},
	Oxygen = {},
	Hydrogen = {},
	CarbonDioxide = {
		Name = "Carbon Dioxide",
	},
	Nitrogen = {},
	LiquidNitrogen = {
		Name = "Liquid Nitrogen",
	},
	Water = {},
	Biofuel = {},
	Deuterium = {},
}

local MinimumResourceFootprint = {IsSolid=false, Equivalent={}, Abstract=false}
for ResourceName, ResourceTable in pairs(NS3.ResourceMeta) do
	ResourceTable.Name = ResourceTable.Name or ResourceName
	for FootprintKey,FootprintValue in pairs(MinimumResourceFootprint) do
		ResourceTable[FootprintKey] = ResourceTable[FootprintKey] or FootprintValue
	end
	NS3.Resources[ResourceName] = 0
end
for k,_ in pairs(NS3.Resources) do NS3.Space.Resources[k] = 0 end



-- =======================
-- == MODEL DECLARATION ==
-- For the Tool to be able to spawn something, it must have a model declaration here

-- models/props_crates/static_crate_(40, 48, 64).mdl are great "ammo" crates
-- models/Slyfo/barrel_orange.mdl perfect for fuel or maybe water
local Tanks = {
	"models/props_wasteland/laundry_washer001a.mdl",
	"models/props_c17/canister_propane01a.mdl",
	"models/props_c17/FurnitureBoiler001a.mdl",
	"models/props_borealis/bluebarrel001.mdl",
}
local GasTanks = table.Add({
	"models/props_c17/canister01a.mdl",
}, Tanks)
local LiquidTanks = table.Add({
	"models/props_industrial/oil_storage.mdl",
	"models/Slyfo/crate_watersmall.mdl",
	"models/props_fortifications/fueldrum.mdl", -- Good for liquids
}, Tanks)
NS3.StorageModels = {
	Oxygen 			= table.Add({
		"models/XQM/podremake.mdl",
	}, GasTanks),
	Hydrogen 		= table.Add({}, GasTanks),
	Nitrogen 		= table.Add({}, GasTanks),
	CarbonDioxide 	= table.Add({}, GasTanks),
	Water 			= table.Add({}, LiquidTanks),
	LiquidNitrogen 	= table.Add({}, LiquidTanks),
	Energy = {
		"models/props_industrial/oil_storage.mdl",
		"models/Slyfo/pallet_battery.mdl",
		"models/Items/car_battery01.mdl",
	},
	Fuel = {
		"models/props_industrial/oil_storage.mdl",
		"models/props_junk/gascan001a.mdl",
	},
}

local GasGenerators = {
	"models/props_wasteland/horizontalcoolingtank04.mdl",
	"models/props_outland/generator_static01a.mdl",
	"models/props_wasteland/laundry_washer003.mdl",
	"models/XQM/podremake.mdl",
}
NS3.GeneratorModels = {
	Oxygen = GasGenerators,
	Hydrogen = GasGenerators,
	Nitrogen = GasGenerators,
	CarbonDioxide = GasGenerators,
	LiquidNitrogen = GasGenerators,
	Water_Pump = GasGenerators,
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
	Air_Regulator = {
		"models/props_combine/combine_light001a.mdl",
		"models/props_combine/combine_light001b.mdl",
		"models/sbep_community/d12airscrubber.mdl",

		"models/props/cs_assault/wall_vent.mdl",
		"models/props_c17/furnitureradiator001a.mdl",
		"models/props/cs_militia/vent01.mdl",
		"models/props/cs_assault/ventilationduct01.mdl",
		"models/props_spytech/vent_system_vent01.mdl",
		"models/props/de_train/acunit2.mdl",
	},
	Heat_Regulator = {
		"models/props_c17/utilityconnecter006c.mdl",
		"models/props_c17/substation_transformer01d.mdl",

		"models/props/cs_assault/wall_vent.mdl",
		"models/props_c17/furnitureradiator001a.mdl",
		"models/props/cs_militia/vent01.mdl",
		"models/props/cs_assault/ventilationduct01.mdl",
		"models/props_spytech/vent_system_vent01.mdl",
		"models/props/de_train/acunit2.mdl",
	},
	Suit_Recharger = {
		"models/props_combine/breenPod.mdl",
		"models/props_combine/health_charger001.mdl",
		"models/props_combine/combine_intwallunit.mdl",
		"models/props_combine/combine_emitter01.mdl",
		"models/props_combine/suit_charger001.mdl",
		"models/buildables/dispenser_light.mdl",
	},
	Planetary_Probe = {"models/Slyfo/swordrecondrone.mdl", "models/Slyfo/probe1.mdl", "models/Slyfo/probe2.mdl"},
	Gravity_Regulator = {"models/Slyfo/drillbase_basic.mdl","models/slyfo/sat_rfg.mdl","models/sbep_community/d12shieldemitter.mdl",},
	Resource_Pump = {"models/props_lab/tpplugholder_single.mdl","models/props_wasteland/gaspump001a.mdl",},
	Resource_Counter = {"models/Slyfo/swordrecondrone.mdl", "models/Slyfo/probe1.mdl", "models/Slyfo/probe2.mdl"},
}

-- List of "sizes" to use for specific models. If not set, defaults to a volume formula
NS3.RegulatorModels = {
	["models/props/cs_assault/wall_vent.mdl"] = 400,
	["models/props_c17/utilityconnecter006c.mdl"] = 400,
	["models/props_combine/combine_light001a.mdl"] = 400,
	["models/props_c17/substation_transformer01d.mdl"] = 750,
	["models/props_combine/combine_light001b.mdl"] = 750,
}
