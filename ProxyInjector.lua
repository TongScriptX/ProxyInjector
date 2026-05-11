-- Proxy Injector v2.0
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local PROXY_BASE = "https://api.959966.xyz/github/raw/"
local STORAGE_KEY = "ProxyInjector_Scripts"

local function proxyGet(url)
    local path = url:match("^https://raw%.githubusercontent%.com/(.+)$")
    return game:HttpGet(path and (PROXY_BASE .. path) or url)
end

local function saveScripts(t)
    pcall(writefile, STORAGE_KEY, HttpService:JSONEncode(t))
end

local function loadScripts()
    local ok, data = pcall(function()
        return isfile(STORAGE_KEY) and HttpService:JSONDecode(readfile(STORAGE_KEY)) or {}
    end)
    return ok and data or {}
end

local function executeScript(code)
    local trimmed = code:match("^%s*(.-)%s*$")
    if trimmed == "" then return end
    local ok, err
    if trimmed:match("^https?://") then
        ok, err = pcall(function()
            loadstring(proxyGet(trimmed))()
        end)
    else
        ok, err = pcall(loadstring(trimmed))
    end
    if not ok then warn("[ProxyInjector]", err) end
end

-- UI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("ProxyInjector") then
    playerGui.ProxyInjector:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProxyInjector"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local vp = workspace.CurrentCamera.ViewportSize
local isMobile = vp.X < 700
local W = isMobile and math.floor(vp.X * 0.92) or 400
local H = isMobile and 460 or 520

-- 悬浮按钮
local fab = Instance.new("TextButton")
fab.Size = UDim2.fromOffset(56, 56)
fab.Position = UDim2.new(1, -72, 0.5, -28)
fab.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
fab.Text = "⚡"
fab.TextSize = 26
fab.TextColor3 = Color3.new(1,1,1)
fab.BorderSizePixel = 0
fab.ZIndex = 10
fab.Parent = screenGui
Instance.new("UICorner", fab).CornerRadius = UDim.new(1, 0)

-- 主面板
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(W, H)
panel.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 5
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 6
titleBar.Parent = panel
local tc = Instance.new("UICorner", titleBar)
tc.CornerRadius = UDim.new(0, 14)
-- 遮住底部圆角
local tcFix = Instance.new("Frame")
tcFix.Size = UDim2.new(1, 0, 0, 14)
tcFix.Position = UDim2.new(0, 0, 1, -14)
tcFix.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
tcFix.BorderSizePixel = 0
tcFix.ZIndex = 6
tcFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Proxy Injector"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.TextSize = isMobile and 16 or 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 7
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
closeBtn.Text = "×"
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 7
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- 输入框
local inputH = isMobile and 140 or 180
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -24, 0, inputH)
inputBox.Position = UDim2.new(0, 12, 0, 64)
inputBox.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
inputBox.Text = ""
inputBox.PlaceholderText = "输入脚本URL或Lua代码..."
inputBox.TextColor3 = Color3.new(1,1,1)
inputBox.PlaceholderColor3 = Color3.fromRGB(120,120,140)
inputBox.TextSize = isMobile and 12 or 13
inputBox.Font = Enum.Font.Code
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.TextYAlignment = Enum.TextYAlignment.Top
inputBox.MultiLine = true
inputBox.ClearTextOnFocus = false
inputBox.BorderSizePixel = 0
inputBox.ZIndex = 6
inputBox.Parent = panel
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local inputPad = Instance.new("UIPadding", inputBox)
inputPad.PaddingLeft = UDim.new(0, 8)
inputPad.PaddingTop = UDim.new(0, 6)

-- 按钮行
local btnY = 64 + inputH + 10
local btnH = isMobile and 38 or 42
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -24, 0, btnH)
btnRow.Position = UDim2.new(0, 12, 0, btnY)
btnRow.BackgroundTransparency = 1
btnRow.ZIndex = 6
btnRow.Parent = panel
local btnLayout = Instance.new("UIListLayout", btnRow)
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 8)

local function makeBtn(text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.32, -6, 1, 0)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextSize = isMobile and 12 or 13
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.new(1,1,1)
    b.BorderSizePixel = 0
    b.ZIndex = 7
    b.Parent = btnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local execBtn  = makeBtn("▶ 执行",   Color3.fromRGB(40, 167, 69))
local clipBtn  = makeBtn("📋 剪贴板", Color3.fromRGB(0, 120, 215))
local saveBtn  = makeBtn("💾 保存",   Color3.fromRGB(255, 160, 0))

-- 分隔线
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -24, 0, 1)
sep.Position = UDim2.new(0, 12, 0, btnY + btnH + 10)
sep.BackgroundColor3 = Color3.fromRGB(50, 53, 62)
sep.BorderSizePixel = 0
sep.ZIndex = 6
sep.Parent = panel

-- 已保存脚本列表
local listY = btnY + btnH + 20
local listH = H - listY - 12
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -24, 0, listH)
listFrame.Position = UDim2.new(0, 12, 0, listY)
listFrame.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.ZIndex = 6
listFrame.Parent = panel
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)
local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 4)
local listPad = Instance.new("UIPadding", listFrame)
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
listPad.PaddingTop = UDim.new(0, 6)

local savedScripts = loadScripts()

local function refreshList()
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for name, code in pairs(savedScripts) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(40, 43, 54)
        row.BorderSizePixel = 0
        row.ZIndex = 7
        row.Parent = listFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -76, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextSize = isMobile and 11 or 13
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.ZIndex = 8
        lbl.Parent = row

        local rBtn = Instance.new("TextButton")
        rBtn.Size = UDim2.fromOffset(28, 26)
        rBtn.Position = UDim2.new(1, -62, 0.5, -13)
        rBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        rBtn.Text = "▶"
        rBtn.TextSize = 13
        rBtn.TextColor3 = Color3.new(1,1,1)
        rBtn.BorderSizePixel = 0
        rBtn.ZIndex = 8
        rBtn.Parent = row
        Instance.new("UICorner", rBtn).CornerRadius = UDim.new(0, 4)

        local dBtn = Instance.new("TextButton")
        dBtn.Size = UDim2.fromOffset(28, 26)
        dBtn.Position = UDim2.new(1, -28, 0.5, -13)
        dBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        dBtn.Text = "×"
        dBtn.TextSize = 16
        dBtn.TextColor3 = Color3.new(1,1,1)
        dBtn.BorderSizePixel = 0
        dBtn.ZIndex = 8
        dBtn.Parent = row
        Instance.new("UICorner", dBtn).CornerRadius = UDim.new(0, 4)

        rBtn.MouseButton1Click:Connect(function() executeScript(code) end)
        dBtn.MouseButton1Click:Connect(function()
            savedScripts[name] = nil
            saveScripts(savedScripts)
            refreshList()
        end)
    end
end

-- 按钮逻辑
execBtn.MouseButton1Click:Connect(function()
    executeScript(inputBox.Text)
end)

clipBtn.MouseButton1Click:Connect(function()
    local ok, text = pcall(function() return UserInputService:GetStringForKeyCode(Enum.KeyCode.Unknown) end)
    -- 剪贴板读取
    local clipText = ""
    pcall(function() clipText = getclipboard() end)
    if clipText ~= "" then
        inputBox.Text = clipText
        executeScript(clipText)
    end
end)

saveBtn.MouseButton1Click:Connect(function()
    local code = inputBox.Text:match("^%s*(.-)%s*$")
    if code == "" then return end
    local name = code:match("([^/]+)%.lua$") or ("Script_" .. os.time())
    savedScripts[name] = code
    saveScripts(savedScripts)
    refreshList()
end)

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- 悬浮按钮切换 + 拖拽
local dragging, dragStart, startPos, moved

fab.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        startPos = fab.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

fab.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then moved = true end
        fab.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then moved = true end
        fab.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

fab.MouseButton1Click:Connect(function()
    if not moved then
        panel.Visible = not panel.Visible
    end
end)

refreshList()
