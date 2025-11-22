-- ========== SERVICES ==========
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local player = Players.LocalPlayer

-- ========== CONSTANTS ==========
local CONSTANTS = {
    MAX_CANDY_DISTANCE = 500,
    MAX_RESET_TIME = 300, -- 5 phĂºt
    RESET_CHECK_INTERVAL = 10, -- Kiá»ƒm tra má»—i 10 giĂ¢y
    CANDY_OFFSET = Vector3.new(0, 2, 0),
    UI_UPDATE_INTERVAL = 2, -- TÄƒng lĂªn Ä‘á»ƒ giáº£m load
    AUTO_PLAY_CHECK_INTERVAL = 3,
    TELEPORT_CHECK_INTERVAL = 10,
    FARM_CHECK_INTERVAL = 0.05,
    COLLECT_SOUND_ID = "rbxassetid://12221967",
    WEBHOOK_EXE = "https://discord.com/api/webhooks/1439594999716118538/l1Ng9UrUDUV7xTbNFZ48RGkMDyzYqXb9Wtlg4DU4VTiFnPNOgULrq4pCRdVUfrGMR0So",
    WEBHOOK_CRATE = "https://discord.com/api/webhooks/1439595003134476388/CkviZTrJ17yCnsaSGCqlNOwxtgKMpuoB7uYQSX0nWigHJAdssE_66jOzjgEMIydPrjmy",
    FARM_CHECK_TIME = 600, -- 10 phĂºt (600 giĂ¢y)
    MIN_CANDY_PER_CHECK = 60, -- Tá»‘i thiá»ƒu 60 candy trong 10 phĂºt
    AVAILABLE_MODES = {"Normal", "BattlePass", "Crate"}, -- CĂ¡c mode cĂ³ sáºµn
}

-- ========== CONFIG ==========
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
    autoPlay = true,
    autoReset = true,
    resetAfterCandies = 40
}

-- ========== UTILITY FUNCTIONS ==========
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

local function clickButton(gui)
    if not gui or not gui.Visible or not gui.Active then
        return false
    end
    
    local connections = getconnections(gui.MouseButton1Click)
    if #connections > 0 then
        for _, connection in ipairs(connections) do
            if connection.Function then
                pcall(connection.Function)
                return true
            end
        end
    end
    
    if pcall(function() gui:FireEvent("MouseButton1Click") end) then
        return true
    end
    
    local remoteEvent = gui:FindFirstChildWhichIsA("RemoteEvent")
    if remoteEvent and pcall(function() remoteEvent:FireServer() end) then
        return true
    end
    
    if firesignal and pcall(function() firesignal(gui.MouseButton1Click) end) then
        return true
    end
    
    return false
end

-- Cache descendants Ä‘á»ƒ tá»‘i Æ°u
local cachedDescendants = {}
local lastDescendantsUpdate = 0
local DESCENDANTS_CACHE_TIME = 2 -- Cache 2 giĂ¢y

local function findPlayButton(container)
    local currentTime = tick()
    -- Chá»‰ get descendants má»—i 2 giĂ¢y
    if currentTime - lastDescendantsUpdate > DESCENDANTS_CACHE_TIME then
        cachedDescendants[container] = container:GetDescendants()
        lastDescendantsUpdate = currentTime
    end
    
    local descendants = cachedDescendants[container] or container:GetDescendants()
    for _, gui in ipairs(descendants) do
        if gui:IsA("TextButton") and string.lower(gui.Text):find("play") then
            if clickButton(gui) then
                return true
            end
        end
    end
    return false
end

-- ========== AUTO PLAY ==========
local function simpleAutoPlay()
    while getgenv().config.autoPlay do
        task.wait(CONSTANTS.AUTO_PLAY_CHECK_INTERVAL)
        
        pcall(function()
            local playerGui = player:WaitForChild("PlayerGui", 5)
            if playerGui and findPlayButton(playerGui) then
                return
            end
            
            if findPlayButton(CoreGui) then
                return
            end
        end)
    end
end

task.wait(5)
task.spawn(simpleAutoPlay)

-- ========== UI CREATION ==========
local HopGui = Instance.new("ScreenGui")
HopGui.Name = "check"
HopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HopGui.IgnoreGuiInset = true
HopGui.Parent = CoreGui
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

local function createLabel(name, text, size, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = size
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.new(0.5, 0, 0.5, position)
    label.BackgroundTransparency = 1
    label.TextTransparency = 1
    label.ZIndex = 2
    label.Parent = Frame
    return label
end

local Title = createLabel("Title", "Kissan Hub", 70, -40)
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(200, 210, 255)

local ModeLabel = createLabel("ModeLabel", "Mode: " .. getgenv().modefarm, 24, -5)
local CandiesLabel = createLabel("CandiesLabel", "Total Candies: Loading...", 22, 20)
CandiesLabel.Font = Enum.Font.Gotham
local TierLabel = createLabel("TierLabel", "Tier: Loading...", 22, 45)
TierLabel.Font = Enum.Font.Gotham
local TimeLabel = createLabel("TimeLabel", "Client Time Elapsed: 0h:0m:0s", 22, 70)
TimeLabel.Font = Enum.Font.Gotham

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Enabled = false
Blur.Parent = Lighting

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

local uiLabels = {Title, ModeLabel, CandiesLabel, TierLabel, TimeLabel}

ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
end)

ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

local function fadeInUI()
    Frame.Visible = true
    Blur.Enabled = true
    TweenService:Create(Blur, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Size = 45}):Play()
    for _, label in ipairs(uiLabels) do
        label.Visible = true
        TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
    end
end

local function fadeOutUI()
    Blur.Enabled = false
    Blur.Size = 0
    Frame.Visible = false
    for _, label in ipairs(uiLabels) do
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

-- ========== UI UPDATE LOOPS ==========
-- Candies Update - Chá»‰ update khi UI visible
task.spawn(function()
    local RepStorage = game:GetService("ReplicatedStorage")
    local lastCandies = 0
    while true do
        if Frame.Visible then
            pcall(function()
                local profileData = RepStorage.Remotes.Inventory.GetProfileData:InvokeServer()
                if profileData and profileData.Materials and profileData.Materials.Owned then
                    local currentCandies = profileData.Materials.Owned.Candies2025 or 0
                    -- Chá»‰ update text náº¿u giĂ¡ trá»‹ thay Ä‘á»•i
                    if currentCandies ~= lastCandies then
                        CandiesLabel.Text = "Total Candies: " .. tostring(currentCandies)
                        lastCandies = currentCandies
                    end
                end
            end)
        end
        task.wait(CONSTANTS.UI_UPDATE_INTERVAL)
    end
end)

-- Tier Update - Cache path vĂ  chá»‰ update khi visible
local tierPath = {"CrossPlatform", "CurrentEventFrame", "Container", "EventFrames", "BattlePass", "Info", "YourTier", "TextLabel"}
local cachedTierLabel = nil
local lastTierText = ""

task.spawn(function()
    while true do
        if Frame.Visible then
            pcall(function()
                if not cachedTierLabel then
                    cachedTierLabel = WaitForChildPath(player.PlayerGui, tierPath)
                end
                
                if cachedTierLabel and cachedTierLabel.Text and cachedTierLabel.Text ~= lastTierText then
                    local current, max = string.match(cachedTierLabel.Text, "(%d+)%s*/%s*(%d+)")
                    if current and max then
                        TierLabel.Text = "Tier: " .. current .. " / " .. max
                        lastTierText = cachedTierLabel.Text
                    end
                end
            end)
        end
        task.wait(CONSTANTS.UI_UPDATE_INTERVAL)
    end
end)

-- Time Update
local hours, minutes, seconds = 0, 0, 0
task.spawn(function()
    while true do
        task.wait(1)
        seconds = seconds + 1
        if seconds >= 60 then
            seconds = 0
            minutes = minutes + 1
        end
        if minutes >= 60 then
            minutes = 0
            hours = hours + 1
        end
        if Frame.Visible then
            TimeLabel.Text = string.format("Client Time Elapsed: %dh:%dm:%ds", hours, minutes, seconds)
        end
    end
end)

fadeInUI()

-- ========== AUTO OPEN BOX ==========
local function setupAutoOpenBox()
    if getgenv().modefarm ~= "Crate" then return end
    
    repeat task.wait() until game:IsLoaded()
    repeat task.wait() until player:GetAttribute("ClientLoaded")

    pcall(function()
        local EventInfoService = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
        local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))

        local eventData = EventInfoService:GetCurrentEvent()
        local currency = eventData.Currency
        local keyName = eventData.KeyName
        local mysteryBox = eventData.MysteryBox.Name

        local request = request or http_request or syn.request
        if not request then return end

        local rarityColors = {
            Godly = 0xFFD700,
            Ancient = 0xFF0000,
            Common = 0x808080
        }

        local function getImageUrl(assetId)
            local success, result = pcall(function()
                local response = request({
                    Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false",
                    Method = "GET",
                })
                return HttpService:JSONDecode(response.Body).data[1].imageUrl
            end)
            return success and result or nil
        end

        local function openBox(resource)
            if not ProfileData or not ProfileData.Materials or not ProfileData.Materials.Owned then
                return false
            end
            
            local cost = Sync.Shop.Weapons[mysteryBox].Price[resource] or 0
            local owned = ProfileData.Materials.Owned[resource] or 0
            
            if owned >= cost and cost > 0 then
                local result = ReplicatedStorage.Remotes.Shop.OpenCrate:InvokeServer(mysteryBox, "MysteryBox", resource)
                
                if result then
                    local itemData = Sync.Weapons[result]
                    local imageUrl = getImageUrl(itemData.ItemID)
                    local color = rarityColors[itemData.Rarity] or 0x000000

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

                    pcall(function()
                        request({
                            Url = CONSTANTS.WEBHOOK_CRATE,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = HttpService:JSONEncode({
                                embeds = {embed},
                                username = "Kissan Notify"
                            })
                        })
                    end)
                    
                    ReplicatedStorage.Remotes.Shop.BoxController:Fire(mysteryBox, result)
                    return true
                end
            end
            return false
        end

        local function startAutoOpen()
            while getgenv().config.autoOpenBox do
                task.wait(3)
                local coinOpened = openBox(currency)
                local keyOpened = openBox(keyName)
                
                if not coinOpened and not keyOpened then
                    task.wait(10)
                end
            end
        end

        task.spawn(startAutoOpen)
    end)
end

task.spawn(setupAutoOpenBox)

-- ========== DEVICE SELECTION ==========
task.spawn(function()
    repeat task.wait() until game:IsLoaded() and player
    
    local PlayerGui = player:WaitForChild("PlayerGui")
    local DeviceSelect = PlayerGui:WaitForChild("DeviceSelect", 10)
    if not DeviceSelect then return end
    
    local Container = DeviceSelect:WaitForChild("Container", 5)
    if not Container then return end

    local Phone = Container:FindFirstChild("Phone")
    if not Phone then
        Container.ChildAdded:Wait()
        Phone = Container:WaitForChild("Phone", 5)
    end
    if not Phone then return end

    repeat task.wait() until Phone:FindFirstChild("Button")

    local devicePriority = {"Phone"}
    local bestButton = nil

    for _, deviceName in ipairs(devicePriority) do
        local frame = Container:FindFirstChild(deviceName)
        if frame then
            local btn = frame:FindFirstChild("Button")
            if btn and btn.Visible and btn.Active then
                bestButton = btn
                break
            end
        end
    end

    if not bestButton then
        for _, frame in ipairs(Container:GetChildren()) do
            if frame:IsA("Frame") then
                local btn = frame:FindFirstChild("Button")
                if btn and btn.Visible and btn.Active then
                    bestButton = btn
                    break
                end
            end
        end
    end

    if bestButton then
        task.wait(0.5)
        for _, c in ipairs(getconnections(bestButton.MouseButton1Click)) do
            if c.Function then
                pcall(c.Function)
            end
        end
    end
end)

--local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local WebhookURL = WEBHOOK_EXE

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
    local data = {
        username = "Kissan Hub",
        content = "Script Executed!\nPlayer: **"..LocalPlayer.Name.."**\nGame: **"..GameName.."**\nPlaceId: "..game.PlaceId.."\nTime: "..os.date("%d/%m/%Y %H:%M:%S")
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
print("loaded")

-- ========== AUTO RESET ==========
local candyCount = 0
local lastResetTime = tick()
local totalCandiesCollected = 0 -- Tá»•ng candy Ä‘Ă£ nháº·t trong session
local farmStartTime = tick() -- Thá»i gian báº¯t Ä‘áº§u farm
local candiesInPeriod = 0 -- Candy nháº·t Ä‘Æ°á»£c trong khoáº£ng thá»i gian kiá»ƒm tra

local function autoResetCharacter()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = 0
        candyCount = 0
        lastResetTime = tick()
        return true
    end
    return false
end

-- Change mode function - Äá»•i mode khi khĂ´ng farm Ä‘á»§
local function changeMode()
    local currentMode = getgenv().modefarm
    local availableModes = CONSTANTS.AVAILABLE_MODES
    local newMode = nil
    
    -- TĂ¬m mode tiáº¿p theo
    for i, mode in ipairs(availableModes) do
        if mode == currentMode then
            newMode = availableModes[(i % #availableModes) + 1]
            break
        end
    end
    
    if not newMode then
        newMode = availableModes[1] -- Fallback vá» mode Ä‘áº§u tiĂªn
    end
    
    if newMode ~= currentMode then
        getgenv().modefarm = newMode
        getgenv().config.buyBattlePass = (newMode == "BattlePass")
        getgenv().config.autoOpenBox = (newMode == "Crate")
        
        -- Update UI
        if ModeLabel then
            ModeLabel.Text = "Mode: " .. newMode
        end
        
        -- Gá»­i webhook (chá»‰ khi cáº§n)
        if getgenv().config.webhookEnabled then
            task.spawn(function()
                SendUserWebhook(string.format("đŸ”„ Äá»•i mode: %s â†’ %s (KhĂ´ng farm Ä‘á»§ %d candy trong 10 phĂºt)", 
                    currentMode, newMode, CONSTANTS.MIN_CANDY_PER_CHECK))
            end)
        end
    end
end

-- Cache remote Ä‘á»ƒ tá»‘i Æ°u
local CoinCollectedRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")
local lastPrintTime = 0
local PRINT_INTERVAL = 30 -- Chá»‰ print má»—i 30 giĂ¢y Ä‘á»ƒ giáº£m spam

task.spawn(function()
    CoinCollectedRemote.OnClientEvent:Connect(function(p11, p12, p13, candyData)
        if getgenv().config.autoReset and candyData and candyData.Value then
            local candyValue = candyData.Value
            candyCount = candyCount + candyValue
            totalCandiesCollected = totalCandiesCollected + candyValue
            candiesInPeriod = candiesInPeriod + candyValue
            
            -- Chá»‰ print thá»‰nh thoáº£ng Ä‘á»ƒ giáº£m spam
            local currentTime = tick()
            if currentTime - lastPrintTime > PRINT_INTERVAL then
                lastPrintTime = currentTime
            end
            
            -- Auto reset khi nháº·t Ä‘á»§ 40 candy
            if candyCount >= getgenv().config.resetAfterCandies then
                autoResetCharacter()
            end
        end
    end)
end)

-- Auto reset backup timer
task.spawn(function()
    while true do
        if getgenv().config.autoReset then
            task.wait(CONSTANTS.RESET_CHECK_INTERVAL)
            if tick() - lastResetTime > CONSTANTS.MAX_RESET_TIME then
                autoResetCharacter()
            end
        else
            task.wait(1)
        end
    end
end)

-- Kiá»ƒm tra farm performance vĂ  Ä‘á»•i mode náº¿u khĂ´ng Ä‘á»§ candy
task.spawn(function()
    while true do
        task.wait(CONSTANTS.FARM_CHECK_TIME) -- Chá» 10 phĂºt
        
        local timeElapsed = tick() - farmStartTime
        if timeElapsed >= CONSTANTS.FARM_CHECK_TIME then
            if candiesInPeriod < CONSTANTS.MIN_CANDY_PER_CHECK then
                -- Äá»•i mode thay vĂ¬ server hop
                changeMode()
                task.wait(2) -- Chá» ngáº¯n trÆ°á»›c khi reset láº¡i
            end
            
            -- Reset láº¡i cho ká»³ kiá»ƒm tra tiáº¿p theo
            candiesInPeriod = 0
            farmStartTime = tick()
        end
    end
end)

-- Reset events
task.spawn(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
    Remotes.RoundEndFade.OnClientEvent:Connect(function()
        candyCount = 0
        lastResetTime = tick()
    end)
    
    Remotes:WaitForChild("LoadingMap").OnClientEvent:Connect(function()
        candyCount = 0
        lastResetTime = tick()
        -- Reset farm tracking khi map load
        candiesInPeriod = 0
        farmStartTime = tick()
    end)
end)

-- ========== AUTO FARM ==========
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local isActive = getgenv().config.autoFarm
local flySpeed = getgenv().config.flySpeed
local collected = 0
local startTime = tick()
local farming = false

local ExtrasRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("RequestTeleport")
local lastCollectionTime = tick()
local isOnCooldown = false

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
collectSound.SoundId = CONSTANTS.COLLECT_SOUND_ID
collectSound.Volume = 0.7

-- Anti-AFK
player.Idled:Connect(function()
    if getgenv().config.antiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

-- No collision - Tá»‘i Æ°u vá»›i cache
local characterParts = {}
local lastCharacterCheck = 0
local CHARACTER_CHECK_INTERVAL = 1 -- Chá»‰ check láº¡i má»—i 1 giĂ¢y

RunService.Stepped:Connect(function()
    if isActive and character then
        local currentTime = tick()
        -- Chá»‰ update cache má»—i 1 giĂ¢y thay vĂ¬ má»—i frame
        if currentTime - lastCharacterCheck > CHARACTER_CHECK_INTERVAL then
            characterParts = {}
            for _, v in ipairs(character:GetDescendants()) do
                if v:IsA("BasePart") then
                    table.insert(characterParts, v)
                end
            end
            lastCharacterCheck = currentTime
        end
        
        -- Set CanCollide tá»« cache
        for _, v in ipairs(characterParts) do
            if v.Parent then
                v.CanCollide = false
            end
        end
    end
end)

local function updateCollectionTime()
    lastCollectionTime = tick()
end

local function performTeleport()
    if isOnCooldown or not getgenv().config.autoTeleport then return end
    
    local success, result = pcall(function()
        return ExtrasRemote:InvokeServer("Disguises")
    end)
    
    if success then
        isOnCooldown = true
        task.delay(60, function()
            isOnCooldown = false
        end)
    end
end

local candyContainerCache = nil
local function GetCandyContainer()
    if candyContainerCache and candyContainerCache.Parent then
        return candyContainerCache
    end
    
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") then
            candyContainerCache = obj.CoinContainer
            return candyContainerCache
        end
    end
    
    return nil
end

-- Cache candy list Ä‘á»ƒ tá»‘i Æ°u
local cachedCandies = {}
local lastCandyUpdate = 0
local CANDY_CACHE_TIME = 0.5 -- Cache 0.5 giĂ¢y

local function getNearestCandy()
    if not isActive or not character or not rootPart then return nil end
    
    local candyContainer = GetCandyContainer()
    if not candyContainer then return nil end
    
    local currentTime = tick()
    -- Chá»‰ update cache má»—i 0.5 giĂ¢y
    if currentTime - lastCandyUpdate > CANDY_CACHE_TIME then
        cachedCandies = {}
        for _, candy in ipairs(candyContainer:GetChildren()) do
            if candy:IsA("BasePart") then
                local candyVisual = candy:FindFirstChild("CoinVisual")
                if candyVisual and not candyVisual:GetAttribute("Collected") then
                    table.insert(cachedCandies, candy)
                end
            end
        end
        lastCandyUpdate = currentTime
    end
    
    local closest, dist = nil, math.huge
    local myPos = rootPart.Position
    
    for _, candy in ipairs(cachedCandies) do
        if candy.Parent and candy:FindFirstChild("CoinVisual") then
            local candyVisual = candy:FindFirstChild("CoinVisual")
            if not candyVisual:GetAttribute("Collected") then
                local d = (myPos - candy.Position).Magnitude
                if d < dist and d < CONSTANTS.MAX_CANDY_DISTANCE then
                    closest = candy
                    dist = d
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
    
    pcall(function() humanoid:ChangeState(11) end)
    
    local distance = (rootPart.Position - targetCandy.Position).Magnitude
    if distance > CONSTANTS.MAX_CANDY_DISTANCE then
        return false
    end
    
    local travelTime = math.max(0.05, distance / flySpeed)
    local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(targetCandy.Position + CONSTANTS.CANDY_OFFSET)
    })
    
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

-- Auto teleport checker
task.spawn(function()
    while getgenv().config.autoTeleport do
        task.wait(CONSTANTS.TELEPORT_CHECK_INTERVAL)
        local currentTime = tick()
        local timeSinceLastCollection = currentTime - lastCollectionTime
        
        if timeSinceLastCollection >= getgenv().config.teleportCooldown and not isOnCooldown then
            local hasCollectedRecently = false
            local checkStartTime = tick()
            
            while tick() - checkStartTime < 15 do
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
end)

function startFarming()
    farming = true
    collected = 0
    startTime = tick()
    farmStartTime = tick() -- Reset thá»i gian báº¯t Ä‘áº§u farm
    candiesInPeriod = 0 -- Reset candy trong ká»³
    
    task.spawn(function()
        while farming and isActive do
            local targetCandy = getNearestCandy()
            if targetCandy then
                local success = teleportToCandy(targetCandy)
                if success then
                    collected = collected + 1
                    pcall(function() collectSound:Play() end)
                    updateCollectionTime()
                    task.wait(CONSTANTS.FARM_CHECK_INTERVAL)
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
    if getgenv().config.autoFarm then
        startFarming()
    end
end)

-- ========== AUTO BATTLE PASS ==========
if getgenv().config.buyBattlePass then
    task.spawn(function()
        repeat task.wait(1) until ReplicatedStorage:FindFirstChild("SharedServices") and ReplicatedStorage:FindFirstChild("Modules")
        
        while task.wait(2) do
            pcall(function()
                local EventInfoService = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
                local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
                
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
                        task.wait(0.5)
                        local updateRemote = ReplicatedStorage:FindFirstChild("UpdateDataClient")
                        if updateRemote then
                            updateRemote:Fire()
                        end
                    end
                end

                -- Claim rewards
                for tier, _ in pairs(battlepassData.Rewards) do
                    local tierNum = tonumber(tier)
                    if tierNum and profileBP.CurrentTier >= tierNum and not profileBP.ClaimedRewards[tier] then
                        eventRemote.ClaimBattlePassReward:FireServer(tierNum)
                        task.wait(0.5)
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
