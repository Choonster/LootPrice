local addon, ns = ...

-- List of globals for Mikk's FindGlobals script
-- GLOBALS: GetItemCount, GetItemInfo, LootPrice_DB, SLASH_LOOTPRICE1, SLASH_LOOTPRICE2, SLASH_LOOTPRICE_ITEMID1, SLASH_LOOTPRICE_ITEMID2

local print, tonumber, select = print, tonumber, select
local match, gsub, strsub = string.match, string.gsub, string.sub
local concat = table.concat
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
			colourTemp[i] = tostring(select(i, ...)):gsub("%$(%a+)%$", colours)
		end
		return concat(colourTemp, " ", 1, numArgs)
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
		
		return (gsub(str, "%%(%a)", localeTemp))
	end
end

--------------------
-- Implementation --
--------------------
local DB

local Session = {}
Session.__index = function(self, key)
	if rawget(Session, key) then
		return Session[key]
	elseif DB.priceData[key] then
		self[key] = 0
		return 0
	end
end

setmetatable(Session, Session)

function Session:New()
	local currentSession = DB.currentSession
	if currentSession then
		currentSession:Stop()
		currentSession:Archive()
	end
	
	local instance = setmetatable({}, self)
	DB.currentSession = instance
	instance:Start()
	return instance
end

function Session:Start()
	self.startTime = time()
end

function Session:Stop()
	self.endTime = time()
end

function Session:Archive()
	assert(DB.currentSession == self, "Attempt to acrhive an inactive session")
	tinsert(DB.previousSessions, self)
end

-- This should be incremented whenever the structure of the SavedVariable table changes
local DB_VERSION = 1

local function UpgradeDB()
	DB.version = DB.version or 0
	
	if db.version < 1 then
	end
end




local L = ns.locales
for english, localised in pairs(L) do -- `L["some phrase"] = true` becomes `L["some phrase"] = "some phrase"`
	if localised == true then
		L[english] = english
	end
end

local LootPrice = CreateFrame("Frame")
LootPrice:RegisterEvent("ADDON_LOADED")
LootPrice:RegisterEvent("CHAT_MSG_LOOT")

LootPrice:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)



function LootPrice:ADDON_LOADED(name)
	if name ~= addon then return end
	
	LootPrice_DB = LootPrice_DB or {}
	DB = LootPrice_DB
	
	self:UnregisterEvent("ADDON_LOADED")
end

function LootPrice:CHAT_MSG_LOOT(msg, ...)
	local id, amount = match(msg, L["^You receive %a+: |c%w+|Hitem:(%d+).+|rx?(%d-)%.+$"])
	
	id = tonumber(id)
	amount = tonumber(amount) or 1
	
	local data = DB[id]
	if data then
		data.count = data.count + amount
		
		local sessionData = db.currentSession[id]
		if sessionData then
			sessionData.count = sessionData.count + amount
		end
		
		if self.db.spam then
			local coins = data.price * data.count
			local _, link = GetItemInfo(id)
			prefixprint(LocaleSub(L["You've looted %n %l, worth %c total."], link, data.count, coins))
		end
	end
end

------------------
--Slash Commands--
------------------

local function PrintHelp()
	prefixprint(L["Slash command usage."])
	tabprint(1, L["$red$/lootprice|r or $red$/lp command itemId price|r"])
	tabprint(2, L["$red$spam on||off|r -- Enable/disable price messages when looting an item"])
	tabprint(2, L["$red$add itemId|r -- Adds the item to the LootPrice database, allowing it to record how many you've looted."])
	tabprint(2, L["$red$set itemId X$gold$g$red$Y$silver$s$red$Z$copper$c|r -- Sets the value of the item to the specified amount."])
	tabprint(2, L["$red$reset itemId|r -- Resets the looted count for the item."])
	tabprint(2, L["$red$display itemId|r -- Displays information for the item."], "\n")
	tabprint(1, L["$red$/lootpriceitemid|r or $red$/lpitemid itemLink||itemName|r"])
	tabprint(2, L["Displays the itemId of the given item."])
	tabprint(2, L["$red$Note:|r Using the item's link will always return the correct itemId, but using the item's name may return the wrong itemId if there are multiple items with that name."])
end

local function coinToNumber(str)
	return str and tonumber(strsub(str, 1, -2)) or 0
end

local function HandleSlashCommand(msg)
	local cmd, id, rawPrice = msg:lower():match("^%s*(%S+)%s*(%S+)%s*(%S-)%s*$") --Put the message in lower case, trim leading and trailing whitespace and split the message into command, id and price.
	id = tonumber(id) or id
	
	local link
	if id then link = GetItemInfo(id) end
	
	local data = DB[id]
	
	if cmd == L["spam"] and id then -- Enable/disable price message when looting an item
		DB.spam = id == L["on"]
		prefixprint(L["Price messages when looting an item now %s|r."]:format(DB.spam and L["$green$enabled"] or L["$red$disabled"]))
	
	elseif cmd == L["add"] and id then -- Add the item to the DB
		DB[id] = data or {count = 0, price = 0}
		prefixprint(LocaleSub(L["Added %l (ID %n) to the DB."], link, id))	
	
	elseif cmd == L["set"] and id and data and rawPrice then -- Set the price of the item to the given amount
		local g, s, c = rawPrice:match("^(%d-g?)(%d-s?)(%d-c?)$")
		g, s, c = coinToNumber(g), coinToNumber(s), coinToNumber(c)
		
		local copperPrice = g * 10000 + s * 100 + c -- Convert the price to copper
		data.price = copperPrice
		prefixprint(LocaleSub(L["Set the price of %l (ID %n) to %c"], link, id, copperPrice))
		
	elseif cmd == L["reset"] and id and data then
		data.count = 0
		prefixprint(LocaleSub(L["Reset the looted count of %l (ID %n)"], link, id))
		
	elseif cmd == L["display"] and id and DB[id] then -- Display totals for the given item
		local itemPrice = data.price
		local lootCount = data.count
		local bagsCount = GetItemCount(id)
		
		prefixprint(LocaleSub(L["Displaying information for %l (ID %n)."], link, id))
		tabprint(2, LocaleSub( L["Looted: %n worth %c total."], nil, lootCount, itemPrice * lootCount))
		tabprint(2, LocaleSub(L["In bags: %n worth %c total."], nil, bagsCount, itemPrice * bagsCount))

	else -- Display help.
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
		PrintHelp()
	end
end

SLASH_LOOTPRICE1, SLASH_LOOTPRICE2 = L["/lootprice"], L["/lp"]
SlashCmdList.LOOTPRICE = HandleSlashCommand

SLASH_LOOTPRICE_ITEMID1, SLASH_LOOTPRICE_ITEMID2 = L["/lootpriceitemid"], L["/lpitemid"]
SlashCmdList.LOOTPRICE_ITEMID = HandleIDSlashCommand