if(CLIENT)
then
	DevicePopupFontCreated=false
	hook.Add("PostDrawTranslucentRenderables","PaintDeviceOverlay",function()
		local GUIScale=3
		local OverlayWidth=18
		local HoloScale=GUIScale
		local FontSize=72
		local TextScale=GUIScale*1.2/FontSize
		if(!DevicePopupFontCreated)
		then
			surface.CreateFont("DevicePopupFont",{font="Arial",size=FontSize,weight=600,antialias=false})
			DevicePopupFontCreated=true
		end
		if(LocalPlayer():GetActiveWeapon():IsValid() and LocalPlayer():GetActiveWeapon():GetClass()=="gmod_tool") then return end
		local Trace=LocalPlayer():GetEyeTrace()
		local Ent=Trace.Entity
		if(!Ent:IsValid()) then return end
		local DisplayText=Trace.Entity:GetNWString("DeviceOverlayText","Bork")
		if(DisplayText=="Bork") then return end
		if(Trace.HitPos:DistToSqr(LocalPlayer():GetPos())>300^2) then return end
		local Lines=string.Split(DisplayText,"\n")
		local LineCount=#Lines
		local HoloHeight=LineCount*HoloScale
		local HoloWidth=OverlayWidth*HoloScale
		local HoloPos,HoloNorm=Vector(0,0,0),Trace.HitNormal
		if(Ent:BoundingRadius()>OverlayWidth*1.5 and (HoloNorm.x~=0 or HoloNorm.y~=0))
		then
			HoloPos=Trace.HitPos+HoloNorm*5
			--HoloPos.z=HoloPos.z-HoloHeight/2
		else
			HoloPos=Ent:GetPos()+Vector(0,0,(Ent:BoundingRadius()*0.6)+(HoloHeight/2))
			HoloNorm=-LocalPlayer():EyeAngles():Forward()
			HoloNorm.z=0
		end
		render.SuppressEngineLighting(true)
		render.SetMaterial(Material("models/props_lab/generatorconsole_disp"))
		render.DrawQuadEasy(HoloPos,HoloNorm,HoloWidth,HoloHeight,Color(255,0,0),0)
		render.SuppressEngineLighting(false)
		local NormRight=-HoloNorm:Angle():Right()
		local NormUp=HoloNorm:Angle():Up()
		local TextAng=NormRight:Angle()
		TextAng.r=HoloNorm:Angle().p+90
		local UpperX,UpperY=0,0
		cam.Start3D2D(HoloPos+(NormRight*(-HoloWidth/2))+(NormUp*(HoloHeight/2))+HoloNorm*0.1,TextAng,TextScale)
			for i,Line in pairs(Lines)
			do
				draw.SimpleText(Line,"DevicePopupFont",UpperX,UpperY+((i-1.1)*FontSize*0.8),Color(230,230,230),TEXT_ALIGN_LEFT)
			end
		cam.End3D2D()
	end)
end