AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	local b = LDRP_SH.AllItems[self.ItemType]
	if !b then self:Remove() return end
	
	if b.fakemdl then
		local Fake = ents.Create("prop_physics")
		Fake:SetModel(b.mdl);
		Fake:SetParent(self)
		Fake:SetPos(self:GetPos())
		Fake:SetAngles(self:GetAngles())
		Fake:SetMaterial(b.mat)
		Fake:SetColor(b.clr)
		
		self.Fake = Fake
		self:SetColor(0,0,0,0)
		self:SetModel(b.fakemdl)
	else
		self:SetColor(b.clr)
		self:SetMaterial(b.mat)
		self:SetModel(b.mdl)
	end
	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetAngles(Angle(0, math.random(1, 360), 0));
	
	
	local phys = self:GetPhysicsObject()
	if phys and phys:IsValid() then phys:Wake() end
	
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end

function ENT:Use(ply, caller)
	if ply:CanCarry(self.ItemType, 1) then
		self:Remove()
		ply:AddItem(self.ItemType, 1)
		ply:LiquidChat("GAME", Color(0,200,200), "Picked up a " .. self.ItemType .. ".")
	else
		ply:LiquidChat("GAME", Color(0,200,200), "You need to free up inventory space before picking this up.")
	end
end

function ENT:OnRemove()
	if self.Fake then self.Fake:Remove() end
end