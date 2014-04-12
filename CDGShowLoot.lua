Player = {}
Player.GoldOld = 0
Player.GoldUpdate = 0

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
	local currentTime = GetTimeStamp()
	if Player.GoldOld ~= currentGold then
		local timeDiff = GetDiffBetweenTimeStamps(currentTime, Player.GoldUpdate)		
		if timeDiff > 1 then
			d(string.format("%d Gold",  currentGold - Player.GoldOld))
			Player.GoldUpdate = currentTime
			Player.GoldOld = currentGold
		end
	end
end

function CDGSL_OnInitialized()
	Player.GoldOld = GetCurrentMoney()
	Player.GoldUpdate = GetTimeStamp()

	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_MONEY_UPDATE, CDGSL_MoneyUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_RECEIVED, CDGSL_LootReceived)
end
