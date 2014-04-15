Player = {}
Player.GoldOld = 0
Player.GoldUpdate = 0
Player.Active = true

Player.LastLootName = ""
Player.LastLootType = 0
Player.LastLootAction = ""

Player.LootList = {}

INTERACT_TARGET_TYPE = {
	[INTERACT_TARGET_TYPE_AOE_LOOT]   = "AOE Loot",
	[INTERACT_TARGET_TYPE_FIXTURE]    = "fixture",
	[INTERACT_TARGET_TYPE_ITEM]       = "Item",
	[INTERACT_TARGET_TYPE_NONE]       = "None",
	[INTERACT_TARGET_TYPE_OBJECT]     = "Object",
	[INTERACT_TARGET_TYPE_QUEST_ITEM] = "Quest item"
}

List = {}

function List.new()
	return {first = 0, last = -1}
end

function List.push(list, value)
	list.last = list.last + 1
	list[list.last] = value
end

function List.pop(list)
	if list.first > list.last then 
		return nil 
	end
	local value = list[list.first]
	list[list.first] = nil
	list.first = list.first + 1
	return value
end

function List.peek(list)
	if list.first > list.last then 
		return nil 
	end
	return list[list.first]
end

function List.empty(list)
	if list.first > list.last then
		return true
	else
		return false
	end
end

function CDGSL_GameCameraUIModeChange()
	Player.LastLootName, Player.LastLootType, Player.LastLootAction = GetLootTargetInfo()
	Player.LastLootName = string.gsub(Player.LastLootName,"%^%a","")
end

function CDGSL_LootClosed()
	if not List.empty(Player.LootList) then

		table.sort(Player.LootList, function (a,b) 
			if a[2] <= b[2] then
				return true
			elseif a[2] > b[2] then
				return false
			end
		end) 

		local msg = "Looted"

		while not List.empty(Player.LootList) do
			local l = List.pop(Player.LootList)
			while not List.empty(Player.LootList) do
				local l_peek = List.peek(Player.LootList)
				if l_peek[1] == l[1] then
					l[1] = l[1] + l_peek[1]
					_ ,_ = List.pop(Player.LootList)
				else
					break
				end
			end
			msg = msg .. " " .. l[1] .. " " .. l[2]
			if not List.empty(Player.LootList) then
				msg = msg .. ","
			end
		end
		d(msg .. " from " .. Player.LastLootName .. ".")
	end
	Player.LastLootName, Player.LastLootType, Player.LastLootAction = "", 0, ""
end

function CDGSL_ChatterBegin()
	CDGSL_LootClosed()
end

function CDGSL_ReticleHiddenUpdate(_, hidden)
	if hidden then CDGSL_GameCameraUIModeChange() end
end

function CDGSL_LootReceived(_, _, itemName, quantity, _, _, self)
	if not self then
		return
	end

	itemName = string.gsub(itemName,"%^%a","")

	List.push(Player.LootList, {quantity,itemName})
	
	if Player.LastLootAction == "" then
		if quantity > 1 then
			d(string.format("Looted %d %s",quantity,itemName))
		else
			d(string.format("Looted %s",itemName))
		end 
	elseif Player.LastLootAction == "Search" and
	       ( Player.LastLootType == INTERACT_TARGET_TYPE_FIXTURE or
		     Player.LastLootType == INTERACT_TARGET_TYPE_OBJECT ) then
		if quantity > 1 then
			d(string.format("Searched %s and found %d %s",string.lower(Player.LastLootName), quantity, itemName))
		else
			d(string.format("Searched %s and found %s ",string.lower(Player.LastLootName), itemName))
		end		
	elseif Player.LastLootAction == "Take" and
		   ( Player.LastLootType == INTERACT_TARGET_TYPE_FIXTURE or 
		     Player.LastLootType == INTERACT_TARGET_TYPE_OBJECT )then
		 if quantity > 1 then
			d(string.format("Took %d %s", quantity, itemName))
		else
			d(string.format("Took %s", itemName))
		end	
	elseif Player.LastLootAction == "Examine" and
		   Player.LastLootType == INTERACT_TARGET_TYPE_OBJECT then
		local text = "Examined " .. Player.LastLootName .. " and found"
		if quantity > 1 then text = text .. " " .. quantity end
		d(text .. " " .. itemName)
	elseif ( Player.LastLootAction == "Collect" or
	         Player.LastLootAction == "Mine" or
		     Player.LastLootAction == "Cut" ) and
		   Player.LastLootType == INTERACT_TARGET_TYPE_OBJECT then
		local text = "Collected"
		if quantity > 1 then text = text .. " " .. quantity end
		d(text .. " " .. itemName .. " from " .. Player.LastLootName)  
	elseif Player.LastLootAction == "Use" and
		   Player.LastLootType == INTERACT_TARGET_TYPE_OBJECT then
		local text = "Used " .. Player.LastLootName .. " and found "
		if quantity > 1 then text = text .. " " .. quantity end
	else 
		d(string.format("CDGShowLoot undefined, please report @ esoui - %d %s from %s type %s action %s",quantity,itemName, Player.LastLootName, INTERACT_TARGET_TYPE[Player.LastLootType], Player.LastLootAction ))
	end
end

function CDGSL_MoneyUpdate(_, newMoney, oldMoney, _)
	List.push(Player.LootList, {(newMoney - oldMoney), "gold"})
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

  Player.LootList = List.new()
	
	--EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_GAME_CAMERA_UI_MODE_CHANGED, CDGSL_GameCameraUIModeChange)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_RETICLE_HIDDEN_UPDATE, CDGSL_ReticleHiddenUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_CLOSED, CDGSL_LootClosed)	
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_CHATTER_BEGIN, CDGSL_ChatterBegin)
	
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_PLAYER_DEACTIVATED, CDGSL_PlayerDeactivated)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_PLAYER_ACTIVATED, CDGSL_PlayerActivated)

	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_MONEY_UPDATE, CDGSL_MoneyUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_RECEIVED, CDGSL_LootReceived)
end
