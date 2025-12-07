local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

-- ======================== 配置区域 ========================
local CONFIG = {
    -- 默认有效卡密列表（如远程获取失败时使用）
    VALID_KEYS = {
        "WINTER_2025_VIP", "ROBLOX_SCRIPT_001", "ADMIN_TEST_KEY",
        "a1B2c3D4e5F6g7H8i9J0k", "L1mN2oP3qR4sT5uV6wX7y", "z8A9b0C1dE2fG3hI4jK5l",
        "M6nO7pQ8rS9tU0vW1xY2z", "3B4cD5eF6gH7iJ8kL9mN0", "o1P2qR3sT4uV5wX6yA7b8",
        "C9dE0fG1hI2jK3lM4nO5p", "Q6rS7tU8vW9xY0zA1bC2d", "E3fG4hI5jK6lM7nO8pQ9r"
    },
    -- 最大验证尝试次数
    MAX_ATTEMPTS = 3,
    -- 授权信息本地存储路径
    SAVE_PATH = "AuthSystem/ValidUser.json",
    -- 远程获取有效卡密的URL
    VALID_KEYS_URL = "http://server.enet.online:23524/get_valid_keys", -- 请替换为您的实际URL
    -- 验证成功后执行的脚本
    TARGET_SCRIPT_URL = "https://raw.githubusercontent.com/tfcygvunbind/Apple/main/%E9%BB%91%E7%99%BD%E8%84%9A%E6%9C%AC%E6%9C%80%E6%96%B0",
    -- 管理员用户名
    ADMIN_USER = "gdhdfghffgh7"
}

-- ======================== 日志系统 ========================
local ActionLogs = {}
local LogDisplayLabel -- 提前声明引用

local function AddLog(msg, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local formattedMsg = string.format("[%s] [%s] %s", timestamp, level, msg)
    
    table.insert(ActionLogs, formattedMsg)
    
    -- 打印到控制台
    if level == "WARN" then
        warn(formattedMsg)
    elseif level == "ERROR" then
        warn("ERROR: " .. formattedMsg)
    else
        print(formattedMsg)
    end
    
    -- 如果日志UI存在，更新显示
    if LogDisplayLabel then
        LogDisplayLabel.Text = table.concat(ActionLogs, "\n")
        -- 滚动到底部 (简单实现：调整CanvasPosition，但在纯TextLabel中较难，这里仅更新文本)
    end
end

-- ======================== 本地存储功能 ========================
-- 保存授权状态
local function SaveAuthStatus()
    pcall(function()
        if not isfolder("AuthSystem") then
            makefolder("AuthSystem")
        end
        local authData = {
            PlayerName = player.Name,
            Authorized = true,
            AuthTime = os.time(),
            ExpireTime = os.time() + 86400 * 7 -- 授权有效期7天
        }
        writefile(CONFIG.SAVE_PATH, HttpService:JSONEncode(authData))
    end)
end

-- 读取授权状态
local function LoadAuthStatus()
    if not isfile(CONFIG.SAVE_PATH) then return nil end
    local success, data = pcall(function()
        local content = readfile(CONFIG.SAVE_PATH)
        return HttpService:JSONDecode(content)
    end)
    if success and data then
        return data.Authorized and data.ExpireTime > os.time() and data.PlayerName == player.Name
    end
    return false
end

-- ======================== UI创建 ========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KeyAuthUI"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -80)
MainFrame.Size = UDim2.new(0, 260, 0, 160)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
TitleBar.Size = UDim2.new(1, 0, 0, 30)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Text = "卡密验证"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.SourceSansBold

local KeyInput = Instance.new("TextBox")
KeyInput.Name = "KeyInput"
KeyInput.Parent = MainFrame
KeyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
KeyInput.Position = UDim2.new(0.05, 0, 0.25, 0)
KeyInput.Size = UDim2.new(0.9, 0, 0, 40)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.PlaceholderText = "输入卡密（区分大小写）"
KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
KeyInput.TextSize = 14
KeyInput.ClearTextOnFocus = false

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Name = "VerifyBtn"
VerifyBtn.Parent = MainFrame
VerifyBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
VerifyBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 35)
VerifyBtn.Text = "验证并进入"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 14
VerifyBtn.Font = Enum.Font.SourceSansBold

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Text = "请输入卡密"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Font = Enum.Font.SourceSans

-- ======================== 管理员UI ========================
local ViewLogsBtn = Instance.new("TextButton")
ViewLogsBtn.Name = "ViewLogsBtn"
ViewLogsBtn.Parent = MainFrame
ViewLogsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ViewLogsBtn.Position = UDim2.new(0.8, 0, 0, 5) -- 标题栏右侧
ViewLogsBtn.Size = UDim2.new(0, 45, 0, 20)
ViewLogsBtn.Text = "日志"
ViewLogsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ViewLogsBtn.TextSize = 12
ViewLogsBtn.Visible = false -- 默认隐藏

local LogsFrame = Instance.new("ScrollingFrame")
LogsFrame.Name = "LogsFrame"
LogsFrame.Parent = ScreenGui
LogsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LogsFrame.Position = UDim2.new(0.5, 140, 0.5, -80) -- 主窗口右侧
LogsFrame.Size = UDim2.new(0, 300, 0, 200)
LogsFrame.Visible = false
LogsFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- 自动调整
LogsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

LogDisplayLabel = Instance.new("TextLabel")
LogDisplayLabel.Parent = LogsFrame
LogDisplayLabel.Size = UDim2.new(1, -10, 1, 0)
LogDisplayLabel.Position = UDim2.new(0, 5, 0, 0)
LogDisplayLabel.BackgroundTransparency = 1
LogDisplayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
LogDisplayLabel.TextSize = 12
LogDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
LogDisplayLabel.TextYAlignment = Enum.TextYAlignment.Top
LogDisplayLabel.TextWrapped = true
LogDisplayLabel.Text = "等待日志..."

ViewLogsBtn.MouseButton1Click:Connect(function()
    LogsFrame.Visible = not LogsFrame.Visible
end)
-- ======================== 核心验证逻辑 ========================
local errorCount = 0
local isAuthorized = LoadAuthStatus()

local function ExecuteTargetScript()
    pcall(function()
        loadstring(game:HttpGet(CONFIG.TARGET_SCRIPT_URL))()
    end)
end

local function VerifyKey(inputKey, validKeys)
    for _, validKey in ipairs(validKeys) do
        if inputKey == validKey then
            return true
        end
    end
    return false
end

VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = KeyInput.Text
    -- 去除首尾空格，防止复制时多余空格导致错误
    inputKey = inputKey:gsub("^%s*(.-)%s*$", "%1")
    
    AddLog("尝试验证卡密: " .. inputKey)
    
    if errorCount >= CONFIG.MAX_ATTEMPTS then
        AddLog("验证失败次数过多，踢出玩家", "WARN")
        StatusLabel.Text = "尝试次数已达上限！"
        StatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
        task.wait(1)
        player:Kick("多次输入错误卡密，已暂时封禁")
        return
    end
    if VerifyKey(inputKey, CONFIG.VALID_KEYS) then
        SaveAuthStatus()
        isAuthorized = true
        StatusLabel.Text = "验证成功！正在加载..."
        StatusLabel.TextColor3 = Color3.fromRGB(34, 197, 94)
        VerifyBtn.Text = "加载中..."
        VerifyBtn.Enabled = false
        ExecuteTargetScript()
        task.wait(2)
        MainFrame.Visible = false
    else
        errorCount = errorCount + 1
        local remaining = CONFIG.MAX_ATTEMPTS - errorCount
        StatusLabel.Text = string.format("卡密无效，剩余%d次机会", remaining)
        StatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
        KeyInput.Text = ""
    end
end)

-- ======================== 远程获取有效卡密 ========================

local function FetchValidKeys()
    AddLog("开始请求服务器获取卡密...")
    local success, response = pcall(function()
        return HttpService:GetAsync(CONFIG.VALID_KEYS_URL)
    end)
    if success then
        local successDecode, keysData = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if successDecode and type(keysData) == "table" and keysData.validKeys then
            AddLog("成功获取卡密列表，数量: " .. #keysData.validKeys)
            return keysData.validKeys
        else
            AddLog("服务器响应格式错误或解析失败", "ERROR")
            return CONFIG.VALID_KEYS
        end
    else
        AddLog("连接服务器失败，使用本地列表", "WARN")
        return CONFIG.VALID_KEYS
    end
end

-- ======================== 启动授权检查 ========================
local function CheckAuthorization()
    -- 检查是否为管理员
    if player.Name == CONFIG.ADMIN_USER then
        AddLog("检测到管理员登录: " .. player.Name)
        ViewLogsBtn.Visible = true
    end

    if isAuthorized then
        AddLog("玩家已授权，直接进入: " .. player.Name)
        ExecuteTargetScript()
        return
    end

    AddLog("未授权，正在获取服务器卡密列表...")
    local keys = FetchValidKeys()
    
    if keys and #keys > 0 then
        AddLog("成功同步卡密列表")
        CONFIG.VALID_KEYS = keys
    else
        AddLog("卡密同步失败，使用默认列表", "WARN")
    end
    
    StatusLabel.Text = "请输入卡密（卡密已由服务器同步）"
    MainFrame.Visible = true
end

-- 启动时检查授权
CheckAuthorization()
