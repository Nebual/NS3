DEVICE.Name = "Carbon Dioxide Compressor"
DEVICE.Resource = "CarbonDioxide"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = ENT.Lists.ProduceResource['0_BaseGas']
