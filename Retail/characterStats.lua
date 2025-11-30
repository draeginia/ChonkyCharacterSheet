local addonName, ns = ...
local CCS = ns.CCS

if CCS.GetCurrentVersion() ~= CCS.RETAIL then
    return
end

local option = function(key) return CCS:GetOptionValue(key) end
local L = ns.L  -- grab the localization table
local module = {
    Name = "characterStats",
    CompatibleVersions = { CCS.RETAIL },
}

CCS.Modules[module.Name] = module

function CCS.round(num) 
    local returnstring = string.format("%." .. option("round") .. "f", num)
    return returnstring
end

local function UpdateMoveSpeed()
    --if InCombatLockdown()then CCS.incombat = true return end
    local btnfont2 = _G["CSPbtn24fs2"]
    if not btnfont2 or not option("showcharacterstats") then return end
    
    local currentSpeed, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player");
    runSpeed = runSpeed/BASE_MOVEMENT_SPEED*100;
    flightSpeed = flightSpeed/BASE_MOVEMENT_SPEED*100;
    swimSpeed = swimSpeed/BASE_MOVEMENT_SPEED*100;
    currentSpeed = currentSpeed/BASE_MOVEMENT_SPEED*100;
    local speed = runSpeed;
    
    if (UnitInVehicle("player")) then
        local vehicleSpeed = GetUnitSpeed("Vehicle")/BASE_MOVEMENT_SPEED*100;
        speed = vehicleSpeed
    elseif IsSwimming("player") then speed = swimSpeed;
    elseif UnitOnTaxi("player") then speed = currentSpeed;
    elseif IsFlying("player") then speed = flightSpeed;
    end
    btnfont2:SetText(format("%.0f%%", speed))
    
end

local function showrow(row)
    if row == nil then return false end
    
    if row == 1 then return option("show_headers") and option("show_attributes")
    elseif row == 2 then return option("show_attributes")
    elseif row == 3 then return option("show_attributes")
    elseif row == 4 then return option("show_attributes")
    elseif row == 5 then return option("show_headers") and option("show_secondary_stats")
    elseif row == 6 then return option("show_secondary_stats")
    elseif row == 7 then return option("show_secondary_stats")
    elseif row == 8 then return option("show_secondary_stats")
    elseif row == 9 then return option("show_secondary_stats")
    elseif row == 10 then return option("show_headers") and option("show_attack_stats")
    elseif row == 11 then return option("show_attack_stats")
    elseif row == 12 then return option("show_attack_stats")
    elseif row == 13 then return option("show_attack_stats")
    elseif row == 14 then return option("show_headers") and option("show_defense_stats")
    elseif row == 15 then return option("show_defense_stats")
    elseif row == 16 then return option("show_defense_stats")
    elseif row == 17 then return option("show_defense_stats")
    elseif row == 18 then return option("show_defense_stats")
    elseif row == 19 then return option("show_defense_stats")
    elseif row == 20 then return option("show_headers") and option("show_general_stats")
    elseif row == 21 then return option("show_general_stats")
    elseif row == 22 then return option("show_general_stats")
    elseif row == 23 then return option("show_general_stats")
    elseif row == 24 then return option("show_general_stats")
    end
    
    return false
end

function CCS:RestoreCharacterStatsPane()

    CharacterStatsPane.ItemLevelCategory:SetPoint("TOP", CharacterStatsPane, "TOP", -3, 2)
    CharacterStatsPane.ClassBackground:SetAlpha(1)

    -- Re-register default events
    CharacterStatsPane:RegisterUnitEvent("UNIT_STATS", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_RESISTANCES", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_ATTACK_POWER", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_RANGED_ATTACK_POWER", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_DAMAGE", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_AURA", "player")
    CharacterStatsPane:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")

    CharacterStatsPane:RegisterEvent("PLAYER_LEVEL_UP")
    CharacterStatsPane:RegisterEvent("PLAYER_ENTERING_WORLD")
    CharacterStatsPane:RegisterEvent("COMBAT_RATING_UPDATE")
    CharacterStatsPane:RegisterEvent("MASTERY_UPDATE")
    CharacterStatsPane:RegisterEvent("SPEED_UPDATE")
    CharacterStatsPane:RegisterEvent("LIFESTEAL_UPDATE")
    CharacterStatsPane:RegisterEvent("AVOIDANCE_UPDATE")
    CharacterStatsPane:RegisterEvent("PLAYER_TALENT_UPDATE")
    CharacterStatsPane:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    CharacterStatsPane:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
    CharacterStatsPane:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    CharacterStatsPane:RegisterEvent("UNIT_MODEL_CHANGED")
    if _G["CCS_stat_sf"] then _G["CCS_stat_sf"]:Hide() end
end

-- canonical stat order for tie-breaking
local StatOrder = {"CriticalStrike","Haste","Mastery","Versatility"}

local StatMap = {
    Mastery       = {name=ITEM_MOD_MASTERY_RATING_SHORT, rating=CR_MASTERY},
    CriticalStrike= {name=ITEM_MOD_CRIT_RATING_SHORT,    rating=CR_CRIT_SPELL},
    Haste         = {name=ITEM_MOD_HASTE_RATING_SHORT,   rating=CR_HASTE_SPELL},
    Versatility   = {name=STAT_VERSATILITY,              rating=CR_VERSATILITY_DAMAGE_DONE},
}

local function GetSortedStats(classID, specID, heroID)
    if not classID or not specID or not heroID or not option("show_secondarypriority") then
        -- return default order with dummy priorities
        local fallback = {}
        for i,stat in ipairs(StatOrder) do
            table.insert(fallback, {
                stat   = stat,
                prio   = i,
                tie    = i,
                name   = StatMap[stat].name,
                rating = StatMap[stat].rating,
            })
        end
        return fallback
    end

    local classTable = CCS.ClassSpecStatPriority[classID]
    if not classTable then return StatOrder end

    local specTable = classTable[specID]
    if not specTable then return StatOrder end

    local priorities = specTable[heroID]
    if not priorities then return StatOrder end

    -- build array of {statName, priority, tieIndex, localized name, rating constant}
    local stats = {
        {stat="Mastery",        prio=priorities[1], tie=1, name=StatMap.Mastery.name,        rating=StatMap.Mastery.rating},
        {stat="CriticalStrike", prio=priorities[2], tie=2, name=StatMap.CriticalStrike.name, rating=StatMap.CriticalStrike.rating},
        {stat="Haste",          prio=priorities[3], tie=3, name=StatMap.Haste.name,          rating=StatMap.Haste.rating},
        {stat="Versatility",    prio=priorities[4], tie=4, name=StatMap.Versatility.name,    rating=StatMap.Versatility.rating},
    }

    table.sort(stats, function(a,b)
        if a.prio == b.prio then
            return a.tie < b.tie
        else
            return a.prio < b.prio
        end
    end)

    return stats
end


function module:Initialize()
    --if InCombatLockdown()then CCS.incombat = true return end
    local Width = 230 
    local Height = 23
    local yOffset = 3.5
    local r, g, b, alpha =1,1,1,1                 
    
    if UnitLevel("player") < 10 then return end
    
    if option("showcharacterstats") then
        CharacterStatsPane.ItemLevelCategory:SetPoint("TOP", CharacterStatsPane, "TOP", -3, -7000)
        CharacterStatsPane.ClassBackground:SetAlpha(0)
        CharacterStatsPane:UnregisterAllEvents()
    end
      
    if option("showcharacterstats") then
        local _, _, classID = UnitClass("player")
        local specID = GetSpecialization()
        local heroID = (C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec and C_ClassTalents.GetActiveHeroTalentSpec()) or nil
        local canShowsortedStates = classID ~= nil and specID ~= nil and heroID ~= nil
        local sortedStats = GetSortedStats(classID, specID, heroID)
       
        -- Just a little code to create a scrolling frame to house the stats.  That way we can scroll if we resize the character frame.
        local scrollFrame = _G["CCS_stat_sf"] or CreateFrame("ScrollFrame", "CCS_stat_sf", CharacterStatsPane, "UIPanelScrollFrameTemplate")
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", CharacterStatsPane, "TOPLEFT", 10, 0)
        scrollFrame:SetPoint("BOTTOMRIGHT", CharacterStatsPane, "BOTTOMRIGHT", 3, -10)
        scrollFrame:Show()
        
        local scrollChild = _G["CCS_stat_sc"] or CreateFrame("Frame", _G["CCS_stat_sc"], scrollFrame )
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:SetWidth(Width)
        scrollChild:SetHeight(1)
        if scrollFrame:GetVerticalScrollRange() > 0 then  CCS_stat_sfScrollBar:Show() else CCS_stat_sfScrollBar:Hide() end
        
        -- Ilvl Frame
        
        local btn = _G["CSPilvl"] or CreateFrame("Button", "CSPilvl", scrollChild)
        local btnfont1
        local btnfontilvl = _G["CSPilvlfs1"] or btn:CreateFontString("CSPilvlfs1")
        local btntex = _G["CSPilvltex"] or btn:CreateTexture("CSPilvltex", "BACKGROUND", nil, 1)
        local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel();
        local Color = "a336ed"
        local tt_name = ""
        local tt_desc = ""

        btn:SetParent(scrollChild)
        btn:ClearAllPoints()
        btn:SetSize(Width, Height*(option("fontsize_cilvl") or 20) /20)
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
        btn:SetFrameStrata("HIGH")
        btn.throttle = 0;
        btn:Show()       
        
        btntex:ClearAllPoints()
        btntex:SetAllPoints()
        btntex:SetTexture("Interface\\Masks\\SquareMask.BLP")
        btntex:SetGradient("Vertical", CreateColor(0, 0, 0, .2), CreateColor(.1, .1, .1, .4)) -- Dark Gray
        btnfontilvl:SetPoint("CENTER", btn, "CENTER", 0 ,0)
        btnfontilvl:SetFont(option("fontname_cilvl") or CCS.fontname, (option("fontsize_cilvl") or 20))

        CCS.PreloadEquippedItemInfo("player")
        CCS.WaitForItemInfoReady("player", function()
            local color = CCS:GetAverageEquippedRarityHex("player")
            Color = color

            avgItemLevelEquipped = format("%.2f", avgItemLevelEquipped)
            avgItemLevel = format("%.2f", avgItemLevel)
            avgItemLevelPvP = format("%.2f", avgItemLevelPvP)

            btnfontilvl:SetText(format("|cFF%s%s / %s|r", Color, avgItemLevelEquipped, avgItemLevel))

            tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVERAGE_ITEM_LEVEL).." "..avgItemLevel
            tt_name = tt_name .. "  " .. format(STAT_AVERAGE_ITEM_LEVEL_EQUIPPED, avgItemLevelEquipped)
            tt_name = tt_name .. FONT_COLOR_CODE_CLOSE

            tt_desc = STAT_AVERAGE_ITEM_LEVEL_TOOLTIP
            tt_desc = tt_desc.."\n\n"..STAT_AVERAGE_PVP_ITEM_LEVEL:format(avgItemLevelPvP)

            btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                GameTooltip:AddDoubleLine(tt_name, nil, 1, 1, 1, 1, 1, 1)
                GameTooltip:AddLine(tt_desc, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        end)
        
        -- Health Frame
        btn = _G["CSPhp"] or CreateFrame("Button", "CSPhp", scrollChild)
        btnfont1 = _G["CSPhpfs1"] or btn:CreateFontString("CSPhpfs1")
        btnfont2 = _G["CSPhpfs2"] or btn:CreateFontString("CSPhpfs2")
        btntex = _G["CSPhptex"] or btn:CreateTexture("CSPhptex", "BACKGROUND", nil, 1)
        tt_name = ""
        tt_desc = ""

        local health = UnitHealthMax("player");
        local healthText = BreakUpLargeNumbers(health);
        
        btn:SetParent(scrollChild)
        btn:ClearAllPoints()

        btn:SetSize(Width, Height*(option("fontsize_hppower") or 17)/17)
        btn:SetPoint("TOPLEFT", CSPilvl, "BOTTOMLEFT", 0, -yOffset)            
        btn:SetFrameStrata("HIGH")
        btn:Show()            
        
        btntex:ClearAllPoints()
        btntex:SetAllPoints()
        btntex:SetTexture("Interface\\Masks\\SquareMask.BLP")
        btntex:SetGradient("Horizontal", CreateColor(1, 0, 0, 0.4), CreateColor(1, 0, 0, 0)) -- Red (for HP)
        
        btnfont1:SetPoint("LEFT", CSPhp, "LEFT", 0 ,0)
        btnfont1:SetFont(option("fontname_hppower") or CCS.fontname, (option("fontsize_hppower") or 12), CCS.textoutline)
        btnfont1:SetTextColor(
            option("fontcolor_hppower")[1] or 1,
            option("fontcolor_hppower")[2] or 1,
            option("fontcolor_hppower")[3] or 1,
            option("fontcolor_hppower")[4] or 1
        )
        btnfont1:SetText(ITEM_MOD_HEALTH_SHORT)
        
        btnfont2:SetPoint("RIGHT", CSPhp, "RIGHT", 0 ,0)
        btnfont2:SetFont(option("fontname_hppower") or CCS.fontname, (option("fontsize_hppower") or 12), CCS.textoutline)
        btnfont2:SetTextColor(
            option("fontcolor_hppower")[1] or 1,
            option("fontcolor_hppower")[2] or 1,
            option("fontcolor_hppower")[3] or 1,
            option("fontcolor_hppower")[4] or 1
        )
        
        btnfont2:SetText(healthText)
        
        
        tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, HEALTH).." "..healthText..FONT_COLOR_CODE_CLOSE;
        tt_desc = STAT_HEALTH_TOOLTIP;
        
        btn:SetScript("OnEnter", function() GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                GameTooltip:AddDoubleLine(tt_name, nil, 1, 1, 1, 1, 1, 1) 
                GameTooltip:AddLine(tt_desc, nil, nil, nil, true)   
                GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Character Power Frame
        btn = _G["CSPpower"] or CreateFrame("Button", "CSPpower", scrollChild)
        btnfont1 = _G["CSPpowerfs1"] or btn:CreateFontString("CSPpowerfs1")
        btnfont2 = _G["CSPpowerfs2"] or btn:CreateFontString("CSPpowerfs2")
        btntex = _G["CSPpowertex"] or btn:CreateTexture("CSPpowertex", "BACKGROUND", nil, 1)
        local powerType, powerToken, altR, altG, altB = UnitPowerType("player")
        local power = UnitPowerMax("player") or 0;
        local powerText = BreakUpLargeNumbers(power);
        local info = PowerBarColor[powerToken];
        tt_name = ""
        tt_desc = ""
        altR, altG, altB = 0.1, 0.1, 0.1
        if info then altR, altG, altB = info.r, info.g, info.b end
        
        btn:SetParent(scrollChild)
        btn:ClearAllPoints()
        btn:SetFrameStrata("HIGH")
        btn:Show()            
        
        btn:SetSize(Width, Height*(option("fontsize_hppower") or 17)/17)
        btn:SetPoint("TOPLEFT", CSPhp, "BOTTOMLEFT", 0, -yOffset)            
        btn:SetFrameStrata("HIGH")
        btn:Show()            
        
        btntex:ClearAllPoints()
        btntex:SetAllPoints()
        btntex:SetTexture("Interface\\Masks\\SquareMask.BLP")
        btntex:SetGradient("Horizontal", CreateColor(altR, altG, altB, 0.4), CreateColor(altR, altG, altB, 0)) -- Color based on power type
        
        btnfont1:SetPoint("LEFT", btn, "LEFT", 0 ,0)
        btnfont1:SetFont(option("fontname_hppower") or CCS.fontname, (option("fontsize_hppower") or 12), CCS.textoutline)
        btnfont1:SetTextColor(
            option("fontcolor_hppower")[1] or 1,
            option("fontcolor_hppower")[2] or 1,
            option("fontcolor_hppower")[3] or 1,
            option("fontcolor_hppower")[4] or 1
        )
        btnfont1:SetText(CCS.POWER_TYPES_TABLE[powerType])
        
        btnfont2:SetPoint("RIGHT", btn, "RIGHT", 0 ,0)
        btnfont2:SetFont(option("fontname_hppower") or CCS.fontname, (option("fontsize_hppower") or 12), CCS.textoutline)
        btnfont2:SetTextColor(
            option("fontcolor_hppower")[1] or 1,
            option("fontcolor_hppower")[2] or 1,
            option("fontcolor_hppower")[3] or 1,
            option("fontcolor_hppower")[4] or 1
        )
        btnfont2:SetText(powerText)
        
        tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, (powerToken or "")).." "..(powerText or "") .. FONT_COLOR_CODE_CLOSE;
        tt_desc = _G["STAT_"..(powerToken or "") .."_TOOLTIP"];
        
        btn:SetScript("OnEnter", function() GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                GameTooltip:AddDoubleLine(tt_name, nil, 1, 1, 1, 1, 1, 1) 
                GameTooltip:AddLine(tt_desc, nil, nil, nil, true)   
                GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        ---------------------------
        --  Start Frame Creation --
        ---------------------------
        local prev_row = scrollChild
        
        for row = 1, 24 do -- just mass creating the frames, textures, and strings, will set them later
            btn = _G["CSPbtn"..row] or CreateFrame("Button", "CSPbtn"..row, scrollChild)
            btnfont1 = _G[btn:GetName().."fs1"] or btn:CreateFontString(btn:GetName().."fs1")
            btnfont2 = _G[btn:GetName().."fs2"] or btn:CreateFontString(btn:GetName().."fs2")
            btntex = _G[btn:GetName().."tex"] or btn:CreateTexture(btn:GetName().."tex", "BACKGROUND", nil, 1)
            local tooltip = false
            tt_name = ""
            tt_desc = ""
            
            if row == 1 or row == 2 or row == 3 or row == 4 then
                --r =0.64; g =0.47; b = 0.1 -- Gold
                r       = option("ccs_attribute_color")[1] or 0.64
                g       = option("ccs_attribute_color")[2] or 0.47
                b       = option("ccs_attribute_color")[3] or 0.1
                alpha   = option("ccs_attribute_color")[4] or 0.4
            elseif row == 5 or row == 6 or row == 7 or row == 8 or row == 9 then
                --r =0.16; g =0.34; b = 0.08 -- Dark Green
                r       = option("ccs_secondary_stats_color")[1] or 0.16
                g       = option("ccs_secondary_stats_color")[2] or 0.34
                b       = option("ccs_secondary_stats_color")[3] or 0.08
                alpha   = option("ccs_secondary_stats_color")[4] or 0.4                
            elseif row == 10 or row == 11 or row == 12 or row == 13 then
                --r =0.41; g =0; b = 0 -- Dark Red            
                r       = option("ccs_attack_stats_color")[1] or 0.41
                g       = option("ccs_attack_stats_color")[2] or 0
                b       = option("ccs_attack_stats_color")[3] or 0
                alpha   = option("ccs_attack_stats_color")[4] or 0.4                                
            elseif row == 14 or row == 15 or row == 16 or row == 17 or row == 18 or row == 19 then
                --r =0; g =0.13; b = 0.38 -- Dark Blue            
                r       = option("ccs_defense_stats_color")[1] or 0
                g       = option("ccs_defense_stats_color")[2] or 0.13
                b       = option("ccs_defense_stats_color")[3] or 0.38
                alpha   = option("ccs_defense_stats_color")[4] or 0.4                                
            else
                --r =0.45; g =0.45; b = 0.45-- Gray        
                r       = option("ccs_general_color")[1] or 0.45
                g       = option("ccs_general_color")[2] or 0.45
                b       = option("ccs_general_color")[3] or 0.45
                alpha   = option("ccs_general_color")[4] or 0.4                                
                
            end
            
            btn:SetParent(scrollChild)
            btn:ClearAllPoints()
            btntex:SetTexture("Interface\\Masks\\SquareMask.BLP")
            
            -- Header Rows     
            if row == 1 or row == 5 or row == 10 or row == 14 or row == 20 then
                
                btn:SetSize(Width, Height*(option("fontsize_statheaders") or 14)/14)
                if (prev_row == scrollChild) then 
                    btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset*30)
                else
                    btn:SetPoint("TOPLEFT", prev_row, "BOTTOMLEFT", 0, -yOffset)--*3)
                end
                btn:SetFrameStrata("HIGH")
                btntex:SetAllPoints()

                if option("ccs_stats_solidbg") then
                    btntex:SetVertexColor(r, g, b, alpha)
                else
                    btntex:SetGradient("Horizontal", CreateColor(0, 0, 0, alpha/2), CreateColor(r, g, b, alpha))
                end
                
                btnfont1:SetPoint("CENTER", btn, "CENTER", 0 ,0)
                btnfont1:SetFont(option("fontname_statheaders") or CCS.fontname, (option("fontsize_statheaders") or 14), CCS.textoutline)
                btnfont1:SetText(STAT_CATEGORY_ATTRIBUTES)
                btnfont1:SetTextColor(
                    option("fontcolor_statheaders")[1] or 1,
                    option("fontcolor_statheaders")[2] or 1,
                    option("fontcolor_statheaders")[3] or 1,
                    option("fontcolor_statheaders")[4] or 1
                )
                
                
            else -- all other rows
                btn:SetSize(Width, Height/2*(math.max(option("fontsize_stats"), option("fontsize_statname")) or 10)/10)
                
                if (prev_row == scrollChild) then 
                    btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset*30)
                else
                    btn:SetPoint("TOPLEFT", prev_row, "BOTTOMLEFT", 0, -yOffset)
                end
                
                btn:SetFrameStrata("HIGH")
                
                btntex:SetAllPoints()

                if option("ccs_stats_solidbg") then
                   btntex:SetVertexColor(r, g, b, alpha)
                else
                   btntex:SetGradient("Horizontal",CreateColor(r, g, b, alpha), CreateColor(0, 0, 0, alpha/2))
                end
                
                btnfont1:SetPoint("LEFT", btn, "LEFT", 0 ,0)
                btnfont1:SetFont(option("fontname_statname") or CCS.fontname, (option("fontsize_statname") or 10), CCS.textoutline)
                btnfont1:SetText("Name")
                btnfont1:SetTextColor(
                    option("fontcolor_statname")[1] or 1,
                    option("fontcolor_statname")[2] or 1,
                    option("fontcolor_statname")[3] or 1,
                    option("fontcolor_statname")[4] or 1
                )
               
                btnfont2:SetPoint("RIGHT", btn, "RIGHT", 0 ,0)
                btnfont2:SetFont(option("fontname_stats") or CCS.fontname, (option("fontsize_stats") or 10), CCS.textoutline)
                btnfont2:SetText("Value")
                btnfont2:SetTextColor(
                    option("fontcolor_stats")[1] or 1,
                    option("fontcolor_stats")[2] or 1,
                    option("fontcolor_stats")[3] or 1,
                    option("fontcolor_stats")[4] or 1
                )
                
                tooltip = true
            end
            
            if showrow(row) then
                btn:Show()            
                prev_row = btn
            else
                btn:Hide()            
            end
            
            ---------------------------
            -- Attributes Category
            ---------------------------
            if         row == 1 then btnfont1:SetText(STAT_CATEGORY_ATTRIBUTES)
            elseif    row == 2 then -- Primary Stat
                local spec = GetSpecialization()
                local _, _, _, _, _, primaryStat = GetSpecializationInfo(spec)
                local role = GetSpecializationRole(spec);
                local tmp_stat_name = {ITEM_MOD_STRENGTH_SHORT, ITEM_MOD_AGILITY_SHORT, ITEM_MOD_STAMINA_SHORT, ITEM_MOD_INTELLECT_SHORT, ITEM_MOD_SPIRIT_SHORT};
                local tmp_stat_value= 0
                local statIndex
                local stat, effectiveStat, posBuff, negBuff
                
                
                if primaryStat == 1 then 
                    tmp_stat_value, effectiveStat, posBuff, negBuff = UnitStat("player", 1);
                    tt_desc = DEFAULT_STAT1_TOOLTIP;
                elseif primaryStat == 2 then 
                    tmp_stat_value, effectiveStat, posBuff, negBuff = UnitStat("player", 2);
                    tt_desc = DEFAULT_STAT2_TOOLTIP;
                else 
                    tmp_stat_value, effectiveStat, posBuff, negBuff = UnitStat("player", 4);
                    tt_desc = DEFAULT_STAT4_TOOLTIP;
                end
                
                btnfont1:SetText(tmp_stat_name[primaryStat])                                
                btnfont2:SetText(BreakUpLargeNumbers(tmp_stat_value))
                
                stat = tmp_stat_value;
                local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);
                statIndex = primaryStat;
                -- Set the tooltip text
                
                local tooltipText = ""
                
                if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
                    tt_name = tt_name..effectiveStatDisplay..FONT_COLOR_CODE_CLOSE;
                else
                    tooltipText = tooltipText..effectiveStatDisplay;
                    if ( posBuff > 0 or negBuff < 0 ) then
                        tooltipText = tooltipText.." ("..BreakUpLargeNumbers(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
                    end
                    if ( posBuff > 0 ) then
                        tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff)..FONT_COLOR_CODE_CLOSE;
                    end
                    if ( negBuff < 0 ) then
                        tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff)..FONT_COLOR_CODE_CLOSE;
                    end
                    if ( posBuff > 0 or negBuff < 0 ) then
                        tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
                    end
                    tt_name = tooltipText;
                    
                    -- If there are any negative buffs then show the main number in red even if there are
                    -- positive buffs. Otherwise show in green.
                    if ( negBuff < 0 and not GetPVPGearStatRules() ) then
                        effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay..FONT_COLOR_CODE_CLOSE;
                    end
                end
                
                -- Strength
                if ( statIndex == LE_UNIT_STAT_STRENGTH ) then
                    local attackPower = GetAttackPowerForStat(statIndex,effectiveStat);
                    if (HasAPEffectsSpellPower()) then
                        tt_desc = STAT_TOOLTIP_BONUS_AP_SP;
                    end
                    if (not primaryStat or primaryStat == LE_UNIT_STAT_STRENGTH) then
                        tt_desc = format(tt_desc, BreakUpLargeNumbers(attackPower));
                        if ( role == "TANK" ) then
                            local increasedParryChance = GetParryChanceFromAttribute();
                            if ( increasedParryChance > 0 ) then
                                tt_desc = tt_desc.."|n|n"..format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance);
                            end
                        end
                    else
                        tt_desc = STAT_NO_BENEFIT_TOOLTIP;
                    end
                    -- Agility
                elseif ( statIndex == LE_UNIT_STAT_AGILITY ) then
                    local attackPower = GetAttackPowerForStat(statIndex,effectiveStat);
                    local tooltip4 = STAT_TOOLTIP_BONUS_AP;
                    if (HasAPEffectsSpellPower()) then
                        tooltip4 = STAT_TOOLTIP_BONUS_AP_SP;
                    end
                    if (not primaryStat or primaryStat == LE_UNIT_STAT_AGILITY) then
                        tt_desc = format(tooltip4, BreakUpLargeNumbers(attackPower));
                        if ( role == "TANK" ) then
                            local increasedDodgeChance = GetDodgeChanceFromAttribute();
                            if ( increasedDodgeChance > 0 ) then
                                tt_desc = tt_desc.."|n|n"..format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance);
                            end
                        end
                    else
                        tt_desc = STAT_NO_BENEFIT_TOOLTIP;
                    end
                    -- Stamina
                elseif ( statIndex == LE_UNIT_STAT_STAMINA ) then
                    tt_desc = format(tt_desc, BreakUpLargeNumbers(((effectiveStat*UnitHPPerStamina("player")))*GetUnitMaxHealthModifier("player")));
                    -- Intellect
                elseif ( statIndex == LE_UNIT_STAT_INTELLECT ) then
                    if ( UnitHasMana("player") ) then
                        if (HasAPEffectsSpellPower()) then
                            tt_desc = STAT_NO_BENEFIT_TOOLTIP;
                        else
                            local result, druid = HasSPEffectsAttackPower();
                            if (result and druid) then
                                tt_desc = format(STAT_TOOLTIP_SP_AP_DRUID, max(0, effectiveStat), max(0, effectiveStat));
                            elseif (result) then
                                tt_desc = format(STAT_TOOLTIP_BONUS_AP_SP, max(0, effectiveStat));
                            elseif (not primaryStat or primaryStat == LE_UNIT_STAT_INTELLECT) then
                                tt_desc = format(tt_desc, max(0, effectiveStat));
                            else
                                tt_desc = STAT_NO_BENEFIT_TOOLTIP;
                            end
                        end
                    else
                        tt_desc = STAT_NO_BENEFIT_TOOLTIP;
                    end
                end
                
            elseif row == 3 then  -- Stamina
                local statIndex = 3 -- Stamina
                local tmp_stat_value, effectiveStat = UnitStat("player", statIndex);
                                
                btnfont1:SetText(format("%s", ITEM_MOD_STAMINA_SHORT))                                
                btnfont2:SetText(BreakUpLargeNumbers(tmp_stat_value))
                
                local statName = _G["SPELL_STAT"..statIndex.."_NAME"];
                
                local statName = _G["SPELL_STAT"..statIndex.."_NAME"];
                local hpperstam = 20 --UnitHPPerStamina("player") --hard code to 20?
                local maxhealthmod = 1 --GetUnitMaxHealthModifier("player") -- Btw. This is a secret value now for some reason...
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName).." ";
                tt_desc = tt_desc .. format(_G["DEFAULT_STAT"..statIndex.."_TOOLTIP"], BreakUpLargeNumbers(((effectiveStat*hpperstam))*maxhealthmod));                
                
                --tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName).." ";
                --tt_desc = tt_desc .. format(_G["DEFAULT_STAT"..statIndex.."_TOOLTIP"], BreakUpLargeNumbers(((effectiveStat*UnitHPPerStamina("player")))*GetUnitMaxHealthModifier("player")));
                
            elseif row == 4 then -- Global Cooldown
                local gcd = max(0.75, 1.5 * 100 / (100+GetHaste()))
                local _, _, _, _, _, primaryStat = GetSpecializationInfo(GetSpecialization())
                local _, class = UnitClass("player")
                
                btnfont1:SetText("GCD")
                
                if (class == "DRUID") then 
                    if GetShapeshiftFormID() == 1 then gcd = 1 end
                elseif (primaryStat == LE_UNIT_STAT_INTELLECT) or (primaryStat == LE_UNIT_STAT_STRENGTH) or (class == "DEMONHUNTER") or (class == "HUNTER") or (class == "SHAMAN") then 
                    gcd = gcd
                else gcd = 1
                end
                btnfont2:SetText(format("%.2fs", gcd))
                ---------------------------                
                -- Secondary Category
                ---------------------------
            elseif    row == 5 then 
                if option("show_secondarypriority") and canShowsortedStates then
                    btnfont1:SetText(L["Secondary (Priority)"])
                else
                    btnfont1:SetText(SECONDARY)
                end
            elseif row >= 6 and row <= 9 then
                local statKey = sortedStats[row-5]  -- row 6 → index 1, row 7 → index 2, etc.
                local statName = statKey.name
                
                if option("show_secondarypriority") and canShowsortedStates then
                   statName = format("%s ",statKey.prio) .. (statName or "")
                end


                if statKey.rating == CR_CRIT_SPELL then
                    btnfont1:SetText(statName)
                    btnfont2:SetText(format('(%s%%) %6.6s',
                        CCS.round(GetSpellCritChance('player')),
                        BreakUpLargeNumbers(GetCombatRating(statKey.rating))))
                    local extraCritChance = GetCombatRatingBonus(statKey.rating)
                    local extraCritRating = GetCombatRating(statKey.rating)
                    tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE)..FONT_COLOR_CODE_CLOSE
                    if GetCritChanceProvidesParryEffect() then
                        tt_desc = format(CR_CRIT_PARRY_RATING_TOOLTIP,
                            BreakUpLargeNumbers(extraCritRating),
                            extraCritChance,
                            GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating))
                    else
                        tt_desc = format(CR_CRIT_TOOLTIP,
                            BreakUpLargeNumbers(extraCritRating),
                            extraCritChance)
                    end

                elseif statKey.rating == CR_HASTE_SPELL then
                    btnfont1:SetText(statName)
                    btnfont2:SetText(format('(%s%%) %6.6s',
                        CCS.round(UnitSpellHaste('player')),
                        BreakUpLargeNumbers(GetCombatRating(statKey.rating))))
                    tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_HASTE)..FONT_COLOR_CODE_CLOSE
                    local _, class = UnitClass("player")
                    tt_desc = _G["STAT_HASTE_"..class.."_TOOLTIP"] or STAT_HASTE_TOOLTIP
                    tt_desc = tt_desc .. format(STAT_HASTE_BASE_TOOLTIP,
                        BreakUpLargeNumbers(GetCombatRating(statKey.rating)),
                        GetCombatRatingBonus(statKey.rating))

                elseif statKey.rating == CR_MASTERY then
                    btnfont1:SetText(statName)
                    btnfont2:SetText(format('(%s%%) %6.6s',
                        CCS.round(GetMasteryEffect('player')),
                        BreakUpLargeNumbers(GetCombatRating(statKey.rating))))
                    local _, class = UnitClass("player")
                    local mastery, bonusCoeff = GetMasteryEffect()
                    local masteryBonus = GetCombatRatingBonus(statKey.rating) * bonusCoeff
                    tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MASTERY)..FONT_COLOR_CODE_CLOSE
                    local primaryTalentTree = GetSpecialization()
                    if primaryTalentTree then
                        local masterySpell, masterySpell2 = GetSpecializationMasterySpells(primaryTalentTree)
                        if masterySpell then
                            tt_desc = (C_Spell.GetSpellDescription(masterySpell) or "\n")
                        end
                        if masterySpell2 then
                            tt_desc = (tt_desc or "") .. "\n" .. (C_Spell.GetSpellDescription(masterySpell2) or "\n")
                        end
                        tt_desc = (tt_desc or "") .. "\n" .. format(STAT_MASTERY_TOOLTIP,
                            BreakUpLargeNumbers(GetCombatRating(statKey.rating)),
                            masteryBonus)
                    else
                        tt_desc = format(STAT_MASTERY_TOOLTIP,
                            BreakUpLargeNumbers(GetCombatRating(statKey.rating)),
                            masteryBonus) .. "\n" .. STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC
                    end

                elseif statKey.rating == CR_VERSATILITY_DAMAGE_DONE then
                    local versatility = GetCombatRating(statKey.rating)
                    local versatilityDamageBonus = GetCombatRatingBonus(statKey.rating) + GetVersatilityBonus(statKey.rating)
                    local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)
                    btnfont1:SetText(statName)
                    btnfont2:SetText(format('(%s%% / %s%%) %6.6s',
                        CCS.round(versatilityDamageBonus),
                        CCS.round(versatilityDamageTakenReduction),
                        BreakUpLargeNumbers(versatility)))
                    tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_VERSATILITY)..FONT_COLOR_CODE_CLOSE
                    tt_desc = format(CR_VERSATILITY_TOOLTIP,
                        versatilityDamageBonus,
                        versatilityDamageTakenReduction,
                        BreakUpLargeNumbers(versatility),
                        versatilityDamageBonus,
                        versatilityDamageTakenReduction)
                end


                --[[
            elseif    row == 6 then 
                -- Crit Rating
                btnfont1:SetText(format("%s", ITEM_MOD_CRIT_RATING_SHORT))                
                btnfont2:SetText(format('(%s%%) %6.6s',CCS.round(GetSpellCritChance('player')), BreakUpLargeNumbers(GetCombatRating(CR_CRIT_SPELL))))
                
                local extraCritChance = GetCombatRatingBonus(CR_CRIT_SPELL);
                local extraCritRating = GetCombatRating(CR_CRIT_SPELL);
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE)..FONT_COLOR_CODE_CLOSE;
                if (GetCritChanceProvidesParryEffect()) then
                    tt_desc = format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating));
                else
                    tt_desc =  format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance);
                end
                
            elseif    row == 7 then  
                -- Haste Rating
                btnfont1:SetText(format("%s", ITEM_MOD_HASTE_RATING_SHORT))                
                btnfont2:SetText(format('(%s%%) %6.6s',CCS.round(UnitSpellHaste('player')), BreakUpLargeNumbers(GetCombatRating(CR_HASTE_SPELL))))

                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_HASTE)..FONT_COLOR_CODE_CLOSE;                
                
                
                local _, class = UnitClass("player");
                tt_desc = _G["STAT_HASTE_"..class.."_TOOLTIP"];
                if (not tt_desc) then tt_desc = STAT_HASTE_TOOLTIP;    end
                tt_desc = tt_desc .. format(STAT_HASTE_BASE_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_HASTE_SPELL)), GetCombatRatingBonus(CR_HASTE_SPELL));
                
            elseif    row == 8 then 
                -- Mastery Rating

                btnfont1:SetText(format("%s", ITEM_MOD_MASTERY_RATING_SHORT))                
                btnfont2:SetText(format('(%s%%) %6.6s',CCS.round(GetMasteryEffect('player')),BreakUpLargeNumbers(GetCombatRating(CR_MASTERY))))
                
                local _, class = UnitClass("player");
                local mastery, bonusCoeff = GetMasteryEffect();
                local masteryBonus = GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;
                
                local primaryTalentTree = GetSpecialization();
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MASTERY)..FONT_COLOR_CODE_CLOSE;
                
                if (primaryTalentTree) then
                    local masterySpell, masterySpell2 = GetSpecializationMasterySpells(primaryTalentTree);
                    
                    if (masterySpell) then
                        local spelldesc = C_Spell.GetSpellDescription(masterySpell)
                        tt_desc = tt_desc .. (spelldesc or "\n")
                    end
                    
                    if (masterySpell2) then
                        local spelldesc = C_Spell.GetSpellDescription(masterySpell2)
                        tt_desc = tt_desc .. "\n" .. (spelldesc or "\n")
                    end
                    
                    tt_desc = tt_desc .. "\n" .. format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_MASTERY)), masteryBonus)
                else
                    tt_desc = tt_desc .. format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_MASTERY)), masteryBonus) .. "\n" .. STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC
                end
                
            elseif    row == 9 then 
                -- Versatility Rating
                local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
                local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
                local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);
                
                btnfont1:SetText(format("%s", STAT_VERSATILITY)) -- Versatility
                btnfont2:SetText(format('(%s%% / %s%%) %6.6s',CCS.round(versatilityDamageBonus), CCS.round(versatilityDamageTakenReduction),BreakUpLargeNumbers(versatility)))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_VERSATILITY)..FONT_COLOR_CODE_CLOSE;
                tt_desc = format(CR_VERSATILITY_TOOLTIP, versatilityDamageBonus, versatilityDamageTakenReduction, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction);--]]
                
                ---------------------------
                -- Attack Category
                ---------------------------
            elseif    row == 10 then btnfont1:SetText(ATTACK)
            elseif    row == 11 then 
                -- Attack Power
                local base, posBuff, negBuff;
                local tag, tooltip4;
                
                btnfont1:SetText(format("%s", STAT_ATTACK_POWER))
                
                if IsRangedWeapon() then 
                    base, posBuff, negBuff = UnitRangedAttackPower("player");
                    tag, tooltip4 = RANGED_ATTACK_POWER, RANGED_ATTACK_POWER_TOOLTIP;
                else
                    base, posBuff, negBuff = UnitAttackPower("player");
                    tag, tooltip4 = MELEE_ATTACK_POWER, MELEE_ATTACK_POWER_TOOLTIP;
                end
                
                btnfont2:SetText(BreakUpLargeNumbers(base))
                
                local damageBonus =  BreakUpLargeNumbers(max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER);
                local spellPower = 0;
                local value, valueText, tooltipText;
                
                if (GetOverrideAPBySpellPower() ~= nil) then
                    local holySchool = 2;
                    -- Start at 2 to skip physical damage
                    spellPower = GetSpellBonusDamage(holySchool);
                    for i=(holySchool+1), MAX_SPELL_SCHOOLS do
                        spellPower = min(spellPower, GetSpellBonusDamage(i));
                    end
                    spellPower = min(spellPower, GetSpellBonusHealing()) * GetOverrideAPBySpellPower();
                    
                    value = spellPower;
                    valueText, tooltipText = PaperDollFormatStat(tag, spellPower, 0, 0);
                    damageBonus = BreakUpLargeNumbers(spellPower / ATTACK_POWER_MAGIC_NUMBER);
                else
                    value = base;
                    valueText, tooltipText = PaperDollFormatStat(tag, base, posBuff, negBuff);
                end
                
                tt_name = tooltipText;
                
                local effectiveAP = max(0,base + posBuff + negBuff);
                
                if (GetOverrideSpellPowerByAP() ~= nil) then
                    tt_desc = format(MELEE_ATTACK_POWER_SPELL_POWER_TOOLTIP, damageBonus, BreakUpLargeNumbers(effectiveAP * GetOverrideSpellPowerByAP() + 0.5));
                else
                    tt_desc = format(tooltip4, damageBonus);
                end
                
            elseif    row == 12 then 
                -- Attack Speed
                local meleeHaste = GetMeleeHaste();
                local speed, offhandSpeed = UnitAttackSpeed("player");
                local displaySpeed = format("%.2fs", speed);
                
                
                if offhandSpeed then displaySpeed = format("%s / %.2fs", displaySpeed , offhandSpeed); end
                
                btnfont1:SetText(format("%s", STAT_ATTACK_SPEED))
                btnfont2:SetText(displaySpeed)
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..displaySpeed..FONT_COLOR_CODE_CLOSE;
                tt_desc = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, BreakUpLargeNumbers(meleeHaste));
                
            elseif    row == 13 then 
                -- Spell Power
                btnfont1:SetText(format("%s", ITEM_MOD_SPELL_POWER_SHORT))
                btnfont2:SetText(BreakUpLargeNumbers(GetSpellBonusDamage(2)))
                
                tt_name = STAT_SPELLPOWER;
                tt_desc = STAT_SPELLPOWER_TOOLTIP;
                ---------------------------
                -- Defense Category
                ---------------------------
            elseif    row == 14 then btnfont1:SetText(STAT_CATEGORY_DEFENSE)
            elseif    row == 15 then 
                -- Armor
                local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor("player");
                local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitEffectiveLevel("player"));
                local armorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(effectiveArmor);
                
                btnfont1:SetText(format("%s", ARMOR))
                btnfont2:SetText(BreakUpLargeNumbers(armor))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ARMOR).." "..BreakUpLargeNumbers(effectiveArmor)..FONT_COLOR_CODE_CLOSE;
                tt_desc = format(STAT_ARMOR_TOOLTIP, armorReduction);
                
                if (armorReductionAgainstTarget) then
                    tt_desc = tt_desc .. "\n" .. format(STAT_ARMOR_TARGET_TOOLTIP, armorReductionAgainstTarget);
                end
            elseif    row == 16 then 
                -- Dodge Chance
                local chance = GetDodgeChance();
                btnfont1:SetText(format("%s", ITEM_MOD_DODGE_RATING_SHORT))
                btnfont2:SetText(format("%s%%", CCS.round(chance)))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;
                tt_desc = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));
                
            elseif    row == 17 then 
                -- Parry Chance
                local chance = GetParryChance();
                
                btnfont1:SetText(format("%s", ITEM_MOD_PARRY_RATING_SHORT))
                btnfont2:SetText(format("%s%%", CCS.round(chance)))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;
                tt_desc = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));
                
            elseif    row == 18 then 
                -- Block Chance
                local chance = GetBlockChance();
                local shieldBlockArmor = GetShieldBlock();
                local blockArmorReduction = PaperDollFrame_GetArmorReduction(shieldBlockArmor, UnitEffectiveLevel("player"));
                local blockArmorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(shieldBlockArmor);
                
                btnfont1:SetText(format("%s", BLOCK))
                btnfont2:SetText(format("%s%%", CCS.round(chance)))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;
                tt_desc = CR_BLOCK_TOOLTIP:format(blockArmorReduction);
                if (blockArmorReductionAgainstTarget) then
                    tt_desc = tt_desc .. "\n" .. format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget);
                end                
                
            elseif    row == 19 then 
                -- Stagger Percent
                local stagger, staggerAgainstTarget = C_PaperDollInfo.GetStaggerPercentage("player");
                
                btnfont1:SetText(format("%s", STAGGER))
                btnfont2:SetText(format("%s%%", CCS.round(stagger)))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAGGER).." "..string.format("%.2F%%",stagger)..FONT_COLOR_CODE_CLOSE;
                tt_desc = format(STAT_STAGGER_TOOLTIP, stagger);
                if (staggerAgainstTarget) then
                    tt_desc = tt_desc .. "\n" .. format(STAT_STAGGER_TARGET_TOOLTIP, staggerAgainstTarget);
                end
                
                ---------------------------
                -- General Category
                ---------------------------
            elseif    row == 20 then btnfont1:SetText(GENERAL)
            elseif    row == 21 then
                -- Leech
                local lifesteal = GetLifesteal();
                btnfont1:SetText(format("%s", ITEM_MOD_CR_LIFESTEAL_SHORT))
                btnfont2:SetText(format('(%s%%) %6.6s',CCS.round(GetLifesteal()), BreakUpLargeNumbers(GetCombatRating(CR_LIFESTEAL))))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_LIFESTEAL) .. " " .. format("%.2F%%", lifesteal) .. FONT_COLOR_CODE_CLOSE;
                tt_desc = format(CR_LIFESTEAL_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_LIFESTEAL)), GetCombatRatingBonus(CR_LIFESTEAL));
                
            elseif    row == 22 then 
                -- Avoidance
                local avoidance = GetAvoidance();
                btnfont1:SetText(format("%s", ITEM_MOD_CR_AVOIDANCE_SHORT))
                btnfont2:SetText(format('(%s%%) %6.6s',CCS.round(GetCombatRatingBonus(CR_AVOIDANCE)), BreakUpLargeNumbers(GetCombatRating(CR_AVOIDANCE))))
                
                tt_name = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVOIDANCE) .. " " .. format("%.2F%%", avoidance) .. FONT_COLOR_CODE_CLOSE;
                tt_desc = format(CR_AVOIDANCE_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_AVOIDANCE)), GetCombatRatingBonus(CR_AVOIDANCE));
                
            elseif    row == 23 then 
                -- Speed
                local speed = GetSpeed();
                btnfont1:SetText(format("%s", ITEM_MOD_CR_SPEED_SHORT)) -- Speed
                btnfont2:SetText(format('(%s%%) %6.6s',CCS.round(GetCombatRatingBonus(CR_SPEED)), BreakUpLargeNumbers(GetCombatRating(CR_SPEED))))
                tt_name = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_SPEED) .. " " .. format("%.2F%%", speed) .. FONT_COLOR_CODE_CLOSE;
                tt_desc = format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED));
                
            elseif row == 24 then 
                -- Movement Speed
                UpdateMoveSpeed()
                btnfont1:SetText(format("%s", STAT_MOVEMENT_SPEED))
                
            end
            
            if tooltip then 
                local name, desc = tt_name, tt_desc
                btn:SetScript("OnEnter", function() GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                        GameTooltip:AddDoubleLine(name, nil, 1, 1, 1, 1, 1, 1) 
                        GameTooltip:AddLine(desc, nil, nil, nil, true)   
                        GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            
        end
        
    end
end   

-- Event handler for character stats
function CCS.CharacterStatsEventHandler(event, ...)
    local arg1 = ...
    --if InCombatLockdown()then CCS.incombat = true return end
    if CCS.GetCurrentVersion() ~= CCS.RETAIL then return end
    if UnitLevel("player") < 10 then return end
    if UnitLevel("player") == 10 and InCombatLockdown() and event == "PLAYER_LEVEL_UP" then CCS.incombat = true return end
    
    if (event == "UNIT_DAMAGE" or event == "UNIT_ATTACK_SPEED" or event == "UNIT_MAXHEALTH") and arg1 ~= "player" then return end

    if event == "PLAYER_STARTED_LOOKING" or event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STARTED_TURNING" or 
       event == "PLAYER_STOPPED_LOOKING" or event == "PLAYER_STOPPED_MOVING" or event == "PLAYER_STOPPED_TURNING" or 
       event == "SPEED_UPDATE" then
        if not InCombatLockdown() and CharacterFrame:IsVisible() then
            UpdateMoveSpeed()
        end
        return
    end

    if event == "CCS_EVENT_OPTIONS" then
        if not option("showcharacterstats") then
            CCS:RestoreCharacterStatsPane()
        end
        module:Initialize()
        return true
    end

    if not CCS.statsUpdatePending then
        CCS.statsUpdatePending = true
        C_Timer.After(0.2, function()
            CCS.statsUpdatePending = false
            module:Initialize()
        end)
    end
end