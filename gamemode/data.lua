include("static_data.lua")

/*---------------------------------------------------------------------------
MySQL and SQLite connectivity
---------------------------------------------------------------------------*/

--Only attempt to load the module if we're going to use it in the first place.
if RP_MySQLConfig.EnableMySQL and (file.Exists("bin/gmsv_mysqloo_win32.dll", "LUA") or file.Exists("bin/gmsv_mysqloo_linux.dll", "LUA")) then
	require("mysqloo")
end

DB.CONNECTED_TO_MYSQL = false
DB.MySQLDB = nil
DB.Prefix = "ldrp"
local CustomTables = {}
--Sample value: string: "table_name", table: table_columns{"name", "data_type", bool allow_null (default = false), bool is_pk (default = false)}}

--[[---------------------------------------------------------
	DB.DeclareTable - Tells us that a custom table should be
	be made available in the database. This encompasses
	creating the table if it does not exist, as well as
	allowing for reading, adding, deleting, and editing data.
	table_columns follows the structure of the nested table
	in CustomTables as defined above.
	Ex: DB:DeclareTable("cvars, {{name = "var", data_type = "char(20)", allow_null = false, is_pk = true},
	{name = "value", data_type = "INTEGER", allow_null = false, is_pk = false}})
	* Creates the table ldrp_cvars. See below for the SQL code.
	
	CREATE TABLE IF NOT EXISTS ldrp_cvars(var char(20) NOT NULL, value INTEGER NOT NULL, PRIMARY KEY(var));")
-----------------------------------------------------------]]
function DB:DeclareTable(table_name, table_columns)
	table.insert(CustomTables, {["table_name"] = table_name, ["table_columns"] = table_columns})
	GM.WriteOut("Declaring custom table "..table_name, Severity.Debug)
end

--[[---------------------------------------------------------
	DB.RetrieveData - Gets rows from table_name matching filter,
	returning the columns specified in columns.
	Ex: DB:RetrieveData("npcs", "*", nil) --Gets all NPCs.
-----------------------------------------------------------]]
function DB:RetrieveData(table_name, columns, filter, callback)
	local query = "SELECT "..columns.." FROM "..DB.Prefix.."_"..table_name
	if not filter then
		query = query..";"
	else
		query = query.." WHERE "..filter..";"
	end

	DB.Query(query, callback)
end

--[[---------------------------------------------------------
	DB.StoreEntry - Inserts a table of column-value pairs (data) into a
	new row in table_name. Don't forget to sanitize the
	values!
	Ex of data: {var = "flashlight", value = "1"}
-----------------------------------------------------------]]
function DB:StoreEntry(table_name, data)
	local queryvalues = ""
	local columns = ""
	if not istable( data ) then error( "StoreEntry was not passed a table datatype for var data." ) end
	
	table.foreach(data, function(k, v)
		columns = columns .. tostring( k ) .. ", "
		queryvalues = queryvalues .. tostring(v) .. ", "
	end)
	
	queryvalues = string.sub( queryvalues, 1, #queryvalues - 2 ) --Trim the trailing comma and space
	columns = string.sub( columns, 1, #columns - 2 )

	DB.Query("INSERT INTO "..DB.Prefix.."_"..table_name.." ("..columns..") VALUES ("..queryvalues.. ");")
end

--[[---------------------------------------------------------
	DB.DeleteEntry - Remove a row with values matching match
	(used in the WHERE statement) from table_name.
-----------------------------------------------------------]]
function DB:DeleteEntry(table_name, match)
	DB.Query("DELETE FROM "..DB.Prefix.."_"..table_name.." WHERE "..match..";")
end

function DB.Begin()
	if not CONNECTED_TO_MYSQL then sql.Begin() end
end

function DB.Commit(onFinished)
	if not DB.CONNECTED_TO_MYSQL then
		sql.Commit()
		if onFinished then onFinished() end
	else
		if not QueuedQueries then
			error("No queued queries! Call DB.Begin() first!")
		end

		if #QueuedQueries == 0 then
			QueuedQueries = nil
			return
		end

		-- Copy the table so other scripts can create their own queue
		local queue = table.Copy(QueuedQueries)
		QueuedQueries = nil

		-- Handle queued queries in order
		local queuePos = 0
		local call

		-- Recursion invariant: queuePos > 0 and queue[queuePos] <= #queue
		call = function(...)
			queuePos = queuePos + 1

			if queue[queuePos].callback then
				queue[queuePos].callback(...)
			end

			-- Base case, end of the queue
			if queuePos + 1 > #queue then
				if onFinished then onFinished() end -- All queries have finished
				return
			end

			-- Recursion
			local nextQuery = queue[queuePos + 1]
			DB.Query(nextQuery.query, call, nextQuery.onError)
		end

		DB.Query(queue[1].query, call, queue[1].onError)
	end
end

function DB.QueueQuery(sqlText, callback, errorCallback)
	if DB.CONNECTED_TO_MYSQL then
		table.insert(QueuedQueries, {query = sqlText, callback = callback, onError = errorCallback})
	end
	-- SQLite is instantaneous, simply running the query is equal to queueing it
	DB.Query(sqlText, callback, errorCallback)
end

function DB.Query(query, callback)
	if CONNECTED_TO_MYSQL then 
		if DB.MySQLDB and DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED then
			DB.ConnectToMySQL(RP_MySQLConfig.Host, RP_MySQLConfig.Username, RP_MySQLConfig.Password, RP_MySQLConfig.Database_name, RP_MySQLConfig.Database_port)
		end
		
		local query = DB.MySQLDB:query(query)
		local data
		query.onData = function(Q, D)
			data = data or {}
			data[#data + 1] = D
		end
		
		query.onError = function(Q, E) Error(E) callback() DB.Log("MySQL Error: ".. E) end
		query.onSuccess = function()
			if callback then callback(data) end 
		end
		query:start()
		return
	end
	sql.Begin()
	local Result = sql.Query(query)
	sql.Commit() -- Otherwise it won't save, don't ask me why
	if callback then callback(Result) end
	return Result
end

function DB.QueryValue(sqlText, callback, errorCallback)
	if DB.CONNECTED_TO_MYSQL then
		local query = DB.MySQLDB:query(sqlText)
		local data
		query.onData = function(Q, D)
			data = D
		end
		query.onSuccess = function()
			for k,v in pairs(data or {}) do
				callback(v)
				return
			end
			callback()
		end
		query.onError = function(Q, E)
			if (DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED) then
				table.insert(DB.cachedQueries, {sqlText, callback, true})
				return
			end

			if errorCallback then
				errorCallback()
			end

			DB.Log("MySQL Error: ".. E)
			ErrorNoHalt(E .. " (" .. sqlText .. ")\n")
		end

		query:start()
		return
	end

	local lastError = sql.LastError()
	local val = sql.QueryValue(sqlText)
	if sql.LastError() and sql.LastError() ~= lastError then
		error("SQLite error: " .. lastError)
	end

	if callback then callback(val) end
	return val
end

function DB.ConnectToMySQL(host, username, password, database_name, database_port)
	if not mysqloo then Error("MySQL modules aren't installed properly!") DB.Log("MySQL Error: MySQL modules aren't installed properly!") end
	local databaseObject = mysqloo.connect(host, username, password, database_name, database_port)

	databaseObject.onConnectionFailed = function(db, msg)
		DB:Log("MySQL Error: Connection failed! "..msg)
		--Error("Connection failed! " ..tostring(msg))
		GAMEMODE.WriteOut("", Severity.Critical)
	end
	
	databaseObject.onConnected = function()
		DB:Log("MySQL: Connection to external database "..host.." succeeded!")
		DB.CONNECTED_TO_MYSQL = true
		DB.Init() -- Initialize database
	end
	
	DB:Log("Attempting to connect to the MySQL database at "..host.."...")
	databaseObject:connect() 
	DB.MySQLDB = databaseObject
end

function DB.SQLStr(str)
	if not DB.CONNECTED_TO_MYSQL then
		return sql.SQLStr(str)
	end

	return "\"" .. DB.MySQLDB:escape(str) .. "\""
end

/*---------------------------------------------------------
 Database initialize
 ---------------------------------------------------------*/
function DB.Init()
	local map = DB.SQLStr(string.lower(game.GetMap()))
	DB.Begin()
		-- Gotta love the difference between SQLite and MySQL
		local AUTOINCREMENT = DB.CONNECTED_TO_MYSQL and "AUTO_INCREMENT" or "AUTOINCREMENT"

		-- Create the table for the convars used in DarkRP
		DB.Query([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_cvar(
				var VARCHAR(25) NOT NULL PRIMARY KEY,
				value INTEGER NOT NULL
			);
		]])

		-- Table that holds all position data (jail, consoles, zombie spawns etc.)
		-- Queue these queries because other queries depend on the existence of the darkrp_position table
		-- Race conditions could occur if the queries are executed simultaneously
		DB.QueueQuery([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_position(
				id INTEGER NOT NULL PRIMARY KEY ]]..AUTOINCREMENT..[[,
				map VARCHAR(45) NOT NULL,
				type CHAR(1) NOT NULL,
				x INTEGER NOT NULL,
				y INTEGER NOT NULL,
				z INTEGER NOT NULL
			);
		]])

		-- team spawns require extra data
		DB.QueueQuery([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_jobspawn(
				id INTEGER NOT NULL PRIMARY KEY,
				team INTEGER NOT NULL
			);
		]])

		if DB.CONNECTED_TO_MYSQL then
			DB.QueueQuery([[
				ALTER TABLE ]]..DB.Prefix..[[_jobspawn ADD FOREIGN KEY(id) REFERENCES ]]..DB.Prefix..[[_position(id)
					ON UPDATE CASCADE
					ON DELETE CASCADE;
			]])
		end


		-- Consoles have to be spawned in an angle
		DB.QueueQuery([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_console(
				id INTEGER NOT NULL PRIMARY KEY,
				pitch INTEGER NOT NULL,
				yaw INTEGER NOT NULL,
				roll INTEGER NOT NULL,

				FOREIGN KEY(id) REFERENCES ]]..DB.Prefix..[[_position(id)
					ON UPDATE CASCADE
					ON DELETE CASCADE
			);
		]])

		-- Player information
		DB.Query([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_player(
				uid BIGINT NOT NULL PRIMARY KEY,
				rpname VARCHAR(45),
				salary INTEGER NOT NULL DEFAULT 45,
				wallet INTEGER NOT NULL,
				UNIQUE(rpname)
			);
		]])

		-- Door data
		DB.Query([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_door(
				idx INTEGER NOT NULL,
				map VARCHAR(45) NOT NULL,
				title VARCHAR(25),
				isLocked BOOLEAN,
				isDisabled BOOLEAN NOT NULL DEFAULT FALSE,
				PRIMARY KEY(idx, map)
			);
		]])

		-- Some doors are owned by certain teams
		DB.Query([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_jobown(
				idx INTEGER NOT NULL,
				map VARCHAR(45) NOT NULL,
				job INTEGER NOT NULL,

				PRIMARY KEY(idx, map, job)
			);
		]])

		-- Door groups
		DB.Query([[
			CREATE TABLE IF NOT EXISTS ]]..DB.Prefix..[[_doorgroups(
				idx INTEGER NOT NULL,
				map VARCHAR(45) NOT NULL,
				doorgroup VARCHAR(100) NOT NULL,

				PRIMARY KEY(idx, map)
			)
		]])

		-- SQlite doesn't really handle foreign keys strictly, neither does MySQL by default
		-- So to keep the DB clean, here's a manual partial foreign key enforcement
		-- For now it's deletion only, since updating of the common attribute doesn't happen.

		-- MySQL trigger
		if DB.CONNECTED_TO_MYSQL then
			DB.Query("show triggers", function(data)
				-- Check if the trigger exists first
				if data then
					for k,v in pairs(data) do
						if v.Trigger == "JobPositionFKDelete" then
							return
						end
					end
				end

				DB.Query("SHOW PRIVILEGES", function(data)
					if not data then return end

					local found;
					for k,v in pairs(data) do
						if v.Privilege == "Trigger" then
							found = true
							break;
						end
					end

					if not found then return end
					DB.Query([[
						CREATE TRIGGER JobPositionFKDelete
							AFTER DELETE ON ]]..DB.Prefix..[[_position
							FOR EACH ROW
								IF OLD.type = "T" THEN
									DELETE FROM ]]..DB.Prefix..[[_jobspawn WHERE ]]..DB.Prefix..[[_jobspawn.id = OLD.id;
								ELSEIF OLD.type = "C" THEN
									DELETE FROM ]]..DB.Prefix..[[_console WHERE ]]..DB.Prefix..[[_console.id = OLD.id;
								END IF
						;
					]])
				end)
			end)
		else -- SQLite triggers, quite a different syntax
			DB.Query([[
				CREATE TRIGGER IF NOT EXISTS JobPositionFKDelete
					AFTER DELETE ON ]]..DB.Prefix..[[_position
					FOR EACH ROW
					WHEN OLD.type = "T"
					BEGIN
						DELETE FROM ]]..DB.Prefix..[[_jobspawn WHERE ]]..DB.Prefix..[[_jobspawn.id = OLD.id;
					END;
			]])

			DB.Query([[
				CREATE TRIGGER IF NOT EXISTS ConsolePosFKDelete
					AFTER DELETE ON ]]..DB.Prefix..[[_position
					FOR EACH ROW
					WHEN OLD.type = "C"
					BEGIN
						DELETE FROM ]]..DB.Prefix..[[_console WHERE ]]..DB.Prefix..[[_console.id = OLD.id;
					END;
			]])
		end
		
		--Also create custom tables
		for k, v in ipairs(CustomTables) do
			local query = "CREATE TABLE IF NOT EXISTS "..DB.Prefix.."_"..v["table_name"].."("
			for a, b in pairs(v["table_columns"]) do
				query = query..b["name"].." "..b["data_type"]
				if b["allow_null"] == nil or (b["allow_null"] ~= nil and b["allow_null"] == false) then
					query = query.." NOT NULL"
				end
				if (b["is_pk"] ~= nil and b["is_pk"] == true) then
					query = query.." PRIMARY KEY"
				end
				--If we're on the last column, finish the query, otherwise add a comma and space.
				if a == #v["table_columns"] then query = query..");"
					else query = query..", "
				end
			end
			DB.Query(query)
		end
		
	DB.Commit(function() -- Initialize the data after all the tables have been created

		-- Update older version of database to the current database
		-- Only run when one of the older tables exist
		local updateQuery = [[SELECT name FROM sqlite_master WHERE type="table" AND name="]]..DB.Prefix..[[_cvars";]]
		if DB.CONNECTED_TO_MYSQL then
			updateQuery = [[show tables like "]]..DB.Prefix..[[_cvars";]]
		end

		DB.QueryValue(updateQuery, function(data)
			if data == DB.Prefix.."_cvars" then
				print("UPGRADING DATABASE!")
				DB.UpdateDatabase()
			end
		end)

		DB.SetUpNonOwnableDoors()
		DB.SetUpTeamOwnableDoors()
		DB.SetUpGroupDoors()
		DB.LoadConsoles()

		DB.Query("SELECT * FROM "..DB.Prefix.."_cvar;", function(settings)
			for k,v in pairs(settings or {}) do
				RunConsoleCommand(v.var, v.value)
			end
		end)

		DB.JailPos = DB.JailPos or {}
		zombieSpawns = zombieSpawns or {}
		DB.Query([[SELECT * FROM ]]..DB.Prefix..[[_position WHERE type IN('J', 'Z') AND map = ]] .. map .. [[;]], function(data)
			for k,v in pairs(data or {}) do
				if v.type == "J" then
					table.insert(DB.JailPos, v)
				elseif v.type == "Z" then
					table.insert(zombieSpawns, v)
				end
			end

			if table.Count(DB.JailPos) == 0 then
				DB.CreateJailPos()
				return
			end
			if table.Count(zombieSpawns) == 0 then
				DB.CreateZombiePos()
				return
			end

			jail_positions = nil
		end)

		DB.TeamSpawns = {}
		DB.Query("SELECT * FROM "..DB.Prefix.."_position NATURAL JOIN "..DB.Prefix.."_jobspawn WHERE map = "..map..";", function(data)
			if not data or table.Count(data) == 0 then
				DB.CreateSpawnPos()
				return
			end

			team_spawn_positions = nil

			DB.TeamSpawns = data
		end)

		if DB.CONNECTED_TO_MYSQL then -- In a listen server, the connection with the external database is often made AFTER the listen server host has joined,
									--so he walks around with the settings from the SQLite database
			for k,v in pairs(player.GetAll()) do
				local UniqueID = sql.SQLStr(v:UniqueID())
				DB.Query([[SELECT * FROM ]]..DB.Prefix..[[_player WHERE uid = ]].. UniqueID ..[[;]], function(data)
					if not data or not data[1] then return end

					local Data = data[1]
					v:SetDarkRPVar("rpname", Data.rpname)
					v:SetSelfDarkRPVar("salary", Data.salary)
					v:SetDarkRPVar("money", Data.wallet)
				end)
			end
		end
	end)
	
	--The database is ready to go; raise an event to let other functions know
	--we're ready for data processing.
	hook.Call("DatabaseInitialized")
end

/*---------------------------------------------------------------------------
Updating the older database to work with the current version
(copy as much as possible over)
---------------------------------------------------------------------------*/
function DB.UpdateDatabase()
	print("CONVERTING DATABASE")
	-- Start transaction.
	DB.Begin()

	-- CVars
	DB.Query([[DELETE FROM ]]..DB.Prefix..[[_cvar;]])
	DB.Query([[INSERT INTO ]]..DB.Prefix..[[_cvar SELECT v.var, v.value FROM ]]..DB.Prefix..[[_cvars v;]])
	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_cvars;]])

	-- Positions
	DB.Query([[DELETE FROM ]]..DB.Prefix..[[_position;]])

	-- Team spawns
	DB.Query([[INSERT INTO ]]..DB.Prefix..[[_position SELECT NULL, p.map, "T", p.x, p.y, p.z FROM ]]..DB.Prefix..[[_tspawns p;]])
	DB.Query([[
		INSERT INTO ]]..DB.Prefix..[[_jobspawn
			SELECT new.id, old.team FROM ]]..DB.Prefix..[[_position new JOIN ]]..DB.Prefix..[[_tspawns old ON
				new.map = old.map AND new.x = old.x AND new.y = old.y AND new.z = old.Z
			WHERE new.type = "T";
	]])
	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_tspawns;]])

	-- Zombie spawns
	DB.Query([[INSERT INTO ]]..DB.Prefix..[[_position SELECT NULL, p.map, "Z", p.x, p.y, p.z FROM ]]..DB.Prefix..[[_zspawns p;]])
	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_zspawns;]])


	-- Console spawns
	DB.Query([[INSERT INTO ]]..DB.Prefix..[[_position SELECT NULL, p.map, "C", p.x, p.y, p.z FROM ]]..DB.Prefix..[[_consolespawns p;]])
	DB.Query([[
		INSERT INTO ]]..DB.Prefix..[[_console
			SELECT new.id, old.pitch, old.yaw, old.roll FROM ]]..DB.Prefix..[[_position new JOIN ]]..DB.Prefix..[[_consolespawns old ON
				new.map = old.map AND new.x = old.x AND new.y = old.y AND new.z = old.z
			WHERE new.type = "C";
	]])
	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_consolespawns;]])


	-- Jail positions
	DB.Query([[INSERT INTO ]]..DB.Prefix..[[_position SELECT NULL, p.map, "J", p.x, p.y, p.z FROM ]]..DB.Prefix..[[_jailpositions p;]])
	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_jailpositions;]])

	-- Doors
	DB.Query([[DELETE FROM ]]..DB.Prefix..[[_door;]])
	DB.Query([[INSERT INTO ]]..DB.Prefix..[[_door SELECT old.idx - ]] .. game.MaxPlayers() .. [[, old.map, old.title, old.locked, old.disabled FROM ]]..DB.Prefix..[[_doors old;]])

	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_doors;]])
	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_teamdoors;]])
	DB.Query([[DROP TABLE ]]..DB.Prefix..[[_groupdoors;]])

	DB.Commit()


	local count = DB.QueryValue("SELECT COUNT(*) FROM "..DB.Prefix.."_wallets;") or 0
	for i = 0, count, 1000 do -- SQLite selecting limit
		DB.Query([[SELECT ]]..DB.Prefix..[[_wallets.steam, amount, salary, name FROM ]]..DB.Prefix..[[_wallets
			LEFT OUTER JOIN ]]..DB.Prefix..[[_salaries ON ]]..DB.Prefix..[[_salaries.steam = ]]..DB.Prefix..[[_wallets.steam
			LEFT OUTER JOIN ]]..DB.Prefix..[[_rpnames ON ]]..DB.Prefix..[[_rpnames.steam = ]]..DB.Prefix..[[_wallets.steam LIMIT 1000 OFFSET ]]..i..[[;]], function(data)

			-- Separate transaction for the player data
			DB.Begin()

			for k,v in pairs(data or {}) do
				local uniqueID = util.CRC("gm_" .. v.steam .. "_gm")

				DB.Query([[INSERT INTO ]]..DB.Prefix..[[_player VALUES(]]
					..uniqueID..[[,]]
					..((v.name == "NULL" or not v.name) and "NULL" or DB.SQLStr(v.name))..[[,]]
					..((v.salary == "NULL" or not v.salary) and GAMEMODE.Config.normalsalary or v.salary)..[[,]]
					..v.amount..[[);]])
			end

			if count - i < 1000 then -- the last iteration
				DB.Query([[DROP TABLE ]]..DB.Prefix..[[_wallets;]])
				DB.Query([[DROP TABLE ]]..DB.Prefix..[[_salaries;]])
				DB.Query([[DROP TABLE ]]..DB.Prefix..[[_rpnames;]])
			end

			DB.Commit()
		end)
	end
end

/*---------------------------------------------------------
 positions
 ---------------------------------------------------------*/
function DB.CreateSpawnPos()
	local map = string.lower(game.GetMap())
	if not team_spawn_positions then return end

	for k, v in pairs(team_spawn_positions) do
		if v[1] == map then
			DB.StoreTeamSpawnPos(v[2], Vector(v[3], v[4], v[5]))
		end
	end
end

function DB.CreateZombiePos()
	if not zombie_spawn_positions then return end
	local map = string.lower(game.GetMap())

	local once = false
	DB.Begin()
		for k, v in pairs(zombie_spawn_positions) do
			if map == string.lower(v[1]) then
				if not once then
					DB.Query("DELETE FROM "..DB.Prefix.."_zspawns;")
					once = true
				end
				DB.Query("INSERT INTO "..DB.Prefix.."_zspawns VALUES(" .. sql.SQLStr(map) .. ", " .. v[2] .. ", " .. v[3] .. ", " .. v[4] .. ");")
			end
		end
	DB.Commit()
end

function DB.StoreZombies()
	local map = string.lower(game.GetMap())
	DB.Begin()
	DB.Query("DELETE FROM "..DB.Prefix.."_zspawns WHERE map = " .. sql.SQLStr(map) .. ";", function()
		for k, v in pairs(zombieSpawns) do
			local s = string.Explode(" ", v)
			DB.Query("INSERT INTO "..DB.Prefix.."_zspawns VALUES(" .. sql.SQLStr(map) .. ", " .. s[1] .. ", " .. s[2] .. ", " .. s[3] .. ");")
		end
	end)
	DB.Commit()
end

local FirstZombieSpawn = true
function DB.RetrieveZombies(callback)
	if zombieSpawns and table.Count(zombieSpawns) > 0 and not FirstZombieSpawn then callback() return zombieSpawns end
	FirstZombieSpawn = false
	zombieSpawns = {}
	DB.Query("SELECT * FROM "..DB.Prefix.."_zspawns WHERE map = " .. sql.SQLStr(string.lower(game.GetMap())) .. ";", function(r)
		if not r then callback() return end
		for map, row in pairs(r) do
			zombieSpawns[map] = tostring(Vector(row.x, row.y, row.z))
		end
		callback()
	end)
end

function DB.RetrieveRandomZombieSpawnPos()
	if #zombieSpawns < 1 then return end
	local r = string.Explode(" ", table.Random(zombieSpawns))
	r = Vector(r[1], r[2], r[3])
	if not GAMEMODE:IsEmpty(Vector(r.x, r.y, r.z)) then
		local found = false
		for i = 40, 200, 10 do
			if GAMEMODE:IsEmpty(Vector(r.x, r.y, r.z) + Vector(i, 0, 0)) then
				found = true
				return Vector(r.x, r.y, r.z) + Vector(i, 0, 0)
			end
		end
		
		if not found then
			for i = 40, 200, 10 do
				if GAMEMODE:IsEmpty(Vector(r.x, r.y, r.z) + Vector(0, i, 0)) then
					found = true
					return Vector(r.x, r.y, r.z) + Vector(0, i, 0)
				end
			end
		end
		
		if not found then
			for i = 40, 200, 10 do
				if GAMEMODE:IsEmpty(Vector(r.x, r.y, r.z) + Vector(-i, 0, 0)) then
					found = true
					return Vector(r.x, r.y, r.z) + Vector(-i, 0, 0)
				end
			end
		end
		
		if not found then
			for i = 40, 200, 10 do
				if GAMEMODE:IsEmpty(Vector(r.x, r.y, r.z) + Vector(0, -i, 0)) then
					found = true
					return Vector(r.x, r.y, r.z) + Vector(0, -i, 0)
				end
			end
		end
	else
		return Vector(r.x, r.y, r.z)
	end
	
	return Vector(r.x, r.y, r.z) + Vector(0,0,70)        
end

function DB.CreateJailPos()
	if not jail_positions then return end
	local map = string.lower(game.GetMap())

	local once = false
	DB.Begin()
		for k, v in pairs(jail_positions) do
			if map == string.lower(v[1]) then
				if not once then
					DB.Query("DELETE FROM "..DB.Prefix.."_jailpositions;", function()
						DB.Query("INSERT INTO "..DB.Prefix.."_jailpositions VALUES(" .. sql.SQLStr(map) .. ", " .. v[2] .. ", " .. v[3] .. ", " .. v[4] .. ", " .. 0 .. ");")
					end)
					DB.JailPos = {}
					once = true
					return
				end
				DB.Query("INSERT INTO "..DB.Prefix.."_jailpositions VALUES(" .. sql.SQLStr(map) .. ", " .. v[2] .. ", " .. v[3] .. ", " .. v[4] .. ", " .. 0 .. ");")
			end
		end
	DB.Commit()
end

function DB.StoreJailPos(ply, addingPos)
	local map = string.lower(game.GetMap())
	local pos = string.Explode(" ", tostring(ply:GetPos()))
	DB.QueryValue("SELECT COUNT(*) FROM "..DB.Prefix.."_jailpositions WHERE map = " .. sql.SQLStr(map) .. ";", function(already)
		if not already or already == 0 then
			DB.Query("INSERT INTO "..DB.Prefix.."_jailpositions VALUES(" .. sql.SQLStr(map) .. ", " .. pos[1] .. ", " .. pos[2] .. ", " .. pos[3] .. ", " .. 0 .. ");", function()
				DB.Query("SELECT * FROM "..DB.Prefix.."_jailpositions;", function(jailpos) DB.JailPos = jailpos end)
			end)
			Notify(ply, 0, 4,  LANGUAGE.created_first_jailpos)
		else
			if addingPos then
				DB.Query("INSERT INTO "..DB.Prefix.."_jailpositions VALUES(" .. sql.SQLStr(map) .. ", " .. pos[1] .. ", " .. pos[2] .. ", " .. pos[3] .. ", " .. 0 .. ");", function()
					DB.Query("SELECT * FROM "..DB.Prefix.."_jailpositions;", function(jailpos) DB.JailPos = jailpos end)
				end)
				Notify(ply, 0, 4,  LANGUAGE.added_jailpos)
			else
				DB.Begin()
				DB.Query("DELETE FROM "..DB.Prefix.."_jailpositions WHERE map = " .. sql.SQLStr(map) .. ";")
				DB.Query("INSERT INTO "..DB.Prefix.."_jailpositions VALUES(" .. sql.SQLStr(map) .. ", " .. pos[1] .. ", " .. pos[2] .. ", " .. pos[3] .. ", " .. 0 .. ");", function()
					DB.Query("SELECT * FROM "..DB.Prefix.."_jailpositions;", function(jailpos) DB.JailPos = jailpos end)
				end)
				DB.Commit()
				Notify(ply, 0, 5,  LANGUAGE.reset_add_jailpos)
			end
		end
	end)
end

function DB.RetrieveJailPos()
	local map = string.lower(game.GetMap())
	local r = DB.JailPos
	if not r then return Vector(0,0,0) end
	
	-- Retrieve the least recently used jail position
	local now = CurTime()
	local oldest = 0
	local ret
	
	for k, row in pairs(r) do
		if row.map == map and (now - tonumber(row.lastused)) > oldest then
			oldest = (now - tonumber(row.lastused))
			ret = row
		elseif row.map == map and oldest == 0 then
			ret = row
		end
	end
	-- Mark that position as having been used just now
	if ret then DB.Query("UPDATE "..DB.Prefix.."_jailpositions SET lastused = " .. CurTime() .. " WHERE map = " .. sql.SQLStr(map) .. " AND x = " .. ret.x .. " AND y = " .. ret.y .. " AND z = " .. ret.z .. ";", function()
		DB.Query("SELECT * FROM "..DB.Prefix.."_jailpositions;", function(jailpos) DB.JailPos = jailpos end)
	end) end
	return ret and Vector(ret.x, ret.y, ret.z)
end

function DB.SaveSetting(setting, value)
	DB.Query("SELECT value FROM "..DB.Prefix.."_cvars WHERE var = "..sql.SQLStr(setting)..";", function(Data)
		if Data then
			DB.Query("UPDATE "..DB.Prefix.."_cvars set Value = " .. sql.SQLStr(value) .." WHERE var = " .. sql.SQLStr(setting)..";")
		else
			DB.Query("INSERT INTO "..DB.Prefix.."_cvars VALUES("..sql.SQLStr(setting)..","..sql.SQLStr(value)..");")
		end
	end)
end

function DB.CountJailPos()
	return table.Count(DB.JailPos or {})
end

local function FixDarkRPTspawnsTable() -- SQLite only
	local FixTable = sql.Query("SELECT * FROM "..DB.Prefix.."_tspawns;")
	if not FixTable or (FixTable and FixTable[1] and not FixTable[1].id) then -- The old tspawns table didn't have an 'id' column, this checks if the table is out of date
		sql.Query("DROP TABLE IF EXISTS "..DB.Prefix.."_tspawns;") -- Remove the table and remake it
		sql.Query("CREATE TABLE IF NOT EXISTS "..DB.Prefix.."_tspawns(id INTEGER NOT NULL, map TEXT NOT NULL, team INTEGER NOT NULL, x NUMERIC NOT NULL, y NUMERIC NOT NULL, z NUMERIC NOT NULL, PRIMARY KEY(id));")
		for k,v in pairs(FixTable or {}) do -- Put back the old data in the new format so the end user will not notice any changes, if there was nothing in the old table then loop through nothing
			sql.Query("INSERT INTO "..DB.Prefix.."_tspawns VALUES(NULL, "..sql.SQLStr(v.map)..", "..v.team..", "..v.x..", "..v.y..", "..v.z..");")
		end
	end
end

function DB.StoreTeamSpawnPos(t, pos)
	if not CONNECTED_TO_MYSQL then FixDarkRPTspawnsTable() end -- Check if the server doesn't use an out of date version of this table
	local map = string.lower(game.GetMap())
	DB.QueryValue("SELECT COUNT(*) FROM "..DB.Prefix.."_tspawns WHERE team = " .. t .. " AND map = " .. sql.SQLStr(map) .. ";", function(already)
		already = tonumber(already)
		local ID = 0
		local found = false
		for k,v in SortedPairs(DB.TeamSpawns or {}) do 
			if tonumber(v.id) == ID + 1 then
				ID = tonumber(v.id)
				found = true
			else
				ID = ID + 1
				found = false
				break
			end
		end
		if found or ID == 0 then ID = ID + 1 end
		
		if not already or already == 0 then
			DB.Query("INSERT INTO "..DB.Prefix.."_tspawns VALUES(".. ID .. ", ".. sql.SQLStr(map) .. ", " .. t .. ", " .. pos[1] .. ", " .. pos[2] .. ", " .. pos[3] .. ");", function()
				DB.Query("SELECT * FROM "..DB.Prefix.."_tspawns;", function(data) DB.TeamSpawns = data or {} end) end)
			print(string.format(LANGUAGE.created_spawnpos, team.GetName(t)))
		else
			DB.RemoveTeamSpawnPos(t, function() -- Remove everything and create new
				DB.Query("INSERT INTO "..DB.Prefix.."_tspawns VALUES(".. ID .. ", ".. sql.SQLStr(map) .. ", " .. t .. ", " .. pos[1] .. ", " .. pos[2] .. ", " .. pos[3] .. ");", function()
					DB.Query("SELECT * FROM "..DB.Prefix.."_tspawns;", function(data) DB.TeamSpawns = data or {} end) end)
			end)
			print(string.format(LANGUAGE.updated_spawnpos, team.GetName(t)))
		end
	end)
end

function DB.AddTeamSpawnPos(t, pos)
	if not CONNECTED_TO_MYSQL then FixDarkRPTspawnsTable() end -- Check if the server doesn't use an out of date version of this table
	local map = string.lower(game.GetMap())
	local ID = 0
	local found = false
	for k,v in SortedPairs(DB.TeamSpawns or {}) do 
		if tonumber(v.id) == ID + 1 then
			ID = tonumber(v.id)
			found = true
		else
			ID = ID + 1
			found = false
			break
		end
	end
	if found or ID == 0 then ID = ID + 1 end
	
	DB.Query("INSERT INTO "..DB.Prefix.."_tspawns VALUES(".. ID .. ", " .. sql.SQLStr(map) .. ", " .. t .. ", " .. pos[1] .. ", " .. pos[2] .. ", " .. pos[3] .. ");", function()
		DB.Query("SELECT * FROM "..DB.Prefix.."_tspawns;", function(data) DB.TeamSpawns = data or {} end) end)
end

function DB.RemoveTeamSpawnPos(t, callback)
	local map = string.lower(game.GetMap())
	DB.Query("DELETE FROM "..DB.Prefix.."_tspawns WHERE team = "..t..";", function()
		DB.Query("SELECT * FROM "..DB.Prefix.."_tspawns;", function(data) DB.TeamSpawns = data or {} end)
		if callback then callback() end
	end)
end
	
function DB.RetrieveTeamSpawnPos(ply)
	local map = string.lower(game.GetMap())
	local t = ply:Team()
	
	local returnal = {}
	
	if DB.TeamSpawns then
		for k,v in pairs(DB.TeamSpawns) do
			if v.map == map and tonumber(v.team) == t then
				table.insert(returnal, Vector(v.x, v.y, v.z))
			end
		end
		return (table.Count(returnal) > 0 and returnal) or nil
	end
end

/*---------------------------------------------------------
Players 
 ---------------------------------------------------------*/
function DB.StoreRPName(ply, name)
	if not name or string.len(name) < 2 then return end
	ply:SetDarkRPVar("rpname", name)
	DB.QueryValue("SELECT name FROM "..DB.Prefix.."_rpnames WHERE steam = " .. sql.SQLStr(ply:SteamID()) .. ";", function(r)
		if r then
			DB.Query("UPDATE "..DB.Prefix.."_rpnames SET name = " .. sql.SQLStr(name) .. " WHERE steam = " .. sql.SQLStr(ply:SteamID()) .. ";")
		else
			DB.Query("INSERT INTO "..DB.Prefix.."_rpnames VALUES(" .. sql.SQLStr(ply:SteamID()) .. ", " .. sql.SQLStr(name) .. ");")
		end
	end)
end

function DB.RetrievePlayerData(ply, callback, failed, attempts)
	attempts = attempts or 0

	if attempts > 3 then return failed() end

	DB.Query("SELECT rpname, wallet, salary FROM "..DB.Prefix.."_player WHERE uid = " .. ply:UniqueID() .. ";", callback, function()
		DB.RetrievePlayerData(ply, callback, failed, attempts + 1)
	end)
end

function DB.CreatePlayerData(ply, name, wallet, salary)
	DB.Query([[REPLACE INTO ]]..DB.Prefix..[[_player VALUES(]] ..
			ply:UniqueID() .. [[, ]] ..
			DB.SQLStr(name)  .. [[, ]] ..
			salary  .. [[, ]] ..
			wallet .. ");")
end

function DB.RetrieveRPNames(ply, name, callback)
	DB.Query("SELECT COUNT(*) AS count FROM "..DB.Prefix.."_rpnames WHERE name = "..sql.SQLStr(name)..
	" AND steam <> 'UNKNOWN' AND steam <> 'STEAM_ID_PENDING'"..
	" AND steam <> "..sql.SQLStr(ply:SteamID())..";", function(r)
		callback(tonumber(r[1].count) > 0)
	end)
end

function DB.RetrieveRPName(ply, callback)
	DB.QueryValue("SELECT name FROM "..DB.Prefix.."_rpnames WHERE steam = " .. sql.SQLStr(ply:SteamID()) .. ";", callback)
end

function DB.StoreMoney(ply, amount)
	if not IsValid(ply) then return end
	if amount < 0  then return end

	DB.Query([[UPDATE ]]..DB.Prefix..[[_player SET wallet = ]] .. amount .. [[ WHERE uid = ]] .. ply:UniqueID())
end

function DB.ResetAllMoney(ply,cmd,args)
	if not ply:IsSuperAdmin() then return end
	DB.Query("DELETE FROM "..DB.Prefix.."_wallets;")
	for k,v in pairs(player.GetAll()) do
		v:SetDarkRPVar("money", GAMEMODE.Config.startingmoney or 500)
	end
	if ply:IsPlayer() then
		NotifyAll(0,4, string.format(LANGUAGE.reset_money, ply:Nick()))
	else
		NotifyAll(0,4, string.format(LANGUAGE.reset_money, "Console"))
	end
end
concommand.Add("rp_resetallmoney", DB.ResetAllMoney)

function DB.PayPlayer(ply1, ply2, amount)
	if not IsValid(ply1) or not IsValid(ply2) then return end
	ply1:AddMoney(-amount)
	ply2:AddMoney(amount)
end

function DB.StoreSalary(ply, amount)
	ply:SetSelfDarkRPVar("salary", math.floor(amount))

	DB.Query([[UPDATE darkrp_player SET salary = ]] .. amount .. [[ WHERE uid = ]] .. ply:UniqueID())

	return amount
end

function DB.RetrieveSalary(ply, callback)
	if not IsValid(ply) then return 0 end
	local steamID = ply:SteamID()
	local normal = GAMEMODE.Config.normalsalary
	if ply.DarkRPVars.salary then return callback and callback(ply.DarkRPVars.salary) end -- First check the cache.

	DB.QueryValue("SELECT salary FROM "..DB.Prefix.."_salaries WHERE steam = " .. sql.SQLStr(steamID) .. ";", function(r)
		if not r then
			ply:SetDarkRPVar("salary", normal)
			callback(normal)
		else
			callback(r)
		end
	end)
end

/*---------------------------------------------------------
 Doors
 ---------------------------------------------------------*/
function DB.StoreDoorOwnability(ent)
	local map = string.lower(game.GetMap())
	ent.DoorData = ent.DoorData or {}
	local nonOwnable = ent.DoorData.NonOwnable
	DB.QueryValue("SELECT locked FROM "..DB.Prefix.."_doors WHERE map = " .. sql.SQLStr(map) .. " AND idx = " .. ent:EntIndex() .. ";", function(r)
		print(r)
		if r and not nonOwnable then
			DB.Query("UPDATE "..DB.Prefix.."_doors SET disabled = 0 WHERE map = " .. sql.SQLStr(map) .. " AND idx = " .. ent:EntIndex() .. ";")
		elseif nonOwnable then
			DB.Query("REPLACE INTO "..DB.Prefix.."_doors VALUES(" .. sql.SQLStr(map) .. ", " .. ent:EntIndex() .. ", " .. sql.SQLStr(ent.DoorData.title or "") .. ", "..(tobool(r) and 1 or 0)..", 1);")
		end
	end)
end

function DB.StoreNonOwnableDoorTitle(ent, text)
	ent.DoorData = ent.DoorData or {}
	ent.DoorData.title = text
	DB.Query("UPDATE "..DB.Prefix.."_doors SET title = " .. sql.SQLStr(text) .. " WHERE map = " .. sql.SQLStr(string.lower(game.GetMap())) .. " AND idx = " .. ent:EntIndex() .. ";")
end

function DB.SetUpNonOwnableDoors()
	DB.Query("SELECT idx, title, locked, disabled FROM "..DB.Prefix.."_doors WHERE map = " .. sql.SQLStr(string.lower(game.GetMap())) .. ";", function(r)
		if not r then return end

		for _, row in pairs(r) do
			local e = ents.GetByIndex(tonumber(row.idx))
			if IsValid(e) then
				e.DoorData = e.DoorData or {}
				e.DoorData.NonOwnable = tobool(row.disabled)
				e:Fire((tobool(row.locked) and "" or "un").."lock", "", 0)
				e.DoorData.title = row.title
			end
		end
	end)
end

function DB.SetUpTeamOwnableDoors()
	DB.Query("SELECT idx, job FROM "..DB.Prefix.."_jobown WHERE map = " .. DB.SQLStr(string.lower(game.GetMap())) .. ";", function(r)
		if not r then return end

		for _, row in pairs(r) do
			local e = ents.GetByIndex(GAMEMODE:DoorToEntIndex(tonumber(row.idx)))
			if IsValid(e) then
				e.DoorData = e.DoorData or {}
				e.DoorData.TeamOwn = e.DoorData.TeamOwn or ""
				e.DoorData.TeamOwn = (e.DoorData.TeamOwn == "" and row.job) or (e.DoorData.TeamOwn .. "\n" .. row.job)
			end
		end
	end)
end

function DB.StoreGroupDoorOwnability(ent)
	local map = string.lower(game.GetMap())
	ent.DoorData = ent.DoorData or {}
	
	DB.QueryValue("SELECT COUNT(*) FROM "..DB.Prefix.."_groupdoors WHERE map = " .. sql.SQLStr(map) .. " AND idx = " .. ent:EntIndex() .. ";", function(r)
		r = tonumber(r)
		if not r then return end

		if r > 0 and not ent.DoorData.GroupOwn then
			DB.Query("DELETE FROM "..DB.Prefix.."_groupdoors WHERE map = " .. sql.SQLStr(map) .. " AND idx = " .. ent:EntIndex() .. ";")
		elseif r == 0 and ent.DoorData.GroupOwn then
			DB.Query("INSERT INTO "..DB.Prefix.."_groupdoors VALUES(" .. sql.SQLStr(map) .. ", " .. ent:EntIndex() .. ", " .. sql.SQLStr(ent.DoorData.GroupOwn) .. ", " .. sql.SQLStr(ent.DoorData.title or "") .. ");")
		elseif r == 1 then
			DB.Query("UPDATE "..DB.Prefix.."_groupdoors SET teams = "..sql.SQLStr(ent.DoorData.GroupOwn) .. " WHERE map = " .. sql.SQLStr(map) .. " AND idx = " .. ent:EntIndex() .. ";")
		end
	end)
end

function DB.StoreGroupOwnableDoorTitle(ent, text)
	DB.Query("UPDATE "..DB.Prefix.."_groupdoors SET title = " .. sql.SQLStr(text) .. " WHERE map = " .. sql.SQLStr(string.lower(game.GetMap())) .. " AND idx = " .. ent:EntIndex() .. ";")
	e.DoorData = e.DoorData or {}
	ent.DoorData.title = text
end

function DB.SetUpGroupOwnableDoors()
	DB.Query("SELECT idx, title, teams FROM "..DB.Prefix.."_groupdoors WHERE map = " .. sql.SQLStr(string.lower(game.GetMap())) .. ";", function(r)
		if not r then return end

		for _, row in pairs(r) do
			local e = ents.GetByIndex(tonumber(row.idx))
			if IsValid(e) then
				e.DoorData = e.DoorData or {}
				e.DoorData.title = row.title
				e.DoorData.GroupOwn = row.teams
			end
		end
	end)
end

function DB.SetUpGroupDoors()
	local map = DB.SQLStr(string.lower(game.GetMap()))
	DB.Query("SELECT idx, doorgroup FROM "..DB.Prefix.."_doorgroups WHERE map = " .. map, function(data)
		if not data then return end

		for _, row in pairs(data) do
			local ent = ents.GetByIndex(GAMEMODE:DoorToEntIndex(tonumber(row.idx)))

			if not IsValid(ent) then
				continue
			end

			ent.DoorData = ent.DoorData or {}
			ent.DoorData.GroupOwn = row.doorgroup
		end
	end)
end

function DB.LoadConsoles()
	local map = string.lower(game.GetMap())
	DB.Query("SELECT * FROM "..DB.Prefix.."_consolespawns WHERE map = " .. sql.SQLStr(map) .. ";", function(data)
		if data then
			for k, v in pairs(data) do
				local console = ents.Create("darkrp_console")
				console:SetPos(Vector(tonumber(v.x), tonumber(v.y), tonumber(v.z)))
				console:SetAngles(Angle(tonumber(v.pitch), tonumber(v.yaw), tonumber(v.roll)))
				console:Spawn()
				console.ID = v.id
			end
		else -- If there are no custom positions in the database, use the presets.
			for k,v in pairs(RP_ConsolePositions) do
				if v[1] == map then
					local console = ents.Create("darkrp_console")
					console:SetPos(Vector(RP_ConsolePositions[k][2], RP_ConsolePositions[k][3], RP_ConsolePositions[k][4]))
					console:SetAngles(Angle(RP_ConsolePositions[k][5], RP_ConsolePositions[k][6], RP_ConsolePositions[k][7]))
					console:Spawn()
					console:Activate()
					
					console.ID = "0"
				end
			end
		end
	end)
end

function DB.CreateConsole(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end
	
	local tr = {}
	tr.start = ply:EyePos()
	tr.endpos = ply:EyePos() + 95 * ply:GetAimVector()
	tr.filter = ply
	local trace = util.TraceLine(tr)
	
	local console = ents.Create("darkrp_console")
	console:SetPos(trace.HitPos)
	console:Spawn()
	console:Activate()
	
	DB.QueryValue("SELECT MAX(id) FROM "..DB.Prefix.."_consolespawns;", function(Data)
		console.ID = (tonumber(Data) and tostring(tonumber(Data) + 1)) or "1"	
	end)
	
	ply:ChatPrint("Console spawned, move and freeze it to save it!")
end
concommand.Add("rp_CreateConsole", DB.CreateConsole)

function DB.RemoveConsoles(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end
	DB.Query("DELETE FROM "..DB.Prefix.."_consolespawns WHERE map = " .. sql.SQLStr(string.lower(game.GetMap())) .. ";")
end
concommand.Add("rp_removeallconsoles", DB.RemoveConsoles)

/*---------------------------------------------------------
 Logging
 ---------------------------------------------------------*/
function DB.Log(text, force)
	GAMEMODE:WriteOut(text, Severity.Info) --Might consider reducing to debug
	if (not GAMEMODE.Config.logging or not text) and not force then return end
	if not DB.File then -- The log file of this session, if it's not there then make it!
		if not file.IsDir("DarkRP_logs", "DATA") then
			file.CreateDir("DarkRP_logs", "DATA")
		end
		DB.File = "DarkRP_logs/"..os.date("%m_%d_%Y %I_%M %p")..".txt"
		file.Write(DB.File, os.date().. "\t".. text)
		return
	end
	file.Write(DB.File, (file.Read(DB.File) or "").."\n"..os.date().. "\t"..(text or ""))
end