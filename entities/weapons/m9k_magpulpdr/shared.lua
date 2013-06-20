-- Variables that are used on both client and server
SWEP.Gun = ("m9k_magpulpdr") -- must be the name of your swep but NO CAPITALS!
SWEP.Category				= "M9K Submachine Guns"
SWEP.Author				= ""
SWEP.Contact				= ""
SWEP.Purpose				= ""
SWEP.Instructions				= ""
SWEP.MuzzleAttachment			= "1" 	-- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment			= "2" 	-- Should be "2" for CSS models or "1" for hl2 models
SWEP.PrintName				= "Magpul PDR"		-- Weapon name (Shown on HUD)	
SWEP.Slot				= 2				-- Slot in the weapon selection menu
SWEP.SlotPos				= 3			-- Position in the slot
SWEP.DrawAmmo				= true		-- Should draw the default HL2 ammo counter
SWEP.DrawWeaponInfoBox			= false		-- Should draw the weapon info box
SWEP.BounceWeaponIcon   		= 	false	-- Should the weapon icon bounce?
SWEP.DrawCrosshair			= true		-- set false if you want no crosshair
SWEP.Weight				= 30			-- rank relative ot other weapons. bigger is better
SWEP.AutoSwitchTo			= true		-- Auto switch to if we pick it up
SWEP.AutoSwitchFrom			= true		-- Auto switch from if you pick up a better weapon
SWEP.HoldType 				= "smg"		-- how others view you carrying the weapon
-- normal melee melee2 fist knife smg ar2 pistol rpg physgun grenade shotgun crossbow slam passive 
-- you're mostly going to use ar2, smg, shotgun or pistol. rpg and crossbow make for good sniper rifles

SWEP.ViewModelFOV			= 70
SWEP.ViewModelFlip			= true
SWEP.ViewModel				= "models/weapons/v_pdr_smg.mdl"	-- Weapon view model
SWEP.WorldModel				= "models/weapons/w_magpul_pdr.mdl"	-- Weapon world model 
SWEP.Base				= "bobs_gun_base"
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true
SWEP.FiresUnderwater = false

SWEP.Primary.Sound			= Sound("MAG_PDR.Single")		-- Script that calls the primary fire sound
SWEP.Primary.RPM			= 575			-- This is in Rounds Per Minute
SWEP.Primary.ClipSize			= 30		-- Size of a clip
SWEP.Primary.DefaultClip		= 60		-- Bullets you start with
SWEP.Primary.KickUp				= 0.3		-- Maximum up recoil (rise)
SWEP.Primary.KickDown			= 0.3		-- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal		= 0.3		-- Maximum up recoil (stock)
SWEP.Primary.Automatic			= true		-- Automatic = true; Semi Auto = false
SWEP.Primary.Ammo			= "smg1"			-- pistol, 357, smg1, ar2, buckshot, slam, SniperPenetratedRound, AirboatGun
-- Pistol, buckshot, and slam always ricochet. Use AirboatGun for a light metal peircing shotgun pellets

SWEP.SelectiveFire		= true

SWEP.Secondary.IronFOV			= 55		-- How much you 'zoom' in. Less is more! 	

SWEP.data 				= {}				--The starting firemode
SWEP.data.ironsights			= 1

SWEP.Primary.NumShots	= 1		-- How many bullets to shoot per trigger pull
SWEP.Primary.Damage		= 30	-- Base damage per bullet
SWEP.Primary.Spread		= .03	-- Define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.IronAccuracy = .02 -- Ironsight accuracy, should be the same for shotguns

-- Enter iron sight info and bone mod info below
SWEP.IronSightsPos = Vector(4.731, 0, 1.08)
SWEP.IronSightsAng = Vector(0.95, -0.26, 0)
SWEP.SightsPos = Vector(4.731, 0, 1.08)
SWEP.SightsAng = Vector(0.95, -0.26, 0)
SWEP.RunSightsPos = Vector(-2.437, -1.364, 1.45)
SWEP.RunSightsAng = Vector(-15.263, -41.1, 0)

SWEP.VElements = {
	["dot"] = { type = "Model", model = "models/hunter/plates/plate1x1.mdl", bone = "wpn_body", rel = "rdot", pos = Vector(0.363, 3.479, 4.423), angle = Angle(90, 90, 0), size = Vector(0.026, 0.026, 0.026), color = Color(255, 255, 255, 255), surpresslightning = true, material = "models/wystan/attachments/doctor/rdot", skin = 0, bodygroup = {} },
	["rdot"] = { type = "Model", model = "models/wystan/attachments/doctorrds.mdl", bone = "wpn_body", rel = "", pos = Vector(0.349, 2.585, -0.419), angle = Angle(0, 180, 0), size = Vector(1.536, 1.536, 1.536), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["docter"] = { type = "Model", model = "models/wystan/attachments/doctorrds.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(-0.419, 0.207, 0.028), angle = Angle(-180, 86.781, -5.77), size = Vector(1.838, 1.838, 1.838), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}