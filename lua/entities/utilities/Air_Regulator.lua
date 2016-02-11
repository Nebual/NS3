DEVICE.Setup = function(self)
	self.Regulate = self.Lists.Regulate[self.Style] or NS3.NullFunction
	self.Range = NS3.RegulatorModels[self:GetModel()] or math.Round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.72 * 0.8)
	self.WaterPhobic = false
	self.BufferSize = math.Round(self.Range / 10)
	self.OverlayBase = "NS3 Air Regulator"
	table.insert(NS3.AirRegulators, self)
	local timerid = "NS3_FindFootBreathEnts_"..self:EntIndex()
	timer.Create(timerid, 10, 0, function() if self:IsValid() then self:FindFootBreathEnts(timerid) else timer.Remove(timerid) end end)
end

DEVICE.SubThink = function(self)
	if self.Active then
		if self.Resources.Energy < 5 then self:LowResource("energy") self:SetActive(false)
		elseif self.Resources.Oxygen < 5 then self:LowResource("oxygen")
		else
			self.OverlayWarning = nil
			self.Resources.Energy = self.Resources.Energy - 5
		end
	end
	self.Requesting.Energy = self.BufferSize - self.Resources.Energy
	self.Requesting.Oxygen = self.BufferSize * math.Max(1, self.Environment.Pressure or 1) - self.Resources.Oxygen
	self.Overlay3 = "Buffer: Energy " .. math.Round(self.Resources.Energy) .. ", Oxygen " .. math.Round(self.Resources.Oxygen)
end

DEVICE.Regulate = function(self, ply) // Returns true if it can handle the draw, false otherwise
	local cost = 5
	if ply.Environment then cost = math.Max(5 * ply.Environment.Pressure, 5) end
	if self.Resources.Oxygen >= cost then
		self.Resources.Oxygen = self.Resources.Oxygen - cost
		self.Environment.Resources.CarbonDioxide = self.Environment.Resources.CarbonDioxide + cost
		return true
	end
end
