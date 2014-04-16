Player = {}

Player.isCrafting = false

Player.LastLootName = ""
Player.LastLootType = 0
Player.LastLootAction = ""

Player.LootList = {}

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

function List.elements(list)
	return list.last
end

function CDGSL_GameCameraUIModeChange()
	Player.LastLootName, Player.LastLootType, Player.LastLootAction = GetLootTargetInfo()
	Player.LastLootName = string.gsub(Player.LastLootName,"%^%a","")
end

function CDGSL_LootClosed()
	if not List.empty(Player.LootList) then

	  if List.elements(Player.LootList) > 1 then	
			table.sort(Player.LootList, function (a,b) return (a.val < b.val) end) 
		end

		local msg = ""

		while not List.empty(Player.LootList) do
			local l = List.pop(Player.LootList)
			while not List.empty(Player.LootList) do
				local l_peek = List.peek(Player.LootList)
				if l_peek.val == l.val then
					l.qty = l.qty + l_peek.qty
					_ ,_ = List.pop(Player.LootList)
				else
					break
				end
			end
			msg = msg .. " " .. l.qty .. " " .. l.val
			if not List.empty(Player.LootList) then
				msg = msg .. ","
			end
		end
		d(msg .. " from " .. Player.LastLootName .. ".")
	end
	Player.LastLootName, Player.LastLootType, Player.LastLootAction = "", 0, ""
end

function CDGSL_ChatterEnd()
	CDGSL_LootClosed()
end

function CDGSL_ChatterBegin()
end

function CDGSL_ReticleHiddenUpdate(_, hidden)
	if hidden then CDGSL_GameCameraUIModeChange() end
end

function CDGSL_LootReceived(_, _, itemName, quantity, _, _, self)
	if not self then
		return
	end

	itemName = string.gsub(itemName,"%^%a","")

	List.push(Player.LootList, {qty = quantity, val = itemName})	
end

function CDGSL_MoneyUpdate(_, newMoney, oldMoney, _)
	List.push(Player.LootList, {qty = (newMoney - oldMoney), val = "gold"})
end

function CDGSL_PlayerDeactivated()
end

function CDGSL_PlayerActivated()
end

function CDGSL_OnUpdate()
end

function CDGSL_CraftCompleted()
	Player.LastLootName, Player.LastLootType, Player.LastLootAction = GetLootTargetInfo()
	local items = GetNumLastCraftingResultItems()
	local _, bagslots = GetBagInfo(BAG_BACKPACK)
	for i=1, items do
		itemName, _, quantity, _, _, _, _, _, _, _, _ = GetLastCraftingResultItemInfo(i)
		for b=1, bagslots do
			local bagItemName = GetItemName(BAG_BACKPACK, b) 
		
			if (bagItemName == itemName) then 
		
				local itemLink = GetItemLink(BAG_BACKPACK, b, LINK_STYLE_DEFAULT) 
				itemLink = string.gsub(itemLink,"%^%a+","")
				List.push(Player.LootList, {qty = quantity, val = itemLink})
				break
			
			end
		end		
	end
    CDGSL_LootClosed()
end


function CDGSL_OnInitialized()

  Player.LootList = List.new()


	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_CRAFT_COMPLETED, CDGSL_CraftCompleted)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_RETICLE_HIDDEN_UPDATE, CDGSL_ReticleHiddenUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_CLOSED, CDGSL_LootClosed)	
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_CHATTER_BEGIN, CDGSL_ChatterBegin)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_CHATTER_END, CDGSL_ChatterEnd)
	
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_PLAYER_DEACTIVATED, CDGSL_PlayerDeactivated)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_PLAYER_ACTIVATED, CDGSL_PlayerActivated)

	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_MONEY_UPDATE, CDGSL_MoneyUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_RECEIVED, CDGSL_LootReceived)
end
