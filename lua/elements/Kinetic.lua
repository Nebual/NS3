ELEMENT.Cost = {
	Energy = 5
}

ELEMENT.DecayRate = 100
ELEMENT.Color = Color(100, 255, 0)
ELEMENT.AllowNegative = true

function ELEMENT:HitSide(Pos, Norm, Radius, Ent)
	local Phys = Ent
	if (not IsValid(Ent)) then return end
	Phys = Ent:GetPhysicsObject()
	if (not IsValid(Phys)) then return end
	Phys:ApplyForceCenter(Norm * Radius * -25000, Ent:WorldToLocal(Pos))
end