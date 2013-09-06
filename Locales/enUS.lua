if GetLocale() ~= "enUS" then return end

local _, ns = ...
ns.locales = {}
local L = ns.locales

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="comment", same-key-is-true=true)@

--@do-not-package@--
L["$green$enabled"] = true
L["$red$/lootpriceitemid|r or $red$/lpitemid itemLink||itemName|r"] = true
L["$red$/lootprice|r or $red$/lp command itemId price|r"] = true
L["$red$add itemId|r -- Adds the item to the LootPrice database, allowing it to record how many you've looted."] = true
L["$red$all|r (all sessions),"] = true
L["$red$current|r (the current session),"] = true
L["$red$date format|r -- Set the date format to $red$format|r."] = true
L["$red$disabled"] = true
L["$red$display itemId|r -- Displays information for the item."] = true
L["$red$display sessionID|r -- Display information about a session. $red$sessionID|r can be one of the following:"] = true
L["$red$Note:|r Using the item's link will always return the correct itemId, but using the item's name may return the wrong itemId if there are multiple items with that name."] = true
L["$red$previous|r (the most recent previous session),"] = true
L["$red$reset itemId|r -- Resets the looted count for the item."] = true
L["$red$session cmd sessionID|r -- Do various things with sessions. See the individual sub-commands below for details"] = true
L["$red$set itemId X$gold$g$red$Y$silver$s$red$Z$copper$c|r -- Sets the value of the item to the specified amount."] = true
L["$red$spam total||session on||off|r -- Enable/disable price messages when looting an item"] = true
L["$red$start|r -- Start a new session."] = true
L["$red$stop|r -- Stop the current session."] = true
L["%l * %n = %c"] = true
L["%n is not a valid session number."] = true
L["/lootprice"] = true
L["/lootpriceitemid"] = true
L["/lp"] = true
L["/lpitemid"] = true
L["Added %l (ID %n) to the DB."] = true
L["all"] = true
L["Current Session - Started: %s, Current Total: %s"] = true
L["Current Session"] = true
L["current"] = true
L["display"] = true
L["Displaying all sessions."] = true
L["Displaying information for %l (ID %n)."] = true
L["Displays the itemId of the given item."] = true
L["In bags: %n worth %c total."] = true
L["Invalid date specifier(s): %s"] = true
L["Looted: %n worth %c total."] = true
L["New session started."] = true
L["No active session."] = true
L["No previous session."] = true
L["on"] = true
L["or the number of a previous session (1 is the first recorded session, 2 is the one after that, etc.)"] = true
L["Previous Session #%d - Started: %s, Ended: %s, Total: %s"] = true
L["previous"] = true
L["Reset the looted count of %l (ID %n)"] = true
L["Session price messages when looting an item now %s|r."] = true
L["session"] = true
L["Set the price of %l (ID %n) to %c"] = true
L["Slash command usage -"] = true
L["some phrase"] = true
L["start"] = true
L["stop"] = true
L["The default format is \"%m/%d/%Y %H:%M:%S\", which displays the date as \"month/day/year hour:minute:second\" (a common American format). Non-American users may wish to swap %m and %d so the date displays as \"day/month/year ...\" instead."] = true
L["The itemID of %l is %n."] = true
L["This command does some basic checks to warn you about invalid codes, but it may not catch all cases. If you get a Lua error saying \"'date' format too long\", it means your format has one or more invalid codes in it."] = true
L["This format uses special codes starting with a percent sign (%) to display dates and times in various ways. These codes differ for Windows and Mac clients."] = true
L["To see a full list of codes for your client, please follow the links in the AddOn's Curse/WoW Interface description page."] = true
L["Total price messages when looting an item now %s|r."] = true
L["Total"] = true
L["total"] = true
L["^You receive %a+: |c%w+|Hitem:(%d+).+|rx?(%d-)%.+$"] = true
--@end-do-not-package@--