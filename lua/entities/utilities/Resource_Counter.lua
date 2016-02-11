DEVICE.Setup = function(self)
	self.OverlayBase = "NS3 Resource Counter"
	self.Mute = true
	self.WaterPhobic = false

	self.SetActive = function() return end
	timer.Create("ResourceCounterSetup"..self:EntIndex(), 0.1, 3, function() self.Overlay = self.OverlayBase end)

	WireLib.AdjustSpecialInputs(self.Entity, {}, {})
	local tab = {}
	local tab2 = {}
	for _, res in pairs({"Energy", "Oxygen", "CarbonDioxide", "Nitrogen", "Hydrogen", "Water"}) do
		table.insert(tab, res) table.insert(tab2, "NORMAL")
		table.insert(tab, "Max "..res) table.insert(tab2, "NORMAL")
		table.insert(tab, "% "..res) table.insert(tab2, "NORMAL")
	end
	WireLib.AdjustSpecialOutputs(self.Entity, tab, tab2)
end

DEVICE.SubThink = function(self)
	local resources = table.Copy(NS3.Resources)
	local maxes = {}
	for k,v in pairs(self.Links) do
		if IsValid(v) and v.Resources and v.Resource and v.Max then
			resources[v.Resource] = (resources[v.Resource] or 0) + v.Resources[v.Resource]
			maxes[v.Resource] = (maxes[v.Resource] or 0) + v.Max
		end
	end

	for _,v in pairs({"Energy", "Oxygen","CarbonDioxide","Nitrogen","Hydrogen", "Water"}) do
		WireLib.TriggerOutput(self.Entity, v, resources[v])
		WireLib.TriggerOutput(self.Entity, "Max "..v, maxes[v] or 0)
		WireLib.TriggerOutput(self.Entity, "% "..v, 100 * resources[v] / (maxes[v] or 1))
	end
end
