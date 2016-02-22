AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName 	= "NS3 Base Entity"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= "Base ent for NS3"
ENT.IsWire = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

util.PrecacheSound( "Airboat_engine_idle" )
util.PrecacheSound( "Airboat_engine_stop" )
util.PrecacheSound( "apc_engine_start" )

if CLIENT then
	net.Receive("NS3_Links", function(netlen)
		local ent = net.ReadEntity()
		if IsValid(ent) then
			ent.Links = net.ReadTable()
		end
	end)
	return
end

local function BoolNum(bool) if bool then return 1 else return 0 end end
local floor = math.floor

function ENT:SpawnFunction(ply,tr)
	local Ent=ents.Create(ENT.Classname)
	Ent:SetPos(tr.HitPos + tr.HitNormal*8)
	Ent:SetAngles(ply:GetAngles())
	Ent:Spawn()
	Ent:Activate()
	return Ent
end

function ENT:Initialize()
	if !self.Entity:GetModel() or self.Entity:GetModel() == "" then self.Entity:SetModel("models/props_c17/oildrum001.mdl") end
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	//self.Entity:GetPhysicsObject():Wake()
	if self.Entity:GetPhysicsObject():GetMass() < 20 then self.Entity:GetPhysicsObject():SetMass(30) end

	-- Incase we don't have environments, like on gm_ maps, give the generator its own 'planet' to harvest from
	self.Environment = {Resources = {Empty = 0}, Max = 4000000, Name = '', Atmosphere = 1, Gravity = 1, Pressure = 1}
	for k,_ in pairs(NS3.Resources) do self.Environment.Resources[k] = 1000000 end

	self.Resource = self.Resource or ""
	self.Requesting = {}
	self.Links = {}
	self.DaisyLinks = {}
	self.Receiving = {}
	self.OverlayBase = "NS3 Unspecified Entity"
	self.IdleSound = "apc_engine_start"
end

function ENT:SetActive( value, caller )
	if tobool(value) then
		self.Active = true
		local col = self:GetColor() // This is just a quick "fix" for being in water. Namage anyone?
		if col.r == 50 && col.g == 50 then self:SetColor(Color(255,255,255,col.a)) end

		if !self.Mute then
			if self.IdleSound then self.Entity:EmitSound( self.IdleSound ) end
			if self.IdleSound2 then self.Entity:EmitSound( self.IdleSound2 ) end
		end
		self.Overlay = self.OverlayBase .. ": On!"
		Wire_TriggerOutput(self.Entity, "On", BoolNum(self.Active))
	else
		self.Active = nil

		if self.IdleSound then self.Entity:StopSound( self.IdleSound ) end
		if self.IdleSound2 then self.Entity:StopSound( self.IdleSound2 ) end

		if !self.Mute then self.Entity:EmitSound( "Airboat_engine_stop" ) end
		self.Overlay = self.OverlayBase .. ": Off!"
		Wire_TriggerOutput(self.Entity, "On", BoolNum(self.Active))
	end
	self:UpdateOverlayText()
end

function ENT:AcceptInput(name,activator,caller) -- Things like E
	if name == "Use" and caller:IsPlayer() and !caller:KeyDownLast(IN_USE) then -- Edge keyE
		self:SetActive( !self.Active, caller )
	end
end

function ENT:TriggerInput(iname, value) -- Wiremod Inputs
	if iname == "On" then self:SetActive(value)
	elseif iname == "Mute" then
		self.Mute = value != 0
		if self.Mute then
			if self.IdleSound then self.Entity:StopSound( self.IdleSound ) end
			if self.IdleSound2 then self.Entity:StopSound( self.IdleSound2 ) end
		else self:SetActive(self.Active)
		end
	end
end

// Todo: Make sure the link tool garbagecollects on EntityRemoved
util.AddNetworkString("NS3_Links")
function ENT:BroadcastLinks()
	timer.Create("NS3_Links"..self:EntIndex(), 0.5, 1, function()
		net.Start("NS3_Links")
			net.WriteEntity(self)
			local tab = table.Copy(self.Links) or {}
			table.Add(tab, self.DaisyLinks)
			net.WriteTable(tab)
		net.Broadcast()
	end)
end
function ENT:Link(ent)
	if !IsValid(ent) or !ent.Priority or ent == self.Entity then return end
	if self.Priority == 1 && ent.Priority == 1 then
		for k,v in ipairs2(self.DaisyLinks) do if !IsValid(v) then table.remove(self.DaisyLinks, k) elseif v == ent then return end end
		table.insert(self.DaisyLinks, ent)
	else
		for k,v in ipairs2(self.Links) do if !IsValid(v) then table.remove(self.Links, k) elseif v == ent then return end end
		table.insert(self.Links, ent)
		table.sort(self.Links, function(a,b) if a.Priority > b.Priority then return b end end)
	end
	self:BroadcastLinks()
end
function ENT:UnLink(ent)
	if !IsValid(ent) then return end
	if self.Priority == ent.Priority then
		for k,v in ipairs(self.DaisyLinks) do if v == ent then table.remove(self.DaisyLinks, k or 1) break end end
	end
	for k,v in ipairs(self.Links) do if v == ent then table.remove(self.Links, k or 1) break end end
	table.sort(self.Links, function(a,b) if a.Priority > b.Priority then return b end end)
	self:BroadcastLinks()
end


function ENT:CollectResources()
	// Ooh what did we get :D
	local fuels = table.Copy(NS3.Resources)
	for k,v in ipairs(self.Receiving) do
		fuels[v[1]] = fuels[v[1]] + v[2]
	end
	self.Receiving = {}
	return fuels
end
function ENT:StoreCollectResources()
	-- Direct deposit into self.Resources
	for k,v in ipairs(self.Receiving) do
		self.Resources[v[1]] = self.Resources[v[1]] + v[2]
	end
	self.Receiving = {}
end
function ENT:SendResources(product)
	-- Ship it out to our linked ents
	local ourResource = product[1]
	local currentAmount = product[2]
	for k,v in ipairs(self.Links) do
		if !v:IsValid() then table.remove(self.Links, k)
		else
			local neededResource, neededAmount, equivalencyRate
			if v.Requesting[ourResource] then
				neededResource = ourResource
				equivalencyRate = 1
				neededAmount = v.Requesting[ourResource]
			else
				for requestedResource, requestedAmount in pairs(v.Requesting) do
					if NS3.ResourceMeta[requestedResource].Equivalent[ourResource] then
						neededResource = requestedResource
						equivalencyRate = NS3.ResourceMeta[requestedResource].Equivalent[ourResource]
						neededAmount = requestedAmount / equivalencyRate
						break
					end
				end
			end
			if neededAmount && (self.Priority != 1 or v.Priority != 1) then
				-- Are they requesting our resource, and are both of us not storage units?
				if neededAmount < currentAmount then
					v.Requesting[neededResource] = nil
					table.insert(v.Receiving, {neededResource, neededAmount * equivalencyRate})
					currentAmount = currentAmount - neededAmount
				else
					v.Requesting[neededResource] = neededAmount - currentAmount
					table.insert(v.Receiving, {neededResource, currentAmount * equivalencyRate})
					currentAmount = 0
					break
				end
			end
		end
	end
	product[2] = currentAmount
	return product
end


function ENT:OnTakeDamage(DmgInfo)
	/*if self.Shield then //should make the damage go to the shield if the shield is installed(CDS)
		self.Shield:ShieldDamage(DmgInfo:GetDamage())
		CDS_ShieldImpact(self.Entity:GetPos())
		return
	end*/
end

function ENT:LowResource(msg)
	self.OverlayWarning = "Insufficient "..msg.."!"
	self.LastWarned = (self.LastWarned or 0) + 1
	if self.LastWarned == 1 then self.Entity:EmitSound("common/warning.wav") end
	if self.LastWarned > 5 then self.LastWarned = 0 end
end

function ENT:UpdateOverlayText()
	//local state = ": Off!" if self.Active then state = ": On!" end
	local text = self.Overlay or self.OverlayBase or ""//..state
	if self.OverlayWarning then text = text .. "\n"..self.OverlayWarning end
	if self.OverlayStatus then text = text .. "\n"..self.OverlayStatus end
	self:SetOverlayText(text)
end

function ENT:OnRemove()
	if self.IdleSound then self.Entity:StopSound( self.IdleSound ) end
	if self.IdleSound2 then self.Entity:StopSound( self.IdleSound2 ) end
	if self.SoundSpecial && self.SoundSpecial:IsPlaying() then self.SoundSpecial:Stop() end
	if self.VentingSound && self.VentingSound:IsPlaying() then self.VentingSound:Stop() end
	if self.Active && !self.Mute then self.Entity:EmitSound( "Airboat_engine_stop" ) end
	if self.Links then
		for _,v in ipairs(self.Links) do
			if !IsValid(v) then continue end
			v:UnLink(self)
			table.sort(v.Links, function(a,b) if a.Priority > b.Priority then return b end end)
		end
	end
	WireLib.Remove(self)
end

function ENT:PreEntityCopy()
	local DupeInfo = WireLib.BuildDupeInfo(self.Entity)
	if DupeInfo then
		duplicator.StoreEntityModifier( self, "WireDupeInfo", DupeInfo )
	end
	local tab = {Links={},DaisyLinks={}}
	for k,v in pairs(self.Links) do tab.Links[k] = v:EntIndex() end
	for k,v in pairs(self.DaisyLinks) do tab.DaisyLinks[k] = v:EntIndex() end
	duplicator.StoreEntityModifier(self,"NS3Info",tab)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	if !Ent.EntityMods then return end
	if Ent.EntityMods.WireDupeInfo then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
	local tab = Ent.EntityMods.NS3Info
	if tab then
		Ent.Links = {}
		Ent.DaisyLinks = {}
		for k,v in pairs(tab.Links) do
			local otherent = CreatedEntities[v]
			table.insert(Ent.Links, otherent)
			if !otherent.Priority and NS3.HijackEnts[otherent:GetClass()] then NS3.HijackEnts[otherent:GetClass()](otherent) end // Sets up chairs and such
		end
		table.sort(Ent.Links, function(a,b) if a.Priority > b.Priority then return b end end)
		for k,v in pairs(tab.DaisyLinks) do table.insert(Ent.DaisyLinks,CreatedEntities[v]) end

		self:BroadcastLinks()
	//	self.Resource = tab.Resource
	//	if tab.Style then self.Style = tab.Style end
	end
end
