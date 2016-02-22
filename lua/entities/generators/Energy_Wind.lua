DEVICE.Name = "Wind Generator"
DEVICE.Resource = "DC"

DEVICE.Setup = function(self)
	self.RandomFactor = 0.8
	self.IdleSound = "ambient/wind/wasteland_wind.wav"
	self.IdleSound2 = nil
	self:SetActive(true)
end

DEVICE.ProduceResource = function(self)
	return {self.Resource, self.Speed * self.Environment.Atmosphere * 0.2 * math.Rand(1 - self.RandomFactor, 1 + self.RandomFactor * 2)}
end
