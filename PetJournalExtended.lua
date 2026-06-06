local _,pje = ...
local PJX = {}

-- ============================================================================
-- Utility Functions
-- ============================================================================

-- Safely retrieve pet info, handling both old and new API
local function SafeGetPetInfoByPetID(petID)
    if not petID then return end
    if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
        return C_PetJournal.GetPetInfoByPetID(petID)
    elseif GetPetInfoByPetID then
        return GetPetInfoByPetID(petID)
    end
end

-- Extract display information for a specific pet
local function GetPetDisplayInfo(petID)
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, speciesName, icon, petType = SafeGetPetInfoByPetID(petID)
    local name = customName or speciesName or "Unknown Pet"
    return name, icon, petType
end

-- Get list of all pet IDs owned by the player
local function GetOwnedPetIDs()
    local pets = {}
    if not C_PetJournal or not C_PetJournal.GetNumPets then
        return pets
    end
    local numPets = C_PetJournal.GetNumPets()
    for i = 1, numPets do
        local petID = select(1, C_PetJournal.GetPetInfoByIndex(i))
        if petID and petID ~= 0 then
            pets[#pets + 1] = petID
        end
    end
    return pets
end

-- ============================================================================
-- UI Creation Functions
-- ============================================================================

-- Creates the UI elements for a single pet slot in the top section of the frame
function PJX:CreatePetSlot(index, parent)
    local button = CreateFrame("Button", "PetJournalExtendedSlot" .. index, parent, "BackdropTemplate")
    button:SetSize(pje.constants.SLOT_WIDTH, pje.constants.SLOT_HEIGHT)
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    button:SetBackdropColor(unpack(pje.constants.SLOT_BACKDROP_COLOR))

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 12, -12)
    button.icon:SetSize(40, 40)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetPoint("CENTER", button.icon, "CENTER")
    button.border:SetSize(62, 62)
    button.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.name:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 10, -4)
    button.name:SetPoint("RIGHT", button, "RIGHT", -10, 0)
    button.name:SetJustifyH("LEFT")
    button.name:SetText("Empty Slot")

    button.typeText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.typeText:SetPoint("TOPLEFT", button.name, "BOTTOMLEFT", 0, -6)
    button.typeText:SetText("Drag a pet here")

    button.slotLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.slotLabel:SetPoint("BOTTOM", button, "BOTTOM", 0, 10)
    button.slotLabel:SetText("Slot " .. index)

    button.slotIndex = index
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnReceiveDrag", function(self)
        self:GetParent().owner:ReceivePetDrop(self)
    end)
    button:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            self:GetParent().owner:ReceivePetDrop(self)
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.petID then
            GameTooltip:SetText(self.petName)
            GameTooltip:AddLine("Current slot pet", 1, 1, 1)
        else
            GameTooltip:SetText("Empty Slot")
            GameTooltip:AddLine("Drop a pet from the list below to assign it to this slot.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- Creates a reusable pet button element for the scrollable grid
-- Used in a virtual scrolling system: 24 buttons (8 rows × 3 columns) are
-- pre-created and recycled by updating their displayed pet data
function PJX:CreatePetButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(pje.constants.GRID_BUTTON_WIDTH, pje.constants.GRID_ROW_HEIGHT)
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    button:SetBackdropColor(unpack(pje.constants.BUTTON_BACKDROP_COLOR))

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("LEFT", button, "LEFT", 4, 0)
    button.icon:SetSize(pje.constants.GRID_BUTTON_ICON_SIZE, pje.constants.GRID_BUTTON_ICON_SIZE)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.name:SetPoint("LEFT", button.icon, "RIGHT", 4, 5)
    button.name:SetJustifyH("LEFT")
    button.name:SetWidth(190)
    button.name:SetText("Pet Name")

    button.typeText = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.typeText:SetPoint("LEFT", button.icon, "RIGHT", 4, -8)
    button.typeText:SetJustifyH("LEFT")
    button.typeText:SetText("Type")

    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        if self.petID and C_PetJournal and C_PetJournal.PickupPet then
            C_PetJournal.PickupPet(self.petID)
        end
    end)
    button:SetScript("OnEnter", function(self)
        if not self.petID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.petName)
        if self.petType then
            GameTooltip:AddLine(self.petType, 1, 1, 1)
        end
        GameTooltip:AddLine("Drag this pet into one of the top slots to replace it.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

function PJX:CreateUI()
    if self.frame then return end

    self:CreateMainFrame()
    self:CreateSlotPanel()
    self:CreatePetListPanel()
end

-- Create the main window frame
function PJX:CreateMainFrame()
    local frame = CreateFrame("Frame", "PetJournalExtendedMainFrame", UIParent)
    frame:SetSize(pje.constants.FRAME_WIDTH, pje.constants.FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:Hide()
    frame:SetMovable(false)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame.owner = self
    
    self.frame = frame
end

-- Create the top panel with 3 pet loadout slots
function PJX:CreateSlotPanel()
    local topPanel = CreateFrame("Frame", nil, self.frame)
    topPanel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    topPanel:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
    topPanel:SetHeight(pje.constants.SLOTS_PANEL_HEIGHT)
    topPanel.owner = self

    self.slotButtons = {}
    for i = 1, pje.constants.NUM_LOADOUT_SLOTS do
        local slot = self:CreatePetSlot(i, topPanel)
        local xOffset = pje.constants.SLOT_LEFT_MARGIN + (i - 1) * pje.constants.GRID_COLUMN_WIDTH
        slot:SetPoint("TOPLEFT", topPanel, "TOPLEFT", xOffset, -50)
        self.slotButtons[i] = slot
    end

    local label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, pje.constants.BOTTOM_LABEL_Y)
    label:SetText("All Pets")
end

-- Create the scrollable pet list panel with 3-column grid
-- Uses virtual scrolling: pre-creates 24 buttons (8 rows × 3 columns) to display
-- all pets without performance issues. Only visible buttons are updated each frame.
function PJX:CreatePetListPanel()
    local petListContainer = CreateFrame("Frame", nil, self.frame)
    petListContainer:SetPoint("TOPLEFT", self.frame, "TOPLEFT", pje.constants.PANEL_MARGIN, pje.constants.PET_LIST_Y)
    petListContainer:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -pje.constants.PANEL_MARGIN, pje.constants.PANEL_MARGIN)
    petListContainer:EnableMouseWheel(true)

    -- Create 3-column grid of pet buttons (8 rows × 3 columns = 24 visible buttons)
    self.petRows = {}
    for row = 0, pje.constants.GRID_VISIBLE_ROWS - 1 do
        for col = 0, pje.constants.GRID_COLUMNS - 1 do
            local button = self:CreatePetButton(petListContainer)
            local xOffset = col * pje.constants.GRID_COLUMN_WIDTH
            local yOffset = -(row * pje.constants.GRID_ROW_HEIGHT)
            button:SetPoint("TOPLEFT", petListContainer, "TOPLEFT", xOffset, yOffset)
            button:Hide()
            local buttonIndex = row * pje.constants.GRID_COLUMNS + col + 1
            self.petRows[buttonIndex] = button
        end
    end

    -- Create scrollbar
    local scrollbar = self:CreateScrollbar(petListContainer)
    self.petSlider = scrollbar

    -- Setup mouse wheel scrolling
    local function OnMouseWheel(_, delta)
        scrollbar:SetValue((scrollbar:GetValue() or 0) - delta)
    end
    petListContainer:SetScript("OnMouseWheel", OnMouseWheel)
    for _, button in ipairs(self.petRows) do
        button:EnableMouseWheel(true)
        button:SetScript("OnMouseWheel", OnMouseWheel)
    end

    self.petListContainer = petListContainer
    self.petOffset = 0
    self.allPets = {}
end

-- Create the vertical scrollbar
function PJX:CreateScrollbar(parent)
    local scrollbar = CreateFrame("Slider", nil, self.frame)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetWidth(14)
    scrollbar:SetPoint("TOPLEFT", parent, "TOPRIGHT", -5, 0)
    scrollbar:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", -5, 0)
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValueStep(1)
    scrollbar:SetObeyStepOnDrag(true)
    scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    
    local thumb = scrollbar:GetThumbTexture()
    if thumb and thumb.SetSize then
        thumb:SetSize(14, 26)
    end

    scrollbar:SetScript("OnValueChanged", function(_, value)
        self.petOffset = math.floor((value or 0) + 0.5)
        self:RenderPetList()
    end)

    return scrollbar
end

function PJX:ReceivePetDrop(slotButton)
    local cursorType, petID = GetCursorInfo()
    if cursorType ~= "battlepet" or not petID then
        return
    end
    if C_PetJournal and C_PetJournal.SetPetLoadOutInfo then
        C_PetJournal.SetPetLoadOutInfo(slotButton.slotIndex, petID)
        ClearCursor()
        self:Refresh()
    end
end

-- ============================================================================
-- Refresh Functions
-- ============================================================================

function PJX:RefreshSlots()
    if not C_PetJournal or not C_PetJournal.GetPetLoadOutInfo then
        return
    end
    for i = 1, 3 do
        local petID = C_PetJournal.GetPetLoadOutInfo(i)
        local button = self.slotButtons[i]
        button.petID = petID
        if petID and petID ~= 0 then
            button.petName, button.petIcon, button.petType = GetPetDisplayInfo(petID)
            button.icon:SetTexture(button.petIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
            button.name:SetText(button.petName)
            button.typeText:SetText(pje.constants.PETTYPES[button.petType] or "Battle Pet")
        else
            button.petName = nil
            button.petIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
            button.petType = nil
            button.icon:SetTexture(button.petIcon)
            button.name:SetText("Empty Slot")
            button.typeText:SetText("Drag a pet here")
        end
    end
end

-- Render the visible portion of the pet list based on scroll offset
-- Virtual scrolling algorithm: Uses pre-created 24 buttons to display any subset
-- of pets. Calculate which pet data to show in each button using scrollOffset.
-- Formula: petIndex = (scrollOffset + row) * GRID_COLUMNS + col + 1
function PJX:RenderPetList()
    if not self.frame then return end
    
    local scrollOffset = self.petOffset or 0
    
    for row = 0, pje.constants.GRID_VISIBLE_ROWS - 1 do
        for col = 0, pje.constants.GRID_COLUMNS - 1 do
            local buttonIndex = row * pje.constants.GRID_COLUMNS + col + 1
            local button = self.petRows[buttonIndex]
            local petIndex = (scrollOffset + row) * pje.constants.GRID_COLUMNS + col + 1
            local petData = self.allPets[petIndex]
            
            if petData then
                button.petID = petData.petID
                button.petName = petData.name
                button.petType = petData.petType
                button.icon:SetTexture(petData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                button.name:SetText(petData.name)
                button.typeText:SetText(petData.petType)
                button:Show()
            else
                button.petID = nil
                button:Hide()
            end
        end
    end
end

-- Refresh the pet list from Blizzard API and re-render
function PJX:RefreshPetList()
    local petIDs = GetOwnedPetIDs()
    
    -- Build pet data table
    self.allPets = {}
    for index, petID in ipairs(petIDs) do
        local name, icon, petType = GetPetDisplayInfo(petID)
        self.allPets[index] = {
            petID = petID,
            name = name,
            icon = icon,
            petType = pje.constants.PETTYPES[petType] or "Battle Pet"
        }
    end
    
    -- Calculate max scroll offset for 3-column grid
    local totalRows = math.ceil(#self.allPets / pje.constants.GRID_COLUMNS)
    local maxScrollOffset = math.max(0, totalRows - pje.constants.GRID_VISIBLE_ROWS)
    
    if (self.petOffset or 0) > maxScrollOffset then
        self.petOffset = maxScrollOffset
    end
    
    if self.petSlider then
        self.petSlider:SetMinMaxValues(0, maxScrollOffset)
        self.petSlider:SetValue(self.petOffset or 0)
    end
    
    -- Render the visible rows
    self:RenderPetList()
end

function PJX:Refresh()
    if not self.frame or not self.frame:IsShown() then
        return
    end
    self:RefreshSlots()
    self:RefreshPetList()
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

function PJX:OnPetJournalShown()
    if self.suppressHook then
        return
    end
    if InCombatLockdown() then
        return
    end
    if not self.frame then
        self:CreateUI()
    end
    if PetJournal then
        PetJournal:Hide()
        PetJournal:SetShown(false)
    end
    if CollectionsJournal then
        self.frame:SetParent(CollectionsJournal)
        self.frame:SetFrameLevel(CollectionsJournal:GetFrameLevel() + 100)
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPLEFT", CollectionsJournal, "TOPLEFT", 0, 0)
        self.frame:SetPoint("BOTTOMRIGHT", CollectionsJournal, "BOTTOMRIGHT", 0, 0)
    end
    self.frame:Show()
    self.active = true
    self:Refresh()
end

function PJX:OnPetJournalHidden()
    if self.suppressHook then
        return
    end
    if not self.active then
        return
    end
    self.active = false
    if self.frame then
        self.frame:Hide()
    end
    if PetJournal and CollectionsJournal and CollectionsJournal:IsVisible() then
        self.suppressHook = true
        PetJournal:Show()
        self.suppressHook = false
    end
end

function PJX:ADDON_LOADED(addon)
    if addon ~= "Blizzard_Collections" then
        return
    end
    if not PetJournal then
        return
    end
    if PetJournal.Show then
        hooksecurefunc(PetJournal, "Show", function()
            if PJX and PJX.OnPetJournalShown then
                PJX:OnPetJournalShown()
            end
        end)
    end
    if PetJournal.Hide then
        hooksecurefunc(PetJournal, "Hide", function()
            if PJX and PJX.OnPetJournalHidden then
                PJX:OnPetJournalHidden()
            end
        end)
    end
    if PetJournal.SetShown then
        hooksecurefunc(PetJournal, "SetShown", function(_, shown)
            if not PJX then return end
            if shown and PJX.OnPetJournalShown then
                PJX:OnPetJournalShown()
            elseif not shown and PJX.OnPetJournalHidden then
                PJX:OnPetJournalHidden()
            end
        end)
    end
end

function PJX:PLAYER_LOGIN()
    local isLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isLoaded = C_AddOns.IsAddOnLoaded("Blizzard_Collections")
    elseif IsAddOnLoaded then
        isLoaded = IsAddOnLoaded("Blizzard_Collections")
    end
    if isLoaded then
        self:ADDON_LOADED("Blizzard_Collections")
    end
end

function PJX:PLAYER_REGEN_DISABLED()
    if self.active then
        self.active = false
        if self.frame then
            self.frame:Hide()
        end
        if PetJournal then
            self.suppressHook = true
            PetJournal:Show()
            self.suppressHook = false
        end
    end
end

function PJX:PLAYER_REGEN_ENABLED()
    if CollectionsJournal and CollectionsJournal:IsVisible() and PetJournal and PetJournal:IsVisible() and not self.active then
        self:OnPetJournalShown()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local eventHandlers = {
    ADDON_LOADED = function(...) PJX:ADDON_LOADED(...) end,
    PLAYER_LOGIN = function(...) PJX:PLAYER_LOGIN(...) end,
    PLAYER_REGEN_DISABLED = function(...) PJX:PLAYER_REGEN_DISABLED(...) end,
    PLAYER_REGEN_ENABLED = function(...) PJX:PLAYER_REGEN_ENABLED(...) end,
}

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if eventHandlers[event] then
        eventHandlers[event](...)
    end
end)

-- ============================================================================
-- Export UI Module
-- ============================================================================

pje.UI = PJX
_G.PetJournalExtended = PJX
