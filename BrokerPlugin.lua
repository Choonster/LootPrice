local addon, ns = ...

local L = ns.locales
local Session = ns.Session
local prefixprint, tabprint, LocaleSub = ns.prefixprint, ns.tabprint, ns.LocaleSub
local DB

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(L["LootPrice Broker Display"], { type = "data source", text = ""})

function ns.BrokerInit()
	DB = LootPrice_DB
end

function ns.BrokerUpdate()

end