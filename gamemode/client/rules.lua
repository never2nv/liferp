local RulesCategories = { }

local function addCategory(id, name)
	RulesCategories[id] = {id = id, name = name, labels = {}}
	return id
end

local function addLabel(category, text)
	table.insert(RulesCategories[category].labels, text)
end

function GM:AddRulesLabel(category, text)
	addLabel(category, text)
end

function GM:AddRulesLabels(category, labels)
	if type(labels) == "string" then return self:AddRulesLabel(category, labels) end

	for k,v in pairs(labels) do
		table.insert(RulesCategories[category].labels, v)
	end
end

function GM:AddRulesCategory(id, name)
	addCategory(id, name)
end

function GM:RemoveRulesCategory(id)
	RulesCategories[id] = nil
end

function GM:GetHelpCategories()
	return RulesCategories
end

local RULES_CATEGORY_CHATCMD = 1
local RULES_CATEGORY_CONCMD = 2
local RULES_CATEGORY_ZOMBIE = 3
local RULES_CATEGORY_ADMINCMD = 4
local RULES_CATEGORY_ADMINTOGGLE = 5

addCategory(RULES_CATEGORY_CHATCMD, "Server Rules and Commands")
addCategory(RULES_CATEGORY_CONCMD, "Console Commands")
addCategory(RULES_CATEGORY_ZOMBIE, "Zombie Chat Commands")
addCategory(RULES_CATEGORY_ADMINCMD, "Admin Console Commands")

addLabel(RULES_CATEGORY_CONCMD, "gm_showRules - Toggle Rules menu (bind this to F1 if you haven't already)")
addLabel(RULES_CATEGORY_CONCMD, "gm_showteam - Show door menu")
addLabel(RULES_CATEGORY_CONCMD, "gm_showspare1 - Toggle vote clicker (bind this to F3 if you haven't already)")
addLabel(RULES_CATEGORY_CONCMD, "gm_showspare2 - Job menu(bind this to F4 if you haven't already)")

addLabel(RULES_CATEGORY_ZOMBIE, "/addzombie (creates a zombie spawn)")
addLabel(RULES_CATEGORY_ZOMBIE, "/zombiemax (maximum amount of zombies that can be alive)")
addLabel(RULES_CATEGORY_ZOMBIE, "/removezombie index (removes a zombie spawn, index is the number inside ()")
addLabel(RULES_CATEGORY_ZOMBIE, "/showzombie (shows where the zombie spawns are)")
addLabel(RULES_CATEGORY_ZOMBIE, "/enablezombie (enables zombiemode)")
addLabel(RULES_CATEGORY_ZOMBIE, "/disablezombie (disables zombiemode)")
addLabel(RULES_CATEGORY_ZOMBIE, "/enablestorm (enables meteor storms)")

addLabel(RULES_CATEGORY_CHATCMD, "-=-SERVER RULES-=-")
addLabel(RULES_CATEGORY_CHATCMD, "1. NO PROP BLOCKING OR PUSHING!")
addLabel(RULES_CATEGORY_CHATCMD, "2. NO RANDOM DEATHMATCHING!")
addLabel(RULES_CATEGORY_CHATCMD, "/Rules - Bring up this menu")
addLabel(RULES_CATEGORY_CHATCMD, "/job <Job Name> - Set a custom job")
addLabel(RULES_CATEGORY_CHATCMD, "/w <Message> - Whisper a message")
addLabel(RULES_CATEGORY_CHATCMD, "/y <Message> - Yell a message")
addLabel(RULES_CATEGORY_CHATCMD, "/g <Message> - Group only message")
addLabel(RULES_CATEGORY_CHATCMD, "/pm <Person> <Message> - Private message")
addLabel(RULES_CATEGORY_CHATCMD, "/Channel <1-100> - Set the channel of the radio", 1)
addLabel(RULES_CATEGORY_CHATCMD, "/radio <Message> - Say something through the radio!", 1)
addLabel(RULES_CATEGORY_CHATCMD, "/me <Message> - *name* is doing something!", 1)
addLabel(RULES_CATEGORY_CHATCMD, "/advert <Message> - Advertise!", 1)
addLabel(RULES_CATEGORY_CHATCMD, "/broadcast <Message> - Broadcast a message as mayor!", 1)
addLabel(RULES_CATEGORY_CHATCMD, "//, or /a, or /ooc - Out of Character speak", 1)
addLabel(RULES_CATEGORY_CHATCMD, "/x to close a Rules dialog", 1)
addLabel(RULES_CATEGORY_CHATCMD, "/pm <Name/Partial Name> <Message> - Send another player a PM.")
addLabel(RULES_CATEGORY_CHATCMD, "")
addLabel(RULES_CATEGORY_CHATCMD, "Letters - Press use key to read a letter. Look away and press use key again to stop reading a letter.")
addLabel(RULES_CATEGORY_CHATCMD, "/write <Message> - Write a letter in handwritten font. Use // to go down a line.")
addLabel(RULES_CATEGORY_CHATCMD, "/type <Message> - Type a letter in computer font. Use // to go down a line.")
addLabel(RULES_CATEGORY_CHATCMD, "")
addLabel(RULES_CATEGORY_CHATCMD, "/give <Amount> - Give a money amount")
addLabel(RULES_CATEGORY_CHATCMD, "/moneydrop or /dropmoney <Amount> - Drop a money amount")
addLabel(RULES_CATEGORY_CHATCMD, "")
addLabel(RULES_CATEGORY_CHATCMD, "/title <Name> - Give a door you own, a title")
addLabel(RULES_CATEGORY_CHATCMD, "/addowner or ao <Name> - Allow another to player to own your door")
addLabel(RULES_CATEGORY_CHATCMD, "/removeowner <Name> - Remove an owner from your door")
addLabel(RULES_CATEGORY_CHATCMD, "")
addLabel(RULES_CATEGORY_CHATCMD, "/cr <Message> - Request the CP's assistance")
addLabel(RULES_CATEGORY_CHATCMD, "/911 - Call 911 (when you're attacked by a person)")
addLabel(RULES_CATEGORY_CHATCMD, "/report - Call 911 for an illegal entity (you have to be looking at an entity)")

-- concommand Rules labels
addLabel(RULES_CATEGORY_ADMINCMD, "rp_own - Own the door you're looking at.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_unown - Remove ownership from the door you're looking at.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_addowner [Nick|SteamID|UserID] - Add a co-owner to the door you're looking at.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_removeowner [Nick|SteamID|UserID] - Remove co-owner from door you're looking at.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_lock - Lock the door you're looking at.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_unlock - Unlock the door you're looking at.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_tell [Nick|SteamID|UserID] <Message> - Send a noticeable message to a named player.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_removeletters [Nick|SteamID|UserID] - Remove all letters for a given player (or all if none specified).")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_arrest [Nick|SteamID|UserID] <Length> - Arrest a player for a custom amount of time.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_unarrest [Nick|SteamID|UserID] - Unarrest a player.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_setmoney [Nick|SteamID|UserID] <Amount> - Set a player's money to a specific amount.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_setsalary [Nick|SteamID|UserID] <Amount> - Set a player's Roleplay Salary.")
addLabel(RULES_CATEGORY_ADMINCMD, "rp_setname [Nick|SteamID|UserID] <Name> - Set a player's RP name.")