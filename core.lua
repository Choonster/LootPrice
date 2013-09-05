local addon, ns = ...

-- List of globals for Mikk's FindGlobals script
-- GLOBALS: GetItemCount, GetItemInfo, LootPrice_DB, SLASH_LOOTPRICE1, SLASH_LOOTPRICE2, SLASH_LOOTPRICE_ITEMID1, SLASH_LOOTPRICE_ITEMID2

local print, tonumber, select = print, tonumber, select
local match, gsub, strsub = string.match, string.gsub, string.sub
local tconcat = table.concat
local time = time

-----------------------
-- Utility functions --
-----------------------

local prefixprint, tabprint
do
	local prefix = "|cff33ff99" .. addon .. "|r:"

	local colours = {
		red = "|cffff0000",
		cyan = "|cff33ff99",
		green = "|cff00ff00",
		blue = "|cff0000ff",
		gold = "|cffffd800",
		silver = "|cffb0b0b0",
		copper = "|cff9a4f29",
	}
	
	local colourTemp = {}
	local function coloursub(...)
		local numArgs = select("#", ...)
		for i = 1, numArgs do
			colourTemp[i] = gsub(tostring(select(i, ...)), "%$(%S-)%$", colours)
		end
		return tconcat(colourTemp, " ", 1, numArgs)
	end
	
	function prefixprint(...)
		print(prefix, coloursub(...))
	end
	
	local tabs = setmetatable({}, { -- Auto-generated indentation strings. For any integer index n, returns a string of n*4 spaces.
		__index = function(self, indent)
			local str = ("    "):rep(indent)
			self[indent] = str
			return str
		end
	})
		
	function tabprint(indent, ...)
		print(tabs[indent], coloursub(...))
	end
end



-- Wrapper function for string.gsub to be used on locale entries.
-- Used instead of string.format to ensure that the proper strings are returned in languages with a different sentence structure to English
-- (i.e the subsitutions need to be made in a different order)
local LocaleSub
do 
	local localeTemp = {}
	function LocaleSub(str, link, number, copper)
		localeTemp.l = link or "<no link>"
		localeTemp.n = number or "<no number>"
		localeTemp.c = copper and GetCoinTextureString(copper) or "<no copper>"
		
		return (gsub(str, "%%(%S)", localeTemp))
	end
end

--------------------
-- Implementation --
--------------------
local DB

local Session = {}
Session.__index = Session
setmetatable(Session, Session)

local sessionTotalsMT = {
	__index = function(totals, id)
		if DB.priceData[id] then
			totals[id] = 0
			return 0
		end
	end
}

function Session:New()
	local currentSession = DB.currentSession
	if currentSession then
		currentSession:Stop()
	end
	
	local instance = setmetatable({
		isCurrentSession = true,
		startTime = time(),
		totals = setmetatable({}, sessionTotalsMT)
	}, Session)
	
	DB.currentSession = instance
	
	return instance
end

function Session:Stop()
	assert(self.isCurrentSession, "Attempt to stop an inactive session")
	self.endTime = time()
	self.isCurrentSession = false
	setmetatable(self.totals, nil) -- Don't dynamically return 0 for known IDs when the session finishes
	tinsert(DB.previousSessions, self)
end

function Session:GetTotal()
	local total = 0
	for id, count in pairs(self.totals) do
		total = total + (DB.priceData[id].price * count)
	end
	return total
end

function Session:GetBriefDesc(sessionID)
	if sessionID == "current" then
		return format(L["Current Session - Started: %s, Current Total: %s"], date(DB.dateFormat, self.startTime), GetCoinTextureString(self:GetTotal()))
	else
		return format(L["Previous Session #%d - Started: %s, Ended: %s, Total: %s"], date(DB.dateFormat, self.startTime), date(DB.dateFormat, self.endTime), GetCoinTextureString(self:GetTotal()))
	end	
end

do
	local temp = {}
	function Session:GetFullDesc(sessionID)
		temp[1] = self:GetBriefDesc(sessionID)
		
		local lines = 1
		for id, total in pairs(self.totals) do
			lines = lines + 1
			local _, link = GetItemInfo(id)
			temp[lines] = "    " .. LocaleSub(L["%l * %n = %c"], link, total, total * DB.priceData[id].price)
		end
		
		return tconcat(temp, 1, lines)
	end
end

function Session:DisplayBrief(sessionID)
	prefixprint(self:GetBriefDesc(sessionID))
end

function Session:Display(sessionID)
	prefixprint(self:GetFullDesc(sessionID))
end

local function UpgradeDB()
	DB.version = DB.version or 0
	
	if DB.version < 1 then
		DB.version = 1
		
		DB.priceData = {}
		for itemID, data in pairs(DB) do -- Move all the price data to the new priceData subtable
			if type(itemID) == "number" then
				DB.priceData[itemID] = data
				DB[itemID] = nil
			end
		end
		
		DB.totalSpam = DB.spam
		DB.spam = nil
		DB.sessionSpam = true
		DB.dateFormat = "%c"
	end
end

local L = ns.locales
for english, localised in pairs(L) do -- `L["some phrase"] = true` becomes `L["some phrase"] = "some phrase"`
	if localised == true then
		L[english] = english
	end
end
setmetatable(L, { -- Make it easier to tell when we're missing localisation for a phrase
	__index = function(L, phrase)
		error(("Attempt to localise phrase %q"):format(phrase), 2)
	end
})

local LootPrice = CreateFrame("Frame")
LootPrice:RegisterEvent("ADDON_LOADED")
LootPrice:RegisterEvent("CHAT_MSG_LOOT")
LootPrice:RegisterEvent("PLAYER_LOGOUT")

LootPrice:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function LootPrice:ADDON_LOADED(name)
	if name ~= addon then return end
	
	LootPrice_DB = LootPrice_DB or {}
	DB = LootPrice_DB
	
	UpgradeDB()
	for id, session in DB.previousSessions do
		-- WoW's SavedVariables system only saves the tables themselves, so we need to set the metatable of the previous session tables to use Session methods on them
		setmetatable(session, Session)
	end
	
	self:UnregisterEvent("ADDON_LOADED")
end

function LootPrice:PLAYER_LOGOUT()
	local currentSession = DB.currentSession
	if currentSession then
		currentSession:Stop()
	end
end

function LootPrice:CHAT_MSG_LOOT(msg, ...)
	local id, amount = match(msg, L["^You receive %a+: |c%w+|Hitem:(%d+).+|rx?(%d-)%.+$"])
	
	id = tonumber(id)
	amount = tonumber(amount) or 1
	
	local data = DB.priceData[id]
	if data then
		data.count = data.count + amount
		
		local sessionData = DB.currentSession and DB.currentSession.totals[id]
		if sessionData then
			sessionData.count = sessionData.count + amount
			
			if DB.sessionSpam then
				local coins = sessionData.price * sessionData.count
				local _, link = GetItemInfo(id)
				prefixprint(L["Current Session"], "-", LocaleSub(L["%l * %n = %c"], link, data.count, coins))
			end
		end
		
		if DB.totalSpam then
			local coins = data.price * data.count
			local _, link = GetItemInfo(id)
			prefixprint(L["Total"], "-", LocaleSub(L["%l * %n = %c"], link, data.count, coins))
		end
	end
end

------------------
--Slash Commands--
------------------

local function PrintHelp()
	prefixprint(L["Slash command usage -"], L["$red$/lootprice|r or $red$/lp command itemId price|r"])
	tabprint(1, L["$red$spam total||session on||off|r -- Enable/disable price messages when looting an item"])
	tabprint(1, L["$red$add itemId|r -- Adds the item to the LootPrice database, allowing it to record how many you've looted."])
	tabprint(1, L["$red$set itemId X$gold$g$red$Y$silver$s$red$Z$copper$c|r -- Sets the value of the item to the specified amount."])
	tabprint(1, L["$red$reset itemId|r -- Resets the looted count for the item."])
	tabprint(1, L["$red$display itemId|r -- Displays information for the item."])
	tabprint(1, L["$red$session cmd sessionID|r -- Do various things with sessions. See the individual sub-commands below for details"])
	tabprint(2, L["$red$start|r -- Start a new session."])
	tabprint(2, L["$red$stop|r -- Stop the current session."])
	tabprint(2, L["$red$display sessionID|r -- Display information about a session. $red$sessionID|r can be one of the following:"])
	tabprint(3, L["$red$current|r (the current session),"])
	tabprint(3, L["$red$previous|r (the most recent previous session),"])
	tabprint(3, L["$red$all|r (all sessions),"])
	tabprint(3, L["or the number of a previous session (1 is the first recorded session, 2 is the one after that, etc.)"])
end

local function PrintIDHelp()
	prefixprint(L["Slash command usage -"], L["$red$/lootpriceitemid|r or $red$/lpitemid itemLink||itemName|r"])
	tabprint(2, L["Displays the itemId of the given item."])
	tabprint(2, L["$red$Note:|r Using the item's link will always return the correct itemId, but using the item's name may return the wrong itemId if there are multiple items with that name."])
end

local function coinToNumber(str)
	return str and tonumber(strsub(str, 1, -2)) or 0
end

local handlers = {
	-- Slash command handlers receive arguments (id, rawPrice, link, data, input) and return true if help text should be displayed with PrintHelp.

	[L.spam] = function(which, setting, _, _, _)
		if which == L["total"] then
			DB.totalSpam = setting == L["on"]
			prefixprint(L["Total price messages when looting an item now %s|r."]:format(DB.totalSpam and L["$green$enabled"] or L["$red$disabled"]))
		elseif which == L["session"] then
			DB.sessionSpam = setting == L["on"]
			prefixprint(L["Session price messages when looting an item now %s|r."]:format(DB.sessionSpam and L["$green$enabled"] or L["$red$disabled"]))
		else
			return true
		end
	end,
	
	[L.add] = function(id, _, link, data, _)
		DB.priceData[id] = data or {count = 0, price = 0}
		prefixprint(LocaleSub(L["Added %l (ID %n) to the DB."], link, id))
	end,
	
	[L.set] = function(id, rawPrice, link, data, _)
		if not (rawPrice and link and data) then return true end
		
		local g, s, c = rawPrice:match("^(%d-g?)(%d-s?)(%d-c?)$")
		g, s, c = coinToNumber(g), coinToNumber(s), coinToNumber(c)
		
		local copperPrice = g * 10000 + s * 100 + c -- Convert the price to copper
		data.price = copperPrice
		prefixprint(LocaleSub(L["Set the price of %l (ID %n) to %c"], link, id, copperPrice))
	end,
	
	[L.reset] = function(id, _, link, data, _)
		if not (link and data) then return true end
		
		data.count = 0
		prefixprint(LocaleSub(L["Reset the looted count of %l (ID %n)"], link, id))
	end,
	
	[L.display] = function(id, _, link, data, _)
		if not (link and data) then return true end
		
		local itemPrice, lootCount, bagsCount = data.price, data.count, GetItemCount(id)
		prefixprint(LocaleSub(L["Displaying information for %l (ID %n)."], link, id))
		tabprint(2, LocaleSub(L["Looted: %n worth %c total."], nil, lootCount, itemPrice * lootCount))
		tabprint(2, LocaleSub(L["In bags: %n worth %c total."], nil, bagsCount, itemPrice * bagsCount))
	end,
	
	[L.session] = function(cmd, sessionID, _, _, _)
		if not (cmd and sessionID) then return true end
		
		local currentSession = DB.currentSession
		if cmd == L["start"] then
			Session:New()
			prefixprint(L["New session started."])
		elseif cmd == L["stop"] then
			if currentSession then
				currentSession:Stop()
			else
				prefixprint(L["No active session."])
			end
		elseif cmd == L["display"] then
			if sessionID == L["current"] then
				if currentSession then
					currentSession:Display()
				else	
					prefixprint(L["No active session."])
				end
			elseif sessionID == L["previous"] then
				local session = DB.previousSessions[#DB.previousSessions]
				if session then
					previousSession:Display()
				else
					prefixprint(L["No previous session."])
				end
			elseif sessionID == L["all"] then
				prefixprint(L["Displaying all sessions."])
				currentSession:DisplayBrief("current")
				local previousSessions = DB.previousSessions
				for id, session in ipairs(previousSessions) do
					session:DisplayBrief(id)
				end
			elseif type(sessionID) == "number" then
				local session = DB.previousSessions[sessionID]
				if previousSession then
					previousSession:Display()
				else
					prefixprint(LocaleSub(L["%n is not a valid session number."], nil, sessionID, nil))
				end
			else
				return true
			end
		else
			return true
		end
	end,
	
	[L.date] = function(_, _, _, _, input)
		
	end,
}

local function HandleSlashCommand(input)
	local cmd, id, rawPrice = input:lower():match("^%s*(%S+)%s*(%S+)%s*(%S-)%s*$") -- Put the message in lower case, trim leading and trailing whitespace and split the message into command, id and price.
	id = tonumber(id) or id
	
	local link, data
	if type(id) == "number" then
		link = GetItemInfo(id)
		data = DB.priceData[id]
	end
	
	local printHelp = false
	local handler = handlers[cmd]
	if handler and id then
		printHelp = handler(id, rawPrice, link, data, input)
	else
		printHelp = true
	end
	
	if printHelp then
		PrintHelp()
	end
end

local function HandleIDSlashCommand(msg) -- Returns the id and link of the given item. Takes input in the same format as the /lpitemid slash command.
	local itemLink = msg:match("^%s*(.-)%s*$")
	
	if not itemLink:find("|H") then -- If this is an item name, get the link from GetItemInfo
		local _
		_, itemLink = GetItemInfo(itemLink)
		itemLink = itemLink or ""
	end
	
	local itemID = itemLink:match("^|c%x+|Hitem:(%d+):.+|h|r$")
	
	if itemID and itemLink ~= "" then
		prefixprint(LocaleSub(L["The itemID of %l is %n."], itemLink, itemID))
	else
		PrintIDHelp()
	end
end

SLASH_LOOTPRICE1, SLASH_LOOTPRICE2 = L["/lootprice"], L["/lp"]
SlashCmdList.LOOTPRICE = HandleSlashCommand

SLASH_LOOTPRICE_ITEMID1, SLASH_LOOTPRICE_ITEMID2 = L["/lootpriceitemid"], L["/lpitemid"]
SlashCmdList.LOOTPRICE_ITEMID = HandleIDSlashCommand