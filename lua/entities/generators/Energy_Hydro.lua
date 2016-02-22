DEVICE.Name = "Hydroelectric Generator"
DEVICE.Resource = "DC"

DEVICE.Setup = function(self)
	self.WaterPhobic = false
	self.IdleSound = "Airboat_water_fast"
	self.IdleSound2 = nil
end

DEVICE.ProduceResource = function(self)
	local mul = 1

	if not self.Pulse then
		self.Pulse = 1
		timer.Create("NS3_Pulse_" .. self:EntIndex(), math.Rand(8, 22), 1, function()
			if not self:IsValid() or not self.Active then return end
			self.Pulse = math.Rand(4, 11)
			self.PulseTime = CurTime()

			timer.Create("NS3_Pulse_" .. self:EntIndex(), self.Pulse, 1, function()
				self.Pulse = nil
			end)
		end)
	elseif self.Pulse > 1 then
		mul = 1 - math.Min((CurTime() - self.PulseTime) / 6, 0.8)
	end

	if self:WaterLevel() > 1 then
		--self.Entity:EmitSound( self.IdleSound2,100,50 + mul*50, 20 + mul*80 )
		return {self.Resource, self.Speed * mul * 0.25}
	else
		--self.Entity:StopSound( self.IdleSound2 )
		self.OverlayWarning = "Generator must be submerged!"
		self:SetActive(false) -- Should I be switching it off?
	end
end
