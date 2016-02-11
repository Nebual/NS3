DEVICE.Setup = function(self)
	self.WaterPhobic = false
	self.OverlayBase = "NS3 Resource Pump"
	self.SoundSpecial = CreateSound(self.Entity,"ambient/nature/water_streamloop3.wav") // in use sound
	self.SoundSpecial:ChangePitch(90,0.25) self.SoundSpecial:ChangeVolume(120,0.25)
	self.PlugPosAng = {
		["models/props_wasteland/gaspump001a.mdl"] = {Vector(-1,-16,44),Angle(-80,-65,155)},
		["models/props_lab/tpplugholder_single.mdl"] = {Vector(8,13,10),Angle()},
	}
	self.PlugPos = (self.PlugPosAng[self:GetModel()] or {Vector()})[1] self.PlugAng = (self.PlugPosAng[self:GetModel()] or {0,Angle(-90,0,0)})[2]

	self.SetActive = function() return end
	self.SetLength = function(self, len, Visual)
		if Visual then self.Rope:Fire("SetLength", len, 0) end
		self.Elast:Fire("SetSpringLength", len, 0)
		self.Length = len
	end
	self.TriggerInput = function(self, iname, value) -- Wiremod Inputs
		if iname == "Deploy" then
			self.ForceLength = nil
			if value != 0 then
				if !self.Deployed then
					local plug = ents.Create("prop_physics")
					plug:SetModel("models/props_lab/tpplug.mdl")
					plug:SetPos(self:LocalToWorld(self.PlugPos))
					plug:SetAngles(self:LocalToWorldAngles(self.PlugAng))
					plug:Spawn()
					self:CallOnRemove("RemovePlug",function() if IsValid(plug) then plug:Remove() end end)
					//plug:Activate()
					local elastpos = Vector(-2,0,0) elastpos:Rotate(self.PlugAng)
					self.Elast, self.Rope = constraint.Elastic( plug, self.Entity, 0, 0, Vector(11,0,0), self.PlugPos + elastpos, 200, 50,0,"cable/rope",2,true)
					self.Plug = plug
					/*plug.AcceptInput = function(_,name,activator,caller) -- Things like E
						print("WATTTT")
						if name == "Use" and caller:IsPlayer() and !caller:KeyDownLast(IN_USE) then -- Edge keyE
							self:TriggerInput("Deploy",(self.Deployed && !self.Retract) and 0 or 1)
						end
					end*/ // doesn't work on prop_physics,  base_gmodentity won't seem to intialize

					WireLib.TriggerOutput( self, "Deployed", 1)
					self:SetLength(100,true)
				end
				self.Deployed = true self.Retract = false
			elseif value == 0 && !self.Retract then
				self.Retract = true
				if IsValid(self.Plug) then
					if IsValid(self.Plug.Weld) then
						if IsValid(self.Connected) then self.Connected.Connected = nil end
						self.Connected = nil
						self.Plug.Weld:Remove()
					end
					self.Length = (self:LocalToWorld(self.PlugPos) - self.Plug:LocalToWorld(Vector(11,0,0))):Length()
				end
			end
		elseif iname == "Length" then
			self.ForceLength = math.max(0,value)
			self:SetLength(math.max(0,value))
		elseif iname == "Resource" then
			if tobool(value) and NS3.Resources[value] then
				self.SpecificResource = value
			else
				self.SpecificResource = nil
			end
		end
	end
	self.AcceptInput = function(self,name,activator,caller) -- Things like E
		if name == "Use" and caller:IsPlayer() and !caller:KeyDownLast(IN_USE) then -- Edge keyE
			self:TriggerInput("Deploy",(self.Deployed && !self.Retract) and 0 or 1)
		end
	end
	//timer.Create("ChangeOverlay"..self:EntIndex(),0.1,1,function() self.OVerlay = self.OverlayBase end
end

DEVICE.SubThink = function(self)
	if self.Connected then
		self.Overlay = self.OverlayBase .. ": Connected"
		self.Entity:NextThink( math.Round(CurTime()) + 1 )
		if self.Deployed then
			// Sending end
			if !IsValid(self.Plug.Weld) then if IsValid(self.Connected) then self.Connected.Connected = nil end self.Connected = nil return end
			if !self.SoundSpecial:IsPlaying() then self.SoundSpecial:Play() end
			local hastransferred
			for k,v in ipairs(self.Connected.Links) do // Look through all ents linked to receiving socket
				if !v:IsValid() then table.remove(self.Connected.Links, k)
				elseif v.Priority == 1 then // Only talk about storages in pumps
					for res,request in pairs(v.Requesting) do // Look through all the requests of each ent linked to receiving socket
						if self.SpecificResource and self.SpecificResource != res then continue end
						if request > 0 then
							for _,donator in ipairs(self.Links) do // Look through all ents linked to sending socket to find a donor
								if donator.Priority == 1 && donator.Resources[res] > 0 then
									hastransferred = true
									local donation = math.Min(request, v.Max / 15)
									table.insert(v.Receiving, {res,donation}) // give it to requestor
									if donator.Resources[res] < donation then
										donator.Resources[res] = 0 // take it from donator
										request = request - donation // lower the request
									else
										donator.Resources[res] = donator.Resources[res] - donation
										request = nil
										break
									end
								end
							end
						end
					end
				end
			end
			if hastransferred then
				self.SoundSpecial:ChangePitch(90,0.25)
				self.SoundSpecial:ChangeVolume(120,0.25)
			else
				self.SoundSpecial:ChangePitch(50,0.25)
				self.SoundSpecial:ChangeVolume(60,0.25)
			end
		else
			//self.PumpRequesting = {}
			//for k,v in pairs(self.Links) do table.insert(self.PumpRequesting
			// Receiving
		end
	else
		if !IsValid(self.Plug) then
			self.Overlay = self.OverlayBase .. ": Undeployed"
			if self.SoundSpecial:IsPlaying() then self.SoundSpecial:Stop() end
			self.Entity:NextThink( math.Round(CurTime()) + 1 )
			return
		end

		if self.SoundSpecial:IsPlaying() then self.SoundSpecial:Stop() end
		self.Entity:NextThink( CurTime() + 0.2 )

		if self.Retract then
			self.Overlay = self.OverlayBase .. ": Retracting"
			if self.Length == 2000 then self.Length = (self:LocalToWorld(self.PlugPos) - self.Plug:LocalToWorld(Vector(11,0,0))):Length() end
			// Gradually bring her in
			self.Length = self.Length - math.Max(20, self.Length / 20)
			if self.Length < 0 then
				self.Plug:Remove()
				self.Plug = nil
				self.Retract = nil
				self.Deployed = nil
				WireLib.TriggerOutput( self, "Deployed", 0)
				return
			end
			self:SetLength(self.Length)
		else
			self.Overlay = self.OverlayBase .. ": Deployed"
			// Look for nearby sockets
			local ClosestDist, Closest = 60
			for k,v in pairs( ents.FindInSphere( self.Plug:GetPos(), 60 ) ) do
				if v.Resource == "Resource_Pump" && !v.Connected && !v.Deployed then
					local Dist = self.Plug:GetPos():Distance( v:LocalToWorld(self.PlugPos) )
					if ClosestDist > Dist then
						ClosestDist = Dist
						Closest = v
					end
				end
			end
			if Closest then // Found one!
				self.Plug:SetPos(Closest:LocalToWorld(Closest.PlugPos))
				self.Plug:SetAngles(Closest:LocalToWorldAngles(Closest.PlugAng))
				self.Plug.Weld = constraint.Weld(self.Plug,Closest,0,0,5000,true)
				self.Connected,Closest.Connected = Closest,self.Entity
				self:SetLength(2000,false)
				return
			end

			if self.Plug:IsPlayerHolding() then
				self:SetLength(2000,false) // So you can phys/gravgun it unrestrained
			elseif self.ForceLength then
				self:SetLength(self.ForceLength)
			else
				// If its just loose, set its length to be how far away it is, so it seems weakly autoretracting
				local curlen = (self:GetPos() - self.Plug:LocalToWorld(Vector(11,0,0))):Length()
				if math.abs(curlen - self.Length) > 25 then self:SetLength(curlen) end
			end
		end
	end
end
