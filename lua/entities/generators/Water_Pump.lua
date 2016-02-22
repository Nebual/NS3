DEVICE.Name = "Water Pump"
DEVICE.Resource = "Water"

DEVICE.Setup = function(self)
	self.WaterPhobic = false
	self.IdleSound = "ambient/water/water_run1.wav"
	self.IdleSound2 = nil
end

DEVICE.ProduceResource = function(self)
	local fuels = self:CollectResources()

	-- Take away from planet's "water" level, to simulate lakes being depletable (they restore over time)
	if self:WaterLevel() < 2 then
		self:LowResource("water submersion!")
		self:SetActive(false)
		return
	end

	if self.Environment.Resources.Water < self.Speed * 0.5 then
		self:LowResource("water levels in lake!")
		return
	end

	self.OverlayWarning = nil

	if fuels.Energy then
		self.Environment.Resources.Water = self.Environment.Resources.Water - self.Speed * 0.5
		return {self.Resource, self.Speed * 0.3}
	else
		return {"", self.Speed * 0.3}
	end
end
