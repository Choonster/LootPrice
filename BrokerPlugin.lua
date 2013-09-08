local addon, ns = ...

-- Lists of globals for Mikk's FindGlobals script
--
-- AddOn globals
-- GLOBALS: LootPrice_DB
--
-- Libraries
-- GLOBALS: LibStub

local PLAY_ICON = [[Interface\AddOns\LootPrice\GreenTriangle]]
local STOP_ICON = [[Interface\AddOns\LootPrice\RedSquare]]

local L = ns.locales
local Session = ns.Session
local prefixprint, tabprint, LocaleSub = ns.prefixprint, ns.tabprint, ns.LocaleSub
local DB

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject(L["LootPrice Broker Display"], { type = "data source", text = "" })

local function Update()
	local currentSession = DB.currentSession
	if currentSession then
		dataobj.text = currentSession:GetBriefDesc("current")
		dataobj.icon = STOP_ICON
	else
		dataobj.text = L["New session"]
		dataobj.icon = PLAY_ICON
	end
end

function ns.BrokerInit()
	DB = LootPrice_DB
	Update()
end

function ns.BrokerUpdate()
	Update()
end

function dataobj.OnTooltipShow(tooltip)
	local currentSession = DB.currentSession
	if currentSession then
		tooltip:SetText(currentSession:GetFullDesc(), 1,1,1,1, true) -- White text with text wrapping
		tooltip:AddLine("\n" .. L["Click to stop the current session"])
	else
		tooltip:SetText(L["Click to start a new session"])
	end
end