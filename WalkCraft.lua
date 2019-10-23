-- Based on https://github.com/iamcal/wow-NewAddon
WalkCraft = {};
WalkCraft.version = "@project-version@";
WalkCraft.debug = false;
--@debug@
WalkCraft.debug = true;
----@end-debug@
WalkCraft.fully_loaded = false;
WalkCraft.state = {}
WalkCraft.default_options = {

    -- main frame position
    frameRef = "CENTER",
    frameX = 0,
    frameY = 0,
    hide = false,

    -- sizing
    frameW = 200,
    frameH = 200,
};



function WalkCraft.Log(logMessage)
    if not WalkCraft.debug then
        return
    end
    print(logMessage);
end


function WalkCraft.OnReady()

    WalkCraft.Log('OnReady');

    -- set up default options
    _G.WoWFitnessPrefs = _G.WoWFitnessPrefs or {};

    for k,v in pairs(WalkCraft.default_options) do
        if (not _G.WoWFitnessPrefs[k]) then
            _G.WoWFitnessPrefs[k] = v;
        end
    end
    WalkCraft.state = WoWFitnessPrefs.state or {}

    WalkCraft.CreateUIFrame();
end

function WalkCraft.GetTodaysStepsIndex()
    return date("%Y-%M-%d");
end

function WalkCraft.GetSteps()
    return WalkCraft.state[WalkCraft.GetTodaysStepsIndex()] or 0
end

function WalkCraft.CalculateSteps(newVector, lastVector)
	local newX, newY = newVector:GetXY();
	local lastX, lastY = lastVector:GetXY();
    local xDist = lastX - newX;
    local yDist = lastY - newY;
    return math.sqrt( (xDist ^ 2) + (yDist ^ 2) )
end

function WalkCraft.UpdateSteps(newVector)
    local currentValue = WalkCraft.GetSteps()
    if WalkCraft.lastVector then
        local steps = WalkCraft.CalculateSteps(newVector, WalkCraft.lastVector);
        WalkCraft.state[WalkCraft.GetTodaysStepsIndex()] = currentValue + steps;
    end
    WalkCraft.lastVector = newVector
end

function WalkCraft.OnSaving()
    WalkCraft.Log('OnSaving');

    if (WalkCraft.UIFrame) then
        local point, relativeTo, relativePoint, xOfs, yOfs = WalkCraft.UIFrame:GetPoint()
        _G.WoWFitnessPrefs.frameRef = relativePoint;
        _G.WoWFitnessPrefs.frameX = xOfs;
        _G.WoWFitnessPrefs.frameY = yOfs;
    end
    _G.WoWFitnessPrefs.state = WalkCraft.state;
end

function WalkCraft.OnUpdate()
    if (not WalkCraft.fully_loaded) then
        return;
    end

    if (WoWFitnessPrefs.hide) then
        return;
    end

    WalkCraft.UpdateFrame();
end

function WalkCraft.OnEvent(frame, event, ...)
    WalkCraft.MapID = MapUtil.GetDisplayableMapForPlayer();

    WalkCraft.Log(string.format("Got event: %s", event));

    if (event == 'ADDON_LOADED') then
        local name = ...;
        if name == 'WalkCraft' then
            WalkCraft.OnReady();
        end
        return;
    end

    if (event == 'PLAYER_LOGIN') then

        WalkCraft.fully_loaded = true;
        return;
    end

    if (event == 'PLAYER_LOGOUT') then
        WalkCraft.OnSaving();
        return;
    end
end

function WalkCraft.CreateUIFrame()

    -- create the UI frame
    WalkCraft.UIFrame = CreateFrame("Frame",nil,UIParent);
    WalkCraft.UIFrame:SetFrameStrata("BACKGROUND")
    WalkCraft.UIFrame:SetWidth(_G.WoWFitnessPrefs.frameW);
    WalkCraft.UIFrame:SetHeight(_G.WoWFitnessPrefs.frameH);

    -- make it black
    WalkCraft.UIFrame.texture = WalkCraft.UIFrame:CreateTexture();
    WalkCraft.UIFrame.texture:SetAllPoints(WalkCraft.UIFrame);
    WalkCraft.UIFrame.texture:SetTexture(0, 0, 0);

    -- position it
    WalkCraft.UIFrame:SetPoint(_G.WoWFitnessPrefs.frameRef, _G.WoWFitnessPrefs.frameX, _G.WoWFitnessPrefs.frameY);

    -- make it draggable
    WalkCraft.UIFrame:SetMovable(true);
    WalkCraft.UIFrame:EnableMouse(true);

    -- create a button that covers the entire addon
    WalkCraft.Cover = CreateFrame("Button", nil, WalkCraft.UIFrame);
    WalkCraft.Cover:SetFrameLevel(128);
    WalkCraft.Cover:SetPoint("TOPLEFT", 0, 0);
    WalkCraft.Cover:SetWidth(_G.WoWFitnessPrefs.frameW);
    WalkCraft.Cover:SetHeight(_G.WoWFitnessPrefs.frameH);
    WalkCraft.Cover:EnableMouse(true);
    WalkCraft.Cover:RegisterForClicks("AnyUp");
    WalkCraft.Cover:RegisterForDrag("LeftButton");
    WalkCraft.Cover:SetScript("OnDragStart", WalkCraft.OnDragStart);
    WalkCraft.Cover:SetScript("OnDragStop", WalkCraft.OnDragStop);
    WalkCraft.Cover:SetScript("OnClick", WalkCraft.OnClick);

    -- add a main label - just so we can show something
    WalkCraft.Label = WalkCraft.Cover:CreateFontString(nil, "OVERLAY");
    WalkCraft.Label:SetPoint("CENTER", WalkCraft.UIFrame, "CENTER", 2, 0);
    WalkCraft.Label:SetJustifyH("LEFT");
    WalkCraft.Label:SetFont([[Fonts\FRIZQT__.TTF]], 12, "OUTLINE");
    WalkCraft.Label:SetText(" ");
    WalkCraft.Label:SetTextColor(1,1,1,1);
    WalkCraft.SetFontSize(WalkCraft.Label, 20);
end

function WalkCraft.SetFontSize(string, size)
    local Font, Height, Flags = string:GetFont()
    if (not (Height == size)) then
        string:SetFont(Font, size, Flags)
    end
end

function WalkCraft.OnDragStart(frame)
    WalkCraft.UIFrame:StartMoving();
    WalkCraft.UIFrame.isMoving = true;
    GameTooltip:Hide()
end

function WalkCraft.OnDragStop(frame)
    WalkCraft.UIFrame:StopMovingOrSizing();
    WalkCraft.UIFrame.isMoving = false;
end

function WalkCraft.OnClick(self, aButton)
    if (aButton == "RightButton") then
        print(string.format("Current steps: %s", WalkCraft.GetSteps()));
    end
end

function WalkCraft.UpdateFrame()

    -- update the main frame state here
    local vector = C_Map.GetPlayerMapPosition(WalkCraft.MapID, "player");
    if vector then
        WalkCraft.UpdateSteps(vector);
    end
    WalkCraft.Label:SetText(string.format("%d", WalkCraft.GetSteps()));
end


WalkCraft.EventFrame = CreateFrame("Frame");
WalkCraft.MapID = MapUtil.GetDisplayableMapForPlayer();
WalkCraft.EventFrame:Show();
WalkCraft.EventFrame:SetScript("OnEvent", WalkCraft.OnEvent);
WalkCraft.EventFrame:SetScript("OnUpdate", WalkCraft.OnUpdate);
WalkCraft.EventFrame:RegisterEvent("ADDON_LOADED");
WalkCraft.EventFrame:RegisterEvent("PLAYER_LOGIN");
WalkCraft.EventFrame:RegisterEvent("PLAYER_LOGOUT");
