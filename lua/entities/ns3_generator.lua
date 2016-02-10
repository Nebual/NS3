AddCSLuaFile()
DEFINE_BASECLASS( "ns3_base_entity" )
ENT.PrintName 	= "NS3 Resource Generator"
ENT.Purpose		= "Generates NS3 Resources"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName="NS3 Generator"

if CLIENT then return end

ENT.Lists ={}

local function BoolNum(bool) if bool then return 1 else return 0 end end
local round = math.Round

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Entity:NextThink( round(CurTime()) + 2 )

	self.Priority = self.Priority or 5
	self.Efficiency = self.Efficiency or math.Rand(0.4,0.5) // Oxygen should be 2, hydrogen 3, etc. Harder ones higher
	self.RandomFactor = self.RandomFactor or 0.15
	self.Speed = round(round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.46 * 3.75) * 0.05)
	self.Receiving[1] = {"Energy", 1}
	self.Productivity = {}
	self.IdleSound2 = "Airboat_engine_idle"

	-- Default Settings which get overriden by specific generators (IE hydro generator can't be waterphobic or it wouldn't load!)
	self.WaterPhobic = self.WaterPhobic or true
	self.WaitsForResources = self.WaitsForResources or true
	self.MustBeActive = self.MustBeActive or true

	self.OverlayBase =  "NS3 Unspecified Generator Device"
end

function ENT:Setup()
	local overlay = self.Resource
	if self.Style then overlay = self.Style .. " " .. overlay end
	self.OverlayBase =  "NS3 "..overlay.." Generator"
	self.Overlay = self.OverlayBase

	if self.Style then self.ProduceResource = self.Lists.ProduceResource[self.Resource .. "_"..self.Style] else self.ProduceResource = self.Lists.ProduceResource[self.Resource] end
	if !self.ProduceResource then self.ProduceResource = self.Lists.ProduceResource.Default print("NS3 Warning: No such generator type as "..(overlay or "")) end

	if self.Style == "Hydro" or self.Resource == "Water" then
		self.WaterPhobic = false
	elseif self.Style == "Wind" then
		self.RandomFactor = 0.8
		self.IdleSound = "ambient/wind/wasteland_wind.wav"
		self.IdleSound2 = nil
		self:SetActive(true)
	elseif self.Style == "Condenser" then
		// Water Condenser:
		self.Efficiency = 15
	elseif self.Style == "Kinetic" then
		self.Mute = true
	elseif self.Resource == "Plant" then
		self.Watered = 0
		self.Mute = true
		self.MustBeActive = false
		self.WaitsForResources = false
		self.SetActive = function( self, value, caller )
			if !tobool(value) or !IsValid(caller) or !caller:IsPlayer() then return false end
			-- Only letting one person use this at a time fits perfectly into the existing SetActive infrastructure
			if self.Watered < 30 and caller.Suit.Coolant >= 5 then
				self.Watered = self.Watered + 5
				caller.Suit.Coolant = caller.Suit.Coolant - 5
				local watersound = CreateSound(caller, "ambient/levels/canals/water_rivulet_loop2.wav" )
				watersound:Play()
				watersound:FadeOut(2.5)
			end
		end
	end
	if self.Style == "Solar" then
		if self:GetModel() == "models/slyfo_2/miscequipmentsolar.mdl" then self.Speed = 21 end
		self.Mute = true
		self.MustBeActive = false
		self.WaterPhobic = false
		self.AcceptInput = function(self,name, activator, caller) return end
	else
		self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Mute" })
	end
	self.Outputs = Wire_CreateOutputs(self.Entity, {"On", "Productivity" })

	self.NormalSpeed = self.Speed -- So namage can reduce speed
	self:UpdateOverlayText()
end

local function EndThink(self)
	table.insert(self.Productivity, 1, self.TickProductivity) self.Productivity[6] = nil
	local val = 0
	for k,v in pairs(self.Productivity) do val = val + v end
	local productivity = round(val * 100 / #self.Productivity)
	self.OverlayStatus = "Productivity: " .. round(self.TickProductivity * 100) .. "% (" .. productivity .. "% avg)"
	WireLib.TriggerOutput(self.Entity, "Productivity", productivity)
	self:UpdateOverlayText()
	return true
end
function ENT:Think()
	self.BaseClass.BaseClass.Think(self)
	self.Entity:NextThink( round(CurTime()) + 0.95 )
	self.TickProductivity = 0.001
	self.OverlayWarning = nil

	if !self.Active and self.MustBeActive then self.Requesting = {} return EndThink(self) end
	if self.WaterPhobic then
		if self.Entity:WaterLevel() > 1 then
			-- Turn off in water
			self.Entity:SetColor(Color(50, 50, 50, 255))
			self:SetActive(false)
			self.OverlayWarning = "Excessive water detected"
			self.HadWetShutdown = true
			self:UpdateOverlayText()
			return true
		elseif self.HadWetShutdown then
			self.HadWetShutdown = nil
			self.OverlayWarning = ""
			self.Entity:SetColor(Color(255, 255, 255, 255))
			self:UpdateOverlayText()
		end
	end

	if self.Namage then
		local health = self.Namage.HP / self.Namage.MaxHP

		if health > 0.6 then self.Speed = self.NormalSpeed
		elseif health > 0.4 then self.Speed = self.NormalSpeed * 0.5 self.OverlayWarning = "Moderate damage sustained"
		elseif health > 0.2 then self.Speed = self.NormalSpeed * 0.2 self.OverlayWarning = "Heavy damage sustained"
		else self:SetActive(false) self.OverlayWarning = "Severe damage sustained!"
		end
	end

	if next(self.Requesting) && self.WaitsForResources then
		-- We're still looking for shit
		self.OverlayWarning = "Insufficient "..next(self.Requesting)
		return EndThink(self)
	end


	if self.Resource != "Energy" then self.Requesting.Energy = 3 end -- Always ask for a little bit of energy... I mean its gotta power the display! :P
	local product = self:ProduceResource()-- Manufactor the resource!
	if !product then return EndThink(self) end
	if self.Resource != "Energy" then self.Requesting.Energy = product[2] * self.Efficiency end

	-- "Productivity" is based on how often the gen is running (does it have enough fuel?) and how much of its product is actually used
	local produced = product[2]
	product = self:SendResources(product)
	self.TickProductivity = (produced - product[2]) / self.NormalSpeed
	return EndThink(self)
end

/*   About writing new generators:
Please return {self.Resource (which is "Energy" or "Water"), the amount of resource produced}
self.Speed is meant to be the main static multiplier for how much resource to produce, which integrates generator model size.

All non-energy generators are assumed to cost energy based on (ResourceProduced * self.Efficiency (default 0.5))
"Normal" generators (ie mid sized oxygen) generate 30 oxygen a second, costing 15 energy.
*/

-- ProduceResource is basically the custom "think" of each generator
ENT.Lists.ProduceResource = {
	Default = function(self)
		local fuels = self:CollectResources()
		return {self.Resource, self.Speed * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
	end,
	Energy_Solar = function(self)
		local traces = NS3.SunTrace(self.Entity, true)
		if traces then
			--solar panel produces energy // TODO: make 90 degree pitch fail (rather than giving 25%)
			local output = 0
			for k,trace in pairs(traces) do output = output + ((self.Entity:GetUp() + trace.HitNormal).z / 2)^2 end

			if output < 0.05 then self:SetActive(false) return end
			self:SetActive(true)
			self.OverlayWarning = "Power: "..round(output*100) .."%"
			return {"Energy", self.Speed * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor) * output}
		end
	end,
	Energy_Coal = function(self)
		local fuels = self:CollectResources()
		local product = {self.Resource, self.Speed * 3 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		self.Requesting.Fuel = product[2] * self.Efficiency
		return product
	end,
	Energy_NaturalGas = function(self)
		local fuels = self:CollectResources()
		local product = {self.Resource, self.Speed * 8 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		self.Requesting.Fuel = product[2] * 0.4 * self.Efficiency
		return product
	end,
	Energy_Hydro = function(self)
		local mul = 1
		if !self.Pulse then
			self.Pulse = 1
			timer.Create("NS3_Pulse_"..self:EntIndex(), math.Rand(8,22), 1, function() if !self:IsValid() or !self.Active then return end
				self.Pulse = math.Rand(4,11)
				self.PulseTime = CurTime()
				timer.Create("NS3_Pulse_"..self:EntIndex(),self.Pulse,1,function() self.Pulse = nil end)
			end)
		elseif self.Pulse > 1 then
			mul = 1 - math.Min((CurTime() - self.PulseTime)/6,0.8)
		end
		if self:WaterLevel() > 1 then
			//self.Entity:EmitSound( self.IdleSound2,100,50 + mul*50, 20 + mul*80 )
			return {self.Resource, self.Speed * mul * 0.25}
		else
			//self.Entity:StopSound( self.IdleSound2 )
			self.OverlayWarning = "Generator must be submerged!"
			self:SetActive(false) -- Should I be switching it off?
		end
	end,
	Energy_Wind = function(self)
		return {self.Resource, self.Speed * self.Environment.Atmosphere * 0.2 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor*2)}
	end,
	Energy_Kinetic = function(self)
		// Basically this is just so people shove some moving parts on their plane which look steampunky, also it has a rather low max energy output cause people will probably just thruster these.
		local spd = self:GetPhysicsObject():GetAngleVelocity():Length()
		if spd > 10 then
			return {self.Resource, self.Speed * (math.Min(spd,400) ^ 1.5)/8000  * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		end
	end,
	-- Energy_Fusion
	// NEEDS TO BE HARD TO DO (only turns on for a few seconds, thus needs complex wiring to properly maintain)
	Fuel_Pump = function(self)
		// TODO: Make this way cooler with deposits of fuel and shit
		if math.random(1,4) == 1 then return {self.Resource, self.Speed} end
	end,
	LiquidNitrogen = function(self)
		local fuels = self:CollectResources()

		local ret = {self.Resource, self.Speed * 0.9}
		self.Requesting.Nitrogen = self.Speed
		return ret
	end,
	Water_Pump = function(self)
		// Take away from planet's "water" level, to simulate lakes being depletable (they restore over time)
		if self:WaterLevel() < 2 then self:LowResource("water submersion!") self:SetActive(false) return end
		if self.Environment.Resources.Water < self.Speed * 0.5 then self:LowResource("water levels in lake!") return end
		self.OverlayWarning = nil
		self.Environment.Resources.Water = self.Environment.Resources.Water - self.Speed * 0.5
		return {self.Resource, self.Speed * 0.3}
	end,
	Water_Condenser = function(self)
		self.Entity:NextThink( round(CurTime()) + math.random(2,6) + 0.95 )

		if self.Environment.Resources.Hydrogen / self.Environment.Max > 0.005 && self.Environment.Resources.Oxygen / self.Environment.Max > 0.06 then
			self.Environment.Resources.Hydrogen = self.Environment.Resources.Hydrogen - 2
			self.Environment.Resources.Oxygen = self.Environment.Resources.Oxygen - 1
			return {self.Resource, 1}
		end
	end,
	Plant = function(self)
		if self.Watered < 1 then self.OverlayWarning = "Out of water!" return
		else self.OverlayWarning = "Water: "..math.Round(self.Watered / 0.3).."%" end

		if math.random(1,5) != 1 then self.TickProductivity = self.PlantTickProductivity return end
		local fuels = self:CollectResources()

		local availres = self.Environment.Resources.CarbonDioxide / self.Environment.Max
		if fuels.CarbonDioxide > 0 then
			availres = availres + (fuels.CarbonDioxide / self.Speed) / 2 -- Pumping in CO2 isn't as efficient as natural breathing, but can be used in addition to natural respiration
		end
		if availres == 0 then
			self.OverlayWarning = "No natural Carbon Dioxide present!"
			produce = 0
		elseif availres > 0.5 then produce = (self.Speed * 2) * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor) -- If theres lots, purification is easy
		elseif availres > 0.2 then produce = (self.Speed) * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
		elseif availres > 0.125 then produce = (self.Speed * 0.6) * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
		elseif availres > 0.05 then produce = (self.Speed * 0.3) * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
		elseif availres > 0.02 then produce = (self.Speed * 0.2) * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
		else produce = (fuels.CarbonDioxide[2] + self.Speed * 0.1) * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor) -- If theres hardly any of a resource present, purification is hard
		end
		self.Environment.Resources["CarbonDioxide"] = self.Environment.Resources["CarbonDioxide"] - max(produce - fuels.CarbonDioxide, 0)
		self.Environment.Resources["Oxygen"] = self.Environment.Resources["Oxygen"] + produce
		self.Requesting.CarbonDioxide = self.Speed
		self.Watered = self.Watered - math.Rand(0.15, 0.5)
		self.TickProductivity = produce / self.Speed
		self.PlantTickProductivity = self.TickProductivity
	end,
	Oxygen = function(self)
		-- Note: Is also H2/CO2/N2, see below
		if self.Environment.IsSpace then self.OverlayWarning = "No natural resources present in space!" return end
		local fuels = self:CollectResources()
		local product

		-- Rate is based on current saturation of the resource within the environment
		local availres = self.Environment.Resources[self.Resource] / self.Environment.Max
		if availres == 0 then self.OverlayWarning = "No natural "..self.Resource.." present!" return
		elseif availres > 0.5 then product = {self.Resource, self.Speed * 2 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)} -- If theres lots, purification is easy
		elseif availres > 0.2 then product = {self.Resource, self.Speed * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		elseif availres > 0.125 then product = {self.Resource, self.Speed * 0.6 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		elseif availres > 0.05 then product = {self.Resource, self.Speed * 0.4 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		elseif availres > 0.02 then product = {self.Resource, self.Speed * 0.25 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		else product = {self.Resource, self.Speed * 0.2 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)} -- If theres hardly any of a resource present, purification is hard
		end
		self.Environment.Resources[self.Resource] = self.Environment.Resources[self.Resource] - product[2]

		return product
	end,
}
-- H2/CO2/N2 all share the same function :D
for k,v in pairs({"Hydrogen", "CarbonDioxide","Nitrogen"}) do ENT.Lists.ProduceResource[v] = ENT.Lists.ProduceResource.Oxygen end
