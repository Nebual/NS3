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

ENT.Lists = {
	Setup = {},
	SubThink = {},
	Regulate = {},
}

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
	self.SubThink = self.Lists.SubThink[kind] or NS3.NullFunction

	if self.Lists.Setup[kind] then
		self.Lists.Setup[kind](self)
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

for _, filename in pairs(file.Find('entities/utilities/*.lua', 'LUA')) do
	DEVICE = {}
	include('entities/utilities/' .. filename)
	local kind = string.StripExtension(filename)
	if DEVICE.Setup    then ENT.Lists.Setup[kind]    = DEVICE.Setup end
	if DEVICE.SubThink then ENT.Lists.SubThink[kind] = DEVICE.SubThink end
	if DEVICE.Regulate then ENT.Lists.Regulate[kind] = DEVICE.Regulate end
end

function ENT:FindFootBreathEnts(timerid)
	if !IsValid(self) then timer.Remove(timerid) return end
	for k,v in pairs(self.FootBreaths) do v[self.Resource] = nil end
	self.FootBreaths = {}
	for k,v in pairs(ents.FindInSphere(self:GetPos(),self.Range)) do if NS3.EntIsSane(v) then self.FootBreaths[v:EntIndex()] = v end end

	local constraintstab
	if self:GetParent():IsValid() then constraintstab = constraint.GetAllConstrainedEntities(self:GetParent())
	else constraintstab = constraint.GetAllConstrainedEntities(self.Entity)
	end
	for k,v in pairs(constraintstab) do if self.FootBreaths[v:EntIndex()] then v[self.Resource] = self.Entity end end
end
