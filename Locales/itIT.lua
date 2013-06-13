if GetLocale() ~= "itIT" then return end

local _, ns = ...
ns.locales = {}
local L = ns.locales

--@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="comment", same-key-is-true=true)@