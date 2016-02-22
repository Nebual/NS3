AddCSLuaFile()
DEFINE_BASECLASS( "ns3_base_entity" )
ENT.PrintName 	= "NS3 Resource Generator"
ENT.Purpose		= "Generates NS3 Resources"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName="NS3 Generator"

if CLIENT then return end

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

/*   About writing new generators:
Please return {self.Resource (which is "Energy" or "Water"), the amount of resource produced}
self.Speed is meant to be the main static multiplier for how much resource to produce, which integrates generator model size.

All non-energy generators are assumed to cost energy based on (ResourceProduced * self.Efficiency (default 0.5))
"Normal" generators (ie mid sized oxygen) generate 30 oxygen a second, costing 15 energy.
*/

ENT.Lists = {
	Resource = {},
	Setup = {},
	ProduceResource = {
		Default = function(self)
			local fuels = self:CollectResources()
			return {self.Resource, self.Speed * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
		end,
		-- Energy_Fusion
		// NEEDS TO BE HARD TO DO (only turns on for a few seconds, thus needs complex wiring to properly maintain)
	},
	Name = {},
}
for _, filename in pairs(file.Find('entities/generators/*.lua', 'LUA')) do
	DEVICE = {}
	include('entities/generators/' .. filename)
	local kind = string.StripExtension(filename)
	for k,v in pairs(DEVICE) do
		if ENT.Lists[k] then
			ENT.Lists[k][kind] = v
		end
	end
end

function ENT:Setup()

	local kind = self.Style

	if self.Lists.Setup[kind] then
		self.Lists.Setup[kind](self)
	end
	if self.Lists.Resource[kind] then
		self.Resource = self.Lists.Resource[kind]
	end

	if self.Lists.ProduceResource[kind] then
		self.ProduceResource = self.Lists.ProduceResource[kind]
	else
		self.ProduceResource = self.Lists.ProduceResource.Default
		print("NS3 Warning: No such generator type as "..(kind or ""))
	end

	if !self.HasCustomWireInputs then
		self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Mute" })
	end
	self.Outputs = Wire_CreateOutputs(self.Entity, {"On", "Productivity" })

	self.NormalSpeed = self.Speed -- So namage can reduce speed

	local name = self.Lists.Name[self.Style]
	if !name then
		name = string.Replace(self.Style, '_', ' ') .. " Generator"
	end
	self.OverlayBase =  "NS3 " .. name
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


	if not NS3.ResourceMeta.Energy.Equivalent[self.Resource] then self.Requesting.Energy = 3 end -- Always ask for a little bit of energy... I mean its gotta power the display! :P
	local product = self:ProduceResource()-- Manufactor the resource!
	if !product then return EndThink(self) end
	if not NS3.ResourceMeta.Energy.Equivalent[self.Resource] then self.Requesting.Energy = product[2] * self.Efficiency end
	if !product[1] then return EndThink(self) end

	-- "Productivity" is based on how often the gen is running (does it have enough fuel?) and how much of its product is actually used
	local produced = product[2]
	product = self:SendResources(product)
	self.TickProductivity = (produced - product[2]) / self.NormalSpeed
	return EndThink(self)
end
