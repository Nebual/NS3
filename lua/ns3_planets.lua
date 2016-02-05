local DEBUG = false -- Will print out planet information as outlined in the bsp

-- Helper function for dealing with 'flags' of old planet things
local function Extract_Bit(bit, field)
	if not bit or not field then return false end
	if ((field <= 7) and (bit <= 4)) then
		if (field >= 4) then
			field = field - 4
			if (bit == 4) then return true end
		end
		if (field >= 2) then
			field = field - 2
			if (bit == 2) then return true end
		end
		if (field >= 1) then
			field = field - 1
			if (bit == 1) then return true end
		end
	end
	return false
end
local num = tonumber
function NS3.LoadEnvironments()
	print("Registering planets")

	for k,v in pairs(NS3.Planets) do v:Remove() end
	NS3.Planets = {}
	for k,v in pairs(NS3.Stars) do v:Remove() end
	NS3.Stars = {}

	//Load the planets/stars/bloom/color
	for _, ent in pairs( ents.FindByClass( "logic_case" ) ) do
		local v = ent:GetKeyValues()
		local style = v.Case01
		if style == "" or style == "1" or style == "01" then continue end
		if DEBUG then print("Loading planet of style ["..style.."]") PrintTable(v) end
		if style == "planet" then
			local radius,gravity,atmosphere,shadetemp,littemp,flags = num(v.Case02),num(v.Case03),num(v.Case04),num(v.Case05),num(v.Case06),num(v.Case16)
			local planet = ents.Create( "ns3_planet" ) 
			planet:SetAngles(ent:GetAngles()) planet:SetPos(ent:GetPos()) planet.Pos = ent:GetPos() planet:Spawn()
			// planet:SetParent(ent)
			table.insert(NS3.Planets, planet)
			local o2,co2,n,h,unstable,sunburn
			if isnumber(flags) then
				if Extract_Bit(1, flags) then o2=21 co2=0.45 n=78 h=0.55 else o2=0.05 co2=96.35 n=3.5 h=0.1 end
				unstable = Extract_Bit(2, flags)
				sunburn = Extract_Bit(3, flags)
			end
			
			local name = "Planet " .. tostring(#NS3.Planets + 1) -- Most 'planet' styles don't have a name
			if v.Case07 and string.sub(v.Case07,1,6) == "color_" then name = string.upper(string.sub(v.Case07,7,7))..string.sub(v.Case07,8) end -- Some 'planet's reference a planet_color logic_case like 'color_kobol'

			planet:CreateEnvironment(radius, gravity, atmosphere, atmosphere, shadetemp, littemp, o2, co2, n, h, unstable, sunburn, name)
		elseif style == "planet2" or style == "cube" then
			local radius,gravity,atmosphere,pressure,shadetemp,littemp,flags,o2,co2,n,h,name = num(v.Case02),num(v.Case03),num(v.Case04),num(v.Case05),num(v.Case06),num(v.Case07),num(v.Case08),num(v.Case09),num(v.Case10),num(v.Case11),num(v.Case12),tostring(v.Case13)

			local planet = ents.Create( "ns3_planet" ) 
			planet:SetAngles(ent:GetAngles()) planet:SetPos( ent:GetPos() ) planet.Pos = ent:GetPos() planet:Spawn() 
			//planet:SetParent(ent)
			table.insert(NS3.Planets, planet)
			local unstable,sunburn
			if isnumber(flags) then
				unstable = Extract_Bit(1, flags)
				sunburn = Extract_Bit(2, flags)
			end

			if style == "cube" then
				if name == "" then name = "Cubic Environment "..tostring(#NS3.Planets + 1) end
				planet.IsCube = true
				ErrorNoHalt("Hey a cube environment! We don't really support these great yet since theres so few "..name)
				local xyz = string.Explode(" ",v.Case02)
				planet.BoxSize = Vector(num(xyz[1]),num(xyz[2]),num(xyz[3]))
				radius = (((num(xyz[1])^2 + num(xyz[2])^2) ^ 0.5) ^ 2 + num(xyz[3]) ^ 2) ^ 0.5
			end

			if name == "" then name = "Planet " .. tostring(#NS3.Planets + 1) end
			planet:CreateEnvironment(radius, gravity, atmosphere, pressure, shadetemp, littemp, o2, co2, n, h, unstable, sunburn, name)
		elseif style == "star" then
			local star = ents.Create( "ns3_planet" ) 
			star:SetAngles( ent:GetAngles() ) star:SetPos( ent:GetPos() ) star.Pos = ent:GetPos() star:Spawn() 
			//star:SetParent(ent)
			table.insert(NS3.Stars, star) star.IsStar = true
			star.Temperature2 = 700
			star.Temperature3 = 400
			star.Temperature4 = 320
			star.Temperature5 = 285
			star:CreateEnvironment(num(v.Case02)/4, 0, 0, 100, 100000, nil, 0, 0, 0, 100, true, true, "Star "..tostring(#NS3.Stars + 1))
		elseif style == "star2" then
			local star = ents.Create( "ns3_planet" ) 
			star:SetAngles( ent:GetAngles() ) star:SetPos( ent:GetPos() ) star.Pos = ent:GetPos() star:Spawn() 
			//star:SetParent(ent)
			table.insert(NS3.Stars, star) star.IsStar = true
			local temp1,temp2,temp3 = num(v.Case03),num(v.Case04),num(v.Case05)
			star.Temperature2 = temp2
			star.Temperature3 = temp3 // TODO: FIX ALL THIS, THE SIZES ARE HORRIBLE
			star.Temperature4 = temp3 / 2 // for star1, on gm_solarsystem_v3, the sun is so massive (using radius*2) it expands beyond earth, and the whole place cooks you
			star.Temperature5 = temp3 / 4
			star:CreateEnvironment(num(v.Case02), 0, 0, 100, temp1, nil, 0, 0, 0, 100, true, true, "Star "..tostring(#NS3.Stars + 1))
		else
			ErrorNoHalt("NS3: Skipping unhandled environment type '"..style.."'...\n")
		end
	end
	
	NS3.PlanetaryOverrides = util.JSONToTable(file.Read("nebcorp/ns3_overrides.txt") or "{}")
	for k,v in pairs(NS3.PlanetaryOverrides or {}) do
		if v.style == "star" then
			local star = ents.Create("ns3_planet")
			star:SetPos(v.pos)
			star.Pos = v.pos
			star:Spawn()
			star.IsStar = true
			star.Temperature2 = 700
			star.Temperature3 = 400
			star.Temperature4 = 320
			star.Temperature5 = 285
			star:CreateEnvironment(v.radius or 2000, 0, 0, 100, 100000, nil, 0, 0, 0, 100, true, true, "Star "..tostring(#NS3.Stars + 1))
			table.insert(NS3.Stars,star)
		end
	end
end