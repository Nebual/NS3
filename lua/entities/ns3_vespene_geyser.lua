ENT.Type 			= "anim"
ENT.BaseType			= "gmod_baseentity"
ENT.PrintName			= "Vespene Geyser"
ENT.WireDebugName		= "Meepy Poofen Schmirtzer"
ENT.RenderGroup			= RENDERGROUP_BOTH
ENT.Author			= "NEON725"
ENT.Information			= "Poofy"
ENT.Purpose			= "Poofs"
ENT.Category			= "NS3"
ENT.Spawnable			= false
ENT.AdminSpawnable		= true

AddCSLuaFile("ns3_vespene_geyser.lua")
function ENT:Initialize()
	self:NextThink(CurTime())
	self:SetModel("models/props_wasteland/antlionhill.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
end
if(SERVER)
then
	function ENT:Think()
		self:NextThink(round(CurTime())+1)
		local Phys=self:GetPhysicsObject()
	 	Phys:EnableMotion(false)
		return true
	end
else
	function ENT:Draw()
		self:DrawModel()
		local PoofDiameter=48
		local BasePoofHeight=self:OBBMaxs().z*0.8
		local PoofRise=400
		local DriftTime=6
		local DriftTimeMultiplier=(CurTime()%DriftTime)/DriftTime
		local HoloPos=self:LocalToWorld(Vector(0,0,BasePoofHeight+PoofRise*DriftTimeMultiplier))
		local HoloNorm=LocalPlayer():GetShootPos()-HoloPos
		render.SuppressEngineLighting(false)
		render.SetMaterial(Material("sprites/sent_ball"))
		local SinTiming=CurTime()*1.2
		local WobbleAmount=PoofDiameter*0.4
		local SinTime=PoofDiameter+math.sin(SinTiming)*WobbleAmount
		local CosTime=PoofDiameter+math.cos(SinTiming)*WobbleAmount
		render.DrawQuadEasy(HoloPos,HoloNorm,SinTime,CosTime,Color(0,255*(1-DriftTimeMultiplier),0),0)
		render.SuppressEngineLighting(false)
	end
end