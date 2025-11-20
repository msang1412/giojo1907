local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Chờ game load
repeat task.wait(1) until game:IsLoaded() and player

-- Config
getgenv().modefarm = getgenv().modefarm or "Normal"
getgenv().config = {
    autoFarm = true,
    flySpeed = 26,
    autoTeleport = true,
    teleportCooldown = 300,
    antiAFK = true,
    webhookEnabled = true,
    buyBattlePass = (getgenv().modefarm == "BattlePass"),
    autoOpenBox = (getgenv().modefarm == "Crate"),
    autoPlay = true
}

-- Biến toàn cục
local character, rootPart, humanoid
local collected = 0
local startTime = tick()
local lastCollectionTime = tick()
local isOnCooldown = false
local farming = false
local hours, minutes, seconds = 0, 0, 0

-- UI Manager
local function createOptimizedUI()
    local HopGui = Instance.new("ScreenGui")
    HopGui.Name = "check"
    HopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    HopGui.IgnoreGuiInset = true
    HopGui.Parent = game:GetService("CoreGui")
    HopGui.Enabled = true
    HopGui.ResetOnSpawn = false

    local Frame = Instance.new("Frame")
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.Active = false
    Frame.Selectable = false
    Frame.ZIndex = 1
    Frame.Parent = HopGui

    local labels = {}
    local labelConfigs = {
        {"Title", "Kissan Hub", 70, Color3.fromRGB(200, 210, 255), UDim2.new(0.5, 0, 0.5, -40)},
        {"ModeLabel", "Mode: " .. getgenv().modefarm, 24, Color3.fromRGB(255, 255, 255), UDim2.new(0.5, 0, 0.5, -5)},
        {"CandiesLabel", "Total Candies: Loading...", 22, Color3.fromRGB(255, 255, 255), UDim2.new(0.5, 0, 0.5, 20)},
        {"TierLabel", "Tier: Loading...", 22, Color3.fromRGB(255, 255, 255), UDim2.new(0.5, 0, 0.5, 45)},
        {"TimeLabel", "Client Time Elapsed: 0h:0m:0s", 22, Color3.fromRGB(255, 255, 255), UDim2.new(0.5, 0, 0.5, 70)}
    }

    for _, config in ipairs(labelConfigs) do
        local label = Instance.new("TextLabel")
        label.Name = config[1]
        label.Font = config[1] == "Title" and Enum.Font.GothamBold or Enum.Font.Gotham
        label.Text = config[2]
        label.TextSize = config[3]
        label.TextColor3 = config[4]
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.Position = config[5]
        label.BackgroundTransparency = 1
        label.TextTransparency = 1
        label.ZIndex = 2
        label.Parent = Frame
        labels[config[1]] = label
    end

    local Blur = Instance.new("BlurEffect")
    Blur.Size = 0
    Blur.Enabled = false
    Blur.Parent = game.Lighting

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 50, 0, 50)
    ToggleButton.Position = UDim2.new(0.95, 0, 0.05, 0)
    ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 18
    ToggleButton.Text = ""
    ToggleButton.ZIndex = 3
    ToggleButton.Parent = HopGui

    local function fadeInUI()
        Frame.Visible = true
        Blur.Enabled = true
        TweenService:Create(Blur, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Size = 45}):Play()
        for _, label in pairs(labels) do
            label.Visible = true
            TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
        end
    end

    local function fadeOutUI()
        Blur.Enabled = false
        Blur.Size = 0
        Frame.Visible = false
        for _, label in pairs(labels) do
            label.Visible = false
            label.TextTransparency = 1
        end
    end

    ToggleButton.MouseButton1Click:Connect(function()
        if Frame.Visible then
            fadeOutUI()
        else
            fadeInUI()
        end
    end)

    ToggleButton.MouseEnter:Connect(function()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
    end)
    
    ToggleButton.MouseLeave:Connect(function()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    fadeInUI()
    return labels
end

-- Data Updater (Optimized)
local function createDataUpdater(labels)
    local lastCandyUpdate = 0
    local lastTierUpdate = 0
    local lastTimeUpdate = 0
    
    task.spawn(function()
        while true do
            local now = tick()
            
            -- Update candies mỗi 3 giây
            if now - lastCandyUpdate >= 3 then
                pcall(function()
                    local profileData = game:GetService("ReplicatedStorage").Remotes.Inventory.GetProfileData:InvokeServer()
                    if profileData and profileData.Materials and profileData.Materials.Owned then
                        local currentCandies = profileData.Materials.Owned.Candies2025 or 0
                        labels.CandiesLabel.Text = "Total Candies: " .. tostring(currentCandies)
                    end
                end)
                lastCandyUpdate = now
            end
            
            -- Update tier mỗi 5 giây
            if now - lastTierUpdate >= 5 then
                pcall(function()
                    local playerGui = player:WaitForChild("PlayerGui", 2)
                    if playerGui then
                        local tierTextLabel = playerGui:FindFirstChild("CrossPlatform")
                        tierTextLabel = tierTextLabel and tierTextLabel:FindFirstChild("CurrentEventFrame")
                        tierTextLabel = tierTextLabel and tierTextLabel:FindFirstChild("Container")
                        tierTextLabel = tierTextLabel and tierTextLabel:FindFirstChild("EventFrames")
                        tierTextLabel = tierTextLabel and tierTextLabel:FindFirstChild("BattlePass")
                        tierTextLabel = tierTextLabel and tierTextLabel:FindFirstChild("Info")
                        tierTextLabel = tierTextLabel and tierTextLabel:FindFirstChild("YourTier")
                        tierTextLabel = tierTextLabel and tierTextLabel:FindFirstChild("TextLabel")
                        
                        if tierTextLabel and tierTextLabel.Text then
                            local text = tierTextLabel.Text
                            local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
                            if current and max then
                                labels.TierLabel.Text = "Tier: " .. current .. " / " .. max
                            end
                        end
                    end
                end)
                lastTierUpdate = now
            end
            
            -- Update time mỗi 1 giây
            if now - lastTimeUpdate >= 1 then
                seconds = seconds + 1
                if seconds >= 60 then
                    seconds = 0
                    minutes = minutes + 1
                end
                if minutes >= 60 then
                    minutes = 0
                    hours = hours + 1
                end
                labels.TimeLabel.Text = "Client Time Elapsed: " .. hours .. "h:" .. minutes .. "m:" .. seconds .. "s"
                lastTimeUpdate = now
            end
            
            task.wait(0.5) -- Giảm CPU usage
        end
    end)
end

-- Simple Auto Play
local function simpleAutoPlay()
    while getgenv().config.autoPlay do
        task.wait(5) -- Tăng thời gian chờ để giảm CPU
        
        pcall(function()
            local playerGui = player:WaitForChild("PlayerGui", 2)
            if not playerGui then return end
            
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and string.lower(gui.Text):find("play") then
                    if gui.Visible and gui.Active then
                        local connections = getconnections(gui.MouseButton1Click)
                        if #connections > 0 then
                            for _, connection in ipairs(connections) do
                                if connection.Function then
                                    pcall(connection.Function)
                                    break
                                end
                            end
                        end
                        return
                    end
                end
            end
        end)
    end
end

-- Device Select
local function selectBestDevice()
    local PlayerGui = player:WaitForChild("PlayerGui")
    local DeviceSelect = PlayerGui:WaitForChild("DeviceSelect")
    local Container = DeviceSelect:WaitForChild("Container")
    
    local devicePriority = {"Phone", "Computer", "Tablet"}
    
    for _, deviceName in ipairs(devicePriority) do
        local frame = Container:FindFirstChild(deviceName)
        if frame then
            local btn = frame:FindFirstChild("Button")
            if btn and btn.Visible and btn.Active then
                task.wait(0.5)
                for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
                    if c.Function then
                        c.Function()
                        return
                    end
                end
            end
        end
    end
end

-- Auto Open Box (Optimized)
local function setupAutoOpenBox()
    if getgenv().modefarm ~= "Crate" then return end
    
    repeat task.wait(2) until game:IsLoaded()
    repeat task.wait(2) until game:GetService("Players").LocalPlayer:GetAttribute("ClientLoaded")

    local function openBox(resource)
        pcall(function()
            local EventInfoService = require(game:GetService("ReplicatedStorage"):WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
            local Sync = require(game:GetService("ReplicatedStorage"):WaitForChild("Database"):WaitForChild("Sync"))
            local ProfileData = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ProfileData"))

            local eventData = EventInfoService:GetCurrentEvent()
            local eventRemote = EventInfoService:GetEventRemotes()
            local mysteryBox = eventData.MysteryBox.Name

            local cost = Sync.Shop.Weapons[mysteryBox].Price[resource] or 0
            local owned = ProfileData.Materials.Owned[resource] or 0
            
            if owned >= cost and cost > 0 then
                game:GetService("ReplicatedStorage").Remotes.Shop.OpenCrate:InvokeServer(mysteryBox, "MysteryBox", resource)
                task.wait(1)
            end
        end)
    end

    while getgenv().config.autoOpenBox do
        local eventData = pcall(function()
            return require(game:GetService("ReplicatedStorage"):WaitForChild("SharedServices"):WaitForChild("EventInfoService")):GetCurrentEvent()
        end)
        
        if eventData then
            openBox(eventData.Currency)
            openBox(eventData.KeyName)
        end
        
        task.wait(5) -- Giảm tần suất check
    end
end

-- Webhook
local function sendWebhook()
    if not getgenv().config.webhookEnabled then return end
    
    local GameName = "Unknown Game"
    pcall(function()
        GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        GameName = GameName:gsub("%b[]", ""):gsub("^%s*(.-)%s*$", "%1")
    end)

    local data = {
        username = "Kissan Hub",
        content = "Exe\nPlayer: **"..player.Name.."**\nGame: **"..GameName.."**\nPlaceId: "..game.PlaceId.."\nMode: **"..getgenv().modefarm.."**\nTime: "..os.date("%d/%m/%Y %H:%M:%S")
    }
    
    local request = http_request or request or syn and syn.request
    if request then
        pcall(function()
            request({
                Url = "https://discord.com/api/webhooks/1439594999716118538/l1Ng9UrUDUV7xTbNFZ48RGkMDyzYqXb9Wtlg4DU4VTiFnPNOgULrq4pCRdVUfrGMR0So",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(data)
            })
        end)
    end
end

-- Farming System (Optimized)
local function initializeCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    -- Anti-collision
    RunService.Stepped:Connect(function()
        if getgenv().config.autoFarm and character then
            for _, v in ipairs(character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)
end

local function getCandyContainer()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") then
            return obj.CoinContainer
        end
    end
    return nil
end

local function getNearestCandy()
    if not getgenv().config.autoFarm or not character then return nil end
    
    local candyContainer = getCandyContainer()
    if not candyContainer then return nil end
    
    local closest, dist = nil, math.huge
    local myPos = rootPart.Position
    
    for _, candy in ipairs(candyContainer:GetChildren()) do
        if candy:IsA("BasePart") then
            local candyVisual = candy:FindFirstChild("CoinVisual")
            if candyVisual and not candyVisual:GetAttribute("Collected") then
                local d = (myPos - candy.Position).Magnitude
                if d < dist and d < 500 then
                    closest = candy
                    dist = d
                end
            end
        end
    end
    
    return closest
end

local function teleportToCandy(targetCandy)
    if not targetCandy or not getgenv().config.autoFarm or not character then return false end
    
    local candyVisual = targetCandy:FindFirstChild("CoinVisual")
    if not candyVisual or candyVisual:GetAttribute("Collected") then return false end
    
    pcall(function() humanoid:ChangeState(11) end)
    
    local distance = (rootPart.Position - targetCandy.Position).Magnitude
    if distance > 500 then return false end
    
    local travelTime = math.max(0.05, distance / getgenv().config.flySpeed)
    local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), 
        {CFrame = CFrame.new(targetCandy.Position + Vector3.new(0, 2, 0))})
    
    tween:Play()
    
    local startTime = tick()
    while tick() - startTime < travelTime + 0.1 do
        if not getgenv().config.autoFarm or not candyVisual or candyVisual:GetAttribute("Collected") then
            tween:Cancel()
            return false
        end
        task.wait()
    end
    
    return true
end

local function startFarming()
    farming = true
    collected = 0
    startTime = tick()
    
    task.spawn(function()
        while farming and getgenv().config.autoFarm do
            local targetCandy = getNearestCandy()
            if targetCandy then
                local success = teleportToCandy(targetCandy)
                if success then
                    collected = collected + 1
                    lastCollectionTime = tick()
                    task.wait(0.1)
                else
                    task.wait(0.2)
                end
            else
                task.wait(0.5) -- Tăng thời gian chờ khi không có candy
            end
        end
    end)
end

-- Auto Teleport System
local function performTeleport()
    if isOnCooldown or not getgenv().config.autoTeleport then return end
    
    pcall(function()
        local ExtrasRemote = game:GetService("ReplicatedStorage").Remotes.Extras.RequestTeleport
        local args = {"Disguises"}
        ExtrasRemote:InvokeServer(unpack(args))
        isOnCooldown = true
        task.delay(60, function() isOnCooldown = false end)
    end)
end

local function autoTeleportHandler()
    while getgenv().config.autoTeleport do
        task.wait(10) -- Giảm tần suất check
        
        local timeSinceLastCollection = tick() - lastCollectionTime
        if timeSinceLastCollection >= getgenv().config.teleportCooldown and not isOnCooldown then
            local hasCollectedRecently = false
            
            -- Thử collect candy trước
            for i = 1, 3 do -- Giảm số lần thử
                local targetCandy = getNearestCandy()
                if targetCandy then
                    local success = teleportToCandy(targetCandy)
                    if success then
                        collected = collected + 1
                        lastCollectionTime = tick()
                        hasCollectedRecently = true
                        break
                    end
                end
                task.wait(1)
            end
            
            if not hasCollectedRecently then
                performTeleport()
            end
        end
    end
end

-- Battle Pass System
local function setupBattlePass()
    if not getgenv().config.buyBattlePass then return end
    
    task.spawn(function()
        while task.wait(5) do -- Tăng thời gian chờ
            pcall(function()
                local EventInfoService = require(game:GetService("ReplicatedStorage").SharedServices.EventInfoService)
                local ProfileData = require(game:GetService("ReplicatedStorage").Modules.ProfileData)
                
                local eventRemote = EventInfoService:GetEventRemotes()
                local eventData = EventInfoService:GetCurrentEvent()
                local battlepassData = EventInfoService:GetBattlePass()
                
                if not ProfileData or not eventData or not battlepassData then return end
                
                local profileBP = ProfileData[eventData.Title]
                if not profileBP then return end

                -- Buy tiers
                if profileBP.CurrentTier < battlepassData.TotalTiers then
                    local coins = ProfileData.Materials.Owned[eventData.Currency] or 0
                    if coins >= battlepassData.TierCost then
                        eventRemote.BuyTiers:FireServer(1)
                    end
                end

                -- Claim rewards
                for tier, _ in pairs(battlepassData.Rewards) do
                    local tierNum = tonumber(tier)
                    if tierNum and profileBP.CurrentTier >= tierNum and not profileBP.ClaimedRewards[tier] then
                        eventRemote.ClaimBattlePassReward:FireServer(tierNum)
                    end
                end
            end)
        end
    end)
end

-- Anti-AFK
local function setupAntiAFK()
    if getgenv().config.antiAFK then
        player.Idled:Connect(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end
end

-- Initialize System
local function initialize()
    -- Khởi tạo UI
    local labels = createOptimizedUI()
    createDataUpdater(labels)
    
    -- Khởi tạo character
    player.CharacterAdded:Connect(initializeCharacter)
    initializeCharacter()
    
    -- Khởi động các hệ thống
    setupAntiAFK()
    sendWebhook()
    selectBestDevice()
    
    task.spawn(simpleAutoPlay)
    task.spawn(setupAutoOpenBox)
    task.spawn(autoTeleportHandler)
    task.spawn(setupBattlePass)
    
    -- Bắt đầu farm sau 3 giây
    task.delay(3, function()
        if getgenv().config.autoFarm then
            startFarming()
        end
    end)
end

-- Start
initialize()
