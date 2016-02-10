ENT.Type 		= "anim"
ENT.Base 		= "base_anim"
ENT.PrintName 	= "NS3 Planetoid"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= "Planetoid for NS3"
ENT.Instructions	= ""

ENT.Spawnable		= false
ENT.AdminOnly		= false
AddCSLuaFile( "cl_init.lua" )

local round = math.Round
function ENT:Initialize()
	self.Entity:SetModel("models/props_lab/huladoll.mdl")
	//self.Entity:PhysicsInit( SOLID_NONE )
	//self.Entity:SetMoveType( MOVETYPE_NONE )
	//self.Entity:SetSolid( SOLID_NONE )
	self:SetNotSolid(true)
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self.Resources = {Empty = 0}
	self.ResourcePercents = {Empty = 0}
	for k,_ in pairs(NS3.Resources) do self.Resources[k] = 0 self.ResourcePercents[k] = 0 end
	self.CDSIgnore = true
	self.Namage = {Immune = 1}
end

util.AddNetworkString("NS3.AddStar")
function ENT:CreateEnvironment(radius, gravity, atmosphere, pressure, shadetemp, littemp, o2, co2, n, h, unstable, sunburn, name)
	self.Name = name
	self.Radius = math.abs(radius or 100)
	if self.NeedsLuaModel then -- Nothing automatically sets this yet, it was just in alpha
		// If the planet is being created by an lua script, it won't have a physical counterpart from hammer, so we'll need to invent it one!
		self:SetNoDraw(false)

		self.Size = Vector(self.Radius,self.Radius,1)
		if !self.GasGiant then -- Gas giants have no collisions
			self:SetNotSolid(false)
			self.Entity:PhysicsInitBox(-self.Size,self.Size)
			self.Entity:SetCollisionBounds(-self.Size,self.Size)
			self.Entity:GetPhysicsObject():EnableMotion(false)
			self.Entity:SetSolid(SOLID_BBOX) -- May need to be SOLID_CUSTOM in gmod13
		end

		timer.Create("LuaPlanet_"..self:EntIndex(), 0.5, 1, function() -- Delayed so the client can hear the Ent is created via source
			net.Start("ns3_setplanet")
				net.WriteUInt(self:EntIndex(), 16)
				net.WriteUInt(self.Radius, 16)
				net.WriteString("") -- mDiscMat
				net.WriteString("") -- mSphereMat
				net.WriteString("") -- mSphere2Mat
				net.WriteString("") -- mSphereDualMat
				net.WriteFloat(0.6)	-- mSphere2Alpha
				net.WriteFloat(0.4)	-- mSphereDualAlpha
				net.WriteFloat(0.025)-- rotationSpeed
			net.Broadcast()
		end)
	end

	if littemp != 0 then self.TemperatureLit = littemp end
	self.Temperature = shadetemp or 288
	self.Gravity = gravity or 0.99
	self.Atmosphere = math.Max(atmosphere or pressure or 0.99, 0.02) //math.Clamp(atmosphere or 1, 0, 1)
	// Clamping atmosphere to be at least 0.02 was to fix it being 0, making self.Max = 0, ruining all resources.
	// If an environment has 0 atmosphere it should be HARDER to terraform by needing more resources, not easier!
	self.Pressure = pressure or math.Round(self.Atmosphere * self.Gravity)// I was previously math.Max'ing this, math.Round(self.Atmosphere * self.Gravity))
	self.RealPressure = self.Pressure
	self.Unstable = unstable
	self.Sunburn = sunburn

	self.Max = math.Round(400 * (self:GetVolume()/1000) * self.Atmosphere)

	o2 = math.Clamp(o2 or 0, 0, 100)
	self.ResourcePercents.Oxygen = o2
	self.Resources.Oxygen = math.Round(o2 / 100 * self.Max)
	co2 = math.Clamp(co2 or 0, 0, 100-o2)
	self.ResourcePercents.CarbonDioxide = co2
	self.Resources.CarbonDioxide = math.Round(co2 / 100 * self.Max)
	h = math.Clamp(h or 0, 0, 100-o2-co2)
	self.ResourcePercents.Hydrogen = h
	self.Resources.Hydrogen = math.Round(h / 100 * self.Max)
	n = math.Clamp(n or 0, 0, 100-o2-co2-h)
	self.ResourcePercents.Nitrogen = n
	self.Resources.Nitrogen = math.Round(n / 100 * self.Max)
	if o2 + co2 + n + h < 100 then
		self.ResourcePercents.Empty = 100 - (o2 + co2 + n + h)
		self.Resources.Empty = math.Round(self.ResourcePercents.Empty * 4 * (self:GetVolume()/1000) * self.Atmosphere)
	end
	self.Resources.Water = self.Max / 20000 // This number meant sb_gooniverse's spawn had 2000 water to start, water refreshes, no its not part of self.Max
	timer.Create("NS3_Planet_RefreshWater_"..self:EntIndex(), 10, 0, function()
		self.Resources.Water = self.Resources.Water + math.Min(self.Max/20000 - self.Resources.Water, 350)
	end)

	if self.IsStar then
		/*net.Start("NS3.AddStar")
			net.WriteEntity(self)
			net.WriteVector(self:GetPos())
			net.WriteFloat(self.Radius)
		net.Broadcast()*/
		self.Priority = 2
	else
		self.Priority = 1
	end
end

function ENT:Think()
	self.Entity:NextThink( round(CurTime()) + 1 )
	self.Pressure = self.RealPressure - (self.Resources.Empty / self.Max * self.RealPressure * 0.75)
	return true
end

function ENT:AddResource(res, amount)
	self.Resources[res] = self.Resources[res] + amount
end
function ENT:TakeResource(res, amount)
	local cur = self.Resources[res]
	if cur > amount then
		self.Resources[res] = cur - amount
		return amount
	else
		self.Resources[res] = 0
		return cur
	end
end
function ENT:Convert(res1, res2, amount)
	if GetConVar("ns3_staticenvironments"):GetBool() then return amount end
	if self.Resources[res1] < amount then amount = self.Resources[res1] end
	self.Resources[res1] = self.Resources[res1] - amount
	self.Resources[res2] = self.Resources[res2] + amount
	return amount
end

function ENT:GetVolume() if self.IsCube then return self.BoxSize.x * self.BoxSize.y * self.BoxSize.z *8 else return (4/3) * math.pi * self.Radius * self.Radius end end //*8 cause BoxSize is a bunch of radiuses; they're half the side lengths
function ENT:GetTemperature(ent)
	if !IsValid(ent) then return 0 end
	local entpos = ent:GetPos()
	if self.IsStar then
		-- If the ent is in a star's enviromental radius, its temperature is based on star distance
		/*local dist = entpos:Distance(self:GetPos())
		if dist < self.Radius/6 then
			return self.Temperature
		elseif dist < self.Radius * 1/3 then
			return self.Temperature2
		elseif dist < self.Radius * 1/2 then
			return self.Temperature3
		elseif dist < self.Radius * 2/3 then
			return self.Temperature4
		elseif self.Temperature5 <= 14 then //Check that it isn't colder then Space, else return Space temperature
			return 14
		else
			return self.Temperature5 //All other checks failed, player is the farest away from the star, but temp is still warmer then space, return that temperature
		end*/
		return self.Temperature
	end

	-- Otherwise, the ent's temperature is based on its environment's
	if (self.Sunburn or self.TemperatureLit) && NS3.SunTrace(ent) then
		-- If the ent is in direct sunlight, it uses a different temperature
		if ent:IsPlayer() && ent:Alive() && self.Sunburn then
			ent:TakeDamage( 5, 0 )
			ent:EmitSound( "HL2Player.BurnPain" )
		end
		return self.TemperatureLit + (self.TemperatureLit * ((self.Resources.CarbonDioxide/self.Max) - self.ResourcePercents.CarbonDioxide/100) / 2)
	end
	return self.Temperature + (self.Temperature * ((self.Resources.CarbonDioxide/self.Max) - self.ResourcePercents.CarbonDioxide/100) / 2)
end

function ENT:OnEnvironment(ent)
	local pos = ent:GetPos()
	local dist = pos:Distance(self:GetPos())
	if dist < self.Radius then
		if !self.IsCube or table.HasValue(ents.FindInBox( self:GetPos() - self.BoxSize, self:GetPos() + self.BoxSize ), ent) then
			if !ent.Environment then ent.Environment = self
			else
				if ent.Environment.Priority < self.Priority then
					ent.Environment = self
				elseif ent.Environment.Priority == self.Priority then
					if ent.Environment.Radius != 0 then
						if self.Radius <= ent.Environment.Radius then
							ent.Environment = self
						else
							if dist < pos:Distance(ent.Environment:GetPos()) then
								ent.Environment = self
							end
						end
					else
						ent.Environment = self
					end
				end
			end
		end
	end
end

function ENT:OnRemove()
	if self.IsStar then
		for k,v in pairs(NS3.Stars) do if v == self.Entity then table.remove(NS3.Stars,k) end end
	else
		for k,v in pairs(NS3.Planets) do if v == self.Entity then table.remove(NS3.Planets,k) end end
		timer.Remove("NS3_Planet_RefreshWater_"..self:EntIndex())
	end
end
