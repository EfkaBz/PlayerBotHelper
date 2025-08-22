print("PlayerbotHelper chargé")

local classes = {
    { name = "warrior", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_warrior.blp" },
    { name = "paladin", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_paladin.blp" },
    { name = "hunter", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_hunter.blp" },
    { name = "rogue", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_rogue.blp" },
    { name = "priest", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_priest.blp" },
    { name = "dk", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_deathknight.blp" },
    { name = "shaman", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_shaman.blp" },
    { name = "mage", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_mage.blp" },
    { name = "warlock", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_warlock.blp" },
    { name = "druid", icon = "Interface\\AddOns\\PlayerbotHelper\\data\\classicons\\classicon_druid.blp" },
}

-- Fenêtre principale
local frame = CreateFrame("Frame", "PBH_MainFrame", UIParent)
frame:SetSize(260, 115)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
frame:Hide()

-- Cadre autour du titre
local titleBg = frame:CreateTexture(nil, "BACKGROUND")
titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
titleBg:SetSize(450, 64)
titleBg:SetPoint("TOP", frame, "TOP", 0, 20) -- Positionné un peu au-dessus de la frame

-- Titre de la fenêtre
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, 9)
title:SetText("PlayerbotHelper by Daeler")


-- Boutons pour chaque classe
for i, class in ipairs(classes) do
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(40, 40)
    btn:SetPoint("TOPLEFT", 15 + ((i - 1) % 5) * 48, -15 - math.floor((i - 1) / 5) * 48)

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexture(class.icon)

    btn:SetScript("OnClick", function()
        local command = ".playerbots bot addclass " .. class.name
        DEFAULT_CHAT_FRAME.editBox:SetText(command)
        ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
        print("|cff00ff00[PlayerbotHelper]: Bot " .. class.name .. " invoqué.")
    end)
end

-- Commande slash pour afficher/masquer la fenêtre
SLASH_PBHELPER1 = "/pbh"
SlashCmdList["PBHELPER"] = function()
    if PBH_MainFrame:IsShown() then
        PBH_MainFrame:Hide()
    else
        PBH_MainFrame:Show()
    end
end

-- === Boutons utilitaires (3 par ligne) ===
local function CreateUtilityButton(name, label, commandOrFn, index)
    local btn = CreateFrame("Button", name, frame, "UIPanelButtonTemplate")
    btn:SetSize(85, 20)

    local row = math.floor(index / 3)
    local col = index % 3
    local xOffset = -3 + col * 90
    local yOffset = -17 - (row * 20)

    btn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, yOffset)
    btn:SetText(label)

    btn:SetScript("OnClick", function()
        if type(commandOrFn) == "function" then
            commandOrFn()
        else
            local command = commandOrFn
            if command == "LEAVEGROUP" then
                LeaveParty()
                print("|cffff0000[PlayerbotHelper]: Tu as quitté le groupe.")
            else
                DEFAULT_CHAT_FRAME.editBox:SetText(command)
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
                print("|cff00ff00[PlayerbotHelper]: " .. label .. " exécuté.")
            end
        end
    end)
end

-- Liste des boutons utilitaires
CreateUtilityButton("PBH_SummonBtn",     "Summon",     "/p summon",                   0)
CreateUtilityButton("PBH_AutoGearBtn",   "Autogear",   "/p autogear",                 1)
CreateUtilityButton("PBH_MaintenanceBtn","Maintenance","/p maintenance",              2)
CreateUtilityButton("PBH_ReconnectBtn",  "Reconnect",  ".playerbots bot add *",       3)
CreateUtilityButton("PBH_DisconnectBtn", "Disconnect", ".playerbots bot remove *",    4)
CreateUtilityButton("PBH_LeaveGroupBtn", "Leave Group","LEAVEGROUP",                  5)
CreateUtilityButton("PBH_FollowBtn",     "Follow",     "/p follow",                   6)
CreateUtilityButton("PBH_StayBtn",       "Stay",       "/p stay",                     7)
CreateUtilityButton("PBH_GrindBtn",      "Grind",      "/p grind",                    8)
CreateUtilityButton("PBH_RaidBuilderBtn", "Raid Builder", function()
    if not PBH_RaidBuilderFrame then
        PBH_CreateRaidBuilderUI()
    end
    if PBH_RaidBuilderFrame:IsShown() then
        PBH_RaidBuilderFrame:Hide()
    else
        PBH_RaidBuilderFrame:Show()
    end
end, 9)




-- Minimap bouton
local radius = 80
local angle = 0
local dragging = false

-- Charger la position sauvegardée (si existante)
if not PlayerbotHelperDB then
    PlayerbotHelperDB = {}
end
angle = PlayerbotHelperDB.minimapAngle or 0

-- Créer le bouton autour de la minimap
local button = CreateFrame("Button", "PBH_MinimapButton", Minimap)
button:SetFrameStrata("MEDIUM")
button:SetSize(32, 32)
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")
button:SetClampedToScreen(true)

-- Icône personnalisée (centrée et recadrée)
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\AddOns\\PlayerbotHelper\\data\\icon\\icon_pbh.blp")
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
icon:SetPoint("TOPLEFT", button, "TOPLEFT", 6, -6)
icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 6)

-- Bordure ronde style Blizzard (décalée légèrement pour centrage)
local border = button:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("CENTER", button, "CENTER", 10, -12)

-- Surbrillance au survol
local highlight = button:CreateTexture(nil, "HIGHLIGHT")
highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
highlight:SetBlendMode("ADD")
highlight:SetAllPoints(button)

-- Click: ouvrir/fermer l'interface
button:SetScript("OnClick", function()
    if PBH_MainFrame:IsShown() then
        PBH_MainFrame:Hide()
    else
        PBH_MainFrame:Show()
    end
end)

-- Tooltip
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("PlayerbotHelper", 1, 1, 1)
    GameTooltip:AddLine("Clic pour ouvrir/fermer", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", GameTooltip_Hide)

-- Mise à jour de position du bouton
local function UpdatePosition()
    local x = cos(angle) * radius
    local y = sin(angle) * radius
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Dragging
button:SetScript("OnDragStart", function()
    dragging = true
    button:SetScript("OnUpdate", function()
        if dragging then
            local mx, my = GetCursorPosition()
            local cx, cy = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            mx, my = mx / scale, my / scale
            angle = math.deg(math.atan2(my - cy, mx - cx))
            UpdatePosition()
        end
    end)
end)

-- Fin du drag : sauvegarder la position
button:SetScript("OnDragStop", function()
    dragging = false
    button:SetScript("OnUpdate", nil)
    PlayerbotHelperDB.minimapAngle = angle
    UpdatePosition()
end)

-- Appliquer la position sauvegardée au démarrage
UpdatePosition()

-- =============================
-- ========== RAID BUILDER =====
-- =============================

local PBH_RB_MAX_SLOTS = 40
local PBH_RB_VISIBLE_SLOTS = 20   -- 20 par défaut

-- Helper: envoie une commande chat
local function PBH_SendCommand(cmd)
    DEFAULT_CHAT_FRAME.editBox:SetText(cmd)
    ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end

-- Helper: reset texte d'un dropdown
local function PBH_DD_SetEmpty(dd)
    UIDropDownMenu_SetText(dd, "- empty -")
    dd.selectedClass = nil
end

-- Récupère l'icône d'une classe
local function PBH_GetClassIcon(classname)
    for _, c in ipairs(classes) do
        if c.name == classname then
            return c.icon
        end
    end
end

-- ======== PRESETS COMPOS (Tanks, Heals, DPS) ========
-- NOTE: classes génériques pour .playerbots addclass
local PBH_RB_PRESETS = {
    [20] = {
        tanks = { "paladin", "dk" },                                  -- 2
        heals = { "paladin", "priest", "druid", "shaman" },           -- 4
        dps   = {                                                     -- 14
            "shaman","mage","warlock","priest","druid","dk","rogue",
            "warlock","hunter","mage","druid","rogue","warlock","mage"
        },
    },
    [25] = {
        tanks = { "paladin", "dk" },                                  -- 2
        heals = { "paladin","priest","druid","shaman","priest" },     -- 5
        dps   = {                                                     -- 18
            "shaman","mage","warlock","priest","druid","dk","rogue",
            "warlock","hunter","mage","druid","rogue","warlock","mage",
            "hunter","druid","dk","rogue"
        },
    },
    [40] = {
        tanks = { "warrior","warrior","druid" },                      -- 3
        heals = {                                                     -- 10
            "paladin","paladin","priest","priest","druid","shaman",
            "paladin","priest","druid","shaman"
        },
        dps   = {                                                     -- 27
            "warrior","rogue","mage","warlock","hunter","rogue","mage","warlock",
            "rogue","mage","warlock","hunter","mage","rogue","warlock","mage",
            "rogue","warlock","hunter","mage","rogue","warlock","mage","hunter",
            "warlock","rogue","mage"
        },
    },
}

local function PBH_FlattenPreset(p)
    local list = {}
    for _, cls in ipairs(p.tanks or {}) do table.insert(list, cls) end
    for _, cls in ipairs(p.heals or {}) do table.insert(list, cls) end
    for _, cls in ipairs(p.dps   or {}) do table.insert(list, cls) end
    return list
end

-- Retire 1 slot du rôle du joueur (pour faire N-1 bots)
local function PBH_RemoveOneForRole(preset, playerRole)
    local copy = { tanks = {}, heals = {}, dps = {} }
    for _,v in ipairs(preset.tanks or {}) do table.insert(copy.tanks, v) end
    for _,v in ipairs(preset.heals or {}) do table.insert(copy.heals, v) end
    for _,v in ipairs(preset.dps   or {}) do table.insert(copy.dps, v) end

    if playerRole == "TANK" and #copy.tanks > 0 then
        table.remove(copy.tanks, 1)
    elseif playerRole == "HEAL" and #copy.heals > 0 then
        table.remove(copy.heals, 1)
    elseif playerRole == "DPS" and #copy.dps > 0 then
        table.remove(copy.dps, 1)
    end
    return PBH_FlattenPreset(copy)
end

-- Crée 1 dropdown de classe (avec icône)
local function PBH_CreateClassDropdown(parent, index)
    local dd = CreateFrame("Frame", "PBH_RB_DD"..index, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10) -- sera repositionné après
    dd.selectedClass = nil

    UIDropDownMenu_Initialize(dd, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        -- Option vide
        info.text = "- empty -"
        info.func = function()
            UIDropDownMenu_SetText(dd, "- empty -")
            dd.selectedClass = nil
        end
        UIDropDownMenu_AddButton(info, level)

        -- Classes avec icônes
        for _, c in ipairs(classes) do
            info = UIDropDownMenu_CreateInfo()
            info.text = c.name
            info.icon = c.icon                 -- icône dans la liste
            info.tCoordLeft   = 0.07           -- rognage propre (comme Blizz)
            info.tCoordRight  = 0.93
            info.tCoordTop    = 0.07
            info.tCoordBottom = 0.93
            info.func = function()
                -- Affiche icône + nom dans le champ du dropdown
                UIDropDownMenu_SetText(dd, "|T"..c.icon..":16:16:0:0:64:64:5:59:5:59|t "..c.name)
                dd.selectedClass = c.name
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetWidth(dd, 120)
    UIDropDownMenu_SetText(dd, "- empty -")

    return dd
end

-- Positionne les dropdowns en grille
local function PBH_RB_PositionDropdowns(container, dropdowns, visibleCount)
    local cols = 5
    local spacingX, spacingY = 140, 32
    for i = 1, PBH_RB_MAX_SLOTS do
        local dd = dropdowns[i]
        if i <= visibleCount then
            dd:Show()
            local col = (i-1) % cols
            local row = math.floor((i-1) / cols)
            dd:ClearAllPoints()
            dd:SetPoint("TOPLEFT", container, "TOPLEFT", 10 + col*spacingX, -10 - row*spacingY)
        else
            dd:Hide()
        end
    end
end

-- Change mode 20/25/40
local function PBH_RB_SetMode(frame, count)
    PBH_RB_VISIBLE_SLOTS = count
    PBH_RB_PositionDropdowns(frame.scrollChild, frame.dropdowns, PBH_RB_VISIBLE_SLOTS)
    frame.title:SetText("Raid Builder ("..PBH_RB_VISIBLE_SLOTS.." slots)")
end

-- Nettoie tous les slots visibles (sauf le 1er: "Ton personnage")
local function PBH_RB_Clear(frame)
    for i = 2, PBH_RB_VISIBLE_SLOTS do
        PBH_DD_SetEmpty(frame.dropdowns[i])
    end
end

-- Invoque tous les slots visibles remplis (sauf le 1er)
local function PBH_RB_Invoke(frame)
    local invoked = 0
    for i = 2, PBH_RB_VISIBLE_SLOTS do
        local dd = frame.dropdowns[i]
        if dd.selectedClass and dd.selectedClass ~= "" then
            PBH_SendCommand(".playerbots bot addclass "..dd.selectedClass)
            invoked = invoked + 1
        end
    end
    print("|cff00ff00[PlayerbotHelper]: Invocation terminée. Bots ajoutés: "..invoked..".")
end

-- Applique une liste (N-1) sur l'UI (slots 2..N)
local function PBH_RB_ApplyListToUI(frame, list)
    PBH_RB_Clear(frame)
    local k = 1
    for i = 2, math.min(PBH_RB_VISIBLE_SLOTS, (#list + 1)) do
        local cls = list[k]
        if not cls then break end
        local dd = frame.dropdowns[i]
        local ic = PBH_GetClassIcon(cls)
        if ic then
            UIDropDownMenu_SetText(dd, "|T"..ic..":16:16:0:0:64:64:5:59:5:59|t "..cls)
        else
            UIDropDownMenu_SetText(dd, cls)
        end
        dd.selectedClass = cls
        k = k + 1
    end
end

-- Invoque directement une compo (N-1) sans le joueur
local function PBH_RB_InvokeList(list)
    local invoked = 0
    for _, cls in ipairs(list) do
        PBH_SendCommand(".playerbots bot addclass "..cls)
        invoked = invoked + 1
    end
    print("|cff00ff00[PlayerbotHelper]: Team invoquée ("..invoked.." bots).")
end

-- Popup choix du rôle (compat WotLK, sans template exotique)
local function PBH_RB_OpenRoleDialog(parentFrame, totalCount)
    if not PBH_RoleDialog then
        local d = CreateFrame("Frame", "PBH_RoleDialog", UIParent)
        d:SetFrameStrata("FULLSCREEN_DIALOG")
        d:SetToplevel(true)
        d:SetSize(220, 120)
        d:SetPoint("CENTER")
        d:SetMovable(true)
        d:EnableMouse(true)
        d:RegisterForDrag("LeftButton")
        d:SetScript("OnDragStart", d.StartMoving)
        d:SetScript("OnDragStop", d.StopMovingOrSizing)
        d:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })

        local title = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Selectionne ta spéc")
        d.title = title

        -- Tank
        local bTank = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
        bTank:SetSize(60, 22)
        bTank:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 10, 10)
        bTank:SetText("Tank")
        bTank:SetScript("OnClick", function()
            local preset = PBH_RB_PRESETS[d.pendingCount]
            if not preset then d:Hide() return end
            local list = PBH_RemoveOneForRole(preset, "TANK")
            PBH_RB_SetMode(parentFrame, d.pendingCount)
            PBH_RB_ApplyListToUI(parentFrame, list)
            PBH_RB_InvokeList(list)
            d:Hide()
        end)

        -- Heal
        local bHeal = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
        bHeal:SetSize(60, 22)
        bHeal:SetPoint("LEFT", bTank, "RIGHT", 10, 0)
        bHeal:SetText("Heal")
        bHeal:SetScript("OnClick", function()
            local preset = PBH_RB_PRESETS[d.pendingCount]
            if not preset then d:Hide() return end
            local list = PBH_RemoveOneForRole(preset, "HEAL")
            PBH_RB_SetMode(parentFrame, d.pendingCount)
            PBH_RB_ApplyListToUI(parentFrame, list)
            PBH_RB_InvokeList(list)
            d:Hide()
        end)

        -- DPS
        local bDps = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
        bDps:SetSize(60, 22)
        bDps:SetPoint("LEFT", bHeal, "RIGHT", 10, 0)
        bDps:SetText("DPS")
        bDps:SetScript("OnClick", function()
            local preset = PBH_RB_PRESETS[d.pendingCount]
            if not preset then d:Hide() return end
            local list = PBH_RemoveOneForRole(preset, "DPS")
            PBH_RB_SetMode(parentFrame, d.pendingCount)
            PBH_RB_ApplyListToUI(parentFrame, list)
            PBH_RB_InvokeList(list)
            d:Hide()
        end)

        PBH_RoleDialog = d
        tinsert(UISpecialFrames, "PBH_RoleDialog") -- fermeture via Echap
        d:Hide()
    end

    PBH_RoleDialog.pendingCount = totalCount
    PBH_RoleDialog:Show()
end

-- Création UI principale
function PBH_CreateRaidBuilderUI()
    if PBH_RaidBuilderFrame then return end

    local f = CreateFrame("Frame", "PBH_RaidBuilderFrame", UIParent)
    f:SetSize(800, 420)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    -- Titre
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetSize(450, 64)
    titleBg:SetPoint("TOP", f, "TOP", 0, 20)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, 9)
    title:SetText("Raid Builder ("..PBH_RB_VISIBLE_SLOTS.." slots)")
    f.title = title

    -- Conteneur simple (sans scrollbar)
    local child = CreateFrame("Frame", nil, f)
    child:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -35)
    child:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -35, 50)
    f.scrollChild = child

    -- Créer 40 dropdowns
    f.dropdowns = {}
    for i = 1, PBH_RB_MAX_SLOTS do
        f.dropdowns[i] = PBH_CreateClassDropdown(child, i)
    end

    -- Verrouiller le premier slot pour le joueur
    do
        local dd1 = f.dropdowns[1]
        UIDropDownMenu_SetText(dd1, "|cffffd100Ton personnage|r")
        dd1.selectedClass = nil
        if UIDropDownMenu_DisableDropDown then
            UIDropDownMenu_DisableDropDown(dd1)
        else
            dd1:EnableMouse(false)
            local btn = _G[dd1:GetName().."Button"]
            if btn then btn:Disable() end
            dd1:SetAlpha(0.8)
        end
    end

    -- Position initiale (20 visibles)
    PBH_RB_PositionDropdowns(child, f.dropdowns, PBH_RB_VISIBLE_SLOTS)

    -- Boutons 20 / 25 / 40
    local btn20 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn20:SetSize(60, 20)
    btn20:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 15)
    btn20:SetText("20")
    btn20:SetScript("OnClick", function() PBH_RB_SetMode(f, 20) end)

    local btn25 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn25:SetSize(60, 20)
    btn25:SetPoint("LEFT", btn20, "RIGHT", 5, 0)
    btn25:SetText("25")
    btn25:SetScript("OnClick", function() PBH_RB_SetMode(f, 25) end)

    local btn40 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn40:SetSize(60, 20)
    btn40:SetPoint("LEFT", btn25, "RIGHT", 5, 0)
    btn40:SetText("40")
    btn40:SetScript("OnClick", function() PBH_RB_SetMode(f, 40) end)

    -- Clear
    local btnClear = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnClear:SetSize(80, 20)
    btnClear:SetPoint("LEFT", btn40, "RIGHT", 10, 0)
    btnClear:SetText("Clear")
    btnClear:SetScript("OnClick", function() PBH_RB_Clear(f) end)

    -- ---- Boutons LOAD (ouvrent le choix de rôle) ----
    local btnLoad20 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnLoad20:SetSize(80, 20)
    btnLoad20:SetPoint("LEFT", btnClear, "RIGHT", 10, 0)
    btnLoad20:SetText("Load 20")
    btnLoad20:SetScript("OnClick", function() PBH_RB_OpenRoleDialog(f, 20) end)

    local btnLoad25 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnLoad25:SetSize(80, 20)
    btnLoad25:SetPoint("LEFT", btnLoad20, "RIGHT", 5, 0)
    btnLoad25:SetText("Load 25")
    btnLoad25:SetScript("OnClick", function() PBH_RB_OpenRoleDialog(f, 25) end)

    local btnLoad40 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnLoad40:SetSize(80, 20)
    btnLoad40:SetPoint("LEFT", btnLoad25, "RIGHT", 5, 0)
    btnLoad40:SetText("Load 40")
    btnLoad40:SetScript("OnClick", function() PBH_RB_OpenRoleDialog(f, 40) end)
    -- ---- FIN LOAD ----

    -- OK (Invoke) — invoque ce qui est dans l'UI (hors slot 1)
    local btnOK = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnOK:SetSize(100, 22)
    btnOK:SetPoint("RIGHT", f, "BOTTOMRIGHT", -15, 15)
    btnOK:SetText("OK (Summon)")
    btnOK:SetScript("OnClick", function() PBH_RB_Invoke(f) end)

    -- Fermer
    local btnClose = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnClose:SetSize(70, 20)
    btnClose:SetPoint("RIGHT", btnOK, "LEFT", -8, 0)
    btnClose:SetText("Close")
    btnClose:SetScript("OnClick", function() f:Hide() end)

    PBH_RaidBuilderFrame = f
    f:Hide() -- affichée via le bouton utilitaire
end