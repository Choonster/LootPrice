local addon, ns = ...

LootPrice = {}
LibStub("ChoonLib-1.0"):Embed(LootPrice, "LootPrice")
local L = LibStub("AceLocale-3.0"):GetLocale("LootPrice")


local str, c
function LocaleSub(string, link, number, copper)	-- Wrapper function for string.gsub to be used on Locale entries.
	str, c = string:gsub(							-- Used instead of string.format to ensure that the proper strings are returned in languages with a different sentence structure to English
			"%%(%a)", 								-- (i.e the subsitutions need to be made in a different order)
			function(arg)
				    if arg == "l" and link   then return link
				elseif arg == "n" and number then return number
				elseif arg == "c" and copper then return GetCoinTextureString(copper)
				else return "%"..arg end
			end)
	return str
end

function LootPrice:ADDON_LOADED(AL, name)
	if name ~= addon then return end
	
	self.db = LootPrice_DB or {}
	LootPrice_DB = self.db
	
	self:UnregisterEvent("ADDON_LOADED")
end
LootPrice:RegisterEvent("ADDON_LOADED")

local id, amount, itemPrice, lootCount, coins, link
function LootPrice:CHAT_MSG_LOOT(CML, msg, ...)
	id, amount = msg:match(L["^You receive %a+: |c%w+|Hitem:(%d+).+|rx?(%d-)%.+$"])
	
	id = tonumber(id)
	amount = tonumber(amount) or 1
	print(id, amount)
	if id and ( self.db[id] ~= nil ) then
		self.db[id].count = self.db[id].count + amount
		LootPrice_DB = self.db
		
		if self.db.spam then
			itemPrice = self.db[id].price
			lootCount = self.db[id].count
			coins = itemPrice * lootCount
			link = select(2,GetItemInfo(id))
			self:Print(LocaleSub(L["You've looted %n %l, worth %c total."], link, lootCount, coins))
		end
	end
end
LootPrice:RegisterEvent("CHAT_MSG_LOOT")


------------------
--Slash Commands--
------------------

function LootPrice:PrintHelp()
	self:Print(L["Slash command usage."])
	self:TPrint(1, L["$red$/lootprice|r or $red$/lp command itemId price|r"])
	self:TPrint(2, L["$red$spam on||off|r -- Enable/disable price messages when looting an item"])
	self:TPrint(2, L["$red$add itemId|r -- Adds the item to the LootPrice database, allowing it to record how many you've looted."])
	self:TPrint(2, L["$red$set itemId X$gold$g$red$Y$silver$s$red$Z$copper$c|r -- Sets the value of the item to the specified amount."])
	self:TPrint(2, L["$red$reset itemId|r -- Resets the looted count for the item."])
	self:TPrint(2, L["$red$display itemId|r -- Displays information for the item."])
	print()
	self:TPrint(1, L["$red$/lootpriceitemid|r or $red$/lpitemid itemLink||itemName|r"])
	self:TPrint(2, L["Displays the itemId of the given item."])
	self:TPrint(2, L["$red$Note:|r Using the item's link will always return the correct itemId, but using the item's name may return the wrong itemId if there are multiple items with that name."])
end

function LootPrice:HandleSlashCommand(msg)
	local cmd, id, rawPrice = strmatch(strlower(msg), "^%s-(%a+)%s-(%w+)%s-(%w-)%s-$") --Put the message in lower case, trim leading and trailing whitespace and split the message into command, id and price.
	
	id = tonumber(id) or id
	local link = id and select(2, GetItemInfo(id)) or ""
	
	if cmd == L["spam"] and id then --Enable/disable price message when looting an item
		self.db.spam = (id == L["on"] and true) or false
		self:Print(L["Price messages when looting an item now %s|r."]:format(self.db.spam and L["$green$enabled"] or L["$red$disabled"]))
		
	elseif cmd == L["add"] and id then --Add the item to the DB
		self.db[id] = self.db[id] or {count = 0, price = 0}
		self:Print(LocaleSub(L["Added %l (ID %n) to the DB."], link, id))
		
	elseif cmd == L["set"] and id and self.db[id] and rawPrice then --Set the price of the item to the given amount
		local g, s, c = strmatch(rawPrice, "^(%d+)g(%d+)s(%d+)c$")
		g, s, c = tonumber(g), tonumber(s), tonumber(c)
		local copperPrice = (((g or 0) * 100) + (s or 0))*100 + (c or 0) --Convert the price to copper
		self.db[id].price = copperPrice
		self:Print(LocaleSub(L["Set the price of %l (ID %n) to %c"], link, id, copperPrice))
		
	elseif cmd == L["reset"] and id and self.db[id] then
		self.db[id].count = 0
		self:Print(LocaleSub(L["Reset the looted count of %l (ID %n)"], link, id))
		
	elseif cmd == L["display"] and id and self.db[id] then --Display totals for the given item
		local itemPrice = self.db[id].price
		local lootCount = self.db[id].count
		local bagsCount = GetItemCount(id)
		
		self:Print(LocaleSub(L["Displaying information for %l (ID %n)."], link, id))
		self:TPrint(2, LocaleSub( L["Looted: %n worth %c total."], nil, lootCount, itemPrice * lootCount))
		self:TPrint(2, LocaleSub(L["In bags: %n worth %c total."], nil, bagsCount, itemPrice * bagsCount))

	else --Display help.
		self:PrintHelp()
	end
	
	LootPrice_DB = self.db
end

function LootPrice:HandleIDSlashCommand(msg) --Returns the id and link of the given item. Takes input in the same format as the /lpitemid slash command.
	local linkOrName = strmatch(msg, "^%s-(.-%w)%s-$")
	local itemLink, itemId

	if strfind(linkOrName, "|H") then --If it's an item link
		itemLink = linkOrName
	else
		itemLink = select(2, GetItemInfo(linkOrName)) or ""
	end
	
	itemId = strmatch(itemLink, "^|c%x+|Hitem:(%d+):.+|h|r$")
	
	if itemId and itemLink ~= "" then
		self:Print(LocaleSub(L["The itemID of %l is %n."], itemLink, itemId))
	else
		self:PrintHelp()
	end
end

SLASH_LOOTPRICE1, SLASH_LOOTPRICE2 = L["/lootprice"], L["/lp"]
SlashCmdList.LOOTPRICE = function(msg)
	LootPrice:HandleSlashCommand(msg)
end

SLASH_LOOTPRICE_ITEMID1, SLASH_LOOTPRICE_ITEMID2 = L["/lootpriceitemid"], L["/lpitemid"]
SlashCmdList.LOOTPRICE_ITEMID = function(msg)
	LootPrice:HandleIDSlashCommand(msg)
end