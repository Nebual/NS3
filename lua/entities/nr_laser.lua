ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "NR Laser"
ENT.Author = "NEON725"
ENT.RenderGroup = RENDERGROUP_BOTH

if (SERVER) then
	AddCSLuaFile()

	function CreateNRLaser(parent, Pos, Ang, Length, Width, Element)
		local E = ents.Create("nr_laser")

		if (parent) then
			E:SetPos(parent:LocalToWorld(Pos))
			E:SetAngles(parent:LocalToWorldAngles(Ang))
			E:Spawn()
			E:SetParent(parent)
		else
			E:SetPos(Pos)
			E:SetAngles(Ang)
			E:Spawn()
		end

		E.MaxLength = Length
		E.Width = Width
		E.Element = Element

		return E
	end

	function ENT:Initialize()
		self.CenterPos = Vector(0, 0, 0)
		self.MaxLength = 0
		self.LaserLength = 1 / 0
		self.Length = 0
		self.Width = 0
		self.Element = "Heat"
		self.BeamDirection = Vector(1, 0, 0)
		self.ParentLasers = {}
		self.ChildLaser = nil
		self.Partner = nil
		self.Powered = true
	end

	function ENT:Think()
		local function DEB(S)
			BotSay("MSG", tostring(self) .. ":" .. tostring(S))
		end

		local function GetClosestPoint(LaserB, LaserA)
			-- Returns the point along LaserB that is closest to LaserA. Don't forget the order!

			local LaserBOrigin = LaserA:WorldToLocal(LaserB:GetPos())
			local Len = LaserBOrigin:Length()
			LaserBOrigin = LaserBOrigin:Angle()
			LaserBOrigin:RotateAroundAxis(Vector(0, 1, 0), -90)
			LaserBOrigin = LaserBOrigin:Forward() * Len
			local LaserBEndPos = LaserA:WorldToLocal(LaserB:GetPos() + (LaserB:GetForward() * LaserB.Length))
			Len = LaserBEndPos:Length()
			LaserBEndPos = LaserBEndPos:Angle()
			LaserBEndPos:RotateAroundAxis(Vector(0, 1, 0), -90)
			LaserBEndPos = LaserBEndPos:Forward() * Len
			local LaserBForward = LaserBEndPos - LaserBOrigin
			local LaserB2DForward = Vector(LaserBForward.x, LaserBForward.y, 0)
			local LaserB2DOrigin = Vector(LaserBOrigin.x, LaserBOrigin.y, 0)
			local SampleAng = (-LaserB2DOrigin):Angle().y - LaserB2DForward:Angle().y

			if (SampleAng > 180) then
				SampleAng = SampleAng - 360
			end

			if (SampleAng < -180) then
				SampleAng = SampleAng + 360
			end

			local AbsSampleAng = math.abs(SampleAng)
			local ObtuseAngle = false

			if (AbsSampleAng > 90) then
				ObtuseAngle = true
				AbsSampleAng = 180 - AbsSampleAng
			end

			if (AbsSampleAng == 90) then
				--If the angle is precisely 90 degrees, then LaserB's origin is the closest point. Keep in mind this shouldn't happen unless you spawn lasers with expert precision.
				return LaserB:GetPos()
			else
				local Hypotenuse = LaserB2DOrigin:Length()
				local Adjacent = math.cos(AbsSampleAng * math.pi / 180) * Hypotenuse
				local DistanceToLaser = math.sin(AbsSampleAng * math.pi / 180) * Hypotenuse
				local ZPer2DLen = LaserBForward.z / LaserB2DForward:Length()
				local CollisionPointZOffset = ZPer2DLen * Adjacent
				local CollisionPoint2DOffset = LaserB2DForward:GetNormalized() * Adjacent
				local CollisionPointOffset = Vector(CollisionPoint2DOffset.x, CollisionPoint2DOffset.y, CollisionPointZOffset)
				local DistanceFromLaserBOrigin = CollisionPointOffset:Length()

				if (ObtuseAngle) then
					DistanceFromLaserBOrigin = -DistanceFromLaserBOrigin
				end

				return LaserB:LocalToWorld(Vector(DistanceFromLaserBOrigin, 0, 0)), DistanceToLaser, DistanceFromLaserBOrigin
			end
		end

		for _, E in pairs(self.ParentLasers) do
			if (not IsValid(E) or (IsValid(E.ChildLaser) and E.ChildLaser ~= self)) then
				self:Remove()

				return
			end
		end

		if (IsValid(self:GetParent())) then
			self:SetAngles((self:GetParent():LocalToWorld(self.BeamDirection) - self:GetParent():GetPos()):Angle())
		end

		if (table.Count(self.ParentLasers) > 0) then
			local Parent = table.Random(self.ParentLasers)
			self.Powered = Parent.Powered
			self.Element = Parent.Element
			self.NegativeElement = Parent.NegativeElement
		elseif (IsValid(self:GetParent()) and self:GetParent().LaserSupply) then
			self.Powered = self:GetParent():LaserSupply(self)
		else
			self.Powered = true
		end

		local Element = NRDatabase.Elements[self.Element]
		self:SetColor(Element.Color)
		local BeamTrace = util.QuickTrace(self:GetPos(), self:GetForward() * self.MaxLength, {self, self:GetParent()})

		if (not self.Powered) then
			local PropColor = Color(Element.Color.r, Element.Color.g, Element.Color.b)

			for _, v in pairs({"r", "g", "b"}) do
				PropColor[v] = math.random() * PropColor[v]
			end

			self:SetColor(PropColor)
		end

		if (BeamTrace.Hit) then
			if (CurTime() > (self.NextCriticalThink or 0)) then
				if (self.Powered) then
					local Ent = BeamTrace.Entity
					local NegMul = 1

					if (Element.AllowNegative and self.NegativeElement) then
						NegMul = -1
					end

					Element:HitSide(BeamTrace.HitPos, self:GetForward() * -1, self.Width * NegMul, Ent)

					if (IsValid(Ent)) then
						local Multiplier = (self.Width ^ 3) * 5 / GetPropVolume(Ent)
						InflictElement(Ent, self.Element, Multiplier * NegMul)
					end
				end
			end
		end

		local TargetLength = BeamTrace.HitPos:Distance(BeamTrace.StartPos)

		if (TargetLength > self.LaserLength) then
			TargetLength = self.LaserLength
		end

		local Diff = TargetLength - self.Length
		local MaxDiff = self.Width * 5

		if (Diff > MaxDiff) then
			Diff = MaxDiff
		end

		self.Length = self.Length + Diff
		self:SetNWFloat("Length", self.Length)
		self:SetNWFloat("Width", self.Width)

		if (self.Width > 500) then
			self:Remove()
		end

		self.CenterPos = (BeamTrace.HitPos + BeamTrace.StartPos) / 2

		if (CurTime() > (self.NextCriticalThink or 0)) then
			self.NextCriticalThink = CurTime() + 0.2
			local Collisions = {}

			for _, Ent in pairs(ents.FindByClass("nr_laser")) do
				if (Ent:EntIndex() <= self:EntIndex() or Ent == self.ChildLaser or table.HasValue(self.ParentLasers, Ent)) then continue end
				local Dist2 = Ent.CenterPos:DistToSqr(self.CenterPos)

				if (Dist2 < (Ent.Length / 2 + self.Length / 2) ^ 2 or true) then
					local selfCollision, selfDist, selfLength = GetClosestPoint(self, Ent)
					local EntCollision, EntDist, EntLength = GetClosestPoint(Ent, self)

					if (EntLength == nil) then
						print("ODD COLLISION")
						print(EntCollision)
						print(EntDist)
						print(EntLength)
					end

					if (selfCollision ~= nil and EntCollision ~= nil and selfDist < (self.Width + Ent.Width) / 2 and EntLength > 0 and EntLength <= Ent.Length and selfLength > 0 and selfLength <= self.Length) then
						table.insert(Collisions, {
							self = {
								Ent = self,
								Pos = selfCollision,
								Dist = selfDist,
								Length = selfLength
							},
							Partner = {
								Ent = Ent,
								Pos = EntCollision,
								Dist = EntDist,
								Length = EntLength
							}
						})
					end
				end
			end

			local ClosestIndex = nil
			local ClosestLength = 1 / 0

			for I, Collide in pairs(Collisions) do
				if (Collide.self.Length < ClosestLength) then
					ClosestLength = Collide.self.Length
					ClosestIndex = I
				end
			end

			local Collide = nil

			if (ClosestIndex ~= nil) then
				Collide = Collisions[ClosestIndex]
			end

			local function ResetPartner()
				self.Partner.Partner = nil
				self.Partner.LaserLength = 1 / 0

				if (IsValid(self.ChildLaser)) then
					self.ChildLaser:Remove()
				end

				self.ChildLaser = nil
				self.Partner = nil
			end

			if (not IsValid(self.Partner)) then
				self.Partner = nil

				if (IsValid(self.ChildLaser)) then
					self.ChildLaser:Remove()
				end

				self.ChildLaser = nil
				self.LaserLength = 1 / 0
			end

			if (Collide ~= nil) then
				if (IsValid(self.Partner) and Collide.Partner.Ent ~= self.Partner) then
					ResetPartner()
				end

				self.Partner = Collide.Partner.Ent
				self.Partner.Partner = self
				self.LaserLength = Collide.self.Length + 3
				self.Partner.LaserLength = Collide.Partner.Length + 3
				local MergePoint, MergeAngle = (Collide.self.Pos + Collide.Partner.Pos) / 2, ((self:GetForward() + self.Partner:GetForward()) / 2):Angle()

				if (not IsValid(self.ChildLaser)) then
					local Element = self.Element

					if (Element ~= self.Partner.Element) then
						Element = "Heat"
					end

					self.ChildLaser = CreateNRLaser(nil, MergePoint, MergeAngle, 0, 0, Element)
					self.ChildLaser.ParentLasers = {self, self.Partner}
					self.Partner.ChildLaser = self.ChildLaser
				end

				self.ChildLaser:SetPos(MergePoint)
				self.ChildLaser:SetAngles(MergeAngle)
				self.ChildLaser.MaxLength = (self.MaxLength + self.Partner.MaxLength) - (Collide.self.Length + Collide.Partner.Length)
				self.ChildLaser.Width = self.Width + self.Partner.Width
			elseif (IsValid(self.Partner) and self.Partner:EntIndex() > self:EntIndex()) then
				ResetPartner()
			end
		end
	end
elseif CLIENT then

	function ENT:Draw()
		local Length, Width = self:GetNWFloat("Length", 0), self:GetNWFloat("Width", 0)
		render.SetMaterial(Material("cable/cable2"))
		render.DrawBeam(self:GetPos(), self:GetPos() + self:GetForward() * Length, Width, 0, 100, self:GetColor())
		render.DrawSphere(self:GetPos(), Width / 2, 16, 16, self:GetColor())
	end

	function ENT:Think()
		local Length, Width = self:GetNWFloat("Length", 0), self:GetNWFloat("Width", 0)
		self:SetRenderBounds(Vector(0, -Width, -Width), Vector(Length, Width, Width))
	end
end