local Player = {}

function CDGSL_LootReceived(_, _, itemName, quantity, _, _, self)
	if not self then
		return
	end

	itemName = string.gsub(itemName,"%^[pn]","")
	d(string.format("%d %s",quantity,itemName ))
end

function CDGSL_MoneyUpdate(_, newMoney, oldMoney, _)
	d(string.format("%d Gold", newMoney - oldMoney))
end

function CDGSL_OnInitialized()
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_MONEY_UPDATE, CDGSL_MoneyUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_RECEIVED, CDGSL_LootReceived)
end
