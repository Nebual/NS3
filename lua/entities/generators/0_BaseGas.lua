DEVICE.Name = "basegas"
-- Note: Is used by O2/H2/CO2/N2
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = function(self)
    if self.Environment.IsSpace then
        self.OverlayWarning = "No natural resources present in space!"
        return
    end

    local fuels = self:CollectResources()
    local produce
    -- Rate is based on current saturation of the resource within the environment
    local availres = self.Environment.Resources[self.Resource] / self.Environment.Max
    if availres == 0 then self.OverlayWarning = "No natural "..self.Resource.." present!" return
    elseif availres > 0.5 then produce 		= self.Speed * 2 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor) -- If theres lots, purification is easy
    elseif availres > 0.2 then produce 		= self.Speed * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
    elseif availres > 0.125 then produce	= self.Speed * 0.6 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
    elseif availres > 0.05 then produce 	= self.Speed * 0.4 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
    elseif availres > 0.02 then produce 	= self.Speed * 0.25 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor)
    else produce 							= self.Speed * 0.2 * math.Rand(1-self.RandomFactor, 1 + self.RandomFactor) -- If theres hardly any of a resource present, purification is hard
    end

    if fuels.Energy then
        self.Environment.Resources[self.Resource] = self.Environment.Resources[self.Resource] - produce
        return {self.Resource, produce}
    else
        return {"", produce}
    end
end
