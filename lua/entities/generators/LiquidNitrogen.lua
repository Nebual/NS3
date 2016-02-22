DEVICE.Name = "Liquid Nitrogen Freezer"
DEVICE.Resource = "LiquidNitrogen"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = function(self)
	local fuels = self:CollectResources()

	local ret = {self.Resource, fuels.Nitrogen * 0.9}
	self.Requesting.Nitrogen = self.Speed
	return ret
end
