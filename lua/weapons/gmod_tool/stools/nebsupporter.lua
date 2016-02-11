TOOL.Category		= "Construction"
TOOL.Name			= "#tool.nebsupporter.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.LastUpdated = 0

TOOL.ClientConVar[ "model" ]		= "models/props_lab/citizenradio.mdl"
TOOL.ClientConVar[ "type" ]		= "Storage"
TOOL.ClientConVar[ "resource" ]		= "Oxygen"
TOOL.ClientConVar[ "doweld" ]		= "0"
TOOL.ClientConVar[ "rotate90" ]		= "0"


if SERVER then
	function TOOL:Hint(msg)
		self:GetOwner():SendLua("GAMEMODE:AddNotify(\""..msg.."\", NOTIFY_GENERIC, 5); surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
	end
end

if CLIENT then
	language.Add( "tool.nebsupporter.name", "NS3 Tool" )
	language.Add( "tool.nebsupporter.desc", "Supports Neb Support 3" )
	language.Add( "tool.nebsupporter.0", "Left click to spawn shit, right click to link shit, reload to break links." )
	language.Add( "tool.nebsupporter.1", "Right click another ent to create the link." )

	language.Add( "Undone_ns3_storage", "Undone NS3 Storage" )
	language.Add( "Undone_ns3_generator", "Undone NS3 Generator" )
	language.Add( "Undone_ns3_utility", "Undone NS3 Utility Device" )
end
cleanup.Register( "ns3_storage" )
cleanup.Register( "ns3_generator" )
cleanup.Register( "ns3_utility" )

function TOOL:LeftClick(trace) return NS3.NebSupporterLC(self, trace) end
function TOOL:RightClick(trace) return NS3.NebSupporterRC(self, trace) end
function TOOL:Reload(trace) return NS3.NebSupporterReload(self, trace) end

if CLIENT then
	function TOOL:DrawHUD() NS3.NebSupporterDrawHUD(self) end
	function TOOL.BuildCPanel(panel) NS3.NebsupporterBuildCPanel(self, panel) end
	function TOOL:Deploy()
		if self.LastUpdated > CurTime() then return end
		self.LastUpdated = CurTime() + 1
		NS3.NebsupporterBuildCPanel(self, controlpanel.Get("nebsupporter"))
	end
end

function TOOL:Think()
	NS3.NebSupporterUpdateGhost(self, self.GhostEntity, self:GetOwner())
end
