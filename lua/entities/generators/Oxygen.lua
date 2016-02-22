DEVICE.Name = "Oxygen Compressor"
DEVICE.Resource = "Oxygen"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = ENT.Lists.ProduceResource['0_BaseGas']
