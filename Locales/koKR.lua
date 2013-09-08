if GetLocale() ~= "koKR" then return end

local _, ns = ...
ns.locales = {}
local L = ns.locales

--@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="english", same-key-is-true=true)@