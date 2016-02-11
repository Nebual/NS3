DEVICE.Setup = function(self)
	self.OverlayBase = "NS3 Planetary Probe"
	self.Mute = true
	if !NS3.HasPlanets then
		self.Environment = {Name = string.upper(string.sub(game.GetMap(),4,4))..string.sub(game.GetMap(), 5, string.find(game.GetMap(), "_",5) - 1),Pressure = 1, Temperature = 288, Gravity = 1, Atmosphere = 1, Max = 40000, Resources = {Empty = 0}}
		for _,v in pairs({"Oxygen","CarbonDioxide","Nitrogen","Hydrogen"}) do self.Environment.Resources[v] = 10000 end
	end
	WireLib.AdjustSpecialOutputs(self.Entity,
		{"On",		"Name",		"Pressure",	"Atmosphere","Vacuum","Gravity","Temperature","Oxygen",	"CarbonDioxide","Nitrogen",	"Hydrogen"},
		{"NORMAL",	"STRING",	"NORMAL",	"NORMAL",	"NORMAL","NORMAL","NORMAL",		"NORMAL",	"NORMAL",		"NORMAL",	"NORMAL"}
	)
end

DEVICE.SubThink = function(self)
	self.OverlayStatus = nil
	if !self.Active then return end
	if next(self.Requesting) then
		if !self.DoneProbing then self.OverlayStatus = "Probing "..self.LastEnv.." ("..math.Round(100-self.Requesting.Energy).."%)..." end
		self:LowResource("energy")
	else
		self.OverlayWarning = nil
		local env = self.Environment
		if env.Name != self.LastEnv then
			self.DoneProbing = false
			self.LastEnv = env.Name
			self.Requesting.Energy = 100
			self.OverlayStatus = "Probing "..env.Name.." (0%)..."
			return
		end
		self.DoneProbing = true
		local temp = env.Temperature or 14
		if env.TemperatureLit && env.TemperatureLit != env.Temperature then temp = temp .. "-"..env.TemperatureLit end
		if env.Name == "Space" then temp = 14 end // Make it look like its 14, its actually 200 for balance reasons (space can't be THAT hard...)
		self.OverlayStatus = env.Name.."\n"..
			"Pressure: ".. math.Round(100*env.Pressure) .."% ("..math.Round(100*env.Resources.Empty/env.Max).."% Vacuum)  Atmosphere: "..env.Atmosphere .."\n"..
			"Gravity: "..env.Gravity.."x of Earth\n"..
			"Temperature: "..temp .."\n"..
			"Oxygen: "..math.Round(100*env.Resources.Oxygen/env.Max).."%  CarbonDioxide: "..math.Round(100*env.Resources.CarbonDioxide/env.Max).."%\n"..
			"Nitroxen: "..math.Round(100*env.Resources.Nitrogen/env.Max).."%  Hydrogen: "..math.Round(100*env.Resources.Hydrogen/env.Max).."%"
		if env.Unstable then self.OverlayStatus = self.OverlayStatus .. "\nWarning: Unstable!" end
		for _,v in pairs({"Name","Pressure","Atmosphere","Gravity","Temperature"}) do WireLib.TriggerOutput(self.Entity, v, env[v]) end
		for _,v in pairs({"Oxygen","CarbonDioxide","Nitrogen","Hydrogen"}) do WireLib.TriggerOutput(self.Entity, v, math.Round(100*env.Resources[v]/env.Max)) end
		WireLib.TriggerOutput(self.Entity, "Vacuum", math.Round(100*env.Resources.Empty/env.Max))
		self.Requesting.Energy = 5 -- Request more energy to power the display
	end
end
