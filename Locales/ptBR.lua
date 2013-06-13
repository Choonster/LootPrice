if GetLocale() ~= "ptBR" then return end

local _, ns = ...
ns.locales = {}
local L = ns.locales

--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="comment", same-key-is-true=true)@