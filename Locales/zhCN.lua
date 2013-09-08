if GetLocale() ~= "zhCN" then return end

local _, ns = ...
ns.locales = {}
local L = ns.locales

--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="english", same-key-is-true=true)@