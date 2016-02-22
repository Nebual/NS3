DEVICE.Name = "Solar Panels"
DEVICE.Resource = "DC"

DEVICE.Setup = function(self)
	if self:GetModel() == "models/slyfo_2/miscequipmentsolar.mdl" then
		self.Speed = 21
	end

	self.HasCustomWireInputs = true -- Disable wire inputs, solar panels are always on
	self.Mute = true
	self.MustBeActive = false
	self.WaterPhobic = false
	self.AcceptInput = function(self, name, activator, caller) return end
end

DEVICE.ProduceResource = function(self)
	local traces = NS3.SunTrace(self.Entity, true)

	if traces then
		--solar panel produces energy // TODO: make 90 degree pitch fail (rather than giving 25%)
		local output = 0

		for k, trace in pairs(traces) do
			output = output + ((self.Entity:GetUp() + trace.HitNormal).z / 2) ^ 2
		end

		if output < 0.05 then
			self:SetActive(false)
			return
		end

		self:SetActive(true)
		self.OverlayWarning = "Power: " .. math.Round(output * 100) .. "%"

		return {self.Resource, self.Speed * math.Rand(1 - self.RandomFactor, 1 + self.RandomFactor) * output}
	end
end
