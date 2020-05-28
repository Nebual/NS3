local DoNothing = NS3.NullFunction

function GetPropVolume(ent)
	local Vec=ent:OBBMaxs()-ent:OBBMins()
	return Vec.x*Vec.y*Vec.z
end

if (SERVER) then
	if not NRDatabase then
		NRDatabase = {}
	end

	util.AddNetworkString("Element Effect")

	function InflictElement(Ent, ElementName, Amount)
		
		if (Amount <= 0) then return end
		local Element = NRDatabase.Elements[ElementName]

		if (not Element) then
			print("Could not inflict element: " .. ElementName)

			return
		end
		--[[
		local CDS = GetCDS(Ent)
		if (not CDS) then return end
		local ElementList = CDS.Elements

		for _, Data in pairs(ElementList) do
			if (Data.ELEMENTNAME == ElementName) then
				local OldStrength = Data.Strength
				Data.Strength = Data.Strength + Amount
				Data.StrengthLastChanged = CurTime()
				Data:StrengthChange(OldStrength, Amount)

				return
			end
		end
		--]]

		Element = table.Copy(Element)

		if (Amount > 100) then
			Element.Strength = 100
		else
			Element.Strength = Amount
		end

		Element.Host = Ent
		//table.insert(ElementList, Element)
		Element:Setup()
		//MakeActive(Ent)
	end
end

local Elements = {}

local MinimumElementFootprint = {
	ELEMENTNAME = "Primordial Force",
	Setup = DoNothing,
	Think = DoNothing,
	StrengthChange = DoNothing,
	DamageType = 0,
	ThinkDelay = 1,
	DecayRate = 0,
	Strength = 0,
	Cost = {},
	Color = Color(255, 255, 255),
	AllowNegative = false,
	GenerateWeapons = true,
	HitSide = DoNothing,
	Burst = DoNothing,
	EffectSide = DoNothing,
	EffectBurst = DoNothing
}

if (SERVER) then
	NRDatabase.MinimumElementFootprint = MinimumElementFootprnit
end

ELEMENT = {
	ELEMENTNAME = ""
}

function BeginNewElement(Name)
	if (table.Count(ELEMENT) > 1) then
		Elements[ELEMENT.ELEMENTNAME] = table.Copy(ELEMENT)
	end

	ELEMENT = {
		ELEMENTNAME = Name
	}
end

local Path = "elements/"

for k, Str in pairs(file.Find(Path .. "*.lua", "LUA")) do
	local Name = string.Left(Str, string.len(Str) - 4)
	Name = string.Implode(" ", string.Explode("_", Name))
	BeginNewElement(Name)

	if (SERVER) then
		AddCSLuaFile(Path .. Str)
	end

	include(Path .. Str)
end

BeginNewElement("")

for Gen, Tab in pairs(Elements) do
	for k, v in pairs(MinimumElementFootprint) do
		if (Tab[k] == nil) then
			Tab[k] = v
		end
	end
end

if (SERVER) then
	NRDatabase.Elements = Elements
	AddCSLuaFile("ElementDatabase.lua")
end

if (CLIENT) then
	net.Receive("Element Effect", function()
		local Element = Elements[string.lower(net.ReadString())]
		if (Element == nil) then return end
		local Command = net.ReadString()

		if (Command == "EffectSide") then
			Element:EffectSide(net.ReadVector(), net.ReadVector(), net.ReadFloat(), net.ReadEntity())
		elseif (Command == "EffectBurst") then
			Element:EffectBurst(net.ReadVector(), net.ReadFloat())
		end
	end)
end