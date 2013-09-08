if GetLocale() ~= "ruRU" then return end

local _, ns = ...
ns.locales = {}
local L = ns.locales

--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="english", same-key-is-true=true)@