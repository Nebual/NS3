local ns3_base, ns3_utility
hook.Add("InitNS3", "HijackEnts", function()
	ns3_base = scripted_ents.Get( "ns3_base_entity" )
	ns3_utility = scripted_ents.Get("ns3_utility")
	NS3.HijackEnts = {//
		gmod_wire_thruster = function(ent)
			ent.Link = ns3_base.Link
			ent.UnLink = ns3_base.UnLink
			ent.CollectResources = ns3_base.CollectResources
			ent.Requesting = {}
			ent.Links = {}
			ent.DaisyLinks = {}
			ent.Receiving = {}
			ent.Priority = 2
			ent.Power = 1
			if !ent.Environment then ent.Environment = {Resources = {Oxygen = 100000, CarbonDioxide = 0, Empty = 0}, Max = 2000000} end

			ent.NS3Needs,ent.NS3Force = 0,0
			local func = ent.SetForce
			ent.SetForce = function(self, force, mul )
				func(self,force,mul) 												// 940250 is required to move a 1500 weight phx plate straight up "very slowly"
				ent.NS3Force = ent:OBBMaxs().z * ent.force * mul * 50 * FrameTime() / 37610 // 940250 / 25, hopefully so it'd take 50 resource to move said plate
			end
			func = ent.PhysicsSimulate
			ent.PhysicsSimulate = function(self, phys, deltatime)
				local a,b,c = func(self,phys,deltatime)
				if a == SIM_NOTHING or !self.Power then return SIM_NOTHING end
				self.NS3Needs = self.NS3Needs + self.NS3Force
				return a,b * self.Power,c
			end
			local timerid = "NS3_Hijack_"..ent:EntIndex()
			timer.Create(timerid,1,0,function()
				if !IsValid(ent) then timer.Destroy(timerid) return end
				local envoxy = (ent.Environment.Resources.Oxygen / ent.Environment.Max)
				//if !ent.Requesting.Energy or !ent.Requesting.Fuel then ent.HasPower = 1
				if ent.LastRequested then
					local fuels = ent:CollectResources()
					ent.Power = nil
					if fuels.Fuel > 0 then
						-- Combustion thruster; needs oxygen
						ent.Power = fuels.Fuel/ent.LastRequested
						if fuels.Oxygen > 0 then
							ent.Power = ent.Power * (fuels.Oxygen * 2 / ent.LastRequested)
							ent.Environment.Resources.CarbonDioxide = ent.Environment.Resources.CarbonDioxide + fuels.Oxygen
						elseif envoxy < 0.12 then
							ent.Power = ent.Power * (envoxy / 0.12) ^ 0.6
							ent.Environment:Convert("Oxygen", "CarbonDioxide", ent.LastRequested - fuels.Fuel)
						else
							ent.Environment:Convert("Oxygen", "CarbonDioxide", ent.LastRequested - fuels.Fuel)
						end
					elseif fuels.Energy > 0 then
						ent.Power = (fuels.Energy / 8) / ent.LastRequested
					end
					if ent.Power then -- Something gave us power! Stop asking
						ent.Requesting = {}
						ent.LastRequested = nil
					end
				end
				if ent.NS3Needs != 0 then
					ent.LastRequested = ent.NS3Needs
					ent.Requesting = {Energy = ent.NS3Needs*8, Fuel = ent.NS3Needs}
					if envoxy < 0.12 then ent.Requesting.Oxygen = ent.NS3Needs / 2 end
					ent.NS3Needs = 0
				end
			end)
		end,
		prop_vehicle_prisoner_pod = function(ent)
			ent.Link = ns3_base.Link
			ent.UnLink = ns3_base.UnLink
			ent.StoreCollectResources = ns3_base.StoreCollectResources
			ent.Requesting = {}
			ent.Links = {}
			ent.DaisyLinks = {}
			ent.Receiving = {}
			ent.Priority = 2
			ent.Resources = table.Copy(NS3.Resources)
			if !ent.Environment then ent.Environment = {Resources = table.Copy(NS3.Resources), Max = 2000000} end
			ent.BufferSize = 10

			local timerid = "NS3_Hijack_"..ent:EntIndex()
			timer.Create(timerid,1,0,function()
				if !IsValid(ent) then timer.Destroy(timerid) return end
				ent:StoreCollectResources()
				//local envoxy = (ent.Environment.Resources.Oxygen / ent.Environment.Max)
				ent.Requesting.Energy = ent.BufferSize - ent.Resources.Energy
				ent.Requesting.Oxygen = ent.BufferSize - ent.Resources.Oxygen
				ent.Requesting.Coolant = ent.BufferSize - ent.Resources.Coolant
			end)
			ent.RegulateTemp = ns3_utility.Lists.Regulate.Heat_Regulator
			ent.RegulateAir = ns3_utility.Lists.Regulate.Air_Regulator
		end,
	}
end)
