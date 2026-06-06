
local _,pje = ...

pje.constants = {
    -- Main Frame
    FRAME_WIDTH = 760,
    FRAME_HEIGHT = 540,

    -- Top Panel (Pet Slots)
    SLOT_WIDTH = 225,
    SLOT_HEIGHT = 160,
    NUM_LOADOUT_SLOTS = 3,
    SLOTS_PANEL_HEIGHT = 200,
    SLOT_LEFT_MARGIN = 6,

    -- Pet List Grid (3-column layout)
    GRID_VISIBLE_ROWS = 8,
    GRID_COLUMNS = 3,
    GRID_COLUMN_WIDTH = 230,
    GRID_ROW_HEIGHT = 40,
    GRID_BUTTON_WIDTH = 225,
    GRID_BUTTON_ICON_SIZE = 24,

    -- UI Spacing
    PANEL_MARGIN = 6,
    BOTTOM_LABEL_Y = -212,
    PET_LIST_Y = -240,

    -- Backdrop Colors
    SLOT_BACKDROP_COLOR = { 0.05, 0.05, 0.05, 0.75 },
    BUTTON_BACKDROP_COLOR = { 0.08, 0.08, 0.08, 0.85 },

    -- Pet Types (10 families)
    PETTYPES = {
        "Humanoid", "Dragonkin", "Flying", "Undead", "Critter",
        "Magic", "Elemental", "Beast", "Aquatic", "Mechanical"
    },

    BREEDS = {nil, nil, "B/B", "P/P", "S/S", "H/H", "H/P", "P/S", "H/S", "P/B", "S/B", "H/B"},
}