DEVICE.Name = "Vespene Turbine"
DEVICE.Resource = "AC"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = function(self)
	local fuels = self:CollectResources()

	self.Requesting.RefinedVespene = self.Speed / 6
	return {self.Resource, fuels.RefinedVespene * 2 }
end
