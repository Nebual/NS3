DEVICE.Name = "Water Condenser"
DEVICE.Resource = "Water"
DEVICE.Setup = function(self)
	self.Efficiency = 15
end

DEVICE.ProduceResource = function(self)
	local fuels = self:CollectResources()
	if fuels.Energy then
		self.Entity:NextThink(math.Round(CurTime()) + math.random(2, 6) + 0.95)

		if self.Environment.Resources.Hydrogen / self.Environment.Max > 0.005 && self.Environment.Resources.Oxygen / self.Environment.Max > 0.06 then
			self.Environment.Resources.Hydrogen = self.Environment.Resources.Hydrogen - 2
			self.Environment.Resources.Oxygen = self.Environment.Resources.Oxygen - 1
			return {self.Resource, 1}
		end
	else
		return {"", 1}
	end
end
