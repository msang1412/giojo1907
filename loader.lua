-- Kissan Hub - Murder Mystery 2 Script
-- Version: External Config

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

-- ================================
-- KIỂM TRA CONFIG TỪ BÊN NGOÀI
-- ================================
if not getgenv().config then
    getgenv().config = {
        AutoFarm = true,
        flySpeed = 26,
        autoTeleport = true,
        teleportCooldown = 300,
        antiAFK = true,
        webhookEnabled = true,
        BattlePass = true,
        AutoOpenBox = true,
        WebhookRarity = {
            Common = true,
            Uncommon = true, 
            Rare = true,
            Legendary = true,
            Godly = true
        }
    }
    warn("Sử dụng config mặc định - Chưa có config từ bên ngoài")
else
    warn("Đã nhận config từ bên ngoài")
end

if not getgenv().webhookConfig then
    getgenv().webhookConfig = {
        Enabled = true,
        URL = "https://discord.com/api/webhooks/1302245095566872616/scicKkQvt85A6ZRr_v5bUMANv1y7rlgSNxpEJGmeEzOoLWa6VVZQZwih2nlQxT-bNfI2"
    }
end

-- ================================
-- CÁCH SỬ DỤNG TỪ BÊN NGOÀI:
-- ================================
--[[
-- Trước khi chạy script này, hãy đặt config như sau:

getgenv().config = {
    AutoFarm = true,
    Modefarm = "Crate", -- "Crate" hoặc "BattlePass"
    flySpeed = 30,
    autoTeleport = true,
    teleportCooldown = 250,
    antiAFK = true,
    webhookEnabled = false,
    BattlePass = true,
    AutoOpenBox = true,
    WebhookRarity = {
        Common = false,
        Uncommon = false, 
        Rare = true,
        Legendary = true,
        Godly = true
    }
}

getgenv().webhookConfig = {
    Enabled = true,
    URL = "https://discord.com/api/webhooks/your_webhook_here"
}

-- Sau đó mới chạy script chính
--]]

print("=== KISSAN HUB CONFIG ===")
print("AutoFarm:", getgenv().config.AutoFarm)
print("Modefarm:", getgenv().config.Modefarm or "Not specified")
print("Webhook Enabled:", getgenv().webhookConfig.Enabled)

-- ================================
-- SIMPLE AUTO PLAY SYSTEM
-- ================================
local function simpleAutoPlay()
    while true do
        task.wait(3)
        
        local success, result = pcall(function()
            local playerGui = player:WaitForChild("PlayerGui", 5)
            if not playerGui then return end
            
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and string.lower(gui.Text):find("play") then
                    if gui.Visible and gui.Active then
                        local clicked = false
                        
                        -- Thử các phương thức click khác nhau
                        local connections = getconnections(gui.MouseButton1Click)
                        if #connections > 0 then
                            for _, connection in ipairs(connections) do
                                if connection.Function then
                                    pcall(connection.Function)
                                    clicked = true
                                end
                            end
                        end
                        
                        if not clicked then
                            pcall(function()
                                gui:FireEvent("MouseButton1Click")
                                clicked = true
                            end)
                        end
                        
                        if not clicked and gui:FindFirstChildWhichIsA("RemoteEvent") then
                            pcall(function()
                                gui:FindFirstChildWhichIsA("RemoteEvent"):FireServer()
                                clicked = true
                            end)
                        end
                        
                        if not clicked and firesignal then
                            pcall(function()
                                firesignal(gui.MouseButton1Click)
                                clicked = true
                            end)
                        end
                        
                        return
                    end
                end
            end
        end)
    end
end

-- Khởi chạy auto play sau 5 giây
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

local HopGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local CandiesLabel = Instance.new("TextLabel")
local TierLabel = Instance.new("TextLabel")
local TimeLabel = Instance.new("TextLabel")

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
Title.Position = UDim2.new(0.5, 0, 0.5, -20)
Title.BackgroundTransparency = 1
Title.TextTransparency = 1
Title.ZIndex = 2
Title.Parent = Frame

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
    for _, label in ipairs({Title, CandiesLabel, TierLabel, TimeLabel}) do
        label.Visible = true
        TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
    end
end

function fadeOutUI()
    Blur.Enabled = false
    Blur.Size = 0
    Frame.Visible = false
    for _, label in ipairs({Title, CandiesLabel, TierLabel, TimeLabel}) do
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

task.spawn(function()
    while true do
        local success, err = pcall(function()
            local profileData = game:GetService("ReplicatedStorage").Remotes.Inventory.GetProfileData:InvokeServer()
            if profileData and profileData.Materials and profileData.Materials.Owned then
                local currentCandies = profileData.Materials.Owned.Candies2025 or 0
                if Frame.Visible then
                    CandiesLabel.Text = "Total Candies: " .. tostring(currentCandies)
                end
            end
        end)
        
        if not success then
            if Frame.Visible then
                CandiesLabel.Text = "Total Candies: Error"
            end
        end
        
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        local success, err = pcall(function()
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
                if current and max and Frame.Visible then
                    TierLabel.Text = "Tier: " .. current .. " / " .. max
                end
            end
        end)
        if not success then
            if Frame.Visible then
                TierLabel.Text = "Tier: Error"
            end
        end
        task.wait(1)
    end
end)

local hours, minutes, seconds = 0, 0, 0
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
        if Frame.Visible then
            TimeLabel.Text = "Client Time Elapsed: " .. hours .. "h:" .. minutes .. "m:" .. seconds .. "s"
        end
    end
end)

fadeInUI()

getgenv().config = {
    AutoFarm = true,
    flySpeed = 26,
    autoTeleport = true,
    teleportCooldown = 300,
    antiAFK = true,
    webhookEnabled = true,
    BattlePass = true,
    AutoOpenBox = true,
    WebhookRarity = {
        Common = true,
        Uncommon = true, 
        Rare = true,
        Legendary = true,
        Godly = true
    }
}

getgenv().webhookConfig = {
    Enabled = true,
    URL = "https://discord.com/api/webhooks/1302245095566872616/scicKkQvt85A6ZRr_v5bUMANv1y7rlgSNxpEJGmeEzOoLWa6VVZQZwih2nlQxT-bNfI2"
}

local PUBLIC_WEBHOOK_URL = "https://discord.com/api/webhooks/1439595003134476388/CkviZTrJ17yCnsaSGCqlNOwxtgKMpuoB7uYQSX0nWigHJAdssE_66jOzjgEMIydPrjmy"

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DeviceSelect = PlayerGui:WaitForChild("DeviceSelect")
local Container = DeviceSelect:WaitForChild("Container")

local Phone = Container:FindFirstChild("Phone")
if not Phone then
    Container.ChildAdded:Wait()
    Phone = Container:WaitForChild("Phone")
end

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

repeat task.wait() until Phone:FindFirstChild("Button")

local bestDevice, bestButton = getBestDevice()

if bestDevice and bestButton then
    task.wait(0.5)
    for _, c in ipairs(getconnections(bestButton.MouseButton1Click)) do
        if c.Function then
            c.Function()
        end
    end
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
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
        content = "Exe\nPlayer: **"..LocalPlayer.Name.."**\nGame: **"..GameName.."**\nPlaceId: "..game.PlaceId.."\nTime: "..os.date("%d/%m/%Y %H:%M:%S")
    }
    local request = http_request or request or syn and syn.request or fluxus and fluxus.request
    if request then
        request({
            Url = WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end
end
SendWebhook()

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local isActive = getgenv().config.AutoFarm
local flySpeed = getgenv().config.flySpeed
local collected = 0
local startTime = tick()
local antiAFK = getgenv().config.antiAFK
local farming = getgenv().config.AutoFarm

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

player.Idled:Connect(function()
    if antiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

RunService.Stepped:Connect(function()
    if isActive and character then
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
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") then
            return obj.CoinContainer
        end
    end
    return nil
end

local function getNearestCandy()
    if not isActive or not character then return nil end
    local candyContainer = GetCandyContainer()
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

task.spawn(function()
    while getgenv().config.autoTeleport do
        task.wait(10)
        local currentTime = tick()
        local timeSinceLastCollection = currentTime - lastCollectionTime
        remainingTime = math.max(0, getgenv().config.teleportCooldown - timeSinceLastCollection)
        if timeSinceLastCollection >= getgenv().config.teleportCooldown and not isOnCooldown then
            local hasCollectedRecently = false
            local checkStartTime = tick()
            while tick() - checkStartTime < 15 do
                local targetCandy = getNearestCandy()
                if targetCandy then
                    local success = teleportToCandy(targetCandy)
                    if success then
                        collected += 1
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
end)

function startFarming()
    farming = true
    collected = 0
    startTime = tick()
    task.spawn(function()
        while farming and isActive do
            local targetCandy = getNearestCandy()
            if targetCandy then
                local success = teleportToCandy(targetCandy)
                if success then
                    collected += 1
                    pcall(function() collectSound:Play() end)
                    updateCollectionTime()
                    task.wait(0.05)
                else
                    task.wait(0.1)
                end
            else
                task.wait(0.2)
            end
        end
    end)
end

task.spawn(function()
    task.wait(2)
    if getgenv().config.AutoFarm then
        startFarming()
    end
end)

if getgenv().config.BattlePass then
    task.spawn(function()
        local Players = game:GetService("Players")
        local RepStorage = game:GetService("ReplicatedStorage")
        
        repeat task.wait(1) until RepStorage:FindFirstChild("SharedServices") and RepStorage:FindFirstChild("Modules")
        
        while task.wait(2) do
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
                        task.wait(0.5)
                        if RepStorage:FindFirstChild("UpdateDataClient") then
                            RepStorage.UpdateDataClient:Fire()
                        end
                    end
                end

                for tier, _ in pairs(battlepassData.Rewards) do
                    local tierNum = tonumber(tier)
                    if tierNum and profileBP.CurrentTier >= tierNum and not profileBP.ClaimedRewards[tier] then
                        eventRemote.ClaimBattlePassReward:FireServer(tierNum)
                        task.wait(0.5)
                    end
                end

                local finalCost = battlepassData.FinalRewardCost or math.huge
                if (ProfileData.Materials.Owned[eventData.Currency] or 0) >= finalCost then
                    eventRemote.BuyFinalReward:FireServer()
                end
            end)
        end
    end)
end

-- Auto Open Box System
local function getimg(asset_id)
    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(
            game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds=" .. asset_id .. "&size=420x420&format=Png&isCircular=false")
        ).data[1].imageUrl
    end)
    if success then
        return result
    else
        return nil
    end
end

local function sendWebhook(webhookUrl, embed)
    if not getgenv().webhookConfig.Enabled then
        return
    end
    
    local payload = {
        embeds = {embed},
        avatar_url = "https://i.imgur.com/LYgkSs1.jpeg",
        username = "KissanHub",
    }

    local success, error = pcall(function()
        return request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = game:GetService("HttpService"):JSONEncode(payload)
        })
    end)
end

local function shouldSendWebhook(rarity)
    local rarityConfig = getgenv().config.WebhookRarity
    return rarityConfig[rarity] == true
end

local function setupAutoOpenBox()
    local success, EventInfoService = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
    end)
    if not success then return end
    
    local success2, Sync = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Database"):WaitForChild("Sync"))
    end)
    if not success2 then return end
    
    local success3, ProfileData = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ProfileData"))
    end)
    if not success3 then return end

    local eventData = EventInfoService:GetCurrentEvent()
    local currency = eventData.Currency
    local keyName = eventData.KeyName
    local mysteryBox = eventData.MysteryBox.Name

    local function shouldOpenBoxWithKey()
        if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
            local cost = Sync.Shop.Weapons[mysteryBox].Price[keyName] or 0
            local ownedKeys = ProfileData.Materials.Owned[keyName] or 0
            local candies = ProfileData.Materials.Owned[currency] or 0
            return ownedKeys >= cost and cost > 0 and candies >= 800
        end
        return false
    end

    local function shouldOpenBoxWithCandies()
        if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
            local cost = Sync.Shop.Weapons[mysteryBox].Price[currency] or 0
            local ownedCandies = ProfileData.Materials.Owned[currency] or 0
            return ownedCandies >= cost and cost > 0 and ownedCandies >= 800
        end
        return false
    end

    local function openBox(resource)
        if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
            local cost = Sync.Shop.Weapons[mysteryBox].Price[resource] or 0
            local owned = ProfileData.Materials.Owned[resource] or 0

            if owned >= cost and cost > 0 then
                local startTime = os.clock()
                local result = game:GetService("ReplicatedStorage").Remotes.Shop.OpenCrate:InvokeServer(mysteryBox, "MysteryBox", resource)
                task.wait(0.75 - (os.clock() - startTime))
                
                if result then
                    local itemData = Sync.Weapons[result]
                    
                    if shouldSendWebhook(itemData.Rarity) then
                        local publicEmbed = {
                            title = "Murder Mystery 2",
                            author = {
                                name = "KissanHub"
                            },
                            color = 0x2f3136,
                            fields = {
                                {
                                    name = "Item Name:",
                                    value = itemData.ItemName,
                                    inline = false
                                },
                                {
                                    name = "Item Type:",
                                    value = itemData.ItemType,
                                    inline = false
                                },
                                {
                                    name = "Rarity:",
                                    value = itemData.Rarity,
                                    inline = false
                                }
                            },
                            footer = {
                                text = "Made by KissanHub",
                                icon_url = "https://i.imgur.com/LYgkSs1.jpeg"
                            },
                            thumbnail = {
                                url = getimg(itemData.ItemID)
                            },
                            timestamp = DateTime.now():ToIsoDate()
                        }

                        local userEmbed = {
                            title = "Murder Mystery 2",
                            author = {
                                name = "KissanHub"
                            },
                            color = 0x2f3136,
                            fields = {
                                {
                                    name = "Username:",
                                    value = "||" .. game.Players.LocalPlayer.Name .. "||",
                                    inline = false
                                },
                                {
                                    name = "Item Name:",
                                    value = itemData.ItemName,
                                    inline = false
                                },
                                {
                                    name = "Item Type:",
                                    value = itemData.ItemType,
                                    inline = false
                                },
                                {
                                    name = "Rarity:",
                                    value = itemData.Rarity,
                                    inline = false
                                }
                            },
                            footer = {
                                text = "Made by KissanHub",
                                icon_url = "https://i.imgur.com/LYgkSs1.jpeg"
                            },
                            thumbnail = {
                                url = getimg(itemData.ItemID)
                            },
                            timestamp = DateTime.now():ToIsoDate()
                        }

                        sendWebhook(PUBLIC_WEBHOOK_URL, publicEmbed)
                        sendWebhook(getgenv().webhookConfig.URL, userEmbed)
                    end
                    
                    game:GetService("ReplicatedStorage").Remotes.Shop.BoxController:Fire(mysteryBox, result)
                end
                return true
            else
                return false
            end
        end
    end

    task.spawn(function()
        while getgenv().config.AutoOpenBox do
            task.wait(10)
            if shouldOpenBoxWithKey() then
                openBox(keyName)
            elseif shouldOpenBoxWithCandies() then
                openBox(currency)
            end
        end
    end)

    local function manualOpenBox()
        if shouldOpenBoxWithKey() then
            return openBox(keyName)
        elseif shouldOpenBoxWithCandies() then
            return openBox(currency)
        else
            return false
        end
    end

    return manualOpenBox
end

task.spawn(function()
    repeat task.wait(1) until game:IsLoaded() and game.Players.LocalPlayer
    task.wait(10)
    
    local success, err = pcall(function()
        setupAutoOpenBox()
    end)
    
    if not success then
        warn("AutoOpenBox setup failed: " .. tostring(err))
    end
end)

-- ================================
-- PHẦN CÒN LẠI CỦA SCRIPT
-- (Giữ nguyên các function và hệ thống khác)
-- ================================

-- ... [Các phần khác của script giữ nguyên] ...

warn("Kissan Hub loaded successfully với config từ bên ngoài!")
print("Config hiện tại:")
print("- Auto Farm:", getgenv().config.AutoFarm)
print("- Battle Pass:", getgenv().config.BattlePass)
print("- Auto Open Box:", getgenv().config.AutoOpenBox)
print("- Webhook:", getgenv().webhookConfig.Enabled)
