-- Variables that are used on both client and server
SWEP.Gun = ("m9k_dbarrel") -- must be the name of your swep but NO CAPITALS!
SWEP.Category				= "M9K Shotguns"
SWEP.Author				= ""
SWEP.Contact				= ""
SWEP.Purpose				= ""
SWEP.Instructions				= ""
SWEP.MuzzleAttachment			= "1" 	-- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment			= "2" 	-- Should be "2" for CSS models or "1" for hl2 models
SWEP.PrintName				= "Double Barrel Shotgun"		-- Weapon name (Shown on HUD)	
SWEP.Slot				= 2				-- Slot in the weapon selection menu
SWEP.SlotPos				= 3			-- Position in the slot
SWEP.DrawAmmo				= true		-- Should draw the default HL2 ammo counter
SWEP.DrawWeaponInfoBox			= false		-- Should draw the weapon info box
SWEP.BounceWeaponIcon   		= 	false	-- Should the weapon icon bounce?
SWEP.DrawCrosshair			= true		-- set false if you want no crosshair
SWEP.Weight				= 30			-- rank relative ot other weapons. bigger is better
SWEP.AutoSwitchTo			= true		-- Auto switch to if we pick it up
SWEP.AutoSwitchFrom			= true		-- Auto switch from if you pick up a better weapon
SWEP.HoldType 				= "shotgun"	-- how others view you carrying the weapon
-- normal melee melee2 fist knife smg ar2 pistol rpg physgun grenade shotgun crossbow slam passive 
-- you're mostly going to use ar2, smg, shotgun or pistol. rpg and crossbow make for good sniper rifles

SWEP.ViewModelFOV			= 70
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/v_doublebarrl.mdl"	-- Weapon view model
SWEP.WorldModel				= "models/weapons/w_double_barrel_shotgun.mdl"	-- Weapon world model
SWEP.Base 				= "bobs_shotty_base"
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true

SWEP.Primary.Sound			= Sound("Double_Barrel.Single")		-- script that calls the primary fire sound
SWEP.Primary.RPM				= 180		-- This is in Rounds Per Minute
SWEP.Primary.ClipSize			= 2			-- Size of a clip
SWEP.Primary.DefaultClip		= 30	-- Default number of bullets in a clip
SWEP.Primary.KickUp				= 10				-- Maximum up recoil (rise)
SWEP.Primary.KickDown			= 5		-- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal		= 5	-- Maximum up recoil (stock)
SWEP.Primary.Automatic			= false		-- Automatic/Semi Auto
SWEP.Primary.Ammo			= "buckshot"	-- pistol, 357, smg1, ar2, buckshot, slam, SniperPenetratedRound, AirboatGun
-- Pistol, buckshot, and slam always ricochet. Use AirboatGun for a light metal peircing shotgun pellets

SWEP.Secondary.IronFOV			= 0		-- How much you 'zoom' in. Less is more! 

SWEP.data 				= {}				--The starting firemode
SWEP.data.ironsights			= 1

SWEP.ShellTime			= .5

SWEP.Primary.NumShots	= 18		-- How many bullets to shoot per trigger pull, AKA pellets
SWEP.Primary.Damage		= 10	-- Base damage per bullet
SWEP.Primary.Spread		= .03	-- Define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.IronAccuracy = .03	-- Ironsight accuracy, should be the same for shotguns
-- Because irons don't magically give you less pellet spread!

-- Enter iron sight info and bone mod info below
SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(0, 0, 0)
SWEP.SightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(11.475, -7.705, -2.787)
SWEP.RunSightsAng = Vector(0.574, 51.638, 5.737)

function SWEP:SecondaryAttack()
	if self.Weapon:Clip1() == 2 then
		self.Weapon:PrimaryAttack()
		self.Weapon:SetNextPrimaryFire(CurTime() + .05)
		timer.Simple( 0.05, function() if self.Weapon != nil then self.Weapon:PrimaryAttack() end end )
		//self.Owner:ViewPunch(Angle(-30, math.Rand(-20,-25), 0))
	elseif self.Weapon:Clip1() == 1 then
		self.Weapon:PrimaryAttack()
	elseif self.Weapon:Clip1() == 0 then
		self:Reload()
	end	
end