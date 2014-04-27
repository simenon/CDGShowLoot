CDGLibGui = { 
	window = {
		ID = nil,
		BACKDROP = nil,
		TEXTBUFFER = nil 
	},
	defaults = {
		anchor = {
			point = TOPLEFT,
			relativeTo = GuiRoot,
			relativePoint = TOPLEFT,
			offsetX = 0,
			offsetY = 0
		},
		dimensions = {
			width = 560,
			height = 264
		},
		font = {
			name = "EsoUi/Common/Fonts/Univers57.otf",
			height = "14",
			style = "soft-shadow-thick"
		}
	}
}

local savedVars_CDGLibGui = {}

local isHidden = 0

local debugmode = false

function CDGLibGui.CreateWindow( )
	if CDGLibGui.window.ID == nil then
		CDGLibGui.window.ID = WINDOW_MANAGER:CreateTopLevelWindow(nil)
		CDGLibGui.window.ID:SetAlpha(0.8)
		CDGLibGui.window.ID:SetMouseEnabled(true)		
		CDGLibGui.window.ID:SetMovable(true)
		CDGLibGui.window.ID:SetClampedToScreen(true)
		CDGLibGui.window.ID:SetDimensions( savedVars_CDGlibGui.dimensions.width, savedVars_CDGlibGui.dimensions.height )
		CDGLibGui.window.ID:SetResizeHandleSize(8)
		CDGLibGui.window.ID:SetDrawLevel(0)
		CDGLibGui.window.ID:SetDrawLayer(0)
		CDGLibGui.window.ID:SetDrawTier(0)
		CDGLibGui.window.ID:SetAnchor(
			savedVars_CDGlibGui.anchor.point, 
			savedVars_CDGlibGui.anchor.relativeTo, 
			savedVars_CDGlibGui.anchor.relativePoint, 
			savedVars_CDGlibGui.anchor.xPos, 
			savedVars_CDGlibGui.anchor.yPos )		
				
		CDGLibGui.window.TEXTBUFFER = WINDOW_MANAGER:CreateControl(nil, CDGLibGui.window.ID, CT_TEXTBUFFER)	
		CDGLibGui.window.TEXTBUFFER:SetLinkEnabled(true)
		CDGLibGui.window.TEXTBUFFER:SetMouseEnabled(true)
		CDGLibGui.window.TEXTBUFFER:SetFont(savedVars_CDGlibGui.font.name.."|"..savedVars_CDGlibGui.font.height.."|"..savedVars_CDGlibGui.font.style)
		CDGLibGui.window.TEXTBUFFER:SetHidden(false)
		CDGLibGui.window.TEXTBUFFER:SetClearBufferAfterFadeout(false)
		CDGLibGui.window.TEXTBUFFER:SetLineFade(5, 3)
		CDGLibGui.window.TEXTBUFFER:SetMaxHistoryLines(40)
		CDGLibGui.window.TEXTBUFFER:SetDimensions(500-64, 264-64)
		CDGLibGui.window.TEXTBUFFER:SetAnchor(TOPLEFT,CDGLibGui.window.ID,TOPLEFT,32,32)
	
		CDGLibGui.window.BACKDROP = WINDOW_MANAGER:CreateControl(nil, CDGLibGui.window.ID, CT_BACKDROP)
		CDGLibGui.window.BACKDROP:SetCenterTexture([[/esoui/art/chatwindow/chat_bg_center.dds]], 16, 1)
		CDGLibGui.window.BACKDROP:SetEdgeTexture([[/esoui/art/chatwindow/chat_bg_edge.dds]], 32, 32, 32, 0)
		CDGLibGui.window.BACKDROP:SetInsets(32,32,-32,-32)		
		CDGLibGui.window.BACKDROP:SetAnchorFill(CDGLibGui.window.ID)
	
		CDGLibGui.window.TEXTBUFFER:SetHandler("OnLinkClicked", function(self, ...) 
			return ZO_ChatSystem_OnLinkClicked(...) 
		end) 
	
		CDGLibGui.window.ID:SetHandler( "OnMouseEnter", function(self, ...) 
			CDGLibGui.OnMouseEnter() 
		end )
	
		CDGLibGui.window.ID:SetHandler( "OnMouseExit" , function(self, ...) 
			CDGLibGui.OnMouseExit() 
		end )		
	
		CDGLibGui.window.ID:SetHandler( "OnMouseDown" , function() CDGLibGui.OnMouseDown() end )	
		CDGLibGui.window.ID:SetHandler( "OnDragStart" , function() CDGLibGui.OnDragStart() end )
		
		CDGLibGui.window.ID:SetHandler( "OnMouseWheel", function(self, ...)  
			CDGLibGui.window.TEXTBUFFER:MoveScrollPosition(...) 
		end )
	end
end

function CDGLibGui.OnMouseEnter()
	CDGLibGui.window.BACKDROP:SetHidden( false )
end

function CDGLibGui.OnMouseExit()
	--if CDGLibGui.window.ID:IsMovable() then
		local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = CDGLibGui.window.ID:GetAnchor()
		if isValidAnchor then
--			addDebugMessage("x"..offsetX.."y"..offsetY)
			savedVars_CDGlibGui.anchor.point = point
			savedVars_CDGlibGui.anchor.relativeTo = relativeTo
			savedVars_CDGlibGui.anchor.relativePoint = relativePoint
			savedVars_CDGlibGui.anchor.xPos = offsetX
			savedVars_CDGlibGui.anchor.yPos = offsetY
			CDGLibGui.window.ID:ClearAnchors()
			CDGLibGui.window.ID:SetAnchor(
				savedVars_CDGlibGui.anchor.point, 
				savedVars_CDGlibGui.anchor.relativeTo, 
				savedVars_CDGlibGui.anchor.relativePoint, 
				savedVars_CDGlibGui.anchor.xPos, 
				savedVars_CDGlibGui.anchor.yPos )
		end
	--end
	
	isHidden = GetGameTimeMilliseconds()
--	addDebugMessage("Call to hide at " .. isHidden)
	zo_callLater(function() CDGLibGui.delayedHide() end , 5000)	
end

function CDGLibGui.OnMouseDown()		
	CDGLibGui.window.BACKDROP:SetHidden( false )
end

function CDGLibGui.OnDragStart()
	CDGLibGui.window.BACKDROP:SetHidden( false )
end

function CDGLibGui.delayedHide()		
	if ( ( isHidden + 4900 ) < GetGameTimeMilliseconds() ) then
--		addDebugMessage("Hiding at " .. GetGameTimeMilliseconds())
		CDGLibGui.window.BACKDROP:SetHidden( true )
	end
end

function CDGLibGui.setWindowLock(value)
	CDGLibGui.window.ID:SetMovable(value)
end

function CDGLibGui.setFontSize(value)
	savedVars_CDGlibGui.font.height = value
	CDGLibGui.addMessage("Font size changed to " .. savedVars_CDGlibGui.font.height .. ", please do a /reloadui")
end

function CDGLibGui.addMessage(message)
	if CDGLibGui.window.TEXTBUFFER ~= nil then		
		CDGLibGui.window.TEXTBUFFER:AddMessage("|c909000[" .. GetTimeString() .. "]|r " .. message)
	end
end

function CDGLibGui.initializeSavedVariable()
	savedVars_CDGlibGui = ZO_SavedVars:New("CDGLibGui_SavedVariables", 1, nil, CDGLibGui.defaults)
end

function addDebugMessage(message)	
	if debugmode then CDGLibGui.addMessage("|cDD0000[DEBUG]|r" .. message ) end
end