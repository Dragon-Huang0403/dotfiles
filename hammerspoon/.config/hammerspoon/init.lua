-- Use `for _, app in ipairs(hs.application.runningApplications()) do print(app:name()) end`
-- to find the exact application names for your installed apps.

-- Reset keyboard input method to ABC when switching windows
local function switchToABC()
    local inputSource = hs.keycodes.currentSourceID()
    if inputSource ~= "com.apple.keylayout.ABC" then
        hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
    end
end

-- Switch to Zhuyin for specific apps
local function switchToZhuyin()
    hs.keycodes.currentSourceID("com.apple.inputmethod.TCIM.Zhuyin")
end

-- Watch for window focus changes
hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function(window)
    local appName = window:application():name()
    -- 
    if appName == "LINE" then
        switchToZhuyin()
    else
        switchToABC()
    end
end)