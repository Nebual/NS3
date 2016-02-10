AddCSLuaFile()
DEFINE_BASECLASS( "ns3_base_entity" )
ENT.PrintName 	= "NS3 Utility Ent"
ENT.Purpose		= "Uses NS3 Resources"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName="NS3 Utility"

for k=1,5 do util.PrecacheSound( "ambient/creakmetal"..k..".wav" ) end

if CLIENT then
	local ball = ClientsideModel("models/hunter/misc/shell2x2.mdl", RENDERGROUP_OPAQUE)
	ball:SetNoDraw( true ) ball:DrawShadow( false )
	ball:SetMaterial("models/shiny")
	function ENT:Draw()
		self.BaseClass.Draw(self)

		if LocalPlayer():GetEyeTrace().Entity == self and IsValid(LocalPlayer():GetTool()) and LocalPlayer():GetTool().Mode == "nebsupporter" then

			local range = self:GetNetworkedInt("Range")
			if range then
				ball:SetColor(Color(0,0,100,100))
				ball:SetPos(self:GetPos())
				SetScale(ball, Vector(math.Max(range / 95, 0.01), math.Max(range / 95, 0.01), math.Max(range / 95, 0.01)))
				timer.Create("ResetNebsupporterBall",5,1,function()
					ball:SetColor(Color(0,0,0,0))
				end)
			end
		end
	end
	return
end

ENT.Lists = {}

local function BoolNum(bool) if bool then return 1 else return 0 end end
local round = math.Round

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Entity:NextThink( round(CurTime()) + 2 )

	self.Priority = self.Priority or 4
	self.Efficiency = self.Efficiency or math.Rand(0.8,1.2) // Oxygen should be 2, hydrogen 3, etc. Harder ones higher
	self.RandomFactor = self.RandomFactor or 0.15

	self.Resources = table.Copy(NS3.Resources)
	self.FootBreaths = {}
	self.LastWarned = 0
	self.WaterPhobic = true

	-- Incase we don't have environments, like on gm_ maps, give the generator its own 'planet' to harvest from
	self.Environment = {Resources = {Empty = 0}, Max = 4000000, Pressure = 1, Gravity = 1}
	for k,_ in pairs(NS3.Resources) do self.Environment.Resources[k] = 1000000 end

	self.OverlayBase =  "NS3 Unspecified Utility Device"
end

function ENT:Setup()
	local kind = self.Style
	if kind == "Resource_Pump" then
		WireLib.CreateSpecialInputs(self.Entity, { "Deploy","Length","Resource" },{"NORMAL","NORMAL","STRING"})
		WireLib.CreateOutputs(self.Entity, {"Deployed" })
	elseif kind != "Suit_Recharger" then
		WireLib.CreateInputs(self.Entity, { "On", "Mute" })
		WireLib.CreateOutputs(self.Entity, {"On" })
	end
	self.SubThink = self.Lists.SubThink[kind] or self.Lists.SubThink.Default

	if kind == "Air_Regulator" then
		self.Regulate = self.Lists.Regulate[kind] or self.Lists.Regulate.Default
		self.Range = NS3.RegulatorModels[self:GetModel()] or round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.72 * 0.8)
		self.WaterPhobic = false
		self.BufferSize = round(self.Range / 10)
		self.OverlayBase = "NS3 Air Regulator"
		table.insert(NS3.AirRegulators, self)
		local timerid = "NS3_FindFootBreathEnts_"..self:EntIndex()
		timer.Create(timerid, 10, 0, function() if self:IsValid() then self:FindFootBreathEnts(timerid) else timer.Remove(timerid) end end)
	elseif kind == "Heat_Regulator" then
		self.Regulate = self.Lists.Regulate[kind] or self.Lists.Regulate.Default
		self.Range = NS3.RegulatorModels[self:GetModel()] or round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.72 * 0.8)
		self.WaterPhobic = false
		self.BufferSize = round(self.Range / 10)
		self.OverlayBase = "NS3 Heat Regulator"
		table.insert(NS3.TemperatureRegulators, self)
		local timerid = "NS3_FindFootBreathEnts_"..self:EntIndex()
		timer.Create(timerid, 10, 0, function() if self.Entity:IsValid() then self.Entity:FindFootBreathEnts(timerid) else timer.Remove(timerid) end end)
	elseif kind == "Suit_Recharger" then
		self.Speed = round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.3 * 1.32)
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
	elseif kind == "Planetary_Probe" then
		self.OverlayBase = "NS3 Planetary Probe"
		self.Mute = true
		if !NS3.HasPlanets then
			self.Environment = {Name = string.upper(string.sub(game.GetMap(),4,4))..string.sub(game.GetMap(), 5, string.find(game.GetMap(), "_",5) - 1),Pressure = 1, Temperature = 288, Gravity = 1, Atmosphere = 1, Max = 40000, Resources = {Empty = 0}}
			for _,v in pairs({"Oxygen","CarbonDioxide","Nitrogen","Hydrogen"}) do self.Environment.Resources[v] = 10000 end
		end
		WireLib.AdjustSpecialOutputs(self.Entity, {"On","Name","Pressure","Atmosphere","Vacuum","Gravity","Temperature","Oxygen","CarbonDioxide","Nitrogen","Hydrogen"},{"NORMAL","STRING","NORMAL","NORMAL","NORMAL","NORMAL","NORMAL","NORMAL","NORMAL","NORMAL","NORMAL"})
	elseif kind == "Resource_Counter" then
		self.OverlayBase = "NS3 Resource Counter"
		self.Mute = true
		self.WaterPhobic = false

		self.SetActive = function() return end
		timer.Create("ResourceCounterSetup"..self:EntIndex(), 0.1, 3, function() self.Overlay = self.OverlayBase end)

		WireLib.AdjustSpecialInputs(self.Entity, {}, {})
		local tab = {}
		local tab2 = {}
		for _, res in pairs({"Energy", "Oxygen", "CarbonDioxide", "Nitrogen", "Hydrogen", "Water"}) do
			table.insert(tab, res) table.insert(tab2, "NORMAL")
			table.insert(tab, "Max "..res) table.insert(tab2, "NORMAL")
			table.insert(tab, "% "..res) table.insert(tab2, "NORMAL")
		end
		WireLib.AdjustSpecialOutputs(self.Entity, tab, tab2)
	elseif kind == "Gravity_Regulator" then
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
	elseif kind == "SpaceShield" then
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
	elseif kind == "Resource_Pump" then
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
	if self.Range then self:SetNetworkedInt("Range",self.Range) end

	self.Overlay = self.OverlayBase .. ": Off!"
	self:UpdateOverlayText()
end

function ENT:Think()
	self.BaseClass.BaseClass.Think(self)
	self.Entity:NextThink( round(CurTime()) + 1 )

	if self.WaterPhobic then
		if self.Entity:WaterLevel() > 1 then
			-- Turn off in water
			self:SetColor(Color(50, 50, 50, 255))
			self:SetActive(false)
			self.OverlayWarning = "Excessive water detected"
			self.HadWetShutdown = true
			self:UpdateOverlayText()
			return true
		elseif self.HadWetShutdown then
			self.HadWetShutdown = nil
			self.OverlayWarning = ""
			self:SetColor(Color(255, 255, 255, 255))
			self:UpdateOverlayText()
		end
	end
	self:StoreCollectResources() -- Gather incoming resources
	self:SubThink() -- Ask for more resources, think, etc

	self:UpdateOverlayText()
	return true
end

ENT.Lists.SubThink = {
	Default = function() return end, -- default to avoid nil errors
	Air_Regulator = function(self)
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
		self.Overlay3 = "Buffer: Energy " .. round(self.Resources.Energy) .. ", Oxygen " .. round(self.Resources.Oxygen)
	end,
	Heat_Regulator = function(self)
		if self.Active then
			if self.Resources.Energy < 5 then self:LowResource("energy")
			//elseif self.Resources.Water < 5 then self:LowResource("coolant (water)")
			else
				self.OverlayWarning = nil
				self.Resources.Energy = self.Resources.Energy - 5
			end
		end
		self.Requesting.Energy = self.BufferSize*2 - self.Resources.Energy
		self.Requesting.Water = self.BufferSize - self.Resources.Water
		self.OverlayStatus = "Buffer: Energy " .. round(self.Resources.Energy) .. ", Water " .. round(self.Resources.Water)
	end,
	Suit_Recharger = function(self)
		if self.Active then
			local ply = Entity(self.Active or -1)
			local stop = (!IsValid(ply) or !ply:KeyDown(IN_USE))
			if !stop then
				stop = true
				ply.Suit.Show = true
				timer.Create("StopShowingSuit_"..ply:EntIndex(), 3, 1, function() if IsValid(ply) then ply.Suit.Show = nil end end)
				local max = GetConVarNumber("ns3_suitmax")
				local tab1 = {"Oxygen", "Energy", "Coolant"}
				for k,v in ipairs({"Oxygen", "Energy", "Water"}) do
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
		self.Requesting.Water = self.Max - self.Resources.Water
		self.OverlayStatus = "Buffer: Energy " .. round(self.Resources.Energy) .. ", Oxygen " .. round(self.Resources.Oxygen) .. ", Water " .. round(self.Resources.Water)
	end,
	Planetary_Probe = function(self)
		self.OverlayStatus = nil
		if !self.Active then return end
		if next(self.Requesting) then
			if !self.DoneProbing then self.OverlayStatus = "Probing "..self.LastEnv.." ("..round(100-self.Requesting.Energy).."%)..." end
			self:LowResource("energy")
		else
			self.OverlayWarning = nil
			local env = self.Environment
			if env.Name != self.LastEnv then
				self.DoneProbing = false
				self.LastEnv = env.Name
				self.Requesting.Energy = 100
				self.OverlayStatus = "Probing "..env.Name.." (0%)..."
				return
			end
			self.DoneProbing = true
			local temp = env.Temperature or 14
			if env.TemperatureLit && env.TemperatureLit != env.Temperature then temp = temp .. "-"..env.TemperatureLit end
			if env.Name == "Space" then temp = 14 end // Make it look like its 14, its actually 200 for balance reasons (space can't be THAT hard...)
			self.OverlayStatus = env.Name.."\n"..
				"Pressure: ".. round(100*env.Pressure) .."% ("..round(100*env.Resources.Empty/env.Max).."% Vacuum)  Atmosphere: "..env.Atmosphere .."\n"..
				"Gravity: "..env.Gravity.."x of Earth\n"..
				"Temperature: "..temp .."\n"..
				"Oxygen: "..round(100*env.Resources.Oxygen/env.Max).."%  CarbonDioxide: "..round(100*env.Resources.CarbonDioxide/env.Max).."%\n"..
				"Nitroxen: "..round(100*env.Resources.Nitrogen/env.Max).."%  Hydrogen: "..round(100*env.Resources.Hydrogen/env.Max).."%"
			if env.Unstable then self.OverlayStatus = self.OverlayStatus .. "\nWarning: Unstable!" end
			for _,v in pairs({"Name","Pressure","Atmosphere","Gravity","Temperature"}) do WireLib.TriggerOutput(self.Entity, v, env[v]) end
			for _,v in pairs({"Oxygen","CarbonDioxide","Nitrogen","Hydrogen"}) do WireLib.TriggerOutput(self.Entity, v, round(100*env.Resources[v]/env.Max)) end
			WireLib.TriggerOutput(self.Entity, "Vacuum", round(100*env.Resources.Empty/env.Max))
			self.Requesting.Energy = 5 -- Request more energy to power the display
		end
	end,
	Resource_Counter = function(self)
		local resources = table.Copy(NS3.Resources)
		local maxes = {}
		for k,v in pairs(self.Links) do
			if IsValid(v) and v.Resources and v.Resource and v.Max then
				resources[v.Resource] = (resources[v.Resource] or 0) + v.Resources[v.Resource]
				maxes[v.Resource] = (maxes[v.Resource] or 0) + v.Max
			end
		end

		for _,v in pairs({"Energy", "Oxygen","CarbonDioxide","Nitrogen","Hydrogen", "Water"}) do
			WireLib.TriggerOutput(self.Entity, v, resources[v])
			WireLib.TriggerOutput(self.Entity, "Max "..v, maxes[v] or 0)
			WireLib.TriggerOutput(self.Entity, "% "..v, 100 * resources[v] / (maxes[v] or 1))
		end
	end,
	Gravity_Regulator = function(self)
		self.OverlayStatus = nil
		if !self.Active then
			if self.GravWasOn then self.GravWasOn = nil for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = nil end end
			return
		end
		if next(self.Requesting) then
			if self.GravWasOn then self.GravWasOn = nil for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = nil end end
			if !self.DoneSetup then self.OverlayStatus = "Deploying gravity assisters ("..round(100-self.Requesting.Energy).."%)..." end
			self:LowResource("energy")
		else
			self.OverlayWarning = nil
			self.DoneSetup = true
			self.GravWasOn = true
			for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = true end
			self.Requesting.Energy = 5 -- Request more energy
		end
	end,
	Gravity_Regulator = function(self)
		self.OverlayStatus = nil
		if !self.Active then
			if self.GravWasOn then self.GravWasOn = nil for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = nil end end
			return
		end
		if next(self.Requesting) then
			if self.GravWasOn then self.GravWasOn = nil for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = nil end end
			if !self.DoneSetup then self.OverlayStatus = "Deploying gravity assisters ("..round(100-self.Requesting.Energy).."%)..." end
			self:LowResource("energy")
		else
			self.OverlayWarning = nil
			self.DoneSetup = true
			self.GravWasOn = true
			for k,v in pairs(constraint.GetAllConstrainedEntities(self.Entity)) do v.GravPlate = true end
			self.Requesting.Energy = 5 -- Request more energy
		end
	end,
	Resource_Pump = function(self)
		if self.Connected then
			self.Overlay = self.OverlayBase .. ": Connected"
			self.Entity:NextThink( round(CurTime()) + 1 )
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
				self.Entity:NextThink( round(CurTime()) + 1 )
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
	end,
}

ENT.Lists.Regulate = {
	Default = function() return end, -- default to avoid nil errors
	Air_Regulator = function(self, ply) // Returns true if it can handle the draw, false otherwise
		local cost = 5
		if ply.Environment then cost = math.Max(5 * ply.Environment.Pressure, 5) end
		if self.Resources.Oxygen >= cost then
			self.Resources.Oxygen = self.Resources.Oxygen - cost
			self.Environment.Resources.CarbonDioxide = self.Environment.Resources.CarbonDioxide + cost
			return true
		end
	end,
	Heat_Regulator = function(self, ply) // Returns the ent's new temperature
		local temp = ply.Suit.Temperature
		if temp > 295 then
			// if nitro then use that else use below formulas
			local diff = math.Min(math.Min(temp - 295, 15), self.Resources.Water)
			self.Resources.Water = self.Resources.Water - diff
			return temp - diff
		elseif temp < 295 then
			local diff = math.Min(math.Min(295 - temp, 15), self.Resources.Energy)
			self.Resources.Energy = self.Resources.Energy - diff
			return temp + diff
		end
		return temp
	end,
}

local function EntIsNormal(ent)
	return not (!IsValid(ent) or ent:EntIndex() == 0 or !IsValid(ent:GetPhysicsObject()) or ent:IsNPC() or ent:IsPlayer() or !ent:GetModel() or ent.CDSIgnore or ent:GetClass() == "gmod_ghost" or string.sub(ent:GetClass(), 1, 4) == "func")
end

function ENT:FindFootBreathEnts(timerid)
	if !IsValid(self) then timer.Remove(timerid) return end
	for k,v in pairs(self.FootBreaths) do v[self.Resource] = nil end
	self.FootBreaths = {}
	for k,v in pairs(ents.FindInSphere(self:GetPos(),self.Range)) do if EntIsNormal(v) then self.FootBreaths[v:EntIndex()] = v end end

	local constraintstab
	if self:GetParent():IsValid() then constraintstab = constraint.GetAllConstrainedEntities(self:GetParent())
	else constraintstab = constraint.GetAllConstrainedEntities(self.Entity)
	end
	for k,v in pairs(constraintstab) do if self.FootBreaths[v:EntIndex()] then v[self.Resource] = self.Entity end end
end
