DEVICE.Setup = function(self)
	self.OverlayBase = "NS3 Gravity Regulator"

	self.IdleSound = nil
	self.LastSound = "ambient/creakmetal1.wav"
	self.Creak = function(self) self.Entity:StopSound(self.LastSound) if !self.Mute then local snd = "ambient/creakmetal"..math.random(1,5)..".wav" self.Entity:EmitSound(snd, 60) self.LastSound=snd end end
	self.SetActive = function(self, value, caller )
		self.BaseClass.SetActive(self, value, caller)
		if tobool(value) && !self.Mute then
			self:Creak()
			timer.Create("Creak_"..self.Entity:EntIndex(), 6, 0, function() self:Creak() end)
		else
			self.Entity:StopSound(self.LastSound)
			timer.Destroy("Creak_"..self.Entity:EntIndex())
		end
	end
	self.OnRemove = function(self) timer.Destroy("Creak_"..self.Entity:EntIndex()) self.Entity:StopSound(self.LastSound) self.BaseClass.OnRemove(self) end
	self.Requesting.Energy = 100
	self.OverlayStatus = "Deploying gravity assisters (0%)..."
	//ambient/creakmetal4.wav
end

DEVICE.SubThink = function(self)
	self.OverlayStatus = nil
	if !self.Active then
		if self.GravWasOn then self.GravWasOn = nil for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = nil end end
		return
	end
	if next(self.Requesting) then
		if self.GravWasOn then self.GravWasOn = nil for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = nil end end
		if !self.DoneSetup then self.OverlayStatus = "Deploying gravity assisters ("..math.Round(100-self.Requesting.Energy).."%)..." end
		self:LowResource("energy")
	else
		self.OverlayWarning = nil
		self.DoneSetup = true
		self.GravWasOn = true
		for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = true end
		self.Requesting.Energy = 5 -- Request more energy
	end
end
