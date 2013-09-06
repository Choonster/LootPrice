local addon, ns = ...

-- Lists of globals for Mikk's FindGlobals script
--
-- WoW API functions
-- GLOBALS: GetItemInfo, GetItemCount
--
-- AddOn globals
-- GLOBALS: LootPrice_DB, SLASH_LOOTPRICE1, SLASH_LOOTPRICE2, SLASH_LOOTPRICE_ITEMID1, SLASH_LOOTPRICE_ITEMID2

local tonumber, ipairs, type, pcall = tonumber, ipairs, type, pcall
local strsub, format = string.sub, string.format
local tconcat = table.concat
local date = date

local L = ns.locales
local Session = ns.Session
local prefixprint, tabprint, LocaleSub = ns.prefixprint, ns.tabprint, ns.LocaleSub
local DB

function ns.SlashInit()
	DB = LootPrice_DB
end

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
	tabprint(1, L["$red$date format|r -- Set the date format to $red$format|r."])
	tabprint(2, L["This format uses special codes starting with a percent sign (%) to display dates and times in various ways. These codes differ for Windows and Mac clients."])
	tabprint(2, L["The default format is \"%m/%d/%Y %H:%M:%S\", which displays the date as \"month/day/year hour:minute:second\" (a common American format). Non-American users may wish to swap %m and %d so the date displays as \"day/month/year ...\" instead."])
	tabprint(2, L["This command does some basic checks to warn you about invalid codes, but it may not catch all cases. If you get a Lua error saying \"'date' format too long\", it means your format has one or more invalid codes in it."])
	tabprint(2, L["To see a full list of codes for your client, please follow the links in the AddOn's Curse/WoW Interface description page."])
end

local function PrintIDHelp()
	prefixprint(L["Slash command usage -"], L["$red$/lootpriceitemid|r or $red$/lpitemid itemLink||itemName|r"])
	tabprint(1, L["Displays the itemId of the given item."])
	tabprint(1, L["$red$Note:|r Using the item's link will always return the correct itemId, but using the item's name may return the wrong itemId if there are multiple items with that name."])
end

local function coinToNumber(str)
	return str and tonumber(strsub(str, 1, -2)) or 0
end

local verifyDateFormat
do
	local specifiers = { -- ANSI C strftime conversion specifiers (usable on Windows and Mac)
		a = true, A = true, b = true,
		B = true, c = true, d = true,
		H = true, I = true, j = true,
		m = true, M = true, p = true,
		S = true, U = true, w = true,
		W = true, x = true, X = true,
		y = true, Y = true, Z = true,
		["%"] = true,
	}

	local specifierPattern

	if IsWindowsClient() then -- Windows only adds one specifiers and one optional flag to the standard set.
		specifiers.z = true
		specifierPattern = "(%%#?(%S))"
	elseif IsMacClient() then -- Mac adds specifiers from POSIX, Olson's timezone package, GNU C Library and C99. It also adds several optional flags.
		local S = specifiers
		S["+"], S.B, S.C = true, true, true
		S.D, S.e, S.F = true, true, true
		S.G, S.g, S.h = true, true, true
		S.k, S.l, S.n = true, true, true
		S.O, S.R, S.r = true, true, true
		S.s, S.t, S.T = true, true, true
		S.u, S.V, S.v = true, true, true
		S.X, S.y, S.z = true, true, true
		specifierPattern = "(%%[_0%-%^]?%d*[EO]?(%S))"
	else
		error("Client not recognised as Windows or Mac. Something has gone horribly wrong!")
	end

	local invalidSpecifiers = {}
	function verifyDateFormat(input)
		local numInvalidSpecifiers = 0
		for wholeSpecifier, specifierType in input:gmatch(specifierPattern) do
			if not specifiers[specifierType] then
				numInvalidSpecifiers = numInvalidSpecifiers + 1
				invalidSpecifiers[numInvalidSpecifiers] = wholeSpecifier
			end
		end

		if numInvalidSpecifiers == 0 then
			return pcall(date, input) -- If it looks valid, try to call date() with it.
		else
			return false, format(L["Invalid date specifier(s): %s"], tconcat(invalidSpecifiers, ", ", 1, numInvalidSpecifiers))
		end
	end
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
					session:Display()
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
				if session then
					session:Display()
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
		input = input:trim()

		local valid, errors = verifyDateFormat(input)
		if valid then
			DB.dateFormat = input
		else
			prefixprint(errors)
		end
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