-- Tối ưu hóa script để giảm CPU usage - Full Version

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Đợi game load
repeat RunService.Heartbeat:Wait() until game:IsLoaded() and game.Players.LocalPlayer

local player = Players.LocalPlayer

-- Thiết lập chế độ farm
getgenv().modefarm = getgenv().modefarm or "Normal"

-- Cấu hình với các giá trị tối ưu
getgenv().config = {
    autoFarm = true,
    flySpeed = 26,
    autoTeleport = true,
    teleportCooldown = 300,
    antiAFK = true,
    webhookEnabled = true,
    buyBattlePass = (getgenv().modefarm == "BattlePass"),
    autoOpenBox = (getgenv().modefarm == "Crate"),
    autoPlay = true,
    -- Cấu hình tối ưu mới
    updateInterval = 2, -- Giảm tần suất update
    candyCheckRadius = 150, -- Giới hạn bán kính tìm kẹo
    uiUpdateRate = 3, -- Giảm tần suất update UI
    maxCandyChecks = 10 -- Giới hạn số lần kiểm tra kẹo mỗi frame
}

-- Biến quản lý trạng thái
local farming = false
local collected = 0
local startTime = tick()
local lastCollectionTime = tick()
local isOnCooldown = false
local remainingTime = getgenv().config.teleportCooldown

-- Cache các service và object thường dùng
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

-- Tối ưu: Cache các remote function
local ExtrasRemote
local GetProfileDataRemote
local OpenCrateRemote

-- Hàm khởi tạo cache
local function initializeCache()
    ExtrasRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("RequestTeleport")
    GetProfileDataRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("GetProfileData")
    OpenCrateRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("OpenCrate")
end

-- Tối ưu: Hàm wait với timeout
local function safeWait(duration)
    local start = tick()
    while tick() - start < duration and RunService.Heartbeat:Wait() do
        -- Sử dụng Heartbeat thay vì task.wait
    end
end

-- Tối ưu: Hàm get children an toàn
local function getSafeChildren(parent)
    local success, result = pcall(function()
        return parent:GetChildren()
    end)
    return success and result or {}
end

-- Tối ưu: Simple Auto Play với ít CPU usage hơn
local function optimizedAutoPlay()
    local lastCheck = 0
    
    while getgenv().config.autoPlay do
        local currentTime = tick()
        
        -- Chỉ kiểm tra mỗi 3 giây
        if currentTime - lastCheck >= 3 then
            pcall(function()
                local playerGui = player:WaitForChild("PlayerGui", 2)
                if not playerGui then return end
                
                -- Tìm button play hiệu quả hơn
                local function findPlayButtons(guiParent)
                    local buttons = {}
                    for _, child in ipairs(getSafeChildren(guiParent)) do
                        if child:IsA("TextButton") and string.lower(tostring(child.Text)):find("play") then
                            if child.Visible and child.Active then
                                table.insert(buttons, child)
                            end
                        elseif child:IsA("Frame") or child:IsA("ScreenGui") then
                            local childButtons = findPlayButtons(child)
                            for _, btn in ipairs(childButtons) do
                                table.insert(buttons, btn)
                            end
                        end
                    end
                    return buttons
                end
                
                local playButtons = findPlayButtons(playerGui)
                
                -- Thử click button đầu tiên tìm thấy
                if #playButtons > 0 then
                    local button = playButtons[1]
                    local clicked = false
                    
                    -- Thử các phương thức click khác nhau
                    local connections = getconnections(button.MouseButton1Click)
                    if #connections > 0 then
                        for i = 1, math.min(2, #connections) do -- Giới hạn số connection thử
                            local connection = connections[i]
                            if connection.Function then
                                pcall(connection.Function)
                                clicked = true
                                break
                            end
                        end
                    end
                    
                    if not clicked and button:FindFirstChildWhichIsA("RemoteEvent") then
                        pcall(function()
                            button:FindFirstChildWhichIsA("RemoteEvent"):FireServer()
                        end)
                    end
                end
            end)
            
            lastCheck = currentTime
        end
        
        RunService.Heartbeat:Wait()
    end
end

-- Khởi chạy auto play
task.spawn(optimizedAutoPlay)

-- Tối ưu: UI với ít update hơn
local function createOptimizedUI()
    local HopGui = Instance.new("ScreenGui")
    HopGui.Name = "KissanHubUI"
    HopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    HopGui.IgnoreGuiInset = true
    HopGui.Parent = CoreGui
    HopGui.Enabled = true
    HopGui.ResetOnSpawn = false

    local Frame = Instance.new("Frame")
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BackgroundTransparency = 0.3
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.Size = UDim2.new(0.3, 0, 0.2, 0)
    Frame.Active = false
    Frame.Selectable = false
    Frame.ZIndex = 1
    Frame.Parent = HopGui

    local labels = {}
    local labelConfigs = {
        {Name = "Title", Text = "Kissan Hub", Size = 24, Position = UDim2.new(0.5, 0, 0.2, 0)},
        {Name = "ModeLabel", Text = "Mode: " .. getgenv().modefarm, Size = 18, Position = UDim2.new(0.5, 0, 0.4, 0)},
        {Name = "CandiesLabel", Text = "Total Candies: Loading...", Size = 16, Position = UDim2.new(0.5, 0, 0.6, 0)},
        {Name = "TimeLabel", Text = "Time: 0h 0m 0s", Size = 14, Position = UDim2.new(0.5, 0, 0.8, 0)}
    }

    for _, config in ipairs(labelConfigs) do
        local label = Instance.new("TextLabel")
        label.Name = config.Name
        label.Font = Enum.Font.Gotham
        label.Text = config.Text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = config.Size
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.Position = config.Position
        label.BackgroundTransparency = 1
        label.TextTransparency = 0
        label.ZIndex = 2
        label.Parent = Frame
        labels[config.Name] = label
    end

    -- Toggle button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 40, 0, 40)
    ToggleButton.Position = UDim2.new(0.95, 0, 0.05, 0)
    ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 14
    ToggleButton.Text = "UI"
    ToggleButton.ZIndex = 3
    ToggleButton.Parent = HopGui

    local uiVisible = true

    ToggleButton.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        Frame.Visible = uiVisible
        ToggleButton.Text = uiVisible and "UI" or "Show"
    end)

    return {
        Gui = HopGui,
        Labels = labels,
        Frame = Frame
    }
end

-- Khởi tạo UI
local UI = createOptimizedUI()

-- Tối ưu: Update UI với tần suất thấp
task.spawn(function()
    local lastUpdate = 0
    local hours, minutes, seconds = 0, 0, 0
    
    while true do
        local currentTime = tick()
        
        -- Chỉ update UI mỗi config.uiUpdateRate giây
        if currentTime - lastUpdate >= getgenv().config.uiUpdateRate then
            pcall(function()
                -- Update thời gian
                seconds = seconds + getgenv().config.uiUpdateRate
                if seconds >= 60 then
                    seconds = 0
                    minutes = minutes + 1
                end
                if minutes >= 60 then
                    minutes = 0
                    hours = hours + 1
                end
                
                UI.Labels.TimeLabel.Text = string.format("Time: %dh %dm %ds", hours, minutes, seconds)
                
                -- Update candies (ít thường xuyên hơn)
                if currentTime - lastUpdate >= 10 then -- Mỗi 10 giây update candies
                    local profileData = GetProfileDataRemote:InvokeServer()
                    if profileData and profileData.Materials and profileData.Materials.Owned then
                        local candies = profileData.Materials.Owned.Candies2025 or 0
                        UI.Labels.CandiesLabel.Text = "Total Candies: " .. tostring(candies)
                    end
                end
            end)
            
            lastUpdate = currentTime
        end
        
        RunService.Heartbeat:Wait()
    end
end)

-- Tối ưu: Hàm WaitForChildPath
local function WaitForChildPath(parent, path, timeout)
    timeout = timeout or 5
    local obj = parent
    for _, name in ipairs(path) do
        local startTime = tick()
        while tick() - startTime < timeout do
            obj = obj:FindFirstChild(name)
            if obj then break end
            RunService.Heartbeat:Wait()
        end
        if not obj then return nil end
    end
    return obj
end

-- Tối ưu: Auto Open Box
local function setupOptimizedAutoOpenBox()
    if getgenv().modefarm ~= "Crate" then return end
    
    repeat RunService.Heartbeat:Wait() until game:IsLoaded()
    repeat RunService.Heartbeat:Wait() until player:GetAttribute("ClientLoaded")

    local lastOpenAttempt = 0
    
    while getgenv().config.autoOpenBox do
        local currentTime = tick()
        
        -- Chỉ thử mở box mỗi 5 giây
        if currentTime - lastOpenAttempt >= 5 then
            pcall(function()
                local EventInfoService = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
                local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
                local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))

                local eventData = EventInfoService:GetCurrentEvent()
                local currency = eventData.Currency
                local keyName = eventData.KeyName
                local mysteryBox = eventData.MysteryBox.Name

                local function openBox(resource)
                    if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
                        local cost = Sync.Shop.Weapons[mysteryBox].Price[resource] or 0
                        local owned = ProfileData.Materials.Owned[resource] or 0
                        
                        if owned >= cost and cost > 0 then
                            local result = OpenCrateRemote:InvokeServer(mysteryBox, "MysteryBox", resource)
                            return result ~= nil
                        end
                    end
                    return false
                end

                local coinOpened = openBox(currency)
                local keyOpened = openBox(keyName)
                
                if not coinOpened and not keyOpened then
                    safeWait(10) -- Chờ lâu hơn nếu không có gì để mở
                end
            end)
            
            lastOpenAttempt = currentTime
        end
        
        RunService.Heartbeat:Wait()
    end
end

task.spawn(setupOptimizedAutoOpenBox)

-- Tối ưu: Device Selection
task.spawn(function()
    repeat RunService.Heartbeat:Wait() until game:IsLoaded() and player
    
    local PlayerGui = player:WaitForChild("PlayerGui")
    local DeviceSelect = PlayerGui:WaitForChild("DeviceSelect")
    local Container = DeviceSelect:WaitForChild("Container")

    local function getBestDevice()
        local devicePriority = {"Phone", "Computer", "Tablet", "Console"}
        
        for _, deviceName in ipairs(devicePriority) do
            local frame = Container:FindFirstChild(deviceName)
            if frame then
                local btn = frame:FindFirstChild("Button")
                if btn and btn.Visible and btn.Active then
                    return deviceName, btn
                end
            end
        end
        return nil, nil
    end

    local bestDevice, bestButton = getBestDevice()
    if bestDevice and bestButton then
        safeWait(0.5)
        pcall(function()
            for _, connection in ipairs(getconnections(bestButton.MouseButton1Click)) do
                if connection.Function then
                    connection.Function()
                    break
                end
            end
        end)
    end
end)

-- Tối ưu: Webhook với ít request hơn
local function sendOptimizedWebhook()
    if not getgenv().config.webhookEnabled then return end
    
    local GameName = "Unknown Game"
    pcall(function()
        local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        GameName = productInfo.Name
        GameName = GameName:gsub("%b[]", ""):gsub("^%s*(.-)%s*$", "%1")
    end)

    local data = {
        username = "Kissan Hub",
        content = string.format("Player: **%s**\nGame: **%s**\nMode: **%s**\nTime: %s", 
            player.Name, GameName, getgenv().modefarm, os.date("%d/%m/%Y %H:%M:%S"))
    }
    
    local request = http_request or request or syn and syn.request
    if request then
        pcall(function()
            request({
                Url = "https://discord.com/api/webhooks/1439594999716118538/l1Ng9UrUDUV7xTbNFZ48RGkMDyzYqXb9Wtlg4DU4VTiFnPNOgULrq4pCRdVUfrGMR0So",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
    end
end

-- Gửi webhook một lần khi bắt đầu
task.spawn(sendOptimizedWebhook)

-- Tối ưu: Anti-AFK
player.Idled:Connect(function()
    if getgenv().config.antiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        safeWait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

-- Tối ưu: Farming system
local character, rootPart, humanoid

local function initializeCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    -- Disable collision hiệu quả hơn
    RunService.Stepped:Connect(function()
        if getgenv().config.autoFarm and character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

player.CharacterAdded:Connect(initializeCharacter)
task.spawn(initializeCharacter)

-- Tối ưu: Candy collection system
local function GetCandyContainer()
    for _, obj in ipairs(getSafeChildren(workspace)) do
        if obj:FindFirstChild("CoinContainer") then
            return obj.CoinContainer
        end
    end
    return nil
end

local function getNearestCandy()
    if not getgenv().config.autoFarm or not character then return nil end
    
    local candyContainer = GetCandyContainer()
    if not candyContainer then return nil end
    
    local closest, dist = nil, math.huge
    local myPos = rootPart.Position
    local checked = 0
    
    for _, candy in ipairs(getSafeChildren(candyContainer)) do
        if checked >= getgenv().config.maxCandyChecks then break end
        
        if candy:IsA("BasePart") then
            local candyVisual = candy:FindFirstChild("CoinVisual")
            if candyVisual and not candyVisual:GetAttribute("Collected") then
                local d = (myPos - candy.Position).Magnitude
                if d < dist and d < getgenv().config.candyCheckRadius then
                    closest = candy
                    dist = d
                end
            end
        end
        checked = checked + 1
    end
    
    return closest
end

local function teleportToCandy(targetCandy)
    if not targetCandy or not getgenv().config.autoFarm or not character then return false end
    
    local candyVisual = targetCandy:FindFirstChild("CoinVisual")
    if not candyVisual or candyVisual:GetAttribute("Collected") then return false end
    
    pcall(function() humanoid:ChangeState(11) end)
    
    local distance = (rootPart.Position - targetCandy.Position).Magnitude
    if distance > getgenv().config.candyCheckRadius then return false end
    
    local travelTime = math.max(0.05, distance / getgenv().config.flySpeed)
    local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(targetCandy.Position + Vector3.new(0, 2, 0))
    })
    
    tween:Play()
    local startTime = tick()
    
    while tick() - startTime < travelTime + 0.1 do
        if not getgenv().config.autoFarm or not candyVisual or candyVisual:GetAttribute("Collected") or not character then
            tween:Cancel()
            return false
        end
        RunService.Heartbeat:Wait()
    end
    
    return true
end

local function updateCollectionTime()
    lastCollectionTime = tick()
    remainingTime = getgenv().config.teleportCooldown
end

local function performTeleport()
    if isOnCooldown or not getgenv().config.autoTeleport then return end
    
    pcall(function()
        ExtrasRemote:InvokeServer("Disguises")
        isOnCooldown = true
        task.delay(60, function() isOnCooldown = false end)
    end)
end

-- Tối ưu: Main farming loop
local function startOptimizedFarming()
    farming = true
    collected = 0
    startTime = tick()
    
    local lastCandyCheck = 0
    
    while farming and getgenv().config.autoFarm do
        local currentTime = tick()
        
        -- Kiểm tra kẹo mỗi 0.1 giây thay vì liên tục
        if currentTime - lastCandyCheck >= 0.1 then
            local targetCandy = getNearestCandy()
            if targetCandy then
                local success = teleportToCandy(targetCandy)
                if success then
                    collected = collected + 1
                    updateCollectionTime()
                    safeWait(0.05)
                else
                    safeWait(0.1)
                end
            else
                safeWait(0.2)
            end
            
            lastCandyCheck = currentTime
        end
        
        RunService.Heartbeat:Wait()
    end
end

-- Tối ưu: Auto teleport system
task.spawn(function()
    local lastTeleportCheck = 0
    
    while getgenv().config.autoTeleport do
        local currentTime = tick()
        
        -- Chỉ kiểm tra teleport mỗi 5 giây
        if currentTime - lastTeleportCheck >= 5 then
            local timeSinceLastCollection = currentTime - lastCollectionTime
            remainingTime = math.max(0, getgenv().config.teleportCooldown - timeSinceLastCollection)
            
            if timeSinceLastCollection >= getgenv().config.teleportCooldown and not isOnCooldown then
                local hasCollectedRecently = false
                local checkStartTime = tick()
                
                -- Kiểm tra trong 10 giây thay vì 15
                while tick() - checkStartTime < 10 do
                    local targetCandy = getNearestCandy()
                    if targetCandy then
                        local success = teleportToCandy(targetCandy)
                        if success then
                            collected = collected + 1
                            updateCollectionTime()
                            hasCollectedRecently = true
                            break
                        else
                            break
                        end
                    else
                        safeWait(1)
                    end
                end
                
                if not hasCollectedRecently then
                    performTeleport()
                end
            end
            
            lastTeleportCheck = currentTime
        end
        
        RunService.Heartbeat:Wait()
    end
end)

-- Tối ưu: Battle Pass system
if getgenv().config.buyBattlePass then
    task.spawn(function()
        local lastBPCheck = 0
        
        while true do
            local currentTime = tick()
            
            -- Chỉ kiểm tra BP mỗi 10 giây
            if currentTime - lastBPCheck >= 10 then
                pcall(function()
                    local EventInfoService = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
                    local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
                    
                    local eventRemote = EventInfoService:GetEventRemotes()
                    local eventData = EventInfoService:GetCurrentEvent()
                    local battlepassData = EventInfoService:GetBattlePass()
                    
                    if not ProfileData or not eventData or not battlepassData then return end
                    
                    local profileBP = ProfileData[eventData.Title]
                    if not profileBP then return end

                    -- Mua tier
                    if profileBP.CurrentTier < battlepassData.TotalTiers then
                        local coins = ProfileData.Materials.Owned[eventData.Currency] or 0
                        if coins >= battlepassData.TierCost then
                            eventRemote.BuyTiers:FireServer(1)
                            safeWait(0.5)
                        end
                    end

                    -- Nhận reward
                    for tier, _ in pairs(battlepassData.Rewards) do
                        local tierNum = tonumber(tier)
                        if tierNum and profileBP.CurrentTier >= tierNum and not profileBP.ClaimedRewards[tier] then
                            eventRemote.ClaimBattlePassReward:FireServer(tierNum)
                            safeWait(0.3)
                        end
                    end

                    -- Final reward
                    local finalCost = battlepassData.FinalRewardCost or math.huge
                    if (ProfileData.Materials.Owned[eventData.Currency] or 0) >= finalCost then
                        eventRemote.BuyFinalReward:FireServer()
                    end
                end)
                
                lastBPCheck = currentTime
            end
            
            RunService.Heartbeat:Wait()
        end
    end)
end

-- Khởi tạo cache và bắt đầu farm
task.spawn(function()
    safeWait(2)
    initializeCache()
    if getgenv().config.autoFarm then
        startOptimizedFarming()
    end
end)

-- Cleanup khi script kết thúc
game:GetService("ScriptContext").DescendantRemoving:Connect(function(descendant)
    if descendant == script then
        farming = false
        if UI and UI.Gui then
            UI.Gui:Destroy()
        end
    end
end)

warn("Kissan Hub Optimized - Loaded Successfully! Mode: " .. getgenv().modefarm)
