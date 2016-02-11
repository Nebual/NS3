DEVICE.Setup = function(self)
	self.Regulate = self.Lists.Regulate[self.Style] or NS3.NullFunction
	self.Range = NS3.RegulatorModels[self:GetModel()] or math.Round(self.Entity:GetPhysicsObject():GetVolume() ^ 0.72 * 0.8)
	self.WaterPhobic = false
	self.BufferSize = math.Round(self.Range / 10)
	self.OverlayBase = "NS3 Heat Regulator"
	table.insert(NS3.TemperatureRegulators, self)
	local timerid = "NS3_FindFootBreathEnts_"..self:EntIndex()
	timer.Create(timerid, 10, 0, function() if self.Entity:IsValid() then self.Entity:FindFootBreathEnts(timerid) else timer.Remove(timerid) end end)
end

DEVICE.SubThink = function(self)
    if self.Active then
        if self.Resources.Heating < 5 then self:LowResource("Energy")
        //elseif self.Resources.Water < 5 then self:LowResource("coolant (water)")
        else
            self.OverlayWarning = nil
            self.Resources.Heating = self.Resources.Heating - 5
        end
    end
    self.Requesting.Heating = self.BufferSize*2 - self.Resources.Heating
    self.Requesting.Coolant = self.BufferSize - self.Resources.Coolant
    self.OverlayStatus = "Buffer: Heating " .. math.Round(self.Resources.Heating) .. ", Coolant " .. math.Round(self.Resources.Coolant)
end

DEVICE.Regulate = function(self, ply) // Returns the ent's new temperature
    local temp = ply.Suit.Temperature
    if temp > 295 then
        // if nitro then use that else use below formulas
        local diff = math.Min(math.Min(temp - 295, 15), self.Resources.Coolant)
        self.Resources.Coolant = self.Resources.Coolant - diff
        return temp - diff
    elseif temp < 295 then
        local diff = math.Min(math.Min(295 - temp, 15), self.Resources.Heating)
        self.Resources.Heating = self.Resources.Heating - diff
        return temp + diff
    end
    return temp
end
