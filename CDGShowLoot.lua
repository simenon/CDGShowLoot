Player = {}
Player.Gold.old = 0
Player.Gold.new = 0
Player.Gold.lastupdate = 0

function CDGSL_LootReceived(_, _, itemName, quantity, _, _, self)
	if not self then
		return
	end

	itemName = string.gsub(itemName,"%^[pn]","")
	d(string.format("%d %s",quantity,itemName ))
end

function CDGSL_MoneyUpdate(_, newMoney, oldMoney, _)
--	d(string.format("%d Gold", newMoney - oldMoney))
end

function CDGSL_OnUpdate()
	local currentGold = GetCurrentMoney()
	if Player.Gold.old ~= currentGold then
		if Player.gold.lastupdate - os.time() > 1 then
			d(string.format("%d Gold",  currentGold - Player.Gold.old))
			Player.gold.lastupdate = os.time()
		end
	end
end

function CDGSL_OnInitialized()
	Player.Gold.old = GetCurrentMoney()
	Player.Gold.new = Player.Gold.old
	Player.Gold.lastupdate = os.time()

	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_MONEY_UPDATE, CDGSL_MoneyUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_RECEIVED, CDGSL_LootReceived)
end
