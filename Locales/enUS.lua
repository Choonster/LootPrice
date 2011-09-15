local L = LibStub("AceLocale-3.0"):NewLocale("LootPrice", "enUS", true)

if not L then return end

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="comment", same-key-is-true=true@

--@do-not-package@--
L["^You receive %a+: |c%w+|Hitem:(%d+).+|rx?(%d-)%.+$"] = true
L["You've looted %n %l, worth %c total."] = true
L["$red$/lootprice|r or $red$/lp command itemId price|r"] = true
L["Slash command usage."] = true
L["$red$spam on||off|r -- Enable/disable price messages when looting an item"] = true
L["$red$add itemId|r -- Adds the item to the LootPrice database, allowing it to record how many you've looted."] = true
L["$red$set itemId X$gold$g$red$Y$silver$s$red$Z$copper$c|r -- Sets the value of the item to the specified amount."] = true
L["$red$reset itemId -- Resets the looted count for the item."] = true
L["$red$display itemId|r -- Displays information for the item."] = true
L["$red$/lootpriceitemid|r or $red$/lpitemid itemLink||itemName|r"] = true
L["Displays the itemId of the given item."] = true
L["$red$Note:|r Using the item's link will always return the correct itemId, but using the item's name may return the wrong itemId if there are multiple items with that name."] = true
L["on"] = true
L["spam"] = true
L["Price messages when looting an item now %s|r."] = true
L["$green$enabled"] = true
L["$red$disabled"] = true
L["add"] = true
L["Added %l (ID %n) to the DB."] = true
L["set"] = true
L["Set the price of %l (ID %n) to %c"] = true
L["reset"] = true
L["display"] = true
L["Displaying information for %l (ID %n)."] = true
L["Looted: %n worth %c total."] = true
L["In bags: %n worth %c total."] = true
L["The itemID of %l is %n."] = true
L["/lootprice"] = true
L["/lp"] = true
L["/lootpriceitemid"] = true
L["/lpitemid"] = true
L["Reset the looted count of %l (ID %n)"] = true
--@end-do-not-package@--