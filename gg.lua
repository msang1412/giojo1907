-- ================== SAFE INIT ==================
getgenv().Setting = getgenv().Setting or {}
getgenv().Setting.Notify = getgenv().Setting.Notify or {}
getgenv().Setting.Notify.CustomIcon = getgenv().Setting.Notify.CustomIcon or false
getgenv().Setting.Notify.Image = getgenv().Setting.Notify.Image or ""

-- ================== SERVICES ==================
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- ================== UI SETUP ==================
local SC_UI_Name = "Geta_Bi_Thieu_Nang"
local old = CoreGui:FindFirstChild(SC_UI_Name)
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SC_UI_Name
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function Tween(obj, time, style, dir, props)
    return TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
end

-- ================== ASSETS ==================
local ImageAssets = {
    NotifyDetail = "rbxassetid://14184951412",
    NotifyIcon = "rbxassetid://3926307971",
    NotifyPaimon = "rbxassetid://14480278865",
}

-- ================== CONTAINER ==================
local Container = Instance.new("Frame")
Container.Parent = ScreenGui
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(1, 0, 0, 0)
Container.Size = UDim2.new(0, 0, 1, 0)

local Layout = Instance.new("UIListLayout")
Layout.Parent = Container
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
Layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
Layout.Padding = UDim.new(0, 15)

-- ================== NOTIFY FUNCTION ==================
local function Notify(Configs)
    Configs = Configs or {}
    local Text = tostring(Configs.Text or "Notification")
    local Delay = tonumber(Configs.Delay)
    local Type2 = Configs.Type2 or "Normal"

    -- MAIN
    local Main = Instance.new("Frame", Container)
    Main.BackgroundTransparency = 1
    Main.Size = UDim2.new(0, 120, 0, 45)

    local Body = Instance.new("Frame", Main)
    Body.BackgroundColor3 = Color3.fromRGB(15,15,14)
    Body.BackgroundTransparency = 0.35
    Body.Size = UDim2.new(1,0,1,0)
    Body.Position = UDim2.new(3,0,0,0)

    -- TEXT
    local Label = Instance.new("TextLabel", Body)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0,60,0,0)
    Label.Size = UDim2.new(1,-70,1,0)
    Label.Font = Enum.Font.Fantasy
    Label.RichText = true
    Label.TextWrapped = true
    Label.TextXAlignment = Left
    Label.TextColor3 = Color3.fromRGB(236,229,216)
    Label.TextSize = 20
    Label.Text = "<b>"..Text.."</b>"

    -- ICON FRAME
    local IconFrame = Instance.new("Frame", Body)
    IconFrame.Position = UDim2.new(0,10,0,-5)
    IconFrame.Size = UDim2.new(0,50,0,50)
    IconFrame.Rotation = 45
    IconFrame.BackgroundTransparency = 0.3
    IconFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)

    local Stroke = Instance.new("UIStroke", IconFrame)
    Stroke.Thickness = 2
    Stroke.Color = Color3.fromRGB(236,229,216)
    Stroke.Enabled = false

    local IconImage = Instance.new("ImageLabel", IconFrame)
    IconImage.BackgroundTransparency = 1
    IconImage.Size = UDim2.new(1.2,0,1.2,0)
    IconImage.Position = UDim2.new(-0.1,0,-0.1,0)
    IconImage.Rotation = -45
    IconImage.Image = ImageAssets.NotifyPaimon
    IconImage.Visible = false

    local Exclamation = Instance.new("TextLabel", IconFrame)
    Exclamation.BackgroundTransparency = 1
    Exclamation.Size = UDim2.new(1,0,1,0)
    Exclamation.Rotation = -45
    Exclamation.Text = "!"
    Exclamation.Font = Enum.Font.FredokaOne
    Exclamation.TextScaled = true
    Exclamation.TextColor3 = Color3.fromRGB(255,74,74)

    if Type2 == "Paimon" then
        IconImage.Visible = true
        Exclamation.Visible = false
        Stroke.Enabled = true
    end

    -- SIZE CALC
    local sizeX = TextService:GetTextSize(Text,20,Enum.Font.Fantasy,Vector2.new(1000,45)).X + 80
    Main.Size = UDim2.new(0,sizeX,0,45)
    Body.Size = UDim2.new(0,sizeX,0,45)
    Body.Position = UDim2.new(3,-sizeX,0,0)

    Tween(Body,0.6,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,{
        Position = UDim2.new(1,-sizeX,0,0)
    }):Play()

    -- AUTO CLOSE
    if Delay then
        task.delay(Delay,function()
            Tween(Body,0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.In,{
                Position = UDim2.new(3,-sizeX,0,0)
            }):Play()
            task.wait(0.6)
            Main:Destroy()
        end)
    end
end

-- ================== EXPORT ==================
getgenv().Notify = Notify
