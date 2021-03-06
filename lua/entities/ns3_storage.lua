AddCSLuaFile()
DEFINE_BASECLASS( "ns3_base_entity" )
ENT.PrintName 	= "NS3 Resource Storage"
ENT.Purpose		= "Stores NS3 Resources"
ENT.WireDebugName="NS3 Storage"

if CLIENT then return end

local function BoolNum(bool) if bool then return 1 else return 0 end end
local round = math.Round

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Entity:NextThink( round(CurTime()) + 2 )

	self.SpecialSound = "thrusters/jet04.wav" // For venting
	self.Priority = 1
	self.Resources = table.Copy(NS3.Resources)
	self.OverlayBase =  "NS3 Unspecified Storage Device"
end

function ENT:Setup()
	if NS3.ResourceMeta[self.Resource].IsVentable then WireLib.CreateInputs(self.Entity, { "Vent" }) end
	WireLib.CreateSpecialOutputs(self.Entity, {"Current", "Max", "Resource"},{"NORMAL","NORMAL","STRING"})
	WireLib.TriggerOutput(self.Entity, "Resource", self.Resource)

	self.Max = round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.46 * NS3.ResourceMeta[self.Resource].Density) * 5
	WireLib.TriggerOutput(self.Entity, "Max", self.Max)
	self.VentingNoise = CreateSound(self.Entity,"thrusters/jet04.wav")
	self.VentingNoise:ChangeVolume(0.8,0.25) self.VentingNoise:ChangePitch(110,0.25) self.VentingNoise:SetSoundLevel(50)

	self.Overlay = "NS3 "..NS3.ResourceMeta[self.Resource].Name.." Storage"
end

function ENT:AcceptInput(name,activator,caller) -- Things like E
	if name == "Use" and caller:IsPlayer() and !caller:KeyDownLast(IN_USE) then
		caller:PrintMessage(3, ":D")
	end
end

function ENT:TriggerInput(iname, value) -- Wiremod Inputs
	if iname == "Vent" then
		self.Venting = (value != 0) and 1
	//elseif iname == "Mute" then self.Mute = value != 0
	end
end
//local floor = math.floor
function ENT:Think()
	self.BaseClass.Think(self)
	self.Entity:NextThink( round(CurTime()) + 0.9  )
	if self.Resource == "" then ErrorNoHalt("HEY! This storage has no resource! Wtf ["..self:EntIndex().."]") self:Remove() return end -- An odd common bug, investigating
	self.OverlayWarning = ""

	self:StoreCollectResources() -- Add our self.Receiving to our self.Resources
	self.Requesting[self.Resource] = self.Max - self.Resources[self.Resource]
	if self.Resources[self.Resource] != 0 then
		local remainingresources = self:SendResources({self.Resource, self.Resources[self.Resource]})
		self.Resources[self.Resource] = remainingresources[2]
	end

	if self.Namage then
		local health = self.Namage.HP / self.Namage.MaxHP

		if health > 0.5 then
			if self.Venting != 1 then self.Venting = nil end // So if it was wired on, this won't turn it off
		elseif health > 0.4 then self.Venting = 0.5 self.OverlayWarning = "Moderate damage sustained"
		elseif health > 0.2 then self.Venting = 1.25 self.OverlayWarning = "Heavy damage sustained" -- IntentionalExploit: Wire can reduce this down to 1x venting
		else self.Venting = 3 self.OverlayWarning = "Severe damage sustained!"
		end
	end
	if self.Venting then
		if !self.VentingNoise:IsPlaying() then self.VentingNoise:Play() end
		local subtracted = math.min(round(self.Max * self.Venting / 20), self.Resources[self.Resource])
		self.Environment.Resources[self.Resource] = self.Environment.Resources[self.Resource] + subtracted
		self.Resources[self.Resource] = self.Resources[self.Resource] - subtracted
	else self.VentingNoise:Stop()
	end

	WireLib.TriggerOutput(self, "Current", self.Resources[self.Resource])
	self.OverlayStatus = round(self.Resources[self.Resource]) .. "/" .. self.Max .. " " .. round(self.Resources[self.Resource] * 100 / self.Max, 1) .. "%"
	self:UpdateOverlayText()
	return true
end
