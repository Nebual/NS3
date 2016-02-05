local pairs, ipairs, ipairs2 = pairs, ipairs, ipairs2
local print, pcall, ErrorNoHalt = print, pcall, ErrorNoHalt
local IsValid = IsValid

concommand.Add("ns3_reload", function(ply,cmd,args)
	NADMOD.Message("Reloading NS3, this may sting for a second or two...")
	local args = table.concat(args, " ")
	if string.find(args,"full") then NS3 = nil end
	include("autorun/sh_ns3.lua")
	include("sv_ns3.lua")

	for k,v in pairs(player.GetAll()) do v.Suit.Last = "" end
	local noclientside = string.find(args,"nocli")
	if !noclientside then
		net.Start("cltoast")
			local sh_ns3 = file.Read("autorun/sh_ns3.lua","LUA")
			if !NS3 then sh_ns3 = "NS3 = nil\n"..sh_ns3 end
			net.WriteString(sh_ns3)
		net.Broadcast()
		net.Start("cltoast")
			net.WriteString(file.Read("cl_ns3.lua","LUA"))
		net.Broadcast()
	end
	if string.find(args,"small") then return end
	ReloadEnt("ns3_base_entity",noclientside)
	ReloadEnt("ns3_generator",noclientside)
	ReloadEnt("ns3_storage",noclientside)
	ReloadEnt("ns3_utility",noclientside)
	ReloadEnt("ns3_planet",noclientside)

	// Realtime reloading of existing entities! Muwahahahahahaaha
	local base = scripted_ents.Get("ns3_base_entity")
	for _,class in pairs({"ns3_generator","ns3_storage","ns3_utility"}) do
		local base2 = scripted_ents.Get(class)
		for _,ent in pairs(ents.FindByClass(class)) do
			for k,v in pairs(base) do if isfunction(v) then ent[k] = v end end // But only their functions, vars can stay
			for k,v in pairs(base2) do if isfunction(v) then ent[k] = v end end
			ent.Lists = base2.Lists
			ent:Setup()
		end
	end
	local base2 = scripted_ents.Get("ns3_planet")
	for _,ent in pairs(ents.FindByClass("ns3_planet")) do for k,v in pairs(base2) do if isfunction(v) then ent[k] = v end end end
end) -- For development mostly

function NS3.TrackNS3Ent(ent)
	if IsValid(ent) and ent:EntIndex() > 20 then
		timer.Create("TrackNS3Ent_"..ent:EntIndex(), 0.15, 1, function()
			if !IsValid(ent) or ent:EntIndex() == 0 or !IsValid(ent:GetPhysicsObject()) or ent:IsNPC() or ent:IsPlayer() or !ent:GetModel() or ent.CDSIgnore or ent:GetClass() == "gmod_ghost" or string.sub(ent:GetClass(), 1, 4) == "func" then
				table.insert(NS3.TrackedEnts, ent) 
			end
		end)
	end
end

function NS3.InitNS3()
	-- Stuff that should be done once, after server is loaded
	NS3.LoadEnvironments()
	if next(NS3.Planets) then -- Only do this if the map is a SB map with planets
		NS3.HasPlanets = true
		NS3.Environments = table.Copy(NS3.Planets)
		for k,v in pairs(NS3.Stars) do table.insert(NS3.Environments, v) end
		timer.Create("NS3_EnvironmentCheck", 1, 0, NS3.EnvironmentCheck)
		hook.Add("OnEntityCreated", "TrackNS3Ent", NS3.TrackNS3Ent)
		//hook.Add("Think","NS3_SpaceSlow",NS3.SpaceSlow) // Tries to slow all players/ents in space down about 5x (maxspeed 50km/h)
	else
		timer.Create("NS3_EnvironmentCheck", 1, 0, function()
			for k, ply in pairs(player.GetAll()) do
				local success,msg = pcall(NS3.EnvironmentCheckOnPlayer,ply)
				if !success then ErrorNoHalt("NS3_SimpleEnvCheck Error: Ply["..ply:EntIndex().."] "..msg) end
			end 
		end)
	end
end
hook.Add("InitPostEntity", "InitNS3", NS3.InitNS3)


local DamageExempt = {gmod_wire_ex=1,ns3_planet=1}
local suitmax = GetConVarNumber("ns3_suitmax")
local ns3_spacedamage = GetConVar("ns3_spacedamage")
function NS3.EnvironmentCheck() -- On a timer defined in InitPostEntity hook
	for k, ent in ipairs2(NS3.TrackedEnts) do
		if ent:IsValid() then
			ent.Environment = nil
			for k, v in pairs(NS3.Environments) do
				v:OnEnvironment(ent)
			end
			if !ent.Environment then
				ent.Environment = NS3.Space
				if ns3_spacedamage:GetBool() && ent.Namage && !DamageExempt[string.Left(ent:GetClass(),12)] then
					local time = math.random(45,100)
					if IsValid(ent.Heat_Regulator) then time = time * 4
					elseif ent.IsWire then time = time * 3
					end
					local dmg = ent.Namage.MaxHP / time
					if ent.Namage.MaxHP < time then ent:TakeDamage(ent.Namage.MaxHP / time)  else ent:TakeDamage((ent.Namage.MaxHP / time)^0.5) end
				end
			end
			NS3.UpdateGravity(ent)
			//if ent.Environment.Pressure > 1.5 then ent:TakeDamage((ent.Environment.Pressure - 1.5) * 10) end // Do we want this?
		else
			table.remove(NS3.TrackedEnts, k)
		end
	end
	suitmax = GetConVarNumber("ns3_suitmax")
	for k, ply in pairs(player.GetAll()) do
		local success,msg = pcall(NS3.EnvironmentCheckOnPlayer,ply)
		if !success then ErrorNoHalt("NS3_EnvCheck Error: Ply["..ply:EntIndex().."] "..msg) end
	end
end

local ns3_spacenoclip 	= GetConVar("ns3_spacenoclip")
local ns3_god 			= GetConVar("ns3_god")
function NS3.EnvironmentCheckOnPlayer(ply)
	if !ply:IsValid() or !ply:Alive() then return end
	local pos = ply:GetPos()
	local footent

	local pod = ply:GetVehicle()
	if pod:IsValid() then
		footent = pod
		if !pod.Resources then pod = nil end // Disregard vehicle if its not NS3 compatible
	else
		pod = nil
		footent = util.TraceLine({start = pos, endpos = pos - Vector(0,0,512), filter = ply}).Entity
	end
	ply.Suit.HasAir = false
	if NS3.HasPlanets then
		local DSP = 1
		if pod then
			ply.Environment = pod.Environment
		else
			ply.Environment = nil
			for k, v in pairs(NS3.Environments) do
				v:OnEnvironment(ply) -- refresh this player's environment (see if it changed)
			end
			if !ply.Environment then
				ply.Environment = NS3.Space -- No environment claimed them? Assume space
				if !ply:InVehicle() && !ns3_spacenoclip:GetBool() && ply:GetMoveType() == MOVETYPE_NOCLIP then
					ply:SetMoveType(MOVETYPE_WALK)
				end
				if not ns3_god:GetBool() then ply:GodDisable() end
				DSP = 24 // Space is echoy
			end
		end
		if ply.Environment:GetTemperature(ply) > 5000 then ply:SilentKill() return end // Pretty sure this is for stars
		NS3.UpdateGravity(ply)
		
		-- =======================
		-- Temperatures
		-- =======================
		local EnviroTemp = ply.Environment:GetTemperature(ply)
		local Diff=(EnviroTemp-ply.Suit.Temperature)*(math.Max(ply.Environment.Pressure,0.14)* (ply.Suit.VisorDown and 1.5 or 3))
		if Diff < -1 then Diff = -((-Diff)^0.5) elseif Diff > 1 then Diff = Diff ^ 0.5 end
		//if ply:Nick() == "Nebual" then Msg("SuitTemp: "..ply.Suit.Temperature.." EnvTemp: "..EnviroTemp.." Diff: "..Diff) end
		ply.Suit.Temperature = math.Round(ply.Suit.Temperature + Diff)
		local heatreg = footent.Heat_Regulator
		if IsValid(heatreg) and heatreg.Active then
			ply.Suit.Temperature = footent.Heat_Regulator:Regulate(ply)
		end
		if pod and ply.Suit.Temperature != 295 then ply.Suit.Temperature = pod:RegulateTemp(ply) end
		if ply.Suit.Temperature < 280 or ply.Suit.Temperature > 310 then
			local difftemp = 295-ply.Suit.Temperature
			if difftemp > 0 then
				difftemp = math.Min(ply.Suit.Energy,difftemp)
				ply.Suit.Energy = ply.Suit.Energy - difftemp
				ply.Suit.Temperature = ply.Suit.Temperature+difftemp
			else
				difftemp = math.Min(ply.Suit.Coolant,-difftemp)
				ply.Suit.Coolant = ply.Suit.Coolant - difftemp
				ply.Suit.Temperature = ply.Suit.Temperature - difftemp
			end
		end
		local difftemp=295-ply.Suit.Temperature
		if (ply.Suit.Temperature < 255 or ply.Suit.Temperature>335) then
			-- The "Painful zone"
			ply:TakeDamage(math.Min(math.abs(difftemp)/20,10), 0)
			print(ply:Nick()..difftemp)
			if ply:Health() <= 0 then
				ply:StopSound( "NPC_Stalker.BurnFlesh" ) 
				ply:EmitSound( "NPC_Stalker.BurnFlesh" )
				ply:SetModel("models/player/charple01.mdl")
				timer.Create("StopBurningNoise_"..ply:EntIndex(),3,1, function() if IsValid(ply) then ply:StopSound( "NPC_Stalker.BurnFlesh" ) end end)
				return -- They're dead, Jim
			elseif math.random(1,2) == 2 then -- Just to avoid spamming the sound
				if ply.Suit.Temperature < 255 then ply:EmitSound( "vehicles/v8/skid_lowfriction.wav" ) 
				else 
					ply:StopSound( "NPC_Stalker.BurnFlesh" ) 
					ply:EmitSound( "NPC_Stalker.BurnFlesh" )
					timer.Create("StopBurningNoise_"..ply:EntIndex(),3,1, function() if IsValid(ply) then ply:StopSound( "NPC_Stalker.BurnFlesh" ) end end)
				end
			end
		elseif (ply.Suit.Temperature<280 or ply.Suit.Temperature>310) then
			-- The "Uncomfortable zone"
			if math.random(1,5)==5 then ply:TakeDamage(math.random(1,4)) end
			//if ply.Suit.Temperature<280 then
				--ply:slowDown(0.5)
				--Icy Hud Effect I PUT THIS CLIENTSIDE
			//else
				--ply:induceWaver()
				--Reddish Tint Hud Effect
			//end
		end
		
		-- =======================
		-- Breathin
		-- =======================
		if !ply.Environment.IsSpace and (ply.Environment.Resources.Oxygen / ply.Environment.Max) >0.10 and ply:WaterLevel()<3 then 
			local cost = math.Max(5 * ply.Environment.Pressure, 5)
			if ply.Suit.Oxygen < 30 or (!ply.Suit.VisorDown and ply.Suit.Oxygen < ((ply.Environment.Resources.Oxygen / ply.Environment.Max)*suitmax)) then ply.Suit.Oxygen = ply.Suit.Oxygen + 5 cost = cost + 5 end
			ply.Environment.Resources.Oxygen = ply.Environment.Resources.Oxygen - cost
			ply.Environment.Resources.CarbonDioxide = ply.Environment.Resources.CarbonDioxide + cost
			ply.Suit.HasAir=true
		else 
			local airreg = footent.Air_Regulator
			if IsValid(airreg) and airreg.Active then 
				ply.Suit.HasAir = airreg:Regulate(ply) 
				if ply.Suit.HasAir and (ply.Suit.Oxygen < 30 or (!ply.Suit.VisorDown and ply.Suit.Oxygen < ((ply.Environment.Resources.Oxygen / ply.Environment.Max)*suitmax))) and airreg:Regulate(ply) then ply.Suit.Oxygen = ply.Suit.Oxygen + 5 end
			end
		end
		if pod and !ply.Suit.HasAir then ply.Suit.HasAir = pod:RegulateAir(ply) end
		if !ply.Suit.HasAir && ply.Suit.VisorDown then
			local cost = math.Max(5 * ply.Environment.Pressure, 5)
			ply.Suit.HasAir = ply.Suit.Oxygen > 0
			ply.Environment.Resources.CarbonDioxide = ply.Environment.Resources.CarbonDioxide + cost
			ply.Suit.Oxygen=math.Max(ply.Suit.Oxygen-cost, 0)
		end
		
		ply:SetDSP(DSP) // Sound effects, like echoy space I KNOW THERES NO SOUND IN SPACE STFU
	else
		ply.Suit.HasAir=true
		if ply:WaterLevel() > 2 then
			ply.Suit.HasAir=false
			local airreg = footent.Air_Regulator
			if IsValid(airreg) and airreg.Active then ply.Suit.HasAir = airreg:Regulate(ply) end
			if !ply.Suit.HasAir then
				if ply.Suit.Oxygen > 0 then
					ply.Suit.Oxygen = math.Max(ply.Suit.Oxygen - 5, 0) 
					ply.Suit.HasAir = true
				end
			end
		elseif ply.Suit.Oxygen < 60 then ply.Suit.Oxygen = math.Min(ply.Suit.Oxygen + 5, 60) end
	end
	if !ply.Suit.HasAir then 
		ply:TakeDamage( 10, 0 )
		if ply:Health() <= 0 then ply:EmitSound("player/drown"..math.random(1,3)..".wav")
		else ply:EmitSound( "player/pl_drown"..math.random(1,3)..".wav" ) // "Player.DrownStart" end	
		end
	end
	
	if !ply.Suit.VisorDown and ply:WaterLevel() > 1 and ply.Suit.Coolant < 90 then
		ply.Suit.Coolant = ply.Suit.Coolant + 5
		if !ply.Suit.watersound then -- Only play the sound once (it loops), since we keep resetting the timer it'll continuously play until they get out of the water or are full
			ply.Suit.watersound = CreateSound(ply, "ambient/water/water_run1.wav" )
			
			ply.Suit.watersound:Play()
			ply.Suit.watersound:ChangeVolume(0.3,0.25)
		end
		timer.Create("FadeWaterSound_"..ply:Nick(),1.1,1,function() ply.Suit.watersound:FadeOut(0.5) ply.Suit.watersound = nil end)
	end
	
	NS3.UpdateLSClient(ply)
end

local floor = math.floor
function NS3.UpdateLSClient(ply)
	if NS3.HasPlanets then
		ply.Suit.Oxygen = math.Max(ply.Suit.Oxygen,0) ply.Suit.Coolant = math.Max(ply.Suit.Coolant,0) ply.Suit.Energy = math.Max(ply.Suit.Energy,0)
		local envtemp = math.Round(ply.Environment:GetTemperature(ply))
		local this = ply.Suit.Oxygen .. ply.Suit.Coolant .. ply.Suit.Energy .. ply.Suit.Temperature .. envtemp .. ply.Environment.Name
		if ply.Suit.Last == this then return end
		ply.Suit.Last = this
		umsg.Start("LS_umsg1", ply)
			umsg.String( ply.Environment.Name )
			umsg.Short( ply.Suit.Temperature or -1)
			umsg.Short( envtemp or -1 )
			umsg.Short( floor(ply.Suit.Oxygen) or -1 )
			umsg.Short( floor(ply.Suit.Coolant) or -1)
			umsg.Short( floor(ply.Suit.Energy) or -1)
		umsg.End()
	else
		if ply.Suit.Last == ply.Suit.Oxygen then return end
		ply.Suit.Last = ply.Suit.Oxygen
		umsg.Start("LS_umsg2", ply)
			umsg.Short( floor(ply.Suit.Oxygen) or -1 )
		umsg.End()
	end
end

function NS3.ResetSuit(ply)
	local val = GetConVarNumber("ns3_suit")
	local temp = ply.Suit or {}
	temp.Oxygen = val
	temp.Coolant = val
	temp.Energy = val
	temp.Recover = 0
	temp.Temperature = 288
	temp.EnvTemperature = 288
	temp.VisorDown = true
	ply.Suit = temp
end
hook.Add("PlayerSpawn", "NS3_ResetSuits", function(ply) if IsValid(ply) then NS3.ResetSuit(ply) end end)

concommand.Add("ns3_visor",function(ply,cmd,args)
	if IsValid(ply) then ply.Suit.VisorDown = tobool(args[1]) end
end)


function NS3.SunTrace(ent, highquality)
	if !IsValid(ent) then return end
	local pos1, radius = ent:LocalToWorld(ent:OBBCenter()), ent:BoundingRadius()
	local traces = {}
	if next(NS3.Stars) then
		for k,v in pairs(NS3.Stars) do
			local pos2 = v.Pos
			local trace = util.TraceLine({start = pos2, endpos = pos1 - (pos2-pos1)*radius, filter = nil})
			if trace.Hit && trace.Entity == ent then
				table.insert(traces, trace)
			end
		end
	else
		local pos2 = pos1 + Vector(0,0,2000)
		local trace = util.TraceLine({start = pos2, endpos = pos1 - (pos2-pos1)*radius, filter = nil})
		if trace.Hit && trace.Entity == ent then
			table.insert(traces, trace)
		end
	end
	if traces[1] then return traces else return false end
end

function NS3.UpdateGravity(ent)
	if !ent:IsValid() or ent.IgnoreGravity then return end
	local phys = ent:GetPhysicsObject()
	if !IsValid(phys) then return end
	local pos = ent:GetPos()
	local grav = ent.Environment.Gravity or 1
	if grav != 1 && util.TraceLine({start = pos, endpos = pos - Vector(0,0,512), filter = ent}).Entity.GravPlate then grav = 1 end
	if grav > 0 then
		if ent:IsPlayer() or ent:IsNPC() then
			if ent:GetMoveType() != MOVETYPE_NOCLIP then
				ent:SetMoveType(ent:IsNPC() and MOVETYPE_STEP or MOVETYPE_WALK) -- NPCs have diff normal movetypes
			end
			ent:SetMoveCollide(MOVECOLLIDE_DEFAULT)
		else
			phys:EnableGravity( true )
			phys:EnableDrag( true )
		end
	else
		if ent:IsPlayer() or ent:IsNPC() then
			ent:SetMoveType(MOVETYPE_FLY)
			ent:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE)
		else
			phys:EnableGravity( false )
			phys:EnableDrag( false )
		end
		if ent.Environment.IsSpace then NS3.Space.ObjectsIn[ent:EntIndex()] = ent end
	end
	ent:SetGravity(grav)
end
function NS3.SpaceSlow()
	for k,v in pairs(NS3.Space.ObjectsIn) do
		if !IsValid(v) or !IsValid(v:GetPhysicsObject()) then NS3.Space.ObjectsIn[k] = nil
		elseif !v.Environment.IsSpace then v.LastVelocity = nil NS3.Space.ObjectsIn[k] = nil
		else
			local vel = v:GetPhysicsObject():GetVelocity()
			local vellen = vel:Length() // 875 == 60km/h    DESIREDKM * 1/(3600 * 0.0000254 * 0.75)
			if vellen > 583 then
				v:GetPhysicsObject():SetVelocity(((v.LastVelocity or Vector(0,0,0)) + (vel - (v.LastVelocity or Vector(0,0,0))) * 0.2):GetNormal()*583)
			end
			v.LastVelocity = vel

		end
	end
	for k,v in pairs(player.GetAll()) do
		if v.Environment && v.Environment.IsSpace then
			if v:GetVelocity():Length() > 875 then v:SetVelocity(v:GetVelocity():GetNormal() * 875) end
		end
	end
end

timer.Create("CallInitNS3",0.1,1,function() hook.Call("InitNS3") end)
print("[NebSupport3 - Nebcorp's Life Support and Resources Mod Loaded]")
