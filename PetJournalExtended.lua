local PJX = {}

local function SafeGetPetInfoByPetID(petID)
    if not petID then
        return
    end
    if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
        return C_PetJournal.GetPetInfoByPetID(petID)
    elseif GetPetInfoByPetID then
        return GetPetInfoByPetID(petID)
    end
end

local function GetPetDisplayInfo(petID)
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, speciesName, icon, petType = SafeGetPetInfoByPetID(petID)
    local name = customName or speciesName or "Unknown Pet"
    return name, icon, petType
end

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

-- this creates the UI elements for a single pet slot in the top section of the frame, 
-- which shows the currently assigned pets. It includes an icon, name, type, and a label for the slot number. 
-- It also sets up drag-and-drop functionality to allow assigning pets to the slot.
function PJX:CreatePetSlot(index, parent)
    local button = CreateFrame("Button", "PetJournalExtendedSlot" .. index, parent, "BackdropTemplate")
    button:SetSize(214, 160)
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    button:SetBackdropColor(0.05, 0.05, 0.05, 0.75)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 12, -12)
    button.icon:SetSize(80, 80)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetPoint("TOPLEFT", button.icon, "TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 2, -2)
    button.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    button.border:SetTexCoord(0.08, 0.92, 0.08, 0.92)

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
    button:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
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

function PJX:CreatePetButton(index, parent)
    local button = CreateFrame("Button", "PetJournalExtendedPetButton" .. index, parent, "BackdropTemplate")
    button:SetSize(220, 70)
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    button:SetBackdropColor(0.08, 0.08, 0.08, 0.85)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.icon:SetSize(52, 52)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.name:SetPoint("LEFT", button.icon, "RIGHT", 10, 6)
    button.name:SetJustifyH("LEFT")
    button.name:SetWidth(130)
    button.name:SetText("Pet Name")

    button.typeText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.typeText:SetPoint("LEFT", button.icon, "RIGHT", 10, -14)
    button.typeText:SetJustifyH("LEFT")
    button.typeText:SetText("Pet Type")

    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        if self.petID and C_PetJournal and C_PetJournal.PickupPet then
            C_PetJournal.PickupPet(self.petID)
        end
    end)
    button:SetScript("OnEnter", function(self)
        if not self.petID then
            return
        end
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
    if self.frame then
        return
    end

    local parent = UIParent
    self.frame = CreateFrame("Frame", "PetJournalExtendedMainFrame", parent)
    self.frame:SetSize(760, 540)
    self.frame:SetPoint("CENTER")
    self.frame:Hide()
    self.frame:SetMovable(false)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
    self.frame:SetFrameStrata("DIALOG")
    self.frame.owner = self

    local top = CreateFrame("Frame", nil, self.frame)
    top:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
    top:SetHeight(200)
    top.owner = self

    self.slotButtons = {}
    for i = 1, 3 do
        local slot = self:CreatePetSlot(i, top)
        slot:SetPoint("TOPLEFT", top, "TOPLEFT", (i - 1) * 236, -45)
        self.slotButtons[i] = slot
    end

    local bottomLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    bottomLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -212)
    bottomLabel:SetText("All Pets")

    local scrollFrame = CreateFrame("ScrollFrame", "PetJournalExtendedPetScroll", self.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 6, -240)
    scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -6, 6)
    scrollFrame:SetClipsChildren(true)

    self.petScroll = scrollFrame
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(700, 1)
    scrollFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild

    self.petButtons = {}
    local columns = 3
    local rows = 6
    for i = 1, columns * rows do
        local btn = self:CreatePetButton(i, scrollChild)
        local col = ((i - 1) % columns)
        local row = math.floor((i - 1) / columns)
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", col * 228 + 4, -row * 78)
        self.petButtons[i] = btn
    end

    local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    if scrollBar then
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValueStep(1)
        scrollBar:SetValue(0)
        scrollBar:SetScript("OnValueChanged", function(self, value)
            scrollFrame:SetVerticalScroll(value)
        end)
    end
    self.scrollBar = scrollBar

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        self:GetScrollChild():SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offset)
    end)
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
            button.typeText:SetText(button.petType or "Battle Pet")
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

function PJX:RefreshPetList()
    local petIDs = GetOwnedPetIDs()
    for index, button in ipairs(self.petButtons) do
        local petID = petIDs[index]
        if petID then
            local name, icon, petType = GetPetDisplayInfo(petID)
            button.petID = petID
            button.petName = name
            button.petType = petType or "Battle Pet"
            button.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            button.name:SetText(name)
            button.typeText:SetText(button.petType)
            button:Show()
        else
            button.petID = nil
            button.petName = nil
            button.petType = nil
            button:Hide()
        end
    end

    local rows = math.ceil(#petIDs / 3)
    local height = math.max(rows * 78, 1)
    self.scrollChild:SetHeight(height)
    if self.scrollBar then
        local visibleHeight = self.petScroll:GetHeight()
        self.scrollBar:SetMinMaxValues(0, math.max(0, height - visibleHeight))
        self.scrollBar:SetValue(0)
    end
end

function PJX:Refresh()
    if not self.frame or not self.frame:IsShown() then
        return
    end
    self:RefreshSlots()
    self:RefreshPetList()
end

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
