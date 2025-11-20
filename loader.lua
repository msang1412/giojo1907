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
        CANDY_COLLECTION = 0.1,
        TELEPORT_CHECK = 10,
        BOX_OPEN = 3
    },
    DISTANCE_CHECK = 500,
    MAX_CANDY_CHECKS_PER_FRAME = 5
}

-- Cache frequently used objects
local cachedObjects = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Lighting = game:GetService("Lighting"),
    HttpService = game:GetService("HttpService"),
    CoreGui = game:GetService("CoreGui")
}

-- Optimized UI Creation
local function createOptimizedUI()
    local HopGui = Instance.new("ScreenGui")
    HopGui.Name = "check"
    HopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    HopGui.IgnoreGuiInset = true
    HopGui.Parent = cachedObjects.CoreGui
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

    ToggleButton.MouseEnter:Connect(function()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
    end)
    
    ToggleButton.MouseLeave:Connect(function()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

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
        local guisToCheck = {player.PlayerGui, cachedObjects.CoreGui}
        
        for _, gui in ipairs(guisToCheck) do
            local descendants = gui:GetDescendants()
            for i = 1, #descendants do
                local element = descendants[i]
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

    local collectSound = Instance.new("Sound")
    collectSound.SoundId = "rbxassetid://12221967"
    collectSound.Volume = 0.7
    collectSound.Parent = rootPart

    -- Cache candy container
    local candyContainer = nil
    local function getCandyContainer()
        if candyContainer and candyContainer.Parent then
            return candyContainer
        end
        local workspaceChildren = workspace:GetChildren()
        for i = 1, #workspaceChildren do
            local obj = workspaceChildren[i]
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
        local containerChildren = container:GetChildren()
        local checked = 0
        
        for i = 1, #containerChildren do
            if checked >= OPTIMIZATION.MAX_CANDY_CHECKS_PER_FRAME then
                RunService.Heartbeat:Wait()
                checked = 0
            end
            
            local candy = containerChildren[i]
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

    local function performTeleport()
        if farmingState.isOnCooldown or not getgenv().config.autoTeleport then return end
        
        local args = {"Disguises"}
        local success = pcall(function()
            local ExtrasRemote = cachedObjects.ReplicatedStorage.Remotes.Extras.RequestTeleport
            return ExtrasRemote:InvokeServer(unpack(args))
        end)
        
        if success then
            farmingState.isOnCooldown = true
            task.delay(60, function()
                farmingState.isOnCooldown = false
            end)
        end
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
                        pcall(function() collectSound:Play() end)
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

    -- Auto teleport system
    task.spawn(function()
        while getgenv().config.autoTeleport do
            task.wait(OPTIMIZATION.TASK_DELAY.TELEPORT_CHECK)
            local currentTime = tick()
            local timeSinceLastCollection = currentTime - farmingState.lastCollectionTime
            farmingState.remainingTime = math.max(0, getgenv().config.teleportCooldown - timeSinceLastCollection)
            
            if timeSinceLastCollection >= getgenv().config.teleportCooldown and not farmingState.isOnCooldown then
                local hasCollectedRecently = false
                local checkStartTime = tick()
                
                while tick() - checkStartTime < 15 do
                    local targetCandy = getNearestCandy()
                    if targetCandy then
                        local success = teleportToCandy(targetCandy)
                        if success then
                            farmingState.collected += 1
                            pcall(function() collectSound:Play() end)
                            farmingState.lastCollectionTime = tick()
                            hasCollectedRecently = true
                            break
                        else
                            break
                        end
                    else
                        task.wait(1)
                    end
                end
                
                if not hasCollectedRecently then
                    performTeleport()
                end
            end
        end
    end)

    -- Character event handling
    player.CharacterAdded:Connect(function(char)
        character = char
        rootPart = char:WaitForChild("HumanoidRootPart")
        humanoid = char:WaitForChild("Humanoid")
        collectSound.Parent = rootPart
        
        if farmingState.isActive and not farmingState.isFarming then
            task.wait(3)
            startFarming()
        end
    end)

    -- Collision optimization for current character
    RunService.Stepped:Connect(function()
        if farmingState.isActive and character then
            local descendants = character:GetDescendants()
            for i = 1, #descendants do
                local v = descendants[i]
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
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

-- Optimized Anti-AFK
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

-- Optimized Auto Open Box System
if getgenv().config.autoOpenBox then
    task.spawn(function()
        repeat task.wait() until game:IsLoaded()
        repeat task.wait() until player:GetAttribute("ClientLoaded")

        local EventInfoService = require(cachedObjects.ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
        local Sync = require(cachedObjects.ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
        local ProfileData = require(cachedObjects.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))

        local eventData = EventInfoService:GetCurrentEvent()
        local eventRemote = EventInfoService:GetEventRemotes()
        local currency = eventData.Currency
        local keyName = eventData.KeyName
        local mysteryBox = eventData.MysteryBox.Name

        local request = request or http_request or syn.request
        if not request then return end

        local function getimg(asset_id)
            local success, result = pcall(function()
                local response = request({
                    Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. asset_id .. "&size=420x420&format=Png&isCircular=false",
                    Method = "GET",
                })
                return cachedObjects.HttpService:JSONDecode(response.Body).data[1].imageUrl
            end)
            return success and result or nil
        end

        local function openBox(resource)
            if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
                local cost = Sync.Shop.Weapons[mysteryBox].Price[resource] or 0
                local owned = ProfileData.Materials.Owned[resource] or 0
                
                if owned >= cost and cost > 0 then
                    local result = cachedObjects.ReplicatedStorage.Remotes.Shop.OpenCrate:InvokeServer(mysteryBox, "MysteryBox", resource)
                    
                    if result then
                        local itemData = Sync.Weapons[result]
                        local imageUrl = getimg(itemData.ItemID)
                        local color = 0x000000
                        
                        if itemData.Rarity == "Godly" then color = 0xFFD700
                        elseif itemData.Rarity == "Ancient" then color = 0xFF0000
                        elseif itemData.Rarity == "Common" then color = 0x808080
                        end

                        local embed = {
                            title = "Item Unboxed-" .. itemData.Rarity,
                            color = color,
                            fields = {
                                { name = "Username", value = "||" .. player.Name .. "||", inline = true },
                                { name = "Item Name", value = itemData.ItemName, inline = true },
                                { name = "Rarity", value = itemData.Rarity, inline = true },
                                { name = "Year", value = tostring(itemData.Year), inline = true },
                                { name = "Event", value = itemData.Event or "None", inline = true }
                            },
                            footer = { text = "Kissan Hub" },
                            timestamp = DateTime.now():ToIsoDate()
                        }

                        if imageUrl then
                            embed.thumbnail = { url = imageUrl }
                        end

                        local payload = {
                            embeds = {embed},
                            username = "Kissan Notify",
                        }

                        pcall(function()
                            request({
                                Url = "https://discord.com/api/webhooks/1439595003134476388/CkviZTrJ17yCnsaSGCqlNOwxtgKMpuoB7uYQSX0nWigHJAdssE_66jOzjgEMIydPrjmy",
                                Method = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body = cachedObjects.HttpService:JSONEncode(payload)
                            })
                        end)
                        
                        cachedObjects.ReplicatedStorage.Remotes.Shop.BoxController:Fire(mysteryBox, result)
                        return true
                    end
                else
                    return false
                end
            end
            return false
        end

        while getgenv().config.autoOpenBox and task.wait(OPTIMIZATION.TASK_DELAY.BOX_OPEN) do
            local coinOpened = openBox(currency)
            local keyOpened = openBox(keyName)
            
            if not coinOpened and not keyOpened then
                task.wait(10)
            end
        end
    end)
end

-- Device Selection Optimization
task.spawn(function()
    repeat task.wait() until player.PlayerGui:FindFirstChild("DeviceSelect")
    
    local DeviceSelect = player.PlayerGui.DeviceSelect
    local Container = DeviceSelect.Container

    local function getBestDevice()
        local devicePriority = {"Phone"}
        local containerChildren = Container:GetChildren()

        for _, deviceName in ipairs(devicePriority) do
            local frame = Container:FindFirstChild(deviceName)
            if frame then
                local btn = frame:FindFirstChild("Button")
                if btn and btn.Visible and btn.Active then
                    return deviceName, btn
                end
            end
        end

        for i = 1, #containerChildren do
            local frame = containerChildren[i]
            if frame:IsA("Frame") then
                local btn = frame:FindFirstChild("Button")
                if btn and btn.Visible and btn.Active then
                    return frame.Name, btn
                end
            end
        end

        return nil, nil
    end

    local Phone = Container:WaitForChild("Phone")
    repeat task.wait() until Phone:FindFirstChild("Button")

    local bestDevice, bestButton = getBestDevice()

    if bestDevice and bestButton then
        task.wait(0.5)
        local connections = getconnections(bestButton.MouseButton1Click)
        for i = 1, #connections do
            local c = connections[i]
            if c.Function then
                c.Function()
                break
            end
        end
    end
end)

-- Webhook System
local function sendWebhook()
    if not getgenv().config.webhookEnabled then return end
    
    local GameName = "Unknown Game"
    pcall(function()
        local MarketplaceService = game:GetService("MarketplaceService")
        GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        GameName = GameName:gsub("%b[]", ""):gsub("[%z\1-\127\194-\244][\128-\191]*", function(c) 
            return c:match("[%w%s%p]") and c or "" 
        end):gsub("^%s*(.-)%s*$", "%1")
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
                Body = cachedObjects.HttpService:JSONEncode(data)
            })
        end)
    end
end

sendWebhook()

print("Kissan Hub Optimized - CPU Usage Stabilized")
