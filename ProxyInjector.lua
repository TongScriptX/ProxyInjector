-- Proxy Injector v2.1
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

local function patchCode(s)
    return (s:gsub('game:HttpGet%("(https://raw%.githubusercontent%.com/([^"]+))"%)', function(_, path)
        return 'game:HttpGet("' .. PROXY_BASE .. path .. '")'
    end))
end

local function executeScript(code)
    local s = code:match("^%s*(.-)%s*$")
    if s == "" then return end
    local ok, err
    if s:match("^https?://") then
        ok, err = pcall(function() loadstring(patchCode(proxyGet(s)))() end)
    else
        local fn, compErr = loadstring(patchCode(s))
        if not fn then
            warn("[ProxyInjector] 编译错误:", compErr)
            return
        end
        ok, err = pcall(fn)
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
local isMobile = math.min(vp.X, vp.Y) < 500
-- 横向布局：宽 > 高
local PW = math.min(math.floor(vp.X * 0.92), 700)
local PH = math.min(math.floor(vp.Y * 0.88), 340)
local TITLE_H = 46
local PAD = 10
local BTN_H = 36
local LEFT_W = math.floor(PW * 0.55)
local RIGHT_W = PW - LEFT_W - PAD * 3

-- 悬浮按钮
local fab = Instance.new("TextButton")
fab.Size = UDim2.fromOffset(52, 52)
fab.Position = UDim2.new(1, -64, 0.5, -26)
fab.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
fab.Text = "⚡"
fab.TextSize = 24
fab.TextColor3 = Color3.new(1,1,1)
fab.BorderSizePixel = 0
fab.ZIndex = 10
fab.Parent = screenGui
Instance.new("UICorner", fab).CornerRadius = UDim.new(1, 0)

-- 主面板
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(PW, PH)
panel.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 5
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 6
titleBar.Parent = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
local fix = Instance.new("Frame", titleBar)
fix.Size = UDim2.new(1, 0, 0, 12)
fix.Position = UDim2.new(0, 0, 1, -12)
fix.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
fix.BorderSizePixel = 0
fix.ZIndex = 6

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -56, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Proxy Injector"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 7
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
closeBtn.Text = "×"
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 7
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- 内容区 Y 起点
local CY = TITLE_H + PAD
local CH = PH - CY - PAD  -- 内容区高度

-- 左栏：输入框 + 按钮
local inputH = CH - BTN_H - PAD

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.fromOffset(LEFT_W, inputH)
inputBox.Position = UDim2.fromOffset(PAD, CY)
inputBox.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
inputBox.Text = ""
inputBox.PlaceholderText = "输入脚本URL或Lua代码..."
inputBox.TextColor3 = Color3.new(1,1,1)
inputBox.PlaceholderColor3 = Color3.fromRGB(110,110,130)
inputBox.TextSize = 12
inputBox.Font = Enum.Font.Code
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.TextYAlignment = Enum.TextYAlignment.Top
inputBox.MultiLine = true
inputBox.ClearTextOnFocus = false
inputBox.BorderSizePixel = 0
inputBox.ZIndex = 6
inputBox.Parent = panel
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local ip = Instance.new("UIPadding", inputBox)
ip.PaddingLeft = UDim.new(0, 8); ip.PaddingTop = UDim.new(0, 6)

-- 按钮行（左栏底部）
local btnY = CY + inputH + PAD
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.fromOffset(LEFT_W, BTN_H)
btnRow.Position = UDim2.fromOffset(PAD, btnY)
btnRow.BackgroundTransparency = 1
btnRow.ZIndex = 6
btnRow.Parent = panel
local bl = Instance.new("UIListLayout", btnRow)
bl.FillDirection = Enum.FillDirection.Horizontal
bl.Padding = UDim.new(0, 6)

local function makeBtn(text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.32, -4, 1, 0)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.new(1,1,1)
    b.BorderSizePixel = 0
    b.ZIndex = 7
    b.Parent = btnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local execBtn = makeBtn("▶ 执行",    Color3.fromRGB(40, 167, 69))
local clipBtn = makeBtn("📋 剪贴板", Color3.fromRGB(0, 120, 215))
local saveBtn = makeBtn("💾 保存",   Color3.fromRGB(255, 160, 0))

-- 分隔线
local divider = Instance.new("Frame")
divider.Size = UDim2.fromOffset(1, CH)
divider.Position = UDim2.fromOffset(PAD + LEFT_W + PAD, CY)
divider.BackgroundColor3 = Color3.fromRGB(50, 53, 62)
divider.BorderSizePixel = 0
divider.ZIndex = 6
divider.Parent = panel

-- 右栏：已保存脚本列表
local listX = PAD + LEFT_W + PAD * 2 + 1
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.fromOffset(RIGHT_W, CH)
listFrame.Position = UDim2.fromOffset(listX, CY)
listFrame.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 3
listFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
listFrame.CanvasSize = UDim2.new(0,0,0,0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.ZIndex = 6
listFrame.Parent = panel
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)
local ll = Instance.new("UIListLayout", listFrame)
ll.Padding = UDim.new(0, 4)
local lp = Instance.new("UIPadding", listFrame)
lp.PaddingLeft = UDim.new(0,5); lp.PaddingRight = UDim.new(0,5); lp.PaddingTop = UDim.new(0,5)

-- 右栏标题
local listTitle = Instance.new("TextLabel")
listTitle.Size = UDim2.new(1, 0, 0, 20)
listTitle.BackgroundTransparency = 1
listTitle.Text = "已保存脚本"
listTitle.TextColor3 = Color3.fromRGB(150,150,170)
listTitle.TextSize = 11
listTitle.Font = Enum.Font.GothamBold
listTitle.ZIndex = 7
listTitle.Parent = listFrame

local savedScripts = loadScripts()

local function refreshList()
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for name, code in pairs(savedScripts) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = Color3.fromRGB(40, 43, 54)
        row.BorderSizePixel = 0
        row.ZIndex = 7
        row.Parent = listFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.ZIndex = 8
        lbl.Parent = row

        local rBtn = Instance.new("TextButton")
        rBtn.Size = UDim2.fromOffset(24, 22)
        rBtn.Position = UDim2.new(1, -52, 0.5, -11)
        rBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        rBtn.Text = "▶"
        rBtn.TextSize = 11
        rBtn.TextColor3 = Color3.new(1,1,1)
        rBtn.BorderSizePixel = 0
        rBtn.ZIndex = 8
        rBtn.Parent = row
        Instance.new("UICorner", rBtn).CornerRadius = UDim.new(0, 4)

        local dBtn = Instance.new("TextButton")
        dBtn.Size = UDim2.fromOffset(24, 22)
        dBtn.Position = UDim2.new(1, -24, 0.5, -11)
        dBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        dBtn.Text = "×"
        dBtn.TextSize = 13
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

-- 按钮事件
execBtn.MouseButton1Click:Connect(function()
    executeScript(inputBox.Text)
end)

clipBtn.MouseButton1Click:Connect(function()
    local ok, text = pcall(function() return UserInputService:GetStringForKeyCode(Enum.KeyCode.Unknown) end)
    local clip = game:GetService("GuiService"):GetGuiInset() -- dummy
    -- 尝试读取剪贴板
    local s = inputBox.Text  -- fallback: 用户需手动粘贴
    pcall(function()
        s = game:HttpGet("rbxasset://clipboard") -- 不可用时静默失败
    end)
    executeScript(s)
end)

saveBtn.MouseButton1Click:Connect(function()
    local code = inputBox.Text:match("^%s*(.-)%s*$")
    if code == "" then return end
    local name = code:match("^https?://[^/]+/([^?#]+)") or code:sub(1, 24):gsub("%s+", " ")
    local i = 1
    while savedScripts[name] do name = name .. "_" .. i; i = i + 1 end
    savedScripts[name] = code
    saveScripts(savedScripts)
    refreshList()
end)

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- 悬浮按钮拖拽
local dragging, dragStart, startPos, moved = false, nil, nil, false

fab.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        startPos = fab.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
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
    if not moved then panel.Visible = not panel.Visible end
end)

refreshList()
