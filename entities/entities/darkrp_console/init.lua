AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString("darkrp_memory")

function ENT:Initialize()
	self:SetModel("models/props_wasteland/controlroom_monitor001b.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	self:SetUseType(SIMPLE_USE)
	
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then 
		phys:Wake() 
		phys:EnableMotion(false) 
	end
end

function ENT:OnTakeDamage(dmg)
	--Entity can't be damaged.
	return false
end

function ENT:Use(activator, caller)
	if activator:IsCP() and IsValid(self.dt.reporter) then
		local memory = math.random(60, 125)

		net.Start("darkrp_memory")
		net.WriteEntity(self)
		net.WriteBit(true)
		net.WriteUInt(memory, 7) --Max 7 bits (128)
		net.Send(activator)

	elseif not activator:IsCP() then
		GAMEMODE:Notify(activator, 1, 4, "You're not a cop")
	end
end

function ENT:Alarm()
	self.Sound = CreateSound(self, "ambient/alarms/alarm_citizen_loop1.wav")
	self.Sound:Play()
	
	self.dt.alarm = true
	timer.Simple(30, function()
		if self.Sound then self.Sound:Stop() end
		self.dt.alarm = false
		self.dt.reporter = 1
	end)
end

function ENT:PhysgunPickup(ply, ent)
	return ply:IsSuperAdmin()
end

local timeout = 0
function ENT:OnPhysgunFreeze(weapon, phys, ent, ply)
	if CurTime() - timeout < 0.5 then return end
	timeout = CurTime()
	if ply:IsSuperAdmin() then
		local pos = self:GetPos()
		local ang = self:GetAngles()

		local map, x, y, z, pitch, yaw, roll =
			string.lower(game.GetMap()),
			pos.x, pos.y, pos.z,
			ang.p, ang.y, ang.r

		DB.Query("SELECT id FROM "..DB.Prefix.."_position WHERE TYPE = 'C' AND map = " .. DB.SQLStr(map) .. ";", function(data)
			if data then
				for k,v in pairs(data) do
					if tonumber(v.id) == tonumber(self.ID) then
						DB.Query([[UPDATE ]]..DB.Prefix..[[_position SET ]]
						.. "x = " .. DB.SQLStr(x)..", "
						.. "y = " .. DB.SQLStr(y)..", "
						.. "z = " .. DB.SQLStr(z).." "
						.. " WHERE id = "..v.id..";")

						DB.Query([[UPDATE ]]..DB.Prefix..[[_console SET ]]
						.. "pitch = " .. DB.SQLStr(pitch)..", "
						.. "yaw = " .. DB.SQLStr(yaw)..", "
						.. "roll = " .. DB.SQLStr(roll)
						.. " WHERE id = "..v.id..";")

						GAMEMODE:Notify(ply, 0, 4, "CP console position updated!")
						return
					end
				end
			end

			local ID = 0
			local found = false
			for k,v in SortedPairs(data or {}) do
				if k == ID + 1 then
					ID = k
					found = true
				else
					ID = ID + 1
					found = false
					break
				end
			end
			if found or ID == 0 then ID = ID + 1 end
			DB.Query([[INSERT INTO ]]..DB.Prefix..[[_position VALUES(]].. (self.ID or ID) .. [[, ]]
			.. DB.SQLStr(map)..", "
			.."'C', "
			.. DB.SQLStr(x)..", "
			.. DB.SQLStr(y)..", "
			.. DB.SQLStr(z)
			.. ");")

			DB.Query([[INSERT INTO ]]..DB.Prefix..[[_console VALUES(]].. (self.ID or ID) .. [[, ]]
			.. DB.SQLStr(pitch)..", "
			.. DB.SQLStr(yaw)..", "
			.. DB.SQLStr(roll)
			.. ");")

			GAMEMODE:Notify(ply, 0, 4, "CP console position created!")
		end)
	end
end

function ENT:CanTool(ply, trace, tool, ENT)
	if ply:IsSuperAdmin() and tool == "remover" then
		self.CanRemove = true
		DB.Query("DELETE FROM darkrp_consolespawns WHERE id = "..self.ID..";") -- Remove from database if it's there
		GAMEMODE:Notify(ply, 0, 4, "CP console successfully removed!")
		return true
	end
	return false
end