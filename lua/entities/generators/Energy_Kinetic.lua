DEVICE.Name = "Kinetic Energy Collector"
DEVICE.Resource = "DC"
DEVICE.Setup = function(self)
	self.Mute = true
end

DEVICE.ProduceResource = function(self)
	// Basically this is just so people shove some moving parts on their plane which look steampunky, also it has a rather low max energy output cause people will probably just thruster these.
	local spd = self:GetPhysicsObject():GetAngleVelocity():Length()
	if spd > 10 then
		return {self.Resource, self.Speed * (math.Min(spd,400) ^ 1.5)/8000  * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)}
	end
end
