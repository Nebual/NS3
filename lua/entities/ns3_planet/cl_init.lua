ENT.Type 		= "anim"
ENT.Base 		= "base_anim"
ENT.PrintName 	= "NS3 Planetoid"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= "Planetoid for NS3"
ENT.Instructions	= ""

ENT.Spawnable		= false
ENT.AdminOnly		= false

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local mDisc = ClientsideModel( 'models/props_phx/construct/metal_angle360.mdl', RENDERGROUP_OPAQUE )
mDisc:SetNoDraw( true ) mDisc:DrawShadow( false )
local mSphereDual = ClientsideModel( 'models/hunter/misc/shell2x2.mdl', RENDERGROUP_TRANSLUCENT )
mSphereDual:SetNoDraw( true ) mSphereDual:DrawShadow( false )
local mSphere = ClientsideModel( 'models/props_phx/ball.mdl', RENDERGROUP_TRANSLUCENT )
mSphere:SetNoDraw( true ) mSphere:DrawShadow( false )

// This will only be enabled if the planet requires luadrawing (wasn't built in hammer)
local function DrawPlanet(self)
	mDisc:SetMaterial(self.mDiscMat)
	mDisc:SetRenderOrigin(self:GetPos())
	mDisc:SetModelScale(self.mDiscScale)
	mDisc:DrawModel()
	self.mSphereDualYaw= self.mSphereDualYaw + self.rotationSpeed
	mSphere:SetMaterial(self.mSphereMat)
	mSphere:SetRenderOrigin(self.mSpherePos)
	mSphere:SetRenderAngles(Angle(0,self.mSphereDualYaw,0))
	mSphere:SetModelScale(self.mSphereScale)
	mSphere:DrawModel()
	render.SetBlend(self.mSphere2Alpha)
	mSphere:SetMaterial(self.mSphere2Mat)
	mSphere:SetRenderOrigin(self.mSpherePos)
	mSphere:SetRenderAngles(Angle(0,self.mSphereDualYaw*2,0))
	mSphere:SetModelScale(self.mSphere2Scale)
	mSphere:DrawModel()
	render.SetBlend(self.mSphereDualAlpha)
	mSphereDual:SetMaterial(self.mSphereDualMat)
	mSphereDual:SetRenderOrigin(self:GetPos())
	//self.mSphereDualYaw= self.mSphereDualYaw + 0.05
	mSphereDual:SetRenderAngles(Angle(0,self.mSphereDualYaw,0))
	mSphereDual:SetModelScale(self.mSphereDualScale)
	mSphereDual:DrawModel()
	render.SetBlend(1)
end
local function DrawGasGiant(self) // This is just DrawPlanet without the disc or clouds
	self.mSphereDualYaw= self.mSphereDualYaw + self.rotationSpeed
	mSphere:SetMaterial(self.mSphereMat)
	mSphere:SetRenderOrigin(self.mSpherePos)
	mSphere:SetRenderAngles(Angle(0,self.mSphereDualYaw,0))
	mSphere:SetModelScale(self.mSphereScale)
	mSphere:DrawModel()
	render.SetBlend(self.mSphereDualAlpha)
	mSphereDual:SetMaterial(self.mSphereDualMat)
	mSphereDual:SetRenderOrigin(self:GetPos())
	mSphereDual:SetRenderAngles(Angle(0,self.mSphereDualYaw,0))
	mSphereDual:SetModelScale(self.mSphereDualScale)
	mSphereDual:DrawModel()
	render.SetBlend(1)
end

net.Receive("ns3_setplanet",function( netlen )
	local entid = net.ReadUInt(16)
	local ent = Entity(entid)
	local radius = net.ReadUInt(16)
	Msg(entid)
	print ("received ns3_setplanet"..tostring(ent))
	local tmp = net.ReadString() if tmp != "" then ent.mDiscMat = tmp else ent.mDiscMat = "" end
	local tmp = net.ReadString() if tmp != "" then ent.mSphereMat = tmp else ent.mSphereMat = "models/effects/splode_sheet" end
	local tmp = net.ReadString() if tmp != "" then ent.mSphere2Mat = tmp else ent.mSphere2Mat = "models/props/de_tides/clouds" end
	local tmp = net.ReadString() if tmp != "" then ent.mSphereDualMat = tmp else ent.mSphereDualMat = "spacebuild/Hazard2" end
	local tmp = net.ReadFloat() if tmp != 0 then ent.mSphere2Alpha = tmp else ent.mSphere2Alpha = 0.6 end
	local tmp = net.ReadFloat() if tmp != 0 then ent.mSphereDualAlpha = tmp else ent.mSphereDualAlpha = 0.4 end
	local tmp = net.ReadFloat() if tmp != 0 then ent.rotationSpeed = tmp else ent.rotationSpeed = 0.025 end

	
	if (radius != 0 && radius != ent.Radius) then
		ent.Radius = radius
		ent:SetModelScale( vector_origin )
		ent:SetRenderBounds( Vector(2000,2000,2000), Vector(-2000,-2000,-2000) ) -- <-- In gmod12, anything larger than this often didn't work, but it DOES need to be larger...
		timer.Create("NCPhys_"..ent:EntIndex(),0.8,1,function() 
			-- Hence this weird workaround existed... might be better in 13!
			ent:SetRenderBounds( Vector(ent.Radius,ent.Radius,ent.Radius), Vector(-ent.Radius,-ent.Radius,-ent.Radius) )
			ent:SetRenderBounds( Vector(ent.Radius,ent.Radius,ent.Radius), Vector(-ent.Radius,-ent.Radius,-ent.Radius) )
		end)
		ent.mSpherePos = ent:GetPos()-Vector(0,0,ent.Radius)
		ent.mSphereDualYaw = 0
		ent.mDiscScale = Vector(2*ent.Radius/95.3,2*ent.Radius/95.3,1)
		ent.mSphereDualScale = Vector(2*ent.Radius/95.3,2*ent.Radius/95.3,2*ent.Radius/97)
		ent.mSphereScale = Vector(2*ent.Radius/42.5,2*ent.Radius/42.5,2*ent.Radius/42.5)
		ent.mSphere2Scale = Vector(2*ent.Radius/42,2*ent.Radius/42,2*ent.Radius/42)
		if ent:BoundingRadius() < 50 then
			ent.RenderOverride = DrawGasGiant
			ent.Draw = DrawGasGiant
		else
			ent.RenderOverride = DrawPlanet
			ent.Draw = DrawPlanet
		end
	end
end)
