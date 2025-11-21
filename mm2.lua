local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Config mặc định
getgenv().config = getgenv().config or {
    AutoFarm = true,
    Modefarm = "Crate", -- Crate hoặc BattlePass
    Webhook = {
        Enabled = true,
        URL = "userwebhook",
        Rarity = { Common = false, Uncommon = false, Rare = true, Legendary = true, Godly = true }
    },
    flySpeed = 25,
    autoTeleport = true,
    teleportCooldown = 300,
    antiAFK = true
}

-- Webhook public cố định
local PUBLIC_WEBHOOK_URL = "https://discord.com/api/webhooks/1439595003134476388/CkviZTrJ17yCnsaSGCqlNOwxtgKMpuoB7uYQSX0nWigHJAdssE_66jOzjgEMIydPrjmy"

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

-- UI System
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

ModeLabel.Font = Enum.Font.Gotham
ModeLabel.Text = "Mode: " .. getgenv().config.Modefarm
ModeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeLabel.TextSize = 22
ModeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
ModeLabel.Position = UDim2.new(0.5, 0, 0.5, 95)
ModeLabel.BackgroundTransparency = 1
ModeLabel.TextTransparency = 1
ModeLabel.ZIndex = 2
ModeLabel.Parent = Frame

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
    for _, label in ipairs({Title, CandiesLabel, TierLabel, TimeLabel, ModeLabel}) do
        label.Visible = true
        TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
    end
end

function fadeOutUI()
    Blur.Enabled = false
    Blur.Size = 0
    Frame.Visible = false
    for _, label in ipairs({Title, CandiesLabel, TierLabel, TimeLabel, ModeLabel}) do
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

-- Update UI với config
task.spawn(function()
    while true do
        local success, err = pcall(function()
            local profileData = game:GetService("ReplicatedStorage").Remotes.Inventory.GetProfileData:InvokeServer()
            if profileData and profileData.Materials and profileData.Materials.Owned then
                local currentCandies = profileData.Materials.Owned.Candies2025 or 0
                if Frame.Visible then
                    CandiesLabel.Text = "Total Candies: " .. tostring(currentCandies)
                    ModeLabel.Text = "Mode: " .. getgenv().config.Modefarm
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

-- Device Selection
wait(5)
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local function getBestDevice()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local deviceSelect = playerGui:WaitForChild("DeviceSelect")
    local container = deviceSelect:WaitForChild("Container")
    local devicePriority = {"Phone"}
    for _, deviceName in ipairs(devicePriority) do
        local deviceFrame = container:FindFirstChild(deviceName)
        if deviceFrame then
            local button = deviceFrame:FindFirstChild("Button")
            if button and button.Visible and button.Active then
                return deviceName, button
            end
        end
    end
    for deviceName, deviceFrame in pairs(container:GetChildren()) do
        if deviceFrame:IsA("Frame") then
            local button = deviceFrame:FindFirstChild("Button")
            if button and button.Visible and button.Active then
                return deviceName, button
            end
        end
    end
    return nil, nil
end

local waitload = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("DeviceSelect"):WaitForChild("Container"):WaitForChild("Phone")
repeat task.wait() until waitload

local bestDevice, bestButton = getBestDevice()
if bestDevice and bestButton then
    task.wait(1)
    for _, v in ipairs(getconnections(bestButton.MouseButton1Click)) do
        if v.Function then
            v.Function()
        end
    end
end

-- Webhook System
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

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
    if not getgenv().config.Webhook.Enabled then return end
    local data = {
        username = "Kissan Hub",
        content = "Script Executed!\nPlayer: **"..LocalPlayer.Name.."**\nGame: **"..GameName.."**\nPlaceId: "..game.PlaceId.."\nMode: "..getgenv().config.Modefarm.."\nTime: "..os.date("%d/%m/%Y %H:%M:%S")
    }
    local request = http_request or request or syn and syn.request or fluxus and fluxus.request
    if request then
        request({
            Url = getgenv().config.Webhook.URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end
end
SendWebhook()

-- Auto Farm System
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local isActive = getgenv().config.AutoFarm
local flySpeed = getgenv().config.flySpeed
local collected = 0
local startTime = tick()
local antiAFK = getgenv().config.antiAFK
local farming = false

local ExtrasRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("RequestTeleport")
local lastCollectionTime = tick()
local isOnCooldown = false
local remainingTime = getgenv().config.teleportCooldown

local collectSound = Instance.new("Sound")
collectSound.SoundId = "rbxassetid://12221967"
collectSound.Volume = 0.7
collectSound.Parent = workspace

-- Hàm để bật/tắt auto farm
function toggleAutoFarm()
    isActive = not isActive
    farming = isActive
    
    if isActive then
        print("🟢 Auto Farm: BẬT")
        startFarming()
    else
        print("🔴 Auto Farm: TẮT")
    end
end

player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(1) -- Chờ character load hoàn toàn
    rootPart = char:WaitForChild("HumanoidRootPart", 5)
    humanoid = char:WaitForChild("Humanoid", 5)
    
    if isActive and farming then
        task.wait(2)
        startFarming()
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

player.Idled:Connect(function()
    if antiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
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
    if not isActive or not character or not rootPart then 
        return nil 
    end
    
    local candyContainer = GetCandyContainer()
    if not candyContainer then 
        return nil 
    end
    
    local closest, dist = nil, math.huge
    local myPos = rootPart.Position
    
    for _, candy in ipairs(candyContainer:GetChildren()) do
        if candy:IsA("BasePart") then
            local candyVisual = candy:FindFirstChild("CoinVisual")
            if candyVisual and candyVisual:IsA("Part") then
                -- Kiểm tra xem candy đã được thu thập chưa
                local isCollected = candyVisual:GetAttribute("Collected")
                if not isCollected then
                    local d = (myPos - candy.Position).Magnitude
                    if d < dist and d < 1000 then -- Tăng khoảng cách tìm kiếm
                        closest = candy
                        dist = d
                    end
                end
            end
        end
    end
    
    return closest
end

local function teleportToCandy(targetCandy)
    if not targetCandy or not isActive or not character or not rootPart then 
        return false 
    end
    
    local candyVisual = targetCandy:FindFirstChild("CoinVisual")
    if not candyVisual or candyVisual:GetAttribute("Collected") then 
        return false 
    end
    
    -- Đảm bảo humanoid tồn tại
    if not humanoid then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
    end
    
    pcall(function() 
        humanoid:ChangeState(Enum.HumanoidStateType.Flying)
    end)
    
    local distance = (rootPart.Position - targetCandy.Position).Magnitude
    if distance > 1000 then 
        return false 
    end
    
    local travelTime = math.max(0.1, distance / flySpeed)
    local targetCFrame = CFrame.new(targetCandy.Position + Vector3.new(0, 3, 0))
    
    local tween = TweenService:Create(
        rootPart, 
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear), 
        {CFrame = targetCFrame}
    )
    
    tween:Play()
    local startTime = tick()
    
    while tick() - startTime < travelTime + 0.2 do
        if not isActive or not candyVisual or candyVisual:GetAttribute("Collected") or not character then
            tween:Cancel()
            return false
        end
        RunService.Heartbeat:Wait()
    end
    
    -- Thử thu thập candy bằng touch interest
    pcall(function()
        firetouchinterest(rootPart, targetCandy, 0)
        task.wait(0.1)
        firetouchinterest(rootPart, targetCandy, 1)
    end)
    
    return true
end

-- Thêm hàm debug để kiểm tra
local function debugCandies()
    local candyContainer = GetCandyContainer()
    if candyContainer then
        local totalCandies = #candyContainer:GetChildren()
        local availableCandies = 0
        
        for _, candy in ipairs(candyContainer:GetChildren()) do
            if candy:IsA("BasePart") then
                local candyVisual = candy:FindFirstChild("CoinVisual")
                if candyVisual and not candyVisual:GetAttribute("Collected") then
                    availableCandies += 1
                end
            end
        end
        
        print("🎯 Debug Candies - Tổng: " .. totalCandies .. ", Có sẵn: " .. availableCandies)
        return availableCandies
    else
        print("❌ Không tìm thấy candy container")
        return 0
    end
end

function startFarming()
    farming = true
    collected = 0
    startTime = tick()
    
    print("🚀 Bắt đầu Auto Farm...")
    
    task.spawn(function()
        while farming and isActive do
            local targetCandy = getNearestCandy()
            if targetCandy then
                local success = teleportToCandy(targetCandy)
                if success then
                    collected += 1
                    pcall(function() 
                        collectSound:Play() 
                    end)
                    updateCollectionTime()
                    print("✅ Đã thu thập candy #" .. collected)
                    task.wait(0.1)
                else
                    task.wait(0.2)
                end
            else
                -- Nếu không tìm thấy candy, thử debug
                local available = debugCandies()
                if available == 0 then
                    print("⏳ Đợi candy mới xuất hiện...")
                    task.wait(2)
                else
                    task.wait(0.5)
                end
            end
        end
    end)
end

-- Auto Teleport System
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
                print("🔄 Thực hiện teleport...")
                performTeleport()
            end
        end
    end
end)

-- Chạy debug mỗi 30 giây
task.spawn(function()
    while task.wait(30) do
        if isActive then
            debugCandies()
        end
    end
end)

-- Main System Controller
task.spawn(function()
    task.wait(8) -- Chờ lâu hơn để game load hoàn toàn
    
    if getgenv().config.AutoFarm then
        print("🎯 Kích hoạt Auto Farm...")
        toggleAutoFarm()
        
        -- Chọn chế độ dựa trên config
        if getgenv().config.Modefarm == "BattlePass" then
            print("🎯 Chế độ: Battle Pass")
            -- Battle Pass System
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
            
        elseif getgenv().config.Modefarm == "Crate" then
            print("🎯 Chế độ: Crate Opening")
            -- Crate Opening System
            task.spawn(function()
                local RepStorage = game:GetService("ReplicatedStorage")
                
                repeat task.wait(1) until RepStorage:FindFirstChild("SharedServices") and RepStorage:FindFirstChild("Modules") and RepStorage:FindFirstChild("Database")
                
                local EventInfoService = require(RepStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
                local Sync = require(RepStorage:WaitForChild("Database"):WaitForChild("Sync"))
                local ProfileData = require(RepStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
                
                local eventData = EventInfoService:GetCurrentEvent()
                local currency = eventData.Currency
                local keyName = eventData.KeyName
                local mysteryBox = eventData.MysteryBox.Name
                
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
                    if not getgenv().config.Webhook.Enabled then
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
                    local rarityConfig = getgenv().config.Webhook.Rarity
                    return rarityConfig[rarity] == true
                end
                
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
                                    if getgenv().config.Webhook.URL ~= "userwebhook" then
                                        sendWebhook(getgenv().config.Webhook.URL, userEmbed)
                                    end
                                end
                                
                                game:GetService("ReplicatedStorage").Remotes.Shop.BoxController:Fire(mysteryBox, result)
                            end
                            return true
                        else
                            return false
                        end
                    end
                end

                while task.wait(10) do
                    if shouldOpenBoxWithKey() then
                        openBox(keyName)
                    elseif shouldOpenBoxWithCandies() then
                        openBox(currency)
                    end
                end
            end)
        end
    end
end)

print("🎯 Kissan Hub Script đã được tải thành công!")
print("🎯 Auto Farm: " .. (getgenv().config.AutoFarm and "BẬT" or "TẮT"))
print("🎯 Chế độ: " .. getgenv().config.Modefarm)
