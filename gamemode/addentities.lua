AddCustomShipment("Explosive Grenade", "models/weapons/w_eq_fraggrenade.mdl", "weapon_real_cs_grenade", 0, 4, true, 850, true, {TEAM_MILITARYGUN})
AddCustomShipment("Smoke Grenade", "models/weapons/w_eq_smokegrenade.mdl", "weapon_real_cs_smoke", 0, 4, true, 700, true, {TEAM_MILITARYGUN})
AddCustomShipment("Flash Grenade", "models/weapons/w_eq_flashbang.mdl", "weapon_real_cs_flash", 0, 4, true, 700, true, {TEAM_MILITARYGUN})

AddCustomShipment("Knife", "models/weapons/w_knife_t.mdl", "weapon_real_cs_knife", 0, 4, true, 300, true, {TEAM_GUN})

AddEntity("Drug lab", "drug_lab", "models/props_lab/crematorcase.mdl", 400, 3, "/buydruglab", {TEAM_GANG, TEAM_MOB})
AddEntity("Money printer", "money_printer", "models/props_c17/consolebox01a.mdl", 1500, 2, "/buymoneyprinter")
AddEntity("Money printer cooler", "cooler", "models/nukeftw/faggotbox.mdl", 300, 2, "/buycooler")
AddEntity("Pot", "pot", "models/nater/weedplant_pot_dirt.mdl", 100, 7, "/buypot")
AddEntity("Gun lab", "gunlab", "models/props_c17/TrapPropeller_Engine.mdl", 1500, 1, "/buygunlab", TEAM_MOB)

/*
How to add custom vehicles:
FIRST
go ingame, type rp_getvehicles for available vehicles!
then:
AddCustomVehicle(<One of the vehicles from the rp_getvehicles list>, <Model of the vehicle>, <Price of the vehicle>, <OPTIONAL jobs that can buy the vehicle>)
Examples:
AddCustomVehicle("Jeep", "models/buggy.mdl", 100 )
AddCustomVehicle("Airboat", "models/airboat.mdl", 600, {TEAM_CUNT})
AddCustomVehicle("Airboat", "models/airboat.mdl", 600, {TEAM_CUNT, TEAM_CUNT2})

Add those lines under your custom shipments. At the bottom of this file or in data/CustomShipments.txt

HOW TO ADD CUSTOM SHIPMENTS:
AddCustomShipment("<Name of the shipment(no spaces)>"," <the model that the shipment spawns(should be the world model...)>", "<the classname of the weapon>", <the price of one shipment>, <how many guns there are in one shipment>, <OPTIONAL: true/false sold seperately>, <OPTIONAL: price when sold seperately>, < true/false OPTIONAL: /buy only = true> , OPTIONAL which classes can buy the shipment, OPTIONAL: the model of the shipment)

Notes:
MODEL: you can go to Q and then props tab at the top left then search for w_ and you can find all world models of the weapons!
CLASSNAME OF THE WEAPON
there are half-life 2 weapons you can add:
weapon_pistol
weapon_smg1
weapon_ar2
weapon_rpg
weapon_crowbar
weapon_physgun
weapon_357
weapon_crossbow
weapon_slam
weapon_bugbait
weapon_frag
weapon_physcannon
weapon_shotgun
gmod_tool

But you can also add the classnames of Lua weapons by going into the weapons/ folder and look at the name of the folder of the weapon you want.
Like the player possessor swep in addons/Player Possessor/lua/weapons You see a folder called weapon_posessor 
This means the classname is weapon_posessor

YOU CAN ADD ITEMS/ENTITIES TOO! but to actually make the entity you have to press E on the thing that the shipment spawned, BUT THAT'S OK!
YOU CAN MAKE GUNDEALERS ABLE TO SELL MEDKITS!

true/false: Can the weapon be sold seperately?(with /buy name) if you want yes then say true else say no

the price of sold seperate is the price it is when you do /buy name. Of course you only have to fill this in when sold seperate is true.


EXAMPLES OF CUSTOM SHIPMENTS(remove the // to activate it): */

--[[AddCustomVehicle( "Pod", "models/vehicles/prisoner_pod_inner.mdl", 125 )
AddCustomVehicle( "Chair_Wood", "models/nova/chair_wood01.mdl", 50 )
AddCustomVehicle( "Chair_Plastic", "models/nova/chair_plastic01.mdl", 60 )
AddCustomVehicle( "Seat_Jeep", "models/nova/jeep_seat.mdl", 70 )
if IsMounted( "ep2" ) then AddCustomVehicle( "Seat_Jalopy", "models/nova/jalopy_seat.mdl", 75 ) end --So garry put in the model, but not the texture?
AddCustomVehicle( "Seat_Airboat", "models/nova/airboat_seat.mdl", 72 )
AddCustomVehicle( "Chair_Office1", "models/nova/chair_office01.mdl", 75 )
AddCustomVehicle( "Chair_Office2", "models/nova/chair_office02.mdl", 95 )
AddCustomVehicle( "phx_seat", "models/props_phx/carseat2.mdl", 85 )

--HL2 vehicles
AddCustomVehicle("Airboat", "models/airboat.mdl", 600, { TEAM_CARDEALER })
AddCustomVehicle("Jeep", "models/buggy.mdl", 350, { TEAM_CARDEALER })
--]]

--EP2 jalopy
if IsMounted( "ep2" ) then AddCustomVehicle( "Jalopy", "models/vehicle.mdl", 500, { TEAM_CARDEALER } ) end

--EXAMPLE OF AN ENTITY(in this case a medkit)
--AddCustomShipment("bball", "models/Combine_Helicopter/helicopter_bomb01.mdl", "sent_ball", 100, 10, false, 10, false, {TEAM_GUN}, "models/props_c17/oildrum001_explosive.mdl")
--EXAMPLE OF A BOUNCY BALL:   		NOTE THAT YOU HAVE TO PRESS E REALLY QUICKLY ON THE BOMB OR YOU'LL EAT THE BALL LOL
--AddCustomShipment("bball", "models/Combine_Helicopter/helicopter_bomb01.mdl", "sent_ball", 100, 10, true, 10, true)
-- ADD CUSTOM SHIPMENTS HERE(next line):

AddCustomShipment("Remington 1858", "models/weapons/w_remington_1858.mdl", "m9k_remington1858", 10000, 10, true, 500, true, {TEAM_GUN})
AddCustomShipment("Glock 18", "models/weapons/w_dmg_glock.mdl", "m9k_glock", 10000, 10, true, 1000, true, {TEAM_GUN})
AddCustomShipment("Beretta M92", "models/weapons/w_beretta_m92.mdl", "m9k_mp5sd", 10000, 10, true, 900, true, {TEAM_GUN})
AddCustomShipment("Vector SMG", "models/weapons/w_kriss_vector.mdl", "m9k_vector", 10000, 10, true, 1500, true, {TEAM_GUN})
AddCustomShipment("MP5 Supressed", "models/weapons/w_hk_mp5sd.mdl", "m9k_mp5sd", 10000, 10, true, 1800, true, {TEAM_GUN})
AddCustomShipment("Honey Badger", "models/weapons/w_aac_honeybadger.mdl", "m9k_honeybadger", 10000, 10, true, 2200, true, {TEAM_GUN})
AddCustomShipment("Benelli M3", "models/weapons/w_benelli_m3.mdl", "m9k_m3", 10000, 10, true, 1300, true, {TEAM_GUN})
AddCustomShipment("Remington 870", "models/weapons/w_remington_870_tact.mdl", "m9k_remington870", 10000, 10, true, 1500, true, {TEAM_GUN})

-- Military Arms Dealer LMGs
AddCustomShipment("Ares Shrike", "models/weapons/w_ares_shrike.mdl", "m9k_ares_shrike", 10000, 10, true, 3000, true, {TEAM_MILITARYGUN})
AddCustomShipment("M249", "models/weapons/w_m249_machine_gun.mdl", "m9k_m249lmg", 10000, 10, true, 2300, true, {TEAM_MILITARYGUN})

-- Military Arms Dealer Shotguns
AddCustomShipment("Winchester 1887", "models/weapons/w_winchester_1887.mdl", "m9k_1887winchester", 10000, 10, true, 1200, true, {TEAM_MILITARYGUN})
AddCustomShipment("USAS", "models/weapons/w_usas_12.mdl", "m9k_usas", 10000, 10, true, 2300, true, {TEAM_MILITARYGUN})
AddCustomShipment("Striker 12", "models/weapons/w_striker_12g.mdl", "m9k_striker12", 10000, 10, true, 1800, true, {TEAM_MILITARYGUN})

-- Military Arms Dealer Snipers
AddCustomShipment("AW50", "models/weapons/w_acc_int_aw50.mdl", "m9k_aw50", 10000, 10, true, 2500, true, {TEAM_MILITARYGUN})
AddCustomShipment("Barret M98B", "models/weapons/w_barrett_m98b.mdl", "m9k_m98b", 10000, 10, true, 2000, true, {TEAM_MILITARYGUN})
AddCustomShipment("Thompson Contender", "models/weapons/w_g2_contender.mdl", "m9k_contender", 10000, 10, true, 1200, true, {TEAM_MILITARYGUN})


AddEntity("Pistol Ammo", "m9k_ammo_pistol", "models/Items/BoxSRounds.mdl", 150, 2, "/buypistolammo")
AddEntity("357 Ammo", "m9k_ammo_357", "models/Items/BoxSRounds.mdl", 175, 2, "/buy357ammo")
AddEntity("SMG Ammo", "m9k_ammo_smg", "models/Items/BoxSRounds.mdl", 225, 2, "/buysmgammo")
AddEntity("A.R. Ammo", "m9k_ammo_ar2", "models/Items/BoxSRounds.mdl", 225, 2, "/buyarammo")
AddEntity("Sniper Ammo", "m9k_ammo_sniper_rounds", "models/Items/BoxSRounds.mdl", 350, 2, "/buysniperammo")
