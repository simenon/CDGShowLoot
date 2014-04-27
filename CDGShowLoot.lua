local CDGSL = ZO_Object:Subclass()
local delayedHide = false

Player = { logging = {} }

Player.isCrafting = false
Player.LastLootName = nil
Player.LootList = nil


Color = {
	Green3 = "|c00CD00",
	Red3 = "|CD00000"
}

savedVars_CDGShowLoot = nil
savedVars_CDGLibGui = nil

SLASH_COMMANDS["/cdg"] = function (option)

	CDGLibGui.addMessage(option)
	if option ~=nil and option ~= "" and option ~= "help" then
		if option == "lock" then
			CDGLibGui.setWindowLock(value)
		elseif string.sub( option,1,8 ) == "fontsize" then
			local options = { string.match(option,"^(%S*)%s*(.-)$") }
			
			CDGLibGui.addMessage("changing fontsize")
			CDGLibGui.setFontSize(options[2])
		end
	else
		CDGLibGui.addMessage("/CDG Help me !!!")
		CDGLibGui.addMessage("- /cdg lock  [true,false](To toggle lock the window)")
		CDGLibGui.addMessage("- /cdg fontsize value (To set size of font)")
	end
end

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

function argsToString(...)
	local msg=""
	for i,v in ipairs({...}) do
        msg = msg .. tostring(i) .. ":[" .. tostring(v) .."]"
    end
	return "{" .. msg .. "}"
end

function CDGSL:StripControlCharacters(s)
	s = string.gsub(s,"%^%ax","")
	s = string.gsub(s,"%^%a","")
	return s
end

function CDGSL:SetDelayedLootUpdate()
	if not delayedHide then
		delayedHide = true
		zo_callLater(function(...) 
			CDGSL:LootClosed(...) 
			delayedHide = false
		end , 1000)	
	end
end

function CDGSL:LootClosed(...)	
	if List.empty(Player.LootList) then
		return
	end
		--
		-- Sort first the lootlist before we start generating loot messages
		--
		table.sort(Player.LootList, function (a,b) 
				if a.who < b.who then 
					return true
				elseif a.who > b.who then
					return false
				else
					return (a.val < b.val) 
				end
			end ) 
		
		local msg = ""
		--
		-- Start traversing the lootlist as long as there are items : 
		-- * if it is the first item then add the playername
		-- * if it is the same player keep adding to the message
		-- * if it is the same item keep increasing the quantity
		--
		while not List.empty(Player.LootList) do
			local l = List.pop(Player.LootList)
			local l_peek = List.peek(Player.LootList)
			
			if msg == "" then msg = msg .. "|c4C4CFF" .. l.who .. "|r" end
			
			while not List.empty(Player.LootList) do
			
				l_peek = List.peek(Player.LootList)
				
				if l.who == l_peek.who and l.val == l_peek.val then
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
			
			
			if not List.empty(Player.LootList) and l.who == l_peek.who then
				msg = msg .. ","
			end
			
			if (not List.empty(Player.LootList) and l.who ~= l_peek.who) or List.empty(Player.LootList) then
				CDGLibGui.addMessage(msg)
				msg = ""
			end
		end	
	
	if List.empty(Player.LootList) then
		Player.LastLootName = nil
		Player.LootList = List.new()
	else
		CDGLibGui.addMessage("ERROR LIST NOT EMPTY")
	end
end

function CDGSL:ChatterEnd(...)
	CDGSL:LootClosed(...)
end


function CDGSL:ReticleHiddenUpdate(_, hidden, ...)
	if hidden then 
		if not Player.isCrafting then
			Player.LastLootName, _, _ = GetLootTargetInfo()
			Player.LastLootName = CDGSL:StripControlCharacters(Player.LastLootName)
		end
	end
end

function CDGSL:LootReceived(_, lootedBy, itemName, quantity, _, lootType, self)
	if self then	
		itemName = CDGSL:StripControlCharacters(itemName)
		List.push(Player.LootList, {who = GetUnitName("player"), qty = quantity, val = itemName})	
	else	  
		local _, color, _ = ZO_LinkHandler_ParseLink (itemName) 
			
		lootedBy = CDGSL:StripControlCharacters(lootedBy)
		itemName = CDGSL:StripControlCharacters(itemName)
			
		if color ~= "FFFFFF" and color ~= "C3C3C3" then -- No whites and grays
			List.push(Player.LootList, {who = lootedBy, qty = quantity, val = itemName})
				
			CDGSL:SetDelayedLootUpdate()
		end
	end
end

function CDGSL:MoneyUpdate(_, newMoney, oldMoney,...) 
	List.push(Player.LootList, {who = GetUnitName("player"), qty = (newMoney - oldMoney), val = "gold"})
end

function CDGSL:CraftingStationInteract(...)
	Player.isCrafting = true	
end

function CDGSL:EndCraftingStationInteract(...)
	Player.isCrafting = false
end

function CDGSL:CraftCompleted(...)
	Player.LastLootName, _, _ = GetLootTargetInfo()
	local items = GetNumLastCraftingResultItems()
	local _, bagslots = GetBagInfo(BAG_BACKPACK)
	for i=1, items do
		itemName, _, quantity, _, _, _, _, _, _, _, _ = GetLastCraftingResultItemInfo(i)
		for b=1, bagslots do
			local bagItemName = GetItemName(BAG_BACKPACK, b) 
		
			if (bagItemName == itemName) then 
		
				local itemLink = GetItemLink(BAG_BACKPACK, b, LINK_STYLE_DEFAULT) 
				itemLink = CDGSL:StripControlCharacters(itemLink)
				List.push(Player.LootList, {who = GetUnitName("player"),qty = quantity, val = itemLink})
				break
			
			end
		end		
	end
    CDGSL:LootClosed()
end

function CDGSL:AddonLoaded(eventCode, addOnName, ...)
	if(addOnName == "CDGShowLoot") then
		savedVars_CDGShowLoot = ZO_SavedVars:New("CDGShowLoot_SavedVariables", 1, nil)
		CDGLibGui.initializeSavedVariable()		
		CDGLibGui.CreateWindow()
		CDGLibGui.addMessage("|cFF2222CrazyDutchGuy's|r Show Loot |c0066991.7|r Loaded")
		CDGLibGui.addMessage("To configure by command use |c006699/cdg help|r")
    end
end

function CDGSL_OnInitialized()
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_ADD_ON_LOADED, function(...) CDGSL:AddonLoaded(...) end )
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_CRAFTING_STATION_INTERACT, function(...) CDGSL:CraftingStationInteract(...) end)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_END_CRAFTING_STATION_INTERACT, function(...) CDGSL:EndCraftingStationInteract(...) end)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_CRAFT_COMPLETED, function(...) CDGSL:CraftCompleted(...) end)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_RETICLE_HIDDEN_UPDATE, function(...) CDGSL:ReticleHiddenUpdate(...) end)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_LOOT_CLOSED, function(...) CDGSL:LootClosed(...) end)	
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_CHATTER_END, function(...) CDGSL:ChatterEnd(...) end)
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_MONEY_UPDATE, function(...) 
		addDebugMessage("MoneyUpdate " .. argsToString(...))
		CDGSL:MoneyUpdate(...) 
	end )
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_LOOT_RECEIVED, function(...) CDGSL:LootReceived(...) end)	
	
	Player.LootList = List.new()	
end
