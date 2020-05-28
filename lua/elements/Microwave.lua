local function MakeNRMicrowave(Name, Cost, EColor)
	BeginNewElement(Name)
	ELEMENT.Cost = Cost
	ELEMENT.DecayRate = 100
	ELEMENT.Color = EColor
	ELEMENT.GenerateWeapons = false

	function ELEMENT:HitSide(Pos, Norm, Size, Ent)
		if (Ent.DEVICENAME ~= "Microwave Receiver") then return end

		for Type, Amt in pairs(self.Cost) do
			Ent.MicrowavePower[Type] = math.floor((Ent.MicrowavePower[Type] or 0) + Size * Amt)
		end
	end
end

MakeNRMicrowave("Low Freq Microwave", {
	["AC Electricity"] = 5
}, Color(255, 60, 0))

MakeNRMicrowave("Mid Freq Microwave", {
	["AC3 Electricity"] = 5
}, Color(255, 40, 0))

MakeNRMicrowave("High Freq Microwave", {
	["AC3 Electricity"] = 25
}, Color(255, 20, 0))