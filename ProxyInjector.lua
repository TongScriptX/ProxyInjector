-- Proxy Injector v1.0
-- 代理注入器 - 通过代理加载运行脚本

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local PROXY_URL = "https://api.959966.xyz/github/raw/"
local STORAGE_KEY = "ProxyInjector_Scripts"

local function proxyLoad(url)
    if url:match("^https://raw%.githubusercontent%.com/(.+)$") then
        local path = url:match("^https://raw%.githubusercontent%.com/(.+)$")
        return game:HttpGet(PROXY_URL .. path)
    end
    return game:HttpGet(url)
end

local function saveScripts(scripts)
    writefile(STORAGE_KEY, HttpService:JSONEncode(scripts))
end

local function loadScripts()
    return isfile(STORAGE_KEY) and HttpService:JSONDecode(readfile(STORAGE_KEY)) or {}
end

local function createUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("ProxyInjector") then
        playerGui.ProxyInjector:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProxyInjector"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- 悬浮按钮
    local dragButton = Instance.new("TextButton")
    dragButton.Size = UDim2.new(0, 60, 0, 60)
    dragButton.Position = UDim2.new(1, -80, 0.5, -30)
    dragButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    dragButton.Text = "📝"
    dragButton.TextSize = 28
    dragButton.TextColor3 = Color3.new(1, 1, 1)
    dragButton.BorderSizePixel = 0
    dragButton.Parent = screenGui

    local dragCorner = Instance.new("UICorner")
    dragCorner.CornerRadius = UDim.new(1, 0)
    dragCorner.Parent = dragButton

    -- 主界面
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 12)
    titleCover.Position = UDim2.new(0, 0, 1, -12)
    titleCover.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Proxy Injector"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeBtn.Text = "×"
    closeBtn.TextSize = 24
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    -- 输入区域
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -30, 0, 200)
    inputFrame.Position = UDim2.new(0, 15, 0, 65)
    inputFrame.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = mainFrame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputFrame

    local scriptInput = Instance.new("TextBox")
    scriptInput.Size = UDim2.new(1, -20, 1, -20)
    scriptInput.Position = UDim2.new(0, 10, 0, 10)
    scriptInput.BackgroundTransparency = 1
    scriptInput.Text = ""
    scriptInput.PlaceholderText = "输入脚本URL或代码..."
    scriptInput.TextColor3 = Color3.new(1, 1, 1)
    scriptInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    scriptInput.TextSize = 14
    scriptInput.Font = Enum.Font.Code
    scriptInput.TextXAlignment = Enum.TextXAlignment.Left
    scriptInput.TextYAlignment = Enum.TextYAlignment.Top
    scriptInput.MultiLine = true
    scriptInput.ClearTextOnFocus = false
    scriptInput.Parent = inputFrame

    -- 按钮区域
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, -30, 0, 40)
    buttonFrame.Position = UDim2.new(0, 15, 0, 280)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = mainFrame

    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonFrame

    local function createButton(text, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 105, 0, 40)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.BorderSizePixel = 0
        btn.Parent = buttonFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        return btn
    end

    local executeBtn = createButton("执行", Color3.fromRGB(40, 167, 69))
    local clipboardBtn = createButton("剪贴板", Color3.fromRGB(0, 123, 255))
    local saveBtn = createButton("保存", Color3.fromRGB(255, 193, 7))

    -- 脚本列表
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, -30, 0, 160)
    listFrame.Position = UDim2.new(0, 15, 0, 335)
    listFrame.BackgroundColor3 = Color3.fromRGB(40, 43, 50)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 6
    listFrame.Parent = mainFrame

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = listFrame

    -- 功能实现
    local savedScripts = loadScripts()

    local function executeScript(code)
        local isUrl = code:match("^https?://")
        if isUrl then
            local success, result = pcall(function()
                return proxyLoad(code)
            end)
            if success then
                loadstring(result)()
            else
                warn("加载失败:", result)
            end
        else
            loadstring(code)()
        end
    end

    local function refreshList()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        for name, code in pairs(savedScripts) do
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, -10, 0, 35)
            item.BackgroundColor3 = Color3.fromRGB(50, 53, 60)
            item.BorderSizePixel = 0
            item.Parent = listFrame

            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 6)
            itemCorner.Parent = item

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -80, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = name
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = item

            local runBtn = Instance.new("TextButton")
            runBtn.Size = UDim2.new(0, 30, 0, 25)
            runBtn.Position = UDim2.new(1, -65, 0.5, -12.5)
            runBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            runBtn.Text = "▶"
            runBtn.TextSize = 14
            runBtn.TextColor3 = Color3.new(1, 1, 1)
            runBtn.BorderSizePixel = 0
            runBtn.Parent = item

            local runCorner = Instance.new("UICorner")
            runCorner.CornerRadius = UDim.new(0, 4)
            runCorner.Parent = runBtn

            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 30, 0, 25)
            delBtn.Position = UDim2.new(1, -30, 0.5, -12.5)
            delBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
            delBtn.Text = "×"
            delBtn.TextSize = 16
            delBtn.TextColor3 = Color3.new(1, 1, 1)
            delBtn.BorderSizePixel = 0
            delBtn.Parent = item

            local delCorner = Instance.new("UICorner")
            delCorner.CornerRadius = UDim.new(0, 4)
            delCorner.Parent = delBtn

            runBtn.MouseButton1Click:Connect(function()
                executeScript(code)
            end)

            delBtn.MouseButton1Click:Connect(function()
                savedScripts[name] = nil
                saveScripts(savedScripts)
                refreshList()
            end)
        end

        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end

    executeBtn.MouseButton1Click:Connect(function()
        local code = scriptInput.Text
        if code ~= "" then
            executeScript(code)
        end
    end)

    clipboardBtn.MouseButton1Click:Connect(function()
        local clipboard = getclipboard()
        if clipboard then
            scriptInput.Text = clipboard
        end
    end)

    saveBtn.MouseButton1Click:Connect(function()
        local code = scriptInput.Text
        if code ~= "" then
            local name = "Script_" .. os.date("%H%M%S")
            savedScripts[name] = code
            saveScripts(savedScripts)
            refreshList()
            scriptInput.Text = ""
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    dragButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    -- 拖拽功能
    local dragging, dragInput, dragStart, startPos

    dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragButton.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            dragButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    refreshList()
end

createUI()
