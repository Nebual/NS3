DEVICE.Name = "Coal Generator"
DEVICE.Resource = "AC"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = function(self)
	// TODO: Make better
	local fuels = self:CollectResources()
	local produce = self.Speed * 3 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
	self.Requesting.Fuel = produce * self.Efficiency
	if fuels.Fuel then
		return {self.Resource, produce}
	else
		return {"", produce}
	end
end
