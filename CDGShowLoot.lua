Player = {}
Player.GoldOld = 0
Player.GoldUpdate = 0
Player.Active = true

function CDGSL_LootReceived(_, _, itemName, quantity, _, _, self)
	if not self then
		return
	end

	itemName = string.gsub(itemName,"%^[pn]","")
	d(string.format("%d %s",quantity,itemName ))
end

function CDGSL_MoneyUpdate(_, newMoney, oldMoney, _)

end

function CDGSL_PlayerDeactivated()
	Player.Active = false
end

function CDGSL_PlayerActivated()
	Player.Active = true
end

function CDGSL_OnUpdate()
	if Player.Active then
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
end

function CDGSL_OnInitialized()
	Player.GoldOld = GetCurrentMoney()
	Player.GoldUpdate = GetTimeStamp()
	
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_PLAYER_DEACTIVATED, CDGSL_PlayerDeactivated)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_PLAYER_ACTIVATED, CDGSL_PlayerActivated)

	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_MONEY_UPDATE, CDGSL_MoneyUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_RECEIVED, CDGSL_LootReceived)
end
