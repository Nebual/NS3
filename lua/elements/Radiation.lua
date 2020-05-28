ELEMENT.Cost = {
	Uranium = 1
}

ELEMENT.DamageType = DMG_RADIATION
ELEMENT.DecayRate = 0.2
ELEMENT.Color = Color(0, 255, 0)

function ELEMENT:Think()
	local Host = self.Host
	DealDMG(Ent, (self.Strength / 50), self.DamageType)

	for _, Ent in pairs(ents.FindInSphere(Host:GetPos(), Host:BoundingRadius() * 3)) do
		if (Ent:GetClass() ~= "player") then continue end
		local Dist = Host:GetPos():Distance(Ent:GetPos()) - (Host:BoundingRadius() + Ent:BoundingRadius())

		if (Dist <= 1) then
			Dist = 1
		end

		DealDMG(Ent, (self.Strength / 20) / Dist, self.DamageType)
	end
end