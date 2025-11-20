local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

repeat task.wait() until game:IsLoaded() and player

-- setting
getgenv().modefarm = getgenv().modefarm or "Normal"

-- config
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

-- CPU Optimization Variables
local OPTIMIZATION = {
    TASK_DELAY = {
        CANDY_CHECK = 0.3,
        UI_UPDATE = 1,
        BATTLE_PASS = 3,
        AUTO_PLAY = 3,
        CANDY_COLLECTION = 0.1
    },
    DISTANCE_CHECK = 500,
    MAX_CANDY_CHECKS_PER_FRAME = 5
}

-- Cache frequently used objects
local cachedObjects = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Lighting = game:GetService("Lighting"),
    HttpService = game:GetService("HttpService")
}

-- Optimized UI Creation
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
    Frame.BackgroundTransparency = 0
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.Active = false
    Frame.Selectable = false
    Frame.ZIndex = 1
    Frame.Parent = HopGui

    local labels = {}
    local labelConfigs = {
        {Name = "Title", Text = "Kissan Hub", Size = 70, Position = -40},
        {Name = "ModeLabel", Text = "Mode: " .. getgenv().modefarm, Size = 24, Position = -5},
        {Name = "CandiesLabel", Text = "Total Candies: Loading...", Size = 22, Position = 20},
        {Name = "TierLabel", Text = "Tier: Loading...", Size = 22, Position = 45},
        {Name = "TimeLabel", Text = "Client Time Elapsed: 0h:0m:0s", Size = 22, Position = 70}
    }

    for _, config in ipairs(labelConfigs) do
        local label = Instance.new("TextLabel")
        label.Font = config.Name == "Title" and Enum.Font.GothamBold or Enum.Font.Gotham
        label.Text = config.Text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = config.Size
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.Position = UDim2.new(0.5, 0, 0.5, config.Position)
        label.BackgroundTransparency = 1
        label.TextTransparency = 1
        label.ZIndex = 2
        label.Parent = Frame
        labels[config.Name] = label
    end

    local Blur = Instance.new("BlurEffect")
    Blur.Size = 0
    Blur.Enabled = false
    Blur.Parent = cachedObjects.Lighting

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

    return {
        Gui = HopGui,
        Frame = Frame,
        Labels = labels,
        Blur = Blur,
        ToggleButton = ToggleButton
    }
end

local ui = createOptimizedUI()

-- Optimized UI Animation Functions
local function fadeInUI()
    ui.Frame.Visible = true
    ui.Blur.Enabled = true
    TweenService:Create(ui.Blur, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Size = 45}):Play()
    for _, label in pairs(ui.Labels) do
        label.Visible = true
        TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
    end
end

local function fadeOutUI()
    ui.Blur.Enabled = false
    ui.Blur.Size = 0
    ui.Frame.Visible = false
    for _, label in pairs(ui.Labels) do
        label.Visible = false
        label.TextTransparency = 1
    end
end

ui.ToggleButton.MouseButton1Click:Connect(function()
    if ui.Frame.Visible then
        fadeOutUI()
    else
        fadeInUI()
    end
end)

-- Optimized Data Updates
local function createDataUpdaters()
    local hours, minutes, seconds = 0, 0, 0
    
    -- Time updater
    task.spawn(function()
        while true do
            task.wait(1)
            seconds += 1
            if seconds >= 60 then
                seconds = 0
                minutes += 1
            end
            if minutes >= 60 then
                minutes = 0
                hours += 1
            end
            if ui.Frame.Visible then
                ui.Labels.TimeLabel.Text = string.format("Client Time Elapsed: %dh:%dm:%ds", hours, minutes, seconds)
            end
        end
    end)

    -- Candies updater
    task.spawn(function()
        while true do
            local success = pcall(function()
                local profileData = cachedObjects.ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer()
                if profileData and profileData.Materials and profileData.Materials.Owned then
                    local currentCandies = profileData.Materials.Owned.Candies2025 or 0
                    if ui.Frame.Visible then
                        ui.Labels.CandiesLabel.Text = "Total Candies: " .. tostring(currentCandies)
                    end
                end
            end)
            if not success and ui.Frame.Visible then
                ui.Labels.CandiesLabel.Text = "Total Candies: Error"
            end
            task.wait(OPTIMIZATION.TASK_DELAY.UI_UPDATE)
        end
    end)

    -- Tier updater
    task.spawn(function()
        local function WaitForChildPath(parent, path)
            local obj = parent
            for _, name in ipairs(path) do
                obj = obj:WaitForChild(name, 5)
                if not obj then return nil end
            end
            return obj
        end

        while true do
            local success = pcall(function()
                local tierTextLabel = WaitForChildPath(player.PlayerGui, {
                    "CrossPlatform", "CurrentEventFrame", "Container", "EventFrames", 
                    "BattlePass", "Info", "YourTier", "TextLabel"
                })
                if tierTextLabel and tierTextLabel.Text then
                    local text = tierTextLabel.Text
                    local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
                    if current and max and ui.Frame.Visible then
                        ui.Labels.TierLabel.Text = string.format("Tier: %s / %s", current, max)
                    end
                end
            end)
            if not success and ui.Frame.Visible then
                ui.Labels.TierLabel.Text = "Tier: Error"
            end
            task.wait(OPTIMIZATION.TASK_DELAY.UI_UPDATE)
        end
    end)
end

createDataUpdaters()
fadeInUI()

-- Optimized Auto-Play
local function createOptimizedAutoPlay()
    local function attemptPlayClick()
        local guisToCheck = {player.PlayerGui, game:GetService("CoreGui")}
        
        for _, gui in ipairs(guisToCheck) do
            for _, element in ipairs(gui:GetDescendants()) do
                if element:IsA("TextButton") and string.lower(element.Text):find("play") then
                    if element.Visible and element.Active then
                        -- Try multiple click methods
                        local connections = getconnections(element.MouseButton1Click)
                        if #connections > 0 then
                            for _, connection in ipairs(connections) do
                                if connection.Function then
                                    pcall(connection.Function)
                                    return true
                                end
                            end
                        end
                        
                        -- Fallback methods
                        local success = pcall(function() element:FireEvent("MouseButton1Click") end)
                        if success then return true end
                        
                        if element:FindFirstChildWhichIsA("RemoteEvent") then
                            pcall(function() element:FindFirstChildWhichIsA("RemoteEvent"):FireServer() end)
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    task.spawn(function()
        while getgenv().config.autoPlay do
            task.wait(OPTIMIZATION.TASK_DELAY.AUTO_PLAY)
            pcall(attemptPlayClick)
        end
    end)
end

task.wait(2)
createOptimizedAutoPlay()

-- Optimized Candy Farming System
local function createOptimizedFarmingSystem()
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
    local farmingState = {
        isActive = getgenv().config.autoFarm,
        isFarming = false,
        collected = 0,
        startTime = tick(),
        lastCollectionTime = tick(),
        isOnCooldown = false,
        remainingTime = getgenv().config.teleportCooldown
    }

    -- Cache candy container
    local candyContainer = nil
    local function getCandyContainer()
        if candyContainer and candyContainer.Parent then
            return candyContainer
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:FindFirstChild("CoinContainer") then
                candyContainer = obj.CoinContainer
                return candyContainer
            end
        end
        return nil
    end

    -- Optimized candy collection
    local function getNearestCandy()
        if not farmingState.isActive or not character then return nil end
        
        local container = getCandyContainer()
        if not container then return nil end
        
        local closest, minDist = nil, OPTIMIZATION.DISTANCE_CHECK
        local myPos = rootPart.Position
        local checked = 0
        
        for _, candy in ipairs(container:GetChildren()) do
            if checked >= OPTIMIZATION.MAX_CANDY_CHECKS_PER_FRAME then
                RunService.Heartbeat:Wait()
                checked = 0
            end
            
            if candy:IsA("BasePart") then
                local candyVisual = candy:FindFirstChild("CoinVisual")
                if candyVisual and not candyVisual:GetAttribute("Collected") then
                    local dist = (myPos - candy.Position).Magnitude
                    if dist < minDist then
                        closest = candy
                        minDist = dist
                    end
                end
            end
            checked += 1
        end
        
        return closest
    end

    local function teleportToCandy(targetCandy)
        if not targetCandy or not farmingState.isActive or not character then return false end
        
        local candyVisual = targetCandy:FindFirstChild("CoinVisual")
        if not candyVisual or candyVisual:GetAttribute("Collected") then return false end
        
        pcall(function() humanoid:ChangeState(11) end)
        
        local distance = (rootPart.Position - targetCandy.Position).Magnitude
        if distance > OPTIMIZATION.DISTANCE_CHECK then return false end
        
        local travelTime = math.max(0.05, distance / getgenv().config.flySpeed)
        local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(targetCandy.Position + Vector3.new(0, 2, 0))
        })
        
        tween:Play()
        local startTime = tick()
        
        while tick() - startTime < travelTime + 0.1 do
            if not farmingState.isActive or not candyVisual or candyVisual:GetAttribute("Collected") or not character then
                tween:Cancel()
                return false
            end
            RunService.Heartbeat:Wait()
        end
        
        return true
    end

    function startFarming()
        if farmingState.isFarming then return end
        
        farmingState.isFarming = true
        farmingState.collected = 0
        farmingState.startTime = tick()
        
        task.spawn(function()
            while farmingState.isFarming and farmingState.isActive do
                local targetCandy = getNearestCandy()
                if targetCandy then
                    local success = teleportToCandy(targetCandy)
                    if success then
                        farmingState.collected += 1
                        farmingState.lastCollectionTime = tick()
                        task.wait(OPTIMIZATION.TASK_DELAY.CANDY_COLLECTION)
                    else
                        task.wait(OPTIMIZATION.TASK_DELAY.CANDY_CHECK)
                    end
                else
                    task.wait(OPTIMIZATION.TASK_DELAY.CANDY_CHECK)
                end
            end
        end)
    end

    -- Character event handling
    player.CharacterAdded:Connect(function(char)
        character = char
        rootPart = char:WaitForChild("HumanoidRootPart")
        humanoid = char:WaitForChild("Humanoid")
        
        if farmingState.isActive and not farmingState.isFarming then
            task.wait(3)
            startFarming()
        end
    end)

    return {
        startFarming = startFarming,
        stopFarming = function() farmingState.isFarming = false end,
        getState = function() return farmingState end
    }
end

local farmingSystem = createOptimizedFarmingSystem()

-- Initialize farming after delay
task.spawn(function()
    task.wait(3)
    if getgenv().config.autoFarm then
        farmingSystem.startFarming()
    end
end)

-- Anti-AFK Optimization
if getgenv().config.antiAFK then
    player.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

-- Optimized Battle Pass System
if getgenv().config.buyBattlePass then
    task.spawn(function()
        repeat task.wait(1) until cachedObjects.ReplicatedStorage:FindFirstChild("SharedServices")
        
        while task.wait(OPTIMIZATION.TASK_DELAY.BATTLE_PASS) do
            pcall(function()
                local EventInfoService = require(cachedObjects.ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
                local ProfileData = require(cachedObjects.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
                
                local eventRemote = EventInfoService:GetEventRemotes()
                local eventData = EventInfoService:GetCurrentEvent()
                local battlepassData = EventInfoService:GetBattlePass()
                
                if not ProfileData or not eventData or not battlepassData then return end
                
                local profileBP = ProfileData[eventData.Title]
                if not profileBP then return end

                -- Buy tiers if possible
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

                -- Buy final reward
                local finalCost = battlepassData.FinalRewardCost or math.huge
                if (ProfileData.Materials.Owned[eventData.Currency] or 0) >= finalCost then
                    eventRemote.BuyFinalReward:FireServer()
                end
            end)
        end
    end)
end

-- Collision optimization
RunService.Stepped:Connect(function()
    if getgenv().config.autoFarm and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)
