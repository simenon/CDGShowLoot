Player = {}

Player.isCrafting = false
Player.LastLootName = nil
Player.LootList = nil

Color = {
	Green3 = "|c00CD00",
	Red3 = "|CD00000"
}

List = {}

function List.new()
	return {first = 1, last = 0}
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
	if not Player.isCrafting then
		Player.LastLootName, _, _ = GetLootTargetInfo()
		Player.LastLootName = string.gsub(Player.LastLootName,"%^%a","")
	end
end

function CDGSL_LootClosed()
	if not List.empty(Player.LootList) then

		table.sort(Player.LootList, function (a,b) return (a.val < b.val) end) 

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
				
			if l.qty >= 0 then
				msg = msg .. " " .. Color.Green3 .. l.qty .. "|r" .. " " .. l.val
			else
				msg = msg .. " " .. Color.Red3 .. math.abs(l.qty) .. "|r" .. " " .. l.val
			end
			
			
			if not List.empty(Player.LootList) then
				msg = msg .. ","
			end
		end
		
		if Player.LastLootName ~= nil and Player.LastLootName ~= "" then
			--
			-- When you targeted a bookshelf and then go to a crafting station 
			-- it will remain stuck on bookshelf for some odd reason, so override 
			-- in that case
			--
			if Player.isCrafting and Player.LastLootName == "Bookshelf" then
				Player.LastLootName = "crafting station"
			end
			msg = msg .. " from " .. Player.LastLootName .. "."
		end
		d(msg)
	end
	Player.LastLootName = nil
	Player.LootList = List.new()
end

function CDGSL_ChatterEnd()
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

	List.push(Player.LootList, {qty = quantity, val = itemName})	
end

function CDGSL_MoneyUpdate(_, newMoney, oldMoney, _)
	List.push(Player.LootList, {qty = (newMoney - oldMoney), val = "gold"})
end

function CDGSL_CraftingStationInteract()
	Player.isCrafting = true	
end

function CDGSL_EndCraftingStationInteract()
	Player.isCrafting = false
end

function CDGSL_CraftCompleted()
	Player.LastLootName, _, _ = GetLootTargetInfo()
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

	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_CRAFTING_STATION_INTERACT, CDGSL_CraftingStationInteract)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_END_CRAFTING_STATION_INTERACT, CDGSL_EndCraftingStationInteract)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_CRAFT_COMPLETED, CDGSL_CraftCompleted)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_RETICLE_HIDDEN_UPDATE, CDGSL_ReticleHiddenUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_CLOSED, CDGSL_LootClosed)	
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_CHATTER_END, CDGSL_ChatterEnd)

	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_MONEY_UPDATE, CDGSL_MoneyUpdate)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot",EVENT_LOOT_RECEIVED, CDGSL_LootReceived)
end
