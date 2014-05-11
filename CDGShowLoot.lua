local LAM = LibStub:GetLibrary("LibAddonMenu-1.0")
local LMP = LibStub:GetLibrary("LibMediaProvider-1.0")
local CDGSL = ZO_Object:Subclass()

local Player = { 
	isCrafting = false,
	LastLootName = nil,
	LootList = nil
}

local COLOR = {
	GREEN = "00CD00",
	RED= "D00000"
}

local localVars = {
	defaults = {	
		filter = {
			gold = false,
			minGold = 0,	
			self = {
				JUNK = false,
				NORMAL = false,
				FINE = false,
				SUPERIOR = false,
				EPIC = false,
				LEGENDARY = false
			},
			group = {
				JUNK = true,
				NORMAL = true,
				FINE = false,
				SUPERIOR = false,
				EPIC = false,
				LEGENDARY = false
			}
		},
		playerColor = "4C4CFF",
		groupColor = "4C4CFF",
		logToDefaultChat = false
	}
}

local LOOTCOLOR = {
	JUNK = "C3C3C3",
	NORMAL = "FFFFFF",
	FINE = "2DC50E",
	SUPERIOR = "3A92FF",
	EPIC = "A02EF7",
	LEGENDARY = "EECA2A"
}

local savedVars_CDGShowLoot = {}

local List = {}

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
			

			if msg == "" then 
				if GetUnitName("player") == l.who then
					msg = msg .. zo_strformat("|c<<1>> <<2>>|r", savedVars_CDGShowLoot.playerColor, l.who ) 					
				else
					msg = msg .. zo_strformat("|c<<1>> <<2>>|r", savedVars_CDGShowLoot.groupColor, l.who ) 
				end
			end
			
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
				msg = msg .. zo_strformat(" |c<<3>> <<2[1/$d]>>|r <<t:1>>", l.val, l.qty, COLOR.GREEN   ) 
			else
				msg = msg .. zo_strformat(" |c<<3>> <<2[1/$d]>>|r <<t:1>>", l.val, math.abs(l.qty), COLOR.RED   ) 
			end
			
			
			if not List.empty(Player.LootList) and l.who == l_peek.who then
				msg = msg .. ","
			end
			
			if (not List.empty(Player.LootList) and l.who ~= l_peek.who) or List.empty(Player.LootList) then
				CDGSL:sendMessage(msg)
				msg = ""
			end
		end	
	
	if List.empty(Player.LootList) then
		Player.LastLootName = nil
		Player.LootList = List.new()
	end
end

function CDGSL:ChatterEnd(...)
	CDGSL:LootClosed(...)
end


function CDGSL:ReticleHiddenUpdate(_, hidden, ...)	
	if hidden then 
		if not Player.isCrafting then
			Player.LastLootName, _, _ = GetLootTargetInfo()
		end
	end
end

function CDGSL:LootReceived(_, lootedBy, itemName, quantity, _, lootType, self)
	local _, color, _ = ZO_LinkHandler_ParseLink (itemName)
	if self then	
		if 	(savedVars_CDGShowLoot.filter.self.JUNK and (color == LOOTCOLOR.JUNK)) or 
		   	(savedVars_CDGShowLoot.filter.self.NORMAL and (color == LOOTCOLOR.NORMAL)) or
		   	(savedVars_CDGShowLoot.filter.self.FINE and (color == LOOTCOLOR.FINE)) or
			(savedVars_CDGShowLoot.filter.self.SUPERIOR and (color == LOOTCOLOR.SUPERIOR)) or
			(savedVars_CDGShowLoot.filter.self.EPIC and (color == LOOTCOLOR.EPIC)) or
			(savedVars_CDGShowLoot.filter.self.LEGENDARY and (color == LOOTCOLOR.LEGENDARY)) then 
			--
			-- nothing
			--
		else
			List.push(Player.LootList, {who = GetUnitName("player"), qty = quantity, val = itemName})	
		end
	else	  
		if 	(savedVars_CDGShowLoot.filter.group.JUNK and (color == LOOTCOLOR.JUNK)) or 
		   	(savedVars_CDGShowLoot.filter.group.NORMAL and (color == LOOTCOLOR.NORMAL)) or
		   	(savedVars_CDGShowLoot.filter.group.FINE and (color == LOOTCOLOR.FINE)) or
			(savedVars_CDGShowLoot.filter.group.SUPERIOR and (color == LOOTCOLOR.SUPERIOR)) or
			(savedVars_CDGShowLoot.filter.group.EPIC and (color == LOOTCOLOR.EPIC)) or
			(savedVars_CDGShowLoot.filter.group.LEGENDARY and (color == LOOTCOLOR.LEGENDARY)) then 
			--
			-- nothing
			--
		else			
			List.push(Player.LootList, {who = lootedBy, qty = quantity, val = itemName})
				
			CDGSL:SetDelayedLootUpdate()
		end
	end
end

function CDGSL:MoneyUpdate(_, newMoney, oldMoney,...) 
	if not savedVars_CDGShowLoot.filter.gold then
		local goldDiff = newMoney - oldMoney
		if goldDiff < 0 or goldDiff > savedVars_CDGShowLoot.filter.minGold then
			List.push(Player.LootList, {who = GetUnitName("player"), qty = (newMoney - oldMoney), val = "gold"})
		end
	end
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
		local itemName, _, quantity, _, _, _, _, _, _, _, _ = GetLastCraftingResultItemInfo(i)
		if itemName == nil then 
			CDGSL:sendMessage("Failed to retrieve last crafting results") 
		end
		local itemLink = CDGSL:LookUpItemNameInBag(itemName)
		if itemLink == nil then 
			CDGSL:sendMessage("Failed to look up item [" .. itemName .. "], retrying ...")
			itemLink = CDGSL:LookUpItemNameInBag(itemName)
			if itemLink == nil then 
				CDGSL:sendMessage("Retry failed, giving up...")
			end
		end
		--
		-- Some odd cases it can happen that the itemLink is nil, but why ...
		--
		if itemLink ~= nil then
			local _, color, _ = ZO_LinkHandler_ParseLink (itemLink)
			
			if 	(savedVars_CDGShowLoot.filter.self.JUNK and (color == LOOTCOLOR.JUNK)) or 
			   	(savedVars_CDGShowLoot.filter.self.NORMAL and (color == LOOTCOLOR.NORMAL)) or
			   	(savedVars_CDGShowLoot.filter.self.FINE and (color == LOOTCOLOR.FINE)) or
				(savedVars_CDGShowLoot.filter.self.SUPERIOR and (color == LOOTCOLOR.SUPERIOR)) or
				(savedVars_CDGShowLoot.filter.self.EPIC and (color == LOOTCOLOR.EPIC)) or
				(savedVars_CDGShowLoot.filter.self.LEGENDARY and (color == LOOTCOLOR.LEGENDARY)) then 
			--
			-- Do Nothing
			--
			else		
				List.push(Player.LootList, {who = GetUnitName("player"),qty = quantity, val = itemLink})
			end
		end
	end
    CDGSL:LootClosed()
end

function CDGSL:LookUpItemNameInBag(itemName)
	local _, bagslots = GetBagInfo(BAG_BACKPACK)
	for b=1, bagslots do
		local bagItemName = GetItemName(BAG_BACKPACK, b) 
		if (bagItemName == itemName) then 
			return GetItemLink(BAG_BACKPACK, b, LINK_STYLE_DEFAULT) 	
		end		
	end
end

function CDGSL:QuestRemoved(isCompleted, ...)
	if isCompleted then
		CDGSL:LootClosed()
	end
end


function CDGSL:AddonLoaded(eventCode, addOnName, ...)
	if(addOnName == "CDGShowLoot") then
		savedVars_CDGShowLoot = ZO_SavedVars:New("CDGShowLoot_SavedVariables", 2, nil, localVars.defaults)
		CDGLibGui.initializeSavedVariable()		
		CDGLibGui.CreateWindow()		
		CDGSL:sendMessage("|cFF2222CrazyDutchGuy's|r Show Loot |c0066992.4|r Loaded")

		CDGSL:InitializeLAMSettings()

		Player.LootList = List.new()
		--
		-- No point starting these events earlier till the addon is fully loaded.
		--
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_CRAFTING_STATION_INTERACT, function(...) CDGSL:CraftingStationInteract(...) end)
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_END_CRAFTING_STATION_INTERACT, function(...) CDGSL:EndCraftingStationInteract(...) end)
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_CRAFT_COMPLETED, function(...) CDGSL:CraftCompleted(...) end)
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_RETICLE_HIDDEN_UPDATE, function(...) CDGSL:ReticleHiddenUpdate(...) end)
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_LOOT_CLOSED, function(...) CDGSL:LootClosed(...) end)	
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_CHATTER_END, function(...) CDGSL:ChatterEnd(...) end)
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_QUEST_REMOVED, function(...) CDGSL:QuestRemoved(...) end)
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_MONEY_UPDATE, function(...) CDGSL:MoneyUpdate(...) end )
		EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_LOOT_RECEIVED, function(...) CDGSL:LootReceived(...) end)	


    end
end

function CDGSL:sendMessage(message)
	if savedVars_CDGShowLoot.logToDefaultChat then
		d(message)
	end
	CDGLibGui.addMessage(message)
end

local function RGBtoHEX(r,g,b,a)
	--	hex = string.format("%.2x%.2x%.2x%.2x", math.floor(a * 255),math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
	return string.format("%.2x%.2x%.2x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

local function HEXtoRGB(hex)
    local a, r, g, b
    
    if(string.len(hex) == 8)
    then
        a, r, g, b = tonumber("0x"..string.sub(hex, 1, 2)) / 255, tonumber("0x"..string.sub(hex, 3, 4)) / 255, tonumber("0x"..string.sub(hex, 5, 6)) / 255, tonumber("0x"..string.sub(hex, 7, 8)) / 255
    elseif(string.len(hex) == 6)
    then
        a, r, g, b = 1, tonumber("0x"..string.sub(hex, 1, 2)) / 255, tonumber("0x"..string.sub(hex, 3, 4)) / 255, tonumber("0x"..string.sub(hex, 5, 6)) / 255
    end
    
    if(a)
    then
        return r, g, b, a
    end
	
end

function CDGSL:InitializeLAMSettings()
	local lamID = "CDGShowLootLAM"
	local panelID = LAM:CreateControlPanel(lamID, "CDG Show Loot")
	--
	-- General Options
	--
	LAM:AddHeader(panelID, lamID.."Header".."GO", "General Options")
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."LogDefault", "Log to main chat window", nil, function() return savedVars_CDGShowLoot.logToDefaultChat end, function(value) savedVars_CDGShowLoot.logToDefaultChat = value end,  false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."Move", "Move the loot window", nil, function() return CDGLibGui.isMovable() end, function(...) CDGLibGui.setMovable(...) end,  false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."HideBG", "Hide the background", nil, function() return CDGLibGui.isBackgroundHidden() end, function(...) CDGLibGui.setBackgroundHidden(...) end,  true, "Without background you can not resize or move the window.")
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."Hide", "Hide the loot window", nil, function() return CDGLibGui.isHidden() end, function(...) CDGLibGui.setHidden(...) end,  false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."HideInDialog", "Hide when in dialog", nil, function() return CDGLibGui.isHiddenInDialogs() end, function(...) CDGLibGui.HideInDialogs(...) end,  true, "Reload UI")
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."Gold", "Filter Gold", nil, function() return savedVars_CDGShowLoot.filter.gold end, function(value) savedVars_CDGShowLoot.filter.gold = value end,  false, nil)
	LAM:AddSlider(panelID, lamID.."Slider".."minGold", "Minimal gold to display", nil, 0, 500, 1, function(...) return savedVars_CDGShowLoot.filter.minGold end, function(value) savedVars_CDGShowLoot.filter.minGold = value end, true, "Text will not fade out when set at 0")
	LAM:AddSlider(panelID, lamID.."Slider".."TTTFO", "Time till text fades out", nil, 0, 10, 1, function(...) return CDGLibGui.getTimeTillLineFade() end, function(...) CDGLibGui.setTimeTillLineFade(...) end, true, "Text will not fade out when set at 0")
	LAM:AddColorPicker(panelID, lamID.."ColorPicker".."Player", "Player Color", nil, function() return HEXtoRGB(savedVars_CDGShowLoot.playerColor) end,  function(r,g,b,a) savedVars_CDGShowLoot.playerColor = RGBtoHEX(r,g,b,a) end, false, nil)
	LAM:AddColorPicker(panelID, lamID.."ColorPicker".."Group", "Group Color", nil,  function() return HEXtoRGB(savedVars_CDGShowLoot.groupColor) end,  function(r,g,b,a) savedVars_CDGShowLoot.groupColor = RGBtoHEX(r,g,b,a) end, false, nil)
	--
	-- Font Settings
	--
	LAM:AddHeader(panelID, lamID.."Header".."FS", "Font Settings")
	LAM:AddDropdown(panelID, lamID.."Dropdown" .."Font", "Font", nil, LMP:List("font"), function(...) return CDGLibGui.getDefaultFont() end, function(...) return CDGLibGui.setDefaultFont(...) end, true, "Reload UI")
	LAM:AddSlider(panelID, lamID.."Slider", "Font Size", nil, 10, 30, 1, function(...) return CDGLibGui.getFontSize() end, function(...) CDGLibGui.setFontSize(...) end, true, "Reload UI")
	LAM:AddDropdown(panelID, lamID.."Dropdown", "Font Style", nil, CDGLibGui.fontstyles, function(...) return CDGLibGui.getFontStyle() end, function(...) return CDGLibGui.setFontStyle(...) end, true, "Reload UI")
	LAM:AddHeader(panelID, lamID.."Header".."PLS", "Personal Loot Filters")
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."self".."Junk",      "|c"..LOOTCOLOR.JUNK.."Junk".."|r",          "", function() return savedVars_CDGShowLoot.filter.self.JUNK end,      function(value) savedVars_CDGShowLoot.filter.self.JUNK = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."self".."Normal",    "|c"..LOOTCOLOR.NORMAL.."Normal".."|r",      "", function() return savedVars_CDGShowLoot.filter.self.NORMAL end,    function(value) savedVars_CDGShowLoot.filter.self.NORMAL = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."self".."Fine",      "|c"..LOOTCOLOR.FINE.."Fine".."|r",          "", function() return savedVars_CDGShowLoot.filter.self.FINE end,      function(value) savedVars_CDGShowLoot.filter.self.FINE = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."self".."Superior",  "|c"..LOOTCOLOR.SUPERIOR.."Superior".."|r",  "", function() return savedVars_CDGShowLoot.filter.self.SUPERIOR end,  function(value) savedVars_CDGShowLoot.filter.self.SUPERIOR = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."self".."Epic",      "|c"..LOOTCOLOR.EPIC.."Epic".."|r",          "", function() return savedVars_CDGShowLoot.filter.self.EPIC end,      function(value) savedVars_CDGShowLoot.filter.self.EPIC = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."self".."Legendary", "|c"..LOOTCOLOR.LEGENDARY.."Legendary".."|r","", function() return savedVars_CDGShowLoot.filter.self.LEGENDARY end, function(value) savedVars_CDGShowLoot.filter.self.LEGENDARY = value end, false, nil)
	LAM:AddHeader(panelID, lamID.."Header".."GLS", "Group Loot Filters")
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."group".."Junk",      "|c"..LOOTCOLOR.JUNK.."Junk".."|r",          "", function() return savedVars_CDGShowLoot.filter.group.JUNK end,      function(value) savedVars_CDGShowLoot.filter.group.JUNK = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."group".."Normal",    "|c"..LOOTCOLOR.NORMAL.."Normal".."|r",      "", function() return savedVars_CDGShowLoot.filter.group.NORMAL end,    function(value) savedVars_CDGShowLoot.filter.group.NORMAL = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."group".."Fine",      "|c"..LOOTCOLOR.FINE.."Fine".."|r",          "", function() return savedVars_CDGShowLoot.filter.group.FINE end,      function(value) savedVars_CDGShowLoot.filter.group.FINE = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."group".."Superior",  "|c"..LOOTCOLOR.SUPERIOR.."Superior".."|r",  "", function() return savedVars_CDGShowLoot.filter.group.SUPERIOR end,  function(value) savedVars_CDGShowLoot.filter.group.SUPERIOR = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."group".."Epic",      "|c"..LOOTCOLOR.EPIC.."Epic".."|r",          "", function() return savedVars_CDGShowLoot.filter.group.EPIC end,      function(value) savedVars_CDGShowLoot.filter.group.EPIC = value end, false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."group".."Legendary", "|c"..LOOTCOLOR.LEGENDARY.."Legendary".."|r","", function() return savedVars_CDGShowLoot.filter.group.LEGENDARY end, function(value) savedVars_CDGShowLoot.filter.group.LEGENDARY = value end, false, nil)
end

function CDGSL_OnInitialized()
	EVENT_MANAGER:RegisterForEvent("CDGShowLoot", EVENT_ADD_ON_LOADED, function(...) CDGSL:AddonLoaded(...) end )	
end
