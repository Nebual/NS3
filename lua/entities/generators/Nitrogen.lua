DEVICE.Name = "Nitrogen Compressor"
DEVICE.Resource = "Nitrogen"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = ENT.Lists.ProduceResource['0_BaseGas']
