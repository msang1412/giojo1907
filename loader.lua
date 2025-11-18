local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

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

-- Optimized: Reduced frequency and simplified logic
local function simpleAutoPlay()
    local lastCheck = 0
    local checkInterval = 5 -- Increased from 3 to 5 seconds
    
    while getgenv().config.autoPlay do
        local currentTime = tick()
        if currentTime - lastCheck >= checkInterval then
            lastCheck = currentTime
            
            local success, result = pcall(function()
                local playerGui = player:WaitForChild("PlayerGui", 5)
                if not playerGui then return end
                
                -- Cache descendants to avoid multiple calls
                local descendants = playerGui:GetDescendants()
                for _, gui in pairs(descendants) do
                    if gui:IsA("TextButton") and string.lower(gui.Text):find("play") then
                        if gui.Visible and gui.Active then
                            local clicked = false
                            
                            local connections = getconnections(gui.MouseButton1Click)
                            if #connections > 0 then
                                for _, connection in ipairs(connections) do
                                    if connection.Function then
                                        pcall(connection.Function)
                                        clicked = true
                                        break -- Only fire once
                                    end
                                end
                            end
                            
                            if not clicked then
                                pcall(function()
                                    gui:FireEvent("MouseButton1Click")
                                    clicked = true
                                end)
                            end
                            
                            return true -- Found and clicked, exit early
                        end
                    end
                end
                return false
            end)
        end
        task.wait(1) -- Reduced CPU usage
    end
end

task.wait(5)
task.spawn(simpleAutoPlay)

local function WaitForChildPath(parent, path)
    local obj = parent
    for _, name in ipairs(path) do
        obj = obj:WaitForChild(name, 5)
        if not obj then
            return nil
        end
    end
    return obj
end

-- UI Creation
local HopGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local CandiesLabel = Instance.new("TextLabel")
local TierLabel = Instance.new("TextLabel")
local TimeLabel = Instance.new("TextLabel")
local ModeLabel = Instance.new("TextLabel")

HopGui.Name = "check"
HopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HopGui.IgnoreGuiInset = true
HopGui.Parent = game:GetService("CoreGui")
HopGui.Enabled = true
HopGui.ResetOnSpawn = false

Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.Size = UDim2.new(1, 0, 1, 0)
Frame.Active = false
Frame.Selectable = false
Frame.ZIndex = 1
Frame.Parent = HopGui

Title.Font = Enum.Font.GothamBold
Title.Text = "Kissan Hub"
Title.TextColor3 = Color3.fromRGB(200, 210, 255)
Title.TextSize = 70
Title.AnchorPoint = Vector2.new(0.5, 0.5)
Title.Position = UDim2.new(0.5, 0, 0.5, -40)
Title.BackgroundTransparency = 1
Title.TextTransparency = 1
Title.ZIndex = 2
Title.Parent = Frame

ModeLabel.Font = Enum.Font.GothamBold
ModeLabel.Text = "Mode: " .. getgenv().modefarm
ModeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeLabel.TextSize = 24
ModeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
ModeLabel.Position = UDim2.new(0.5, 0, 0.5, -5)
ModeLabel.BackgroundTransparency = 1
ModeLabel.TextTransparency = 1
ModeLabel.ZIndex = 2
ModeLabel.Parent = Frame

CandiesLabel.Font = Enum.Font.Gotham
CandiesLabel.Text = "Total Candies: Loading..."
CandiesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CandiesLabel.TextSize = 22
CandiesLabel.AnchorPoint = Vector2.new(0.5, 0.5)
CandiesLabel.Position = UDim2.new(0.5, 0, 0.5, 20)
CandiesLabel.BackgroundTransparency = 1
CandiesLabel.TextTransparency = 1
CandiesLabel.ZIndex = 2
CandiesLabel.Parent = Frame

TierLabel.Font = Enum.Font.Gotham
TierLabel.Text = "Tier: Loading..."
TierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TierLabel.TextSize = 22
TierLabel.AnchorPoint = Vector2.new(0.5, 0.5)
TierLabel.Position = UDim2.new(0.5, 0, 0.5, 45)
TierLabel.BackgroundTransparency = 1
TierLabel.TextTransparency = 1
TierLabel.ZIndex = 2
TierLabel.Parent = Frame

TimeLabel.Font = Enum.Font.Gotham
TimeLabel.Text = "Client Time Elapsed: 0h:0m:0s"
TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeLabel.TextSize = 22
TimeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
TimeLabel.Position = UDim2.new(0.5, 0, 0.5, 70)
TimeLabel.BackgroundTransparency = 1
TimeLabel.TextTransparency = 1
TimeLabel.ZIndex = 2
TimeLabel.Parent = Frame

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

ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
end)
ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

function fadeInUI()
    Frame.Visible = true
    Blur.Enabled = true
    TweenService:Create(Blur, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Size = 45}):Play()
    for _, label in ipairs({Title, ModeLabel, CandiesLabel, TierLabel, TimeLabel}) do
        label.Visible = true
        TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
    end
end

function fadeOutUI()
    Blur.Enabled = false
    Blur.Size = 0
    Frame.Visible = false
    for _, label in ipairs({Title, ModeLabel, CandiesLabel, TierLabel, TimeLabel}) do
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

-- Optimized: Combined update loops and reduced frequency
task.spawn(function()
    local lastUpdate = 0
    local updateInterval = 2 -- Update every 2 seconds instead of 1
    
    while true do
        local currentTime = tick()
        if currentTime - lastUpdate >= updateInterval and Frame.Visible then
            lastUpdate = currentTime
            
            -- Combined candies and tier updates
            pcall(function()
                -- Candies update
                local profileData = game:GetService("ReplicatedStorage").Remotes.Inventory.GetProfileData:InvokeServer()
                if profileData and profileData.Materials and profileData.Materials.Owned then
                    local currentCandies = profileData.Materials.Owned.Candies2025 or 0
                    CandiesLabel.Text = "Total Candies: " .. tostring(currentCandies)
                end
                
                -- Tier update
                local tierTextLabel = WaitForChildPath(player.PlayerGui, {
                    "CrossPlatform",
                    "CurrentEventFrame",
                    "Container",
                    "EventFrames",
                    "BattlePass",
                    "Info",
                    "YourTier",
                    "TextLabel"
                })
                if tierTextLabel and tierTextLabel.Text then
                    local text = tierTextLabel.Text
                    local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
                    if current and max then
                        TierLabel.Text = "Tier: " .. current .. " / " .. max
                    end
                end
            end)
        end
        task.wait(0.5) -- Reduced from 1 second
    end
end)

-- Optimized: Time counter with less frequent updates
local hours, minutes, seconds = 0, 0, 0
task.spawn(function()
    local lastTimeUpdate = 0
    local timeUpdateInterval = 1 -- Keep 1 second for time but optimize rendering
    
    while true do
        task.wait(timeUpdateInterval)
        seconds = seconds + 1
        if seconds >= 60 then
            seconds = 0
            minutes = minutes + 1
        end
        if minutes >= 60 then
            minutes = 0
            hours = hours + 1
        end
        
        -- Only update text if UI is visible
        if Frame.Visible then
            TimeLabel.Text = "Client Time Elapsed: " .. hours .. "h:" .. minutes .. "m:" .. seconds .. "s"
        end
    end
end)

fadeInUI()

-- Optimized: Auto open box with better resource management
local function setupAutoOpenBox()
    if getgenv().modefarm ~= "Crate" then return end
    
    repeat task.wait() until game:IsLoaded()
    repeat task.wait() until game:GetService("Players").LocalPlayer:GetAttribute("ClientLoaded")

    local EventInfoService = require(game:GetService("ReplicatedStorage"):WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
    local Sync = require(game:GetService("ReplicatedStorage"):WaitForChild("Database"):WaitForChild("Sync"))
    local ProfileData = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ProfileData"))

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
            return game:GetService("HttpService"):JSONDecode(response.Body).data[1].imageUrl
        end)
        if success then return result end
        return nil
    end

    local function openBox(resource)
        if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
            local cost = Sync.Shop.Weapons[mysteryBox].Price[resource] or 0
            local owned = ProfileData.Materials.Owned[resource] or 0
            
            if owned >= cost and cost > 0 then
                local result = game:GetService("ReplicatedStorage").Remotes.Shop.OpenCrate:InvokeServer(mysteryBox, "MysteryBox", resource)
                
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
                            { name = "Username", value = "||" .. game.Players.LocalPlayer.Name .. "||", inline = true },
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
                            Body = game:GetService("HttpService"):JSONEncode(payload)
                        })
                    end)
                    
                    game:GetService("ReplicatedStorage").Remotes.Shop.BoxController:Fire(mysteryBox, result)
                    return true
                end
            else
                return false
            end
        end
        return false
    end

    local function startAutoOpen()
        local lastOpenAttempt = 0
        local openInterval = 5 -- Increased from 3 to 5 seconds
        
        while getgenv().config.autoOpenBox do
            local currentTime = tick()
            if currentTime - lastOpenAttempt >= openInterval then
                lastOpenAttempt = currentTime
                
                local coinOpened = openBox(currency)
                local keyOpened = openBox(keyName)
                
                if not coinOpened and not keyOpened then
                    task.wait(15) -- Increased from 10 to 15 seconds when no resources
                end
            else
                task.wait(1)
            end
        end
    end

    task.spawn(startAutoOpen)
end

task.spawn(setupAutoOpenBox)

-- Optimized: Device selection with better waiting
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DeviceSelect = PlayerGui:WaitForChild("DeviceSelect")
local Container = DeviceSelect:WaitForChild("Container")

local function getBestDevice()
    local devicePriority = {"Phone"}

    for _, deviceName in ipairs(devicePriority) do
        local frame = Container:FindFirstChild(deviceName)
        if frame then
            local btn = frame:FindFirstChild("Button")
            if btn and btn.Visible and btn.Active then
                return deviceName, btn
            end
        end
    end

    for _, frame in ipairs(Container:GetChildren()) do
        if frame:IsA("Frame") then
            local btn = frame:FindFirstChild("Button")
            if btn and btn.Visible and btn.Active then
                return frame.Name, btn
            end
        end
    end

    return nil, nil
end

task.spawn(function()
    local maxWaitTime = 10 -- Maximum wait time for device selection
    local startTime = tick()
    
    while tick() - startTime < maxWaitTime do
        local bestDevice, bestButton = getBestDevice()
        if bestDevice and bestButton then
            task.wait(0.5)
            for _, c in ipairs(getconnections(bestButton.MouseButton1Click)) do
                if c.Function then
                    pcall(c.Function)
                    break
                end
            end
            break
        end
        task.wait(0.5)
    end
end)

-- Webhook (unchanged but with error handling)
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local WebhookURL = "https://discord.com/api/webhooks/1439594999716118538/l1Ng9UrUDUV7xTbNFZ48RGkMDyzYqXb9Wtlg4DU4VTiFnPNOgULrq4pCRdVUfrGMR0So"

local GameName = "Unknown Game"
pcall(function()
    GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    GameName = GameName:gsub("%b[]", "")
    GameName = GameName:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c) 
        return c:match("[%w%s%p]") and c or "" 
    end)
    GameName = GameName:gsub("^%s*(.-)%s*$", "%1")
end)

local function SendWebhook()
    if not getgenv().config.webhookEnabled then return end
    local data = {
        username = "Kissan Hub",
        content = "Exe\nPlayer: **"..LocalPlayer.Name.."**\nGame: **"..GameName.."**\nPlaceId: "..game.PlaceId.."\nMode: **"..getgenv().modefarm.."**\nTime: "..os.date("%d/%m/%Y %H:%M:%S")
    }
    local request = http_request or request or syn and syn.request or fluxus and fluxus.request
    if request then
        pcall(function()
            request({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
    end
end
SendWebhook()

-- Optimized: Main farming logic with better performance
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local isActive = getgenv().config.autoFarm
local flySpeed = getgenv().config.flySpeed
local collected = 0
local startTime = tick()
local antiAFK = getgenv().config.antiAFK
local farming = getgenv().config.autoFarm

local ExtrasRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("RequestTeleport")
local lastCollectionTime = tick()
local isOnCooldown = false
local remainingTime = getgenv().config.teleportCooldown

player.CharacterAdded:Connect(function(char)
    character = char
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    if isActive and not farming then
        task.wait(3)
        startFarming()
    end
end)

local collectSound = Instance.new("Sound", rootPart)
collectSound.SoundId = "rbxassetid://12221967"
collectSound.Volume = 0.7

-- Optimized: Anti-AFK with less frequent checks
if antiAFK then
    player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

-- Optimized: Collision handling with debounce
local lastCollisionCheck = 0
RunService.Stepped:Connect(function()
    if isActive and character and tick() - lastCollisionCheck > 0.1 then
        lastCollisionCheck = tick()
        for _, v in ipairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

local function updateCollectionTime()
    lastCollectionTime = tick()
    remainingTime = getgenv().config.teleportCooldown
end

local function performTeleport()
    if isOnCooldown or not getgenv().config.autoTeleport then return end
    local args = {"Disguises"}
    local success, result = pcall(function()
        return ExtrasRemote:InvokeServer(unpack(args))
    end)
    if success then
        isOnCooldown = true
        task.delay(60, function()
            isOnCooldown = false
        end)
    end
end

local function GetCandyContainer()
    -- Cache the container to avoid multiple searches
    if not GetCandyContainer.cachedContainer then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:FindFirstChild("CoinContainer") then
                GetCandyContainer.cachedContainer = obj.CoinContainer
                break
            end
        end
    end
    return GetCandyContainer.cachedContainer
end

local function getNearestCandy()
    if not isActive or not character then return nil end
    local candyContainer = GetCandyContainer()
    if not candyContainer then return nil end
    
    local closest, dist = nil, math.huge
    local myPos = rootPart.Position
    
    -- Limit the number of candies checked
    local candies = candyContainer:GetChildren()
    local maxChecks = math.min(50, #candies) -- Check max 50 candies
    
    for i = 1, maxChecks do
        local candy = candies[i]
        if candy and candy:IsA("BasePart") then
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
    if not targetCandy or not isActive or not character then return false end
    local candyVisual = targetCandy:FindFirstChild("CoinVisual")
    if not candyVisual or candyVisual:GetAttribute("Collected") then return false end
    
    pcall(function() humanoid:ChangeState(11) end)
    local distance = (rootPart.Position - targetCandy.Position).Magnitude
    if distance > 500 then return false end
    
    local travelTime = math.max(0.05, distance / flySpeed)
    local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetCandy.Position + Vector3.new(0, 2, 0))})
    tween:Play()
    
    local startTime = tick()
    while tick() - startTime < travelTime + 0.1 do
        if not isActive or not candyVisual or candyVisual:GetAttribute("Collected") or not character then
            tween:Cancel()
            return false
        end
        RunService.Heartbeat:Wait()
    end
    return true
end

-- Optimized: Teleport cooldown with better timing
task.spawn(function()
    local lastTeleportCheck = 0
    local teleportCheckInterval = 5 -- Check every 5 seconds instead of 10
    
    while getgenv().config.autoTeleport do
        local currentTime = tick()
        if currentTime - lastTeleportCheck >= teleportCheckInterval then
            lastTeleportCheck = currentTime
            
            local timeSinceLastCollection = currentTime - lastCollectionTime
            remainingTime = math.max(0, getgenv().config.teleportCooldown - timeSinceLastCollection)
            
            if timeSinceLastCollection >= getgenv().config.teleportCooldown and not isOnCooldown then
                local hasCollectedRecently = false
                local checkStartTime = tick()
                
                while tick() - checkStartTime < 10 do -- Reduced from 15 to 10 seconds
                    local targetCandy = getNearestCandy()
                    if targetCandy then
                        local success = teleportToCandy(targetCandy)
                        if success then
                            collected = collected + 1
                            pcall(function() collectSound:Play() end)
                            updateCollectionTime()
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
        task.wait(1)
    end
end)

function startFarming()
    farming = true
    collected = 0
    startTime = tick()
    
    task.spawn(function()
        local lastFarmCheck = 0
        local farmCheckInterval = 0.1 -- Reduced from continuous checking
        
        while farming and isActive do
            local currentTime = tick()
            if currentTime - lastFarmCheck >= farmCheckInterval then
                lastFarmCheck = currentTime
                
                local targetCandy = getNearestCandy()
                if targetCandy then
                    local success = teleportToCandy(targetCandy)
                    if success then
                        collected = collected + 1
                        pcall(function() collectSound:Play() end)
                        updateCollectionTime()
                    end
                end
            end
            task.wait(0.05) -- Reduced CPU usage
        end
    end)
end

task.spawn(function()
    task.wait(2)
    if getgenv().config.autoFarm then
        startFarming()
    end
end)

-- Optimized: Battle pass with better timing
if getgenv().config.buyBattlePass then
    task.spawn(function()
        local RepStorage = game:GetService("ReplicatedStorage")
        local lastBPCheck = 0
        local BPCheckInterval = 5 -- Check every 5 seconds instead of 2
        
        repeat task.wait(1) until RepStorage:FindFirstChild("SharedServices") and RepStorage:FindFirstChild("Modules")
        
        while true do
            local currentTime = tick()
            if currentTime - lastBPCheck >= BPCheckInterval then
                lastBPCheck = currentTime
                
                pcall(function()
                    local EventInfoService = require(RepStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
                    local ProfileData = require(RepStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
                    
                    local eventRemote = EventInfoService:GetEventRemotes()
                    local eventData = EventInfoService:GetCurrentEvent()
                    local battlepassData = EventInfoService:GetBattlePass()
                    
                    if not ProfileData or not eventData or not battlepassData then return end
                    
                    local profileBP = ProfileData[eventData.Title]
                    if not profileBP then return end

                    if profileBP.CurrentTier < battlepassData.TotalTiers then
                        local coins = ProfileData.Materials.Owned[eventData.Currency] or 0
                        if coins >= battlepassData.TierCost then
                            eventRemote.BuyTiers:FireServer(1)
                        end
                    end

                    for tier, _ in pairs(battlepassData.Rewards) do
                        local tierNum = tonumber(tier)
                        if tierNum and profileBP.CurrentTier >= tierNum and not profileBP.ClaimedRewards[tier] then
                            eventRemote.ClaimBattlePassReward:FireServer(tierNum)
                        end
                    end

                    local finalCost = battlepassData.FinalRewardCost or math.huge
                    if (ProfileData.Materials.Owned[eventData.Currency] or 0) >= finalCost then
                        eventRemote.BuyFinalReward:FireServer()
                    end
                end)
            end
            task.wait(1)
        end
    end)
end
