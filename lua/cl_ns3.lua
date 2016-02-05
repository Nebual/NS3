local alwayshud = CreateClientConVar("ns3_hudalways", 0, true, false)
local Suit = {Name = "kelp", Oxygen = 0,Coolant=0,Energy=0,Temperature=290,TempMessage="",EnvTempMessage=""}
NS3.Suit = Suit

local function temperaturemsg(temperature)
	if temperature < 30 then return "Absolute Zero", true
	elseif temperature < 150 then return "Frozen Solid", true
	elseif temperature < 250 then return "Instant Frostbite", true
	elseif temperature < 280 then return "Painfully Cold", true
	elseif temperature < 280 then return "Painfully Cold", true
	elseif temperature < 286 then return "Chilly", nil
	elseif temperature < 302 then return "Nominal", nil
	elseif temperature < 311 then return "Humid", nil
	elseif temperature < 330 then return "Baking", true
	elseif temperature < 400 then return "Boiling", true
	elseif temperature < 550 then return "Inferno", true
	else return "Volcanic", true
	end
end

local function LS_umsg_hook1( um )
	Suit.Name = um:ReadString()

	Suit.Temperature = um:ReadShort()
	Suit.TempMessage, Suit.TempWarn = temperaturemsg(Suit.Temperature)
	local envtemp = um:ReadShort()
	if Suit.Name == "Space" then envtemp = 14 end
	Suit.EnvTempMessage, Suit.EnvTempWarn = temperaturemsg(envtemp)

	Suit.Oxygen = um:ReadShort()
	Suit.Coolant = um:ReadShort()
	Suit.Energy = um:ReadShort()
	//Suit.Bad = Suit.Bad or Suit.Temperature or alwayshud:GetBool()
end
usermessage.Hook("LS_umsg1", LS_umsg_hook1)

local function LS_umsg_hook2( um )
	Suit.Oxygen = um:ReadShort()
end
usermessage.Hook("LS_umsg2", LS_umsg_hook2)

local c 	= {
	White = Color(225,225,225,255),
	Black = Color(0,0,0,100),
	DarkBlack = Color(0,0,0,200),
	Cold = Color(0,225,255,255),
	Blue = Color(0,80,180,255),
	Hot = Color(225,0,0,255),
	Warn = Color(255,165,0,255),
	Grey = Color(150, 150, 150, 255),
	Green = Color(0, 225, 0, 255),
}
NS3.VisorDown = true
local TarHudOffset = ScrH() - 160
local HudOffset = TarHudOffset
local VisorRed,VisorBlue,VisorAlpha = 0,0,20
local TarVisorAlpha = VisorAlpha
local font = "DermaDefault"
local buttonposx, buttonposy
local ns3_suitmax = GetConVar("ns3_suitmax")
function NS3.HUDPaint()
	local ply = LocalPlayer()
	if !ply or not ply:Alive() or (ply:GetActiveWeapon() and ply:GetActiveWeapon() == "Camera") then return end
	local scrw = ScrW() / 2 + math.sin(CurTime())*3
	HudOffset = math.Approach(HudOffset,TarHudOffset,ScrH()*0.4*FrameTime())
	VisorAlpha = math.Approach(VisorAlpha,TarVisorAlpha,65*FrameTime())
	local h = HudOffset + math.cos(CurTime())*3
	local leftpos,rightpos = scrw - 80, scrw + 80
	local percent = ns3_suitmax:GetInt() / 100
	local valcol
	if Suit.Name == "kelp" then
		if ply:WaterLevel() > 2 then
			-- Draw simple HUD as we're not in a SB map
			local res = Suit.Oxygen / percent
			if res < 2 then valcol = c.Warn else valcol = c.White end
			draw.RoundedBox( 8, scrw - 90 , h, 180, 20, c.Black)
			draw.DrawText( "Oxygen:", font, leftpos, h + 5, c.White,	0 )
			draw.DrawText( math.floor(res*10)/10 .."% ("..math.floor(Suit.Oxygen / 5).."s)", font, rightpos,h + 5, valcol, 2 )
		end
	else
		local res
		draw.RoundedBox( 8, 0 , -5, ScrW(), h + ScrH() * 0.17, Color(VisorRed,0,VisorBlue,VisorAlpha)) -- The Visor
		draw.RoundedBox( 8, scrw - 90 , h, 180, 133, c.Black)

		h = h + 5
		draw.DrawText( "["..Suit.Name.."]", font, scrw, h, c.White, 1 )

		h = h + 20
		draw.DrawText( "SuitTemp:", font, leftpos, h, c.White, 0 ) // This 0 means text align left, 2 would mean right
		if Suit.TempWarn then valcol = c.Warn else valcol = c.White end
		draw.DrawText(Suit.TempMessage .. " ("..Suit.Temperature..")", font, rightpos, h, valcol, 2 )
		
		h = h + 15
		draw.DrawText( "EnvTemp:", font, leftpos, h, c.White, 0 ) // This 0 means text align left, 2 would mean right
		if Suit.EnvTempWarn then valcol = c.Warn else valcol = c.White end
		draw.DrawText(Suit.EnvTempMessage, font, rightpos, h, valcol, 2 )

		res = Suit.Oxygen / percent
		if res < 2 then valcol = c.Warn else valcol = c.White end
		h = h + 20
		draw.DrawText( "Oxygen:", font, leftpos, h, c.White, 0 )
		draw.DrawText( math.floor(res*10)/10 .."% ("..math.floor(Suit.Oxygen / 5).."s)", font, rightpos,h, valcol, 2 )

		res = Suit.Coolant / percent
		if res < 2 then valcol = c.Warn else valcol = c.White end
		h = h + 15
		draw.DrawText( "Coolant:", font, leftpos, h, c.White, 0 )
		draw.DrawText( math.floor(res*10)/10 .."% ("..math.floor(Suit.Coolant / 5).."s)", font, rightpos,h, valcol, 2 )

		res = Suit.Energy / percent
		if res < 2 then valcol = c.Warn else valcol = c.White end
		h = h + 15
		draw.DrawText( "Energy:", font, leftpos, h, c.White, 0 )
		draw.DrawText( math.floor(res*10)/10 .."% ("..math.floor(Suit.Energy / 5).."s)", font, rightpos,h, valcol, 2 )
		
		h = h + 18
		draw.RoundedBox( 8, scrw - 45 , h, 90, 20, c.Blue)
		draw.DrawText( "Toggle Helmet", font, scrw, h + 3, c.White, 1 )
		buttonposx, buttonposy = scrw - 45, h
	end
end
hook.Add("HUDPaint", "NS3.HUD", NS3.HUDPaint)
function NS3.GUIMousePressed(mouse)
	local posx,posy = gui.MousePos( )
	if Suit.Name != "kelp" and posx > buttonposx and posx < buttonposx+90 and posy > buttonposy and posy < buttonposy+20 then
		NS3.ToggleVisor()
	end
end
hook.Add("GUIMousePressed","NS3.GUIMousePressed",NS3.GUIMousePressed)
function NS3.ToggleVisor()
	NS3.VisorDown = !NS3.VisorDown
	if NS3.VisorDown then CreateSound(LocalPlayer(), "/doors/door_metal_large_close2.wav" ):Play() else CreateSound(LocalPlayer(), "/doors/door_metal_large_open1.wav" ):Play() end
	RunConsoleCommand("ns3_visor",NS3.VisorDown and "1" or "0") // RunConsoleCommand converts integers into 1.00 and 0.00, which breaks tobool(arg[1]) O.o
	TarHudOffset = ScrH() * (NS3.VisorDown and 0.85 or 0.04)
	TarVisorAlpha = NS3.VisorDown and 20 or 150
end
concommand.Add("togglevisor", NS3.ToggleVisor)

function NS3.CLThink()
	if Suit.Temperature < 280 then
		VisorBlue = math.Min(295 - Suit.Temperature, 100)
		TarVisorAlpha = math.Min(310 - Suit.Temperature,150)
		-- He's cold
	elseif Suit.Temperature > 310 then
		VisorRed = math.Min(Suit.Temperature - 295,100)
		TarVisorAlpha = math.Min(Suit.Temperature - 280,150)
		-- Too hot
	else
		VisorBlue,VisorRed = 0,0
		TarVisorAlpha = NS3.VisorDown and 20 or 150
	end
end
timer.Create("NS3_CLThink",1,0,NS3.CLThink)

hook.Add("InitPostEntity","NS3_gmod_auto_tool",function() if gmod_tool_auto then gmod_tool_auto.AddPattern("^ns3_.*$", { "nebsupporter", "wire_adv", "wire_debugger" }) end end)
print("[NS3 Client - Nebcorp's Life Support and Resources Mod Loaded]")