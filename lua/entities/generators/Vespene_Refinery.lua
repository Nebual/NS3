DEVICE.Name = "Vespene Refinery"
DEVICE.Resource = "RefinedVespene"
DEVICE.Setup = function(self)
end

DEVICE.ProduceResource = function(self)
    local fuels = self:CollectResources()

    self.Requesting.RawVespene = self.Speed
    self.Requesting.Hydrogen = self.Speed * 4
    return {"RefinedVespene", fuels.RawVespene}
end
