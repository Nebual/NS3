DEVICE.Setup = function(self)
	self.Speed = math.Round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.3 * 1.32)
	self.Max = 50
	self.OverlayBase = "NS3 Suit Recharger"
	self.Overlay = self.OverlayBase ..": Ready!"
	self.SetActive = function( self, value, caller )
		if !tobool(value) or !IsValid(caller) or !caller:IsPlayer() then return false end
		-- Only letting one person use this at a time fits perfectly into the existing SetActive infrastructure
		self.Active = caller:EntIndex()
		self.Overlay = self.OverlayBase .. ": In use by "..caller:Nick().."!"
		caller:EmitSound( "ambient.steam01" )
	end
end

DEVICE.SubThink = function(self)
	if self.Active then
		local ply = Entity(self.Active or -1)
		local stop = (!IsValid(ply) or !ply:KeyDown(IN_USE))
		if !stop then
			stop = true
			ply.Suit.Show = true
			timer.Create("StopShowingSuit_"..ply:EntIndex(), 3, 1, function() if IsValid(ply) then ply.Suit.Show = nil end end)
			local max = GetConVarNumber("ns3_suitmax")
			local tab1 = {"Oxygen", "Energy", "Coolant"}
			for k,v in ipairs({"Oxygen", "Energy", "Coolant"}) do
				if ply.Suit[tab1[k]] < max && self.Resources[v] > 0 then
					local gain = math.Min(self.Speed,self.Resources[v])
					ply.Suit[tab1[k]] = ply.Suit[tab1[k]] + gain
					self.Resources[v] = self.Resources[v] - gain
					stop = false
				end
			end
		end
		if stop then
			if IsValid(ply) then ply:StopSound( "ambient.steam01" ) end
			self.Overlay = self.OverlayBase ..": Ready!"
			self.Active = nil
		end
	end

	self.Requesting.Energy = self.Max - self.Resources.Energy
	self.Requesting.Oxygen = self.Max - self.Resources.Oxygen
	self.Requesting.Coolant = self.Max - self.Resources.Coolant
	self.OverlayStatus = "Buffer: Energy " .. math.Round(self.Resources.Energy) .. ", Oxygen " .. math.Round(self.Resources.Oxygen) .. ", Coolant " .. math.Round(self.Resources.Coolant)
end
