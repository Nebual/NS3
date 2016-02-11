DEVICE.Setup = function(self)
	self.OverlayBase = "NS3 Space Shield"

	WireLib.CreateInputs(self.Entity, { "On", "Range", "Strength", "Speed", "Mute" })
	WireLib.CreateOutputs(self.Entity, {"On" })
	self.TriggerInput = function(self, iname, value) -- Wiremod Inputs
		if iname == "On" then self:SetActive(value)
		elseif iname == "Range" then self.Range = math.Clamp(100,5000) // TODO: Also resize the buffer
		elseif iname == "Strength" then self.Strength = math.Clamp(1,10)
		elseif iname == "Speed" then self.FillSpeed = math.Clamp(1,10)
		elseif iname == "Mute" then
			self.Mute = value != 0
			if self.Mute then
				if self.IdleSound then self.Entity:StopSound( self.IdleSound ) end
				if self.IdleSound2 then self.Entity:StopSound( self.IdleSound2 ) end
			else self:SetActive(self.Active)
			end
		end
	end
	self.IdleSound = nil
end

DEVICE.SubThink = function(self)
	
end
