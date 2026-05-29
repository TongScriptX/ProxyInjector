-- Proxy Injector v3.0
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local APP_NAME = "ProxyInjector"
local STORAGE_KEY = "ProxyInjector_State.json"
local DEFAULT_PROXY_ENDPOINT = "https://api.959966.xyz/proxy?url={url}"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function trim(text)
    return tostring(text or ""):match("^%s*(.-)%s*$")
end

local function cloneTable(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function safeDecode(text, fallback)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)
    return ok and data or fallback
end

local function readState()
    local defaultState = {
        proxyEndpoint = DEFAULT_PROXY_ENDPOINT,
        favorites = {}
    }

    local ok, data = pcall(function()
        if isfile and isfile(STORAGE_KEY) then
            return safeDecode(readfile(STORAGE_KEY), defaultState)
        end
        return defaultState
    end)

    if not ok or type(data) ~= "table" then
        return cloneTable(defaultState)
    end

    data.proxyEndpoint = trim(data.proxyEndpoint) ~= "" and trim(data.proxyEndpoint) or DEFAULT_PROXY_ENDPOINT
    data.favorites = type(data.favorites) == "table" and data.favorites or {}
    return data
end

local function writeState(state)
    pcall(function()
        writefile(STORAGE_KEY, HttpService:JSONEncode(state))
    end)
end

local state = readState()

local function normalizeProxyEndpoint(endpoint)
    local value = trim(endpoint)
    if value == "" then
        value = DEFAULT_PROXY_ENDPOINT
    end
    if not value:find("{url}", 1, true) and not value:find("url=", 1, true) then
        value = value .. (value:find("?", 1, true) and "&url={url}" or "?url={url}")
    end
    return value
end

local function buildProxyUrl(targetUrl)
    local cleanTarget = trim(targetUrl)
    if cleanTarget == "" then
        return ""
    end

    local endpoint = normalizeProxyEndpoint(state.proxyEndpoint)
    local encodedTarget = HttpService:UrlEncode(cleanTarget)
    if endpoint:find("{url}", 1, true) then
        return endpoint:gsub("{url}", encodedTarget)
    end
    if endpoint:find("url=", 1, true) then
        return endpoint .. encodedTarget
    end
    return endpoint .. (endpoint:find("?", 1, true) and "&url=" or "?url=") .. encodedTarget
end

local function isHttpUrl(value)
    return trim(value):match("^https?://") ~= nil
end

local function proxyFetch(url)
    local target = trim(url)
    if target == "" then
        error("empty url")
    end
    return game:HttpGet(buildProxyUrl(target))
end

local function rewriteScriptSource(source)
    local patched = tostring(source or "")

    patched = patched:gsub('game:HttpGet%(%s*"(https?://[^"]+)"%s*%)', function(url)
        return 'game:HttpGet("' .. buildProxyUrl(url) .. '")'
    end)

    patched = patched:gsub("game:HttpGet%(%s*'(https?://[^']+)'%s*%)", function(url)
        return "game:HttpGet('" .. buildProxyUrl(url) .. "')"
    end)

    patched = patched:gsub('game%.HttpGet%s*%(%s*game%s*,%s*"(https?://[^"]+)"%s*%)', function(url)
        return 'game:HttpGet("' .. buildProxyUrl(url) .. '")'
    end)

    patched = patched:gsub("game%.HttpGet%s*%(%s*game%s*,%s*'(https?://[^']+)'%s*%)", function(url)
        return "game:HttpGet('" .. buildProxyUrl(url) .. "')"
    end)

    return patched
end

local function compileAndRun(source)
    local chunk, compileError = loadstring(rewriteScriptSource(source))
    if not chunk then
        error("compile error: " .. tostring(compileError))
    end
    return chunk()
end

local function executeInput(rawInput)
    local input = trim(rawInput)
    if input == "" then
        error("empty input")
    end

    if isHttpUrl(input) then
        return compileAndRun(proxyFetch(input))
    end

    return compileAndRun(input)
end

local function inferName(value)
    local input = trim(value)
    if isHttpUrl(input) then
        local lastPart = input:match("/([^/?#]+)[^/]*$") or input
        return trim(lastPart:gsub("%%20", " "))
    end
    local firstLine = input:match("([^\n\r]+)") or input
    return trim(firstLine):sub(1, 28)
end

if playerGui:FindFirstChild(APP_NAME) then
    playerGui[APP_NAME]:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = APP_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
local compact = math.min(viewport.X, viewport.Y) < 560
local panelWidth = math.min(math.floor(viewport.X * 0.94), compact and 420 or 960)
local panelHeight = math.min(math.floor(viewport.Y * 0.9), compact and 620 or 620)
local leftWidth = compact and (panelWidth - 32) or math.floor(panelWidth * 0.62)
local rightWidth = compact and (panelWidth - 32) or (panelWidth - leftWidth - 44)

local palette = {
    bg = Color3.fromRGB(10, 14, 24),
    panel = Color3.fromRGB(18, 24, 38),
    panelSoft = Color3.fromRGB(27, 35, 54),
    border = Color3.fromRGB(47, 58, 84),
    text = Color3.fromRGB(240, 245, 255),
    muted = Color3.fromRGB(151, 165, 194),
    primary = Color3.fromRGB(0, 163, 255),
    primarySoft = Color3.fromRGB(0, 118, 204),
    success = Color3.fromRGB(32, 191, 107),
    warn = Color3.fromRGB(255, 179, 71),
    danger = Color3.fromRGB(244, 91, 105)
}

local function round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function stroke(instance, color, thickness, transparency)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = color
    uiStroke.Thickness = thickness or 1
    uiStroke.Transparency = transparency or 0
    uiStroke.Parent = instance
    return uiStroke
end

local function createLabel(parent, text, size, bold, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or palette.text
    label.TextSize = size
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function createButton(parent, text, backgroundColor, width)
    local button = Instance.new("TextButton")
    button.Size = width and UDim2.new(0, width, 0, 36) or UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = backgroundColor
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    round(button, 10)
    return button
end

local fab = createButton(screenGui, "PX", palette.primary, 56)
fab.Size = UDim2.fromOffset(56, 56)
fab.Position = UDim2.new(1, -72, 0.5, -28)
fab.TextSize = 18
fab.ZIndex = 20
round(fab, 18)
stroke(fab, Color3.fromRGB(255, 255, 255), 1, 0.85)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
panel.Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -panelHeight / 2)
panel.BackgroundColor3 = palette.panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
panel.ZIndex = 5
round(panel, 18)
stroke(panel, palette.border, 1, 0.2)

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = palette.bg
overlay.BackgroundTransparency = 0.22
overlay.BorderSizePixel = 0
overlay.ZIndex = 4
overlay.Visible = false
overlay.Parent = screenGui

local header = Instance.new("Frame")
header.Size = UDim2.new(1, -24, 0, 70)
header.Position = UDim2.fromOffset(12, 12)
header.BackgroundColor3 = palette.panelSoft
header.BorderSizePixel = 0
header.Parent = panel
header.ZIndex = 6
round(header, 16)
stroke(header, palette.border, 1, 0.35)

local title = createLabel(header, "Proxy Injector", 20, true)
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.new(1, -130, 0, 24)
title.ZIndex = 7

local subtitle = createLabel(header, "通用代理注入器，可代理任意脚本链接", 12, false, palette.muted)
subtitle.Position = UDim2.fromOffset(18, 36)
subtitle.Size = UDim2.new(1, -140, 0, 20)
subtitle.ZIndex = 7

local closeButton = createButton(header, "×", palette.danger, 36)
closeButton.Position = UDim2.new(1, -48, 0.5, -18)
closeButton.ZIndex = 7

local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -24, 0, 34)
statusFrame.Position = UDim2.fromOffset(12, 94)
statusFrame.BackgroundColor3 = palette.panelSoft
statusFrame.BorderSizePixel = 0
statusFrame.Parent = panel
statusFrame.ZIndex = 6
round(statusFrame, 12)
stroke(statusFrame, palette.border, 1, 0.45)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(10, 10)
statusDot.Position = UDim2.new(0, 14, 0.5, -5)
statusDot.BackgroundColor3 = palette.primary
statusDot.BorderSizePixel = 0
statusDot.Parent = statusFrame
statusDot.ZIndex = 7
round(statusDot, 10)

local statusLabel = createLabel(statusFrame, "就绪", 12, true)
statusLabel.Position = UDim2.fromOffset(32, 0)
statusLabel.Size = UDim2.new(1, -44, 1, 0)
statusLabel.ZIndex = 7

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -24, 1, -142)
body.Position = UDim2.fromOffset(12, 136)
body.BackgroundTransparency = 1
body.Parent = panel
body.ZIndex = 6

local function setStatus(text, color)
    statusLabel.Text = text
    statusDot.BackgroundColor3 = color or palette.primary
end

local leftColumn = Instance.new("Frame")
leftColumn.Size = compact and UDim2.new(1, 0, 0, 350) or UDim2.new(0, leftWidth, 1, 0)
leftColumn.BackgroundTransparency = 1
leftColumn.Parent = body
leftColumn.ZIndex = 6

local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 10)
leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.Parent = leftColumn

local function makeSection(parent, titleText, height)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, height)
    section.BackgroundColor3 = palette.panelSoft
    section.BorderSizePixel = 0
    section.Parent = parent
    section.ZIndex = 6
    round(section, 16)
    stroke(section, palette.border, 1, 0.3)

    local sectionTitle = createLabel(section, titleText, 12, true, palette.muted)
    sectionTitle.Position = UDim2.fromOffset(14, 10)
    sectionTitle.Size = UDim2.new(1, -28, 0, 18)
    sectionTitle.ZIndex = 7

    return section
end

local proxySection = makeSection(leftColumn, "代理端点", 84)
local proxyBox = Instance.new("TextBox")
proxyBox.Size = UDim2.new(1, -28, 0, 38)
proxyBox.Position = UDim2.fromOffset(14, 32)
proxyBox.BackgroundColor3 = palette.panel
proxyBox.BorderSizePixel = 0
proxyBox.Text = normalizeProxyEndpoint(state.proxyEndpoint)
proxyBox.PlaceholderText = DEFAULT_PROXY_ENDPOINT
proxyBox.TextColor3 = palette.text
proxyBox.PlaceholderColor3 = palette.muted
proxyBox.TextSize = 12
proxyBox.Font = Enum.Font.Code
proxyBox.ClearTextOnFocus = false
proxyBox.TextXAlignment = Enum.TextXAlignment.Left
proxyBox.Parent = proxySection
proxyBox.ZIndex = 7
round(proxyBox, 10)
stroke(proxyBox, palette.border, 1, 0.25)

local editorHeight = compact and 184 or 238
local editorSection = makeSection(leftColumn, "脚本 / 链接", 40 + editorHeight)
local editorBox = Instance.new("TextBox")
editorBox.Size = UDim2.new(1, -28, 0, editorHeight)
editorBox.Position = UDim2.fromOffset(14, 32)
editorBox.BackgroundColor3 = palette.panel
editorBox.BorderSizePixel = 0
editorBox.Text = ""
editorBox.PlaceholderText = "输入 Lua 代码，或直接粘贴任意 http/https 脚本链接"
editorBox.TextColor3 = palette.text
editorBox.PlaceholderColor3 = palette.muted
editorBox.TextSize = 13
editorBox.Font = Enum.Font.Code
editorBox.TextXAlignment = Enum.TextXAlignment.Left
editorBox.TextYAlignment = Enum.TextYAlignment.Top
editorBox.MultiLine = true
editorBox.ClearTextOnFocus = false
editorBox.Parent = editorSection
editorBox.ZIndex = 7
round(editorBox, 10)
stroke(editorBox, palette.border, 1, 0.25)

local editorPadding = Instance.new("UIPadding")
editorPadding.PaddingLeft = UDim.new(0, 10)
editorPadding.PaddingRight = UDim.new(0, 10)
editorPadding.PaddingTop = UDim.new(0, 8)
editorPadding.PaddingBottom = UDim.new(0, 8)
editorPadding.Parent = editorBox

local actionSection = makeSection(leftColumn, "操作", 92)
local actionRow = Instance.new("Frame")
actionRow.Size = UDim2.new(1, -28, 0, 40)
actionRow.Position = UDim2.fromOffset(14, 34)
actionRow.BackgroundTransparency = 1
actionRow.Parent = actionSection
actionRow.ZIndex = 7

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.Padding = UDim.new(0, 8)
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.Parent = actionRow

local runButton = createButton(actionRow, "执行", palette.success)
runButton.Size = UDim2.new(0.34, -6, 1, 0)
runButton.ZIndex = 8

local saveButton = createButton(actionRow, "保存", palette.warn)
saveButton.Size = UDim2.new(0.33, -5, 1, 0)
saveButton.ZIndex = 8

local copyProxyButton = createButton(actionRow, "复制代理链接", palette.primarySoft)
copyProxyButton.Size = UDim2.new(0.33, -5, 1, 0)
copyProxyButton.ZIndex = 8

local rightColumn = Instance.new("Frame")
rightColumn.Size = compact and UDim2.new(1, 0, 0, 0) or UDim2.new(0, rightWidth, 1, 0)
rightColumn.Position = compact and UDim2.fromOffset(0, 360) or UDim2.new(0, leftWidth + 20, 0, 0)
rightColumn.AutomaticSize = compact and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
rightColumn.BackgroundTransparency = 1
rightColumn.Parent = body
rightColumn.ZIndex = 6

if compact then
    body.AutomaticSize = Enum.AutomaticSize.Y
    panel.Size = UDim2.fromOffset(panelWidth, math.min(panelHeight + 180, viewport.Y - 20))
end

local favoritesSection = makeSection(rightColumn, "已保存脚本", compact and 248 or body.AbsoluteSize.Y)
favoritesSection.Size = compact and UDim2.new(1, 0, 0, 248) or UDim2.new(1, 0, 1, 0)

local favoritesList = Instance.new("ScrollingFrame")
favoritesList.Size = UDim2.new(1, -20, 1, -48)
favoritesList.Position = UDim2.fromOffset(10, 34)
favoritesList.BackgroundTransparency = 1
favoritesList.BorderSizePixel = 0
favoritesList.ScrollBarThickness = 4
favoritesList.ScrollBarImageColor3 = palette.primary
favoritesList.AutomaticCanvasSize = Enum.AutomaticSize.Y
favoritesList.CanvasSize = UDim2.new()
favoritesList.Parent = favoritesSection
favoritesList.ZIndex = 7

local favoritesLayout = Instance.new("UIListLayout")
favoritesLayout.Padding = UDim.new(0, 8)
favoritesLayout.SortOrder = Enum.SortOrder.LayoutOrder
favoritesLayout.Parent = favoritesList

local favoritesPadding = Instance.new("UIPadding")
favoritesPadding.PaddingBottom = UDim.new(0, 2)
favoritesPadding.Parent = favoritesList

local function persistProxyEndpoint()
    state.proxyEndpoint = normalizeProxyEndpoint(proxyBox.Text)
    proxyBox.Text = state.proxyEndpoint
    writeState(state)
end

proxyBox.FocusLost:Connect(function()
    persistProxyEndpoint()
    setStatus("代理端点已更新", palette.primary)
end)

local function getFavoritesArray()
    local favorites = {}
    for _, item in ipairs(state.favorites) do
        if type(item) == "table" and trim(item.name) ~= "" and trim(item.value) ~= "" then
            favorites[#favorites + 1] = {
                name = trim(item.name),
                value = trim(item.value)
            }
        end
    end
    return favorites
end

local function refreshFavorites()
    for _, child in ipairs(favoritesList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    state.favorites = getFavoritesArray()
    writeState(state)

    if #state.favorites == 0 then
        local empty = Instance.new("Frame")
        empty.Size = UDim2.new(1, 0, 0, 72)
        empty.BackgroundColor3 = palette.panel
        empty.BorderSizePixel = 0
        empty.Parent = favoritesList
        empty.ZIndex = 7
        round(empty, 12)
        stroke(empty, palette.border, 1, 0.35)

        local emptyText = createLabel(empty, "还没有保存脚本", 13, true, palette.muted)
        emptyText.Size = UDim2.new(1, -24, 1, 0)
        emptyText.Position = UDim2.fromOffset(12, 0)
        emptyText.ZIndex = 8
        return
    end

    for index, item in ipairs(state.favorites) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 82)
        row.BackgroundColor3 = palette.panel
        row.BorderSizePixel = 0
        row.Parent = favoritesList
        row.ZIndex = 7
        round(row, 12)
        stroke(row, palette.border, 1, 0.3)

        local nameLabel = createLabel(row, item.name, 13, true)
        nameLabel.Position = UDim2.fromOffset(12, 10)
        nameLabel.Size = UDim2.new(1, -100, 0, 18)
        nameLabel.ZIndex = 8

        local valueLabel = createLabel(row, item.value, 11, false, palette.muted)
        valueLabel.Position = UDim2.fromOffset(12, 30)
        valueLabel.Size = UDim2.new(1, -24, 0, 18)
        valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
        valueLabel.ZIndex = 8

        local useButton = createButton(row, "载入", palette.success, 56)
        useButton.Position = UDim2.new(1, -136, 1, -34)
        useButton.Size = UDim2.fromOffset(56, 24)
        useButton.TextSize = 11
        useButton.ZIndex = 8

        local runSavedButton = createButton(row, "运行", palette.primarySoft, 56)
        runSavedButton.Position = UDim2.new(1, -72, 1, -34)
        runSavedButton.Size = UDim2.fromOffset(56, 24)
        runSavedButton.TextSize = 11
        runSavedButton.ZIndex = 8

        local deleteButton = createButton(row, "删", palette.danger, 24)
        deleteButton.Position = UDim2.new(1, -40, 0, 10)
        deleteButton.Size = UDim2.fromOffset(24, 24)
        deleteButton.TextSize = 11
        deleteButton.ZIndex = 8

        useButton.MouseButton1Click:Connect(function()
            editorBox.Text = item.value
            setStatus("已载入: " .. item.name, palette.primary)
        end)

        runSavedButton.MouseButton1Click:Connect(function()
            persistProxyEndpoint()
            setStatus("执行中: " .. item.name, palette.warn)
            local ok, err = pcall(function()
                executeInput(item.value)
            end)
            if ok then
                setStatus("执行完成: " .. item.name, palette.success)
            else
                warn("[" .. APP_NAME .. "]", err)
                setStatus("执行失败: " .. tostring(err), palette.danger)
            end
        end)

        deleteButton.MouseButton1Click:Connect(function()
            table.remove(state.favorites, index)
            refreshFavorites()
            setStatus("已删除: " .. item.name, palette.danger)
        end)
    end
end

runButton.MouseButton1Click:Connect(function()
    persistProxyEndpoint()
    setStatus("执行中...", palette.warn)
    local ok, err = pcall(function()
        executeInput(editorBox.Text)
    end)
    if ok then
        setStatus("执行完成", palette.success)
    else
        warn("[" .. APP_NAME .. "]", err)
        setStatus("执行失败: " .. tostring(err), palette.danger)
    end
end)

saveButton.MouseButton1Click:Connect(function()
    local value = trim(editorBox.Text)
    if value == "" then
        setStatus("没有可保存的内容", palette.danger)
        return
    end

    local entry = {
        name = inferName(value),
        value = value
    }

    state.favorites[#state.favorites + 1] = entry
    refreshFavorites()
    setStatus("已保存: " .. entry.name, palette.success)
end)

copyProxyButton.MouseButton1Click:Connect(function()
    local value = trim(editorBox.Text)
    if not isHttpUrl(value) then
        setStatus("当前输入不是链接", palette.danger)
        return
    end

    persistProxyEndpoint()
    local proxied = buildProxyUrl(value)
    local copied = false

    if setclipboard then
        copied = pcall(setclipboard, proxied)
    elseif toclipboard then
        copied = pcall(toclipboard, proxied)
    end

    if copied then
        setStatus("代理链接已复制", palette.success)
    else
        setStatus("代理链接: " .. proxied, palette.primary)
    end
end)

local function setPanelVisible(visible)
    overlay.Visible = visible
    panel.Visible = visible
    if visible then
        panel.BackgroundTransparency = 1
        TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        }):Play()
    end
end

closeButton.MouseButton1Click:Connect(function()
    setPanelVisible(false)
end)

overlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        setPanelVisible(false)
    end
end)

local dragging = false
local dragStart
local startPosition
local moved = false

fab.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        startPosition = fab.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        moved = moved or delta.Magnitude > 6
        fab.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

fab.MouseButton1Click:Connect(function()
    if not moved then
        setPanelVisible(not panel.Visible)
    end
end)

refreshFavorites()
setStatus("就绪，可直接执行任意链接", palette.primary)
