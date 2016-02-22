DEVICE.Name = "Plant"
DEVICE.Setup = function(self)
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

DEVICE.ProduceResource = function(self)
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
end

DEVICE.Regulate = function(self, ply) // Returns true if it can handle the draw, false otherwise
	local cost = 5
	if ply.Environment then cost = math.Max(5 * ply.Environment.Pressure, 5) end
	if self.Resources.Oxygen >= cost then
		self.Resources.Oxygen = self.Resources.Oxygen - cost
		self.Environment.Resources.CarbonDioxide = self.Environment.Resources.CarbonDioxide + cost
		return true
	end
end
