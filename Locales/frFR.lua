if GetLocale() ~= "frFR" then return end

local _, ns = ...
ns.locales = {}
local L = ns.locales

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", same-key-is-true=true)@