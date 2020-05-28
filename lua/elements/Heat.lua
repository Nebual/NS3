ELEMENT.Cost = {
	Energy = 5
}

ELEMENT.DamageType = DMG_BURN
ELEMENT.DecayRate = 2
ELEMENT.Color = Color(255, 0, 0)

function ELEMENT:Think()
	local Host = self.Host
	local Scale = self.Strength * 10.24

	if (Scale > 512) then
		Scale = 512
	end

	//local HostCDS = GetCDS(Host)
	//local EColor = HostCDS.OldColor
	local EColor = Host:GetColor()
	local R, G, B = EColor.r, EColor.g, EColor.b
	G = math.Clamp(G - Scale, 0, 255)
	B = math.Clamp(B - Scale, 0, 255)

	if (Scale > 255) then
		Scale = Scale - 255
		R = math.Clamp(R + Scale, 0, 255)
	end

	Host:SetColor(Color(R, G, B))
	local BurnStrength = 0
	local MinIgnition = 50

	//if (not HostCDS.HijackHP) then
		MinIgnition = 25
	//end

	if (self.Strength > MinIgnition) then
		BurnStrength = (self.Strength - MinIgnition) / (100 - MinIgnition)
		local Comp = GetComposition(Host)
		local FireConsumption = 0.5
		Comp.Oxygen = (Comp.Oxygen or 0) - (self.Strength * FireConsumption)

		if (Comp.Oxygen < 0) then
			BurnStrength = BurnStrength + (Comp.Oxygen / FireConsumption)
			Comp.Oxygen = 0
		end
	end

	DebugInfo(20, BurnStrength)

	if (BurnStrength > 0) then
		self.StrengthLastChanged = CurTime()
		self.Strength = self.Strength + 1
		local HostScale = GetPropVolume(Host)

		if (not Host:IsOnFire()) then
			Host:Ignite(10000, 0)
		end

		for _, Ent in pairs(ents.FindInSphere(Host:GetPos(), Host:BoundingRadius() * 2)) do
			if (not IsValidForCDS(Ent)) then continue end
			local Dist = Host:GetPos():Distance(Ent:GetPos()) - (Ent:BoundingRadius() + Host:BoundingRadius())
			if (Dist > Host:BoundingRadius() * 2) then continue end

			if (Dist < 0) then
				Dist = 0
			end

			local Scale = (HostScale / GetPropVolume(Ent)) / Dist

			if (Scale > 1) then
				Scale = 1
			end

			InflictElement(Ent, "Heat", Scale * 5)
		end
	elseif (Host:IsOnFire()) then
		if (self.Strength >= MinIgnition) then
			self.Strength = MinIgnition
		end

		Host:Extinguish()
	end

	self.StrengthCap = self.Strength + 10
end

function ELEMENT:StrengthChange(Old, Change)
	if (self.Host:GetClass() == "player") then
		DealDMG(self.Host, Change, DMG_BURN)
		self.Strength = 0

		return
	end

	if (self.StrengthCap and self.Strength > self.StrengthCap) then
		self.Strength = self.StrengthCap
	end

	local DMG = Change

	if (self.Strength >= 100) then
		DMG = DMG + GetCDS(self.Host).MaxHP / 100
	end

	DealDMG(self.Host, DMG, DMG_BURN)
end