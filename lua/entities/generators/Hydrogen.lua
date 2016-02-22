DEVICE.Name = "Hydrogen Compressor"
DEVICE.Resource = "Hydrogen"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = ENT.Lists.ProduceResource['0_BaseGas']
