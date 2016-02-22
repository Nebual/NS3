-- Tools are a pain to reload... so we have this silly file instead!

function NS3.NebSupporterLC(self, trace)
	local tar = trace.Entity
	if not tar or tar:IsPlayer() then return false end
	if CLIENT then return true end

	local ply           = self:GetOwner()
	local model			= self:GetClientInfo("model")
	local type			= self:GetClientInfo("type")
	local res			= self:GetClientInfo("resource")
	local doweld		= (self:GetClientNumber("doweld") != 0)
	local rotate90		= (self:GetClientNumber("rotate90") != 0)

	-- We shot an existing sensor - just change its values
	--if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "mv_soundemitter" && trace.Entity:GetTable():GetPlayer() == ply ) then
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + (rotate90 and 90 or 0)
	local ent

	if type == "Storage" then
		ent = MakeNS3Storage(ply, trace.HitPos, Ang, model, res)
	elseif type == "Generator" then
		ent = MakeNS3Generator(ply, trace.HitPos, Ang, model, res)
	elseif type == "Utility" then
		ent = MakeNS3Utility(ply, trace.HitPos, Ang, model, res)
	end

	if not ent then return false end
	ent:SetPos(trace.HitPos - trace.HitNormal * ent:OBBMins().z)
	undo.Create("ns3_" .. string.lower(type))
	undo.AddEntity(ent)

	if doweld and IsValid(tar) then
		weld = constraint.Weld(tar, ent, trace.PhysicsBone, 0, 0, not tar:IsWorld())

		weld:CallOnRemove("TempSleep", function(_, id)
			if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
				ent:GetPhysicsObject():EnableMotion(false)

				timer.Create(id .. "Wakeup", 1, 1, function()
					if IsValid(ent) then
						ent:GetPhysicsObject():EnableMotion(true)
					end
				end)
			end
		end, ent:EntIndex())

		undo.AddEntity(weld)
		ply:AddCleanup("ns3_" .. string.lower(type), weld)
	end

	if tar:IsWorld() then
		ent:GetPhysicsObject():EnableMotion(false)
	end

	ply:AddCleanup("ns3_" .. string.lower(type), ent)
	undo.SetPlayer(ply)
	undo.Finish()
	ent:GetPhysicsObject():Sleep()

	return true
end

function NS3.NebSupporterRC(self, trace)
	local tar = trace.Entity
	if not IsValid(tar) or tar:IsPlayer() then return false end
	if CLIENT then return true end

	if not self.FirstEnt then
		if tar.Priority then
			self.FirstEnt = tar
		elseif NS3.HijackEnts[tar:GetClass()] then
			NS3.HijackEnts[tar:GetClass()](tar)
			self.FirstEnt = tar
			self:Hint(tar:GetClass() .. " is now NS3 compatible")
		else
			self:Hint("Err: Only NS3 ents are supported atm")

			return false
		end
	else
		if not tar.Priority then
			if NS3.HijackEnts[tar:GetClass()] then
				NS3.HijackEnts[tar:GetClass()](tar)
				self:Hint(tar:GetClass() .. " is now NS3 compatible")
			else
				self:Hint("Err: Only NS3 ents are supported atm")
				self.FirstEnt = nil

				return false
			end
		end

		local ent1, ent2 = tar, self.FirstEnt
		self.FirstEnt = nil

		if not IsValid(ent1) or not IsValid(ent2) then
			self:Hint("One of your ents died!")

			return false
		end

		for k, v in ipairs2(ent1.DaisyLinks) do
			if not IsValid(v) then
				table.remove(self.Links, k or 1)
			else
				ent2:Link(v)
				v:Link(ent2)
			end
		end

		for k, v in ipairs2(ent2.DaisyLinks) do
			if not IsValid(v) then
				table.remove(self.Links, k or 1)
			else
				ent1:Link(v)
				v:Link(ent1)
			end
		end

		if ent1.Priority == 1 and ent2.Priority == 1 then
			for k, v in ipairs2(ent1.Links) do
				if not IsValid(v) then
					table.remove(self.Links, k or 1)
				else
					ent2:Link(v)
					v:Link(ent2)
				end
			end
			for k, v in ipairs2(ent2.Links) do
				if not IsValid(v) then
					table.remove(self.Links, k or 1)
				else
					ent1:Link(v)
					v:Link(ent1)
				end
			end
		end

		ent1:Link(ent2)
		ent2:Link(ent1)
		self:Hint((ent1.Resource or "") .. " " .. string.sub(ent1:GetClass(), 5) .. " [" .. ent1:EntIndex() .. "] and " ..
				  (ent2.Resource or "") .. " " .. string.sub(ent2:GetClass(), 5) .. " [" .. ent2:EntIndex() .. "] have been linked.")
		self.FirstEnt = nil
	end

	return true
end

function NS3.NebSupporterReload(self, trace)
	self.FirstEnt = nil
	local tar = trace.Entity
	if tar and tar:IsPlayer() then return false end
	if CLIENT then return true end

	if tar.Links then -- TODO: for k=1,#tarLinks???
		for k = 1, #tar.Links do
			local _, v = next(tar.Links)
			v:UnLink(tar)
			tar:UnLink(v)
		end

		for k = 1, #tar.DaisyLinks do
			local _, v = next(tar.DaisyLinks)
			v:UnLink(tar)
			tar:UnLink(v)
		end

		self:Hint((tar.Resource or "") .. " " .. string.sub(tar:GetClass(), 4) .. " [" .. tar:EntIndex() .. "] has been unlinked!")
	end
end

local ball
function NS3.NebSupporterUpdateGhost(self, ent, ply)
	local model = self:GetClientInfo("model")
	if model == "" then return end

	if not util.IsValidProp(model) then
		util.PrecacheModel(model)
		return
	end
	if (SERVER && !game.SinglePlayer()) then return end
	if (CLIENT && game.SinglePlayer()) then return end

	if !IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= string.lower(model) then
		self:MakeGhostEntity(model, Vector(0, 0, 0), Angle(0, 0, 0))

		if IsValid(self.GhostEntity) then
			if CLIENT then
				self.GhostEntity:SetPredictable(true)
			end

			if NS3.EntMaterials[model] then
				self.GhostEntity:SetMaterial(NS3.EntMaterials[model])
			end
		end
	end

	if not IsValid(ent) then return end
	local trace = ply:GetEyeTrace()
	if not trace.Hit then return end

	if IsValid(trace.Entity) and (string.Left(trace.Entity:GetClass(), 3) == "ns3" or trace.Entity:IsPlayer()) then
		ent:SetNoDraw(true)
		return
	end

	local rotate90 = (self:GetClientNumber("rotate90") ~= 0)
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + (rotate90 and 90 or 0)
	ent:SetAngles(Ang)
	ent:SetPos(trace.HitPos - trace.HitNormal * ent:OBBMins().z)
	ent:SetNoDraw(false)

	if CLIENT then
		local range = NS3.UtilityModels[ent:GetModel()]

		if range then
			if not ball then
				ball = ClientsideModel("models/hunter/misc/shell2x2.mdl", RENDERGROUP_OPAQUE)
				ball:SetMaterial("models/shiny")
			end

			ball:SetColor(Color(0, 0, 100, 100))
			ball:SetPos(ent:GetPos())
			SetScale(ball, Vector(math.Max(range / 95, 0.01), math.Max(range / 95, 0.01), math.Max(range / 95, 0.01)))

			timer.Create("ResetNebsupporterBall", 0.1, 1, function()
				ball:SetColor(Color(0, 0, 0, 0))
			end)
		end
	end
end

if CLIENT then
	--local sphereent = 0
	local pos1 = {
		x = ScrW() / 2,
		y = ScrH() / 1.9
	}

	local matBall = Material("sprites/sent_ball")

	function NS3.NebSupporterDrawHUD(self)
		local trace = self:GetOwner():GetEyeTrace()
		local tar = trace.Entity
		if not IsValid(tar) or not tar.Links then return end
		--local pos1 = {x = //trace.HitPos:ToScreen()
		--pos1.x = pos1.x -
		surface.SetDrawColor(255, 255, 255, 80)

		for k, v in pairs(tar.Links) do
			if v:IsValid() then
				local pos2 = v:GetPos():ToScreen()

				if pos1.visible or pos2.visible then
					surface.DrawLine(pos1.x, pos1.y, pos2.x, pos2.y)
				end
			end
		end

		if tar.Range then
			render.SetMaterial(matBall)
			local lcolor = render.GetLightColor(tar:GetPos()) * 2
			print(tar.Range)
			render.DrawSprite(tar:GetPos(), tar.Range, tar.Range, Color(0, 0, 100 * math.Clamp(lcolor.z, 0, 1), 50))
		end
	end

	function NS3.NebsupporterBuildCPanel(self, CPanel)
		CPanel:ClearControls()
		local Spawnicons = {}
		local plist

		local function AddSpawnIcons(category, kind)
			--Clear plist
			for k, v in ipairs(Spawnicons) do
				plist:RemoveItem(v)
			end

			table.Empty(Spawnicons)

			--Create spawnicons, add spawnicons to Grid and plist for easy clearing, send concmds
			for k, v in ipairs(NS3[category .. "Models"][kind]) do
				local spawnicon = vgui.Create("SpawnIcon")
				spawnicon:SetModel(v)

				--if NS3.EntMaterials[v] then spawnicon.Icon:SetMaterial(NS3.EntMaterials[v]) end
				spawnicon.DoClick = function()
					RunConsoleCommand("nebsupporter_type", category)
					RunConsoleCommand("nebsupporter_resource", kind)
					RunConsoleCommand("nebsupporter_model", v)
				end

				table.insert(Spawnicons, spawnicon)
				plist:AddItem(spawnicon)
			end

			--Fixes Grid size
			plist:SizeToContents()
			local _, height = plist:GetPos()
			CPanel:SetTall(height + plist:GetTall())
		end

		-- Image
		--[[local image = CPanel:AddControl("DImage", {})
        image:SetImage("VGUI/entities/npc_citizen_rebel")
        image:SetSize(150,150)]]
		local w, _ = CPanel:GetSize()
		CPanel:Help("All of NS3 is still very much a work in progress. If you have any complaints or suggestions please tell Nebual either in chat or via '!report Neb solar panels are broken'")
		CPanel:CheckBox("Weld", "nebsupporter_doweld")
		-- Begin Tree -----------------------
		local tree = vgui.Create("DTree", CPanel)
		tree:Dock(TOP)
		tree:SetSize(w, 450)

		for _, category in pairs({"Storage", "Generator", "Utility"}) do
			local cattree = tree:AddNode(category)

			for kind, models in pairsByKeys(NS3[category .. "Models"]) do
				local name = string.Replace(kind, '_', ' ')

				if NS3.ResourceMeta[kind] then
					name = NS3.ResourceMeta[kind].Name
				end

				cattree:AddNode(name).DoClick = function()
					AddSpawnIcons(category, kind)
					RunConsoleCommand("nebsupporter_type", category)
					RunConsoleCommand("nebsupporter_resource", kind)
					RunConsoleCommand("nebsupporter_model", models[1])
				end
			end
		end

		CPanel:AddItem(tree)
		-- Model picker List
		plist = vgui.Create("DGrid", CPanel)
		plist:SetSize(w, 350)
		plist:SetColWide(66)
		plist:SetRowHeight(66)
		CPanel:AddItem(plist)
		CPanel:CheckBox("Rotate Prop 90 degrees", "nebsupporter_rotate90")
	end
end

function MakeNS3Storage(ply, Pos, Ang, Model, Resource)
	--if ( !pl:CheckLimit( "ns3_storage" ) ) then return false end
	local ent = ents.Create("ns3_storage")
	if not IsValid(ent) then return false end
	ent:SetModel(Model)
	ent:SetAngles(Ang)
	ent:SetPos(Pos)
	ent.Resource = Resource
	ent:Spawn()
	ent:Setup(Resource)
	ent:SetPlayer(ply)

	--ply:AddCount( "ns3_storage", ent )
	return ent
end

duplicator.RegisterEntityClass("ns3_storage", MakeNS3Storage, "Pos", "Ang", "Model", "Resource")

function MakeNS3Generator(ply, Pos, Ang, Model, Style, Resource)
	--if ( !pl:CheckLimit( "ns3_storage" ) ) then return false end
	local ent = ents.Create("ns3_generator")
	if not IsValid(ent) then return false end
	ent:SetModel(Model)

	if NS3.EntMaterials[Model] then
		ent:SetMaterial(NS3.EntMaterials[Model])
	end

	--if res == "Energy" then ent.Voltage = NS3.GeneratorVoltages[model] * math.Rand(0.95,1.05) end
	ent:SetAngles(Ang)
	ent:SetPos(Pos)
	if Resource then ent.Resource = Resource end
	ent.Style = Style
	ent:Spawn()
	ent:Setup()
	ent:SetPlayer(ply)

	--ply:AddCount( "ns3_storage", ent )
	return ent
end

duplicator.RegisterEntityClass("ns3_generator", MakeNS3Generator, "Pos", "Ang", "Model", "Style", "Resource")

function MakeNS3Utility(ply, Pos, Ang, Model, Resource)
	--if ( !pl:CheckLimit( "ns3_storage" ) ) then return false end
	local ent = ents.Create("ns3_utility")
	if not IsValid(ent) then return false end
	ent:SetModel(Model)

	if Model == "models/slyfo/sat_rfg.mdl" then
		Ang.r = math.angnorm(Ang.r + 90)
	end

	ent:SetAngles(Ang)
	ent:SetPos(Pos)
	ent.Resource = Resource
	ent.Style = Resource
	ent:Spawn()
	ent:Setup()
	ent:SetPlayer(ply)

	return ent
end

duplicator.RegisterEntityClass("ns3_utility", MakeNS3Utility, "Pos", "Ang", "Model", "Resource")
