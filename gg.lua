-- CÁC VẤN ĐỀ:
-- 1. Thiếu hàm getasset() - bạn dùng getasset(...) nhưng không định nghĩa
-- 2. Thiếu biến IconFolder - bạn dùng IconFolder nhưng không khai báo
-- 3. getgenv().Setting.Notify có thể không tồn tại (gây lỗi)
-- 4. Logic tính toán text size có vấn đề

-- ĐÂY LÀ CODE ĐÃ FIX:
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Kiểm tra xem có phải đang trong Roblox Studio không
local isStudio = RunService:IsStudio()

local SC_UI_Name = "Geta Bi Thieu Nang"
local existingUI = game:GetService("CoreGui"):FindFirstChild(SC_UI_Name)

-- FIX 1: Tạo hàm getasset nếu không tồn tại
if not getasset and isStudio then
    -- Trong Studio, có thể dùng function giả
    getasset = function(path)
        warn("getasset called with path:", path, "- Using placeholder")
        return "rbxassetid://14184951412" -- Return một asset id mặc định
    end
end

-- FIX 2: Khai báo IconFolder
local IconFolder = "" -- Đặt đường dẫn thư mục icon ở đây

-- FIX 3: Kiểm tra setting
local Setting = getgenv().Setting or {}
Setting.Notify = Setting.Notify or {}
Setting.Notify.CustomIcon = Setting.Notify.CustomIcon or false
Setting.Notify.Image = Setting.Notify.Image or "default.png"

local ScreenGui = Instance.new("ScreenGui")

if existingUI then
    existingUI:Destroy()
end

function Tween(object, time, easingstyle, easingdirection, properties)
    return TweenService:Create(object, TweenInfo.new(time, easingstyle, easingdirection), properties)
end

ScreenGui.Name = SC_UI_Name
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local NotificationContainer_1 = Instance.new("Frame")
local UIListLayout_3 = Instance.new("UIListLayout")

local ImageAssets = {
    NotifyDetail = "rbxassetid://14184951412",
    NotifyIcon = "rbxassetid://3926307971",
    NotifyPaimon = "rbxassetid://14480278865", 
}

NotificationContainer_1.Name = "NotificationContainer_1"
NotificationContainer_1.Parent = ScreenGui
NotificationContainer_1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
NotificationContainer_1.BackgroundTransparency = 1.000
NotificationContainer_1.BorderColor3 = Color3.fromRGB(0, 0, 0)
NotificationContainer_1.BorderSizePixel = 0
NotificationContainer_1.Position = UDim2.new(1, 0, 0, 0)
NotificationContainer_1.Size = UDim2.new(0, 0, 0.970000029, 0)

UIListLayout_3.Parent = NotificationContainer_1
UIListLayout_3.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_3.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout_3.Padding = UDim.new(0, 30)

function Notify(Configs)
    Configs = Configs or {}
    Configs.Text = Configs.Text or "No Text Provided"
    Configs.Delay = Configs.Delay or 3
    Configs.Type2 = Configs.Type2 or "Default"
    
    local Notify = Instance.new("Frame")
    local Notify2 = Instance.new("Frame")
    local NotifyText = Instance.new("TextLabel")
    local NotifyDetail = Instance.new("ImageLabel")
    local NotifyIcon = Instance.new("ImageButton")
    local NotifyIconFrame = Instance.new("Frame")
    local NotifyIcon2 = Instance.new("TextLabel")
    local NotifyDelayFrame1 = Instance.new("Frame")
    local NotifyDelayFrame2 = Instance.new("Frame")
    local UIStroke = Instance.new("UIStroke")
    local NotifyImage = Instance.new("ImageLabel")

    Notify.Name = "Notify"
    Notify.Parent = NotificationContainer_1
    Notify.BackgroundColor3 = Color3.fromRGB(15, 15, 14)
    Notify.BackgroundTransparency = 1 -- FIX: Set transparency = 1 thay vì backgroundtransparency = 1
    Notify.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Notify.BorderSizePixel = 0
    Notify.Size = UDim2.new(0, 110, 0, 45)

    Notify2.Name = "Notify2"
    Notify2.Parent = Notify
    Notify2.BackgroundColor3 = Color3.fromRGB(15, 15, 14)
    Notify2.BackgroundTransparency = 0.350
    Notify2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Notify2.BorderSizePixel = 0
    Notify2.Position = UDim2.new(3, -110, 0, 0)
    Notify2.Size = UDim2.new(1, 0, 1, 0)

    -- Tính toán kích thước dựa trên text
    local textSize = TextService:GetTextSize(
        Configs.Text, 
        22, 
        Enum.Font.Fantasy, 
        Vector2.new(9999, 9999)
    )
    
    local totalTextSize = textSize.X
    local saveTemp = Notify.Size.X.Offset/2
    
    -- Đặt lại kích thước frame
    local frameWidth = math.max(200, totalTextSize + saveTemp + 100) -- Thêm padding
    Notify.Size = UDim2.new(0, frameWidth, 0, 45)
    
    -- Đặt vị trí ban đầu cho Notify2
    Notify2.Position = UDim2.new(3, -frameWidth, 0, 0)
    Notify2.Size = UDim2.new(1, 0, 1, 0)

    NotifyText.Name = "NotifyText"
    NotifyText.Parent = Notify2
    NotifyText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyText.BackgroundTransparency = 1.000
    NotifyText.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyText.BorderSizePixel = 0
    NotifyText.Position = UDim2.new(0, 75, 0.200000003, 0)
    NotifyText.Size = UDim2.new(1, -110, 0.600000024, 0)
    NotifyText.Font = Enum.Font.Fantasy
    NotifyText.RichText = true
    NotifyText.Text = "<b>"..Configs.Text.."</b>"
    NotifyText.TextColor3 = Color3.fromRGB(236, 229, 216)
    NotifyText.TextSize = 22
    NotifyText.TextWrapped = true
    NotifyText.TextXAlignment = Enum.TextXAlignment.Left

    NotifyDetail.Name = "NotifyDetail"
    NotifyDetail.Parent = Notify2
    NotifyDetail.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyDetail.BackgroundTransparency = 1.000
    NotifyDetail.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyDetail.BorderSizePixel = 0
    NotifyDetail.Position = UDim2.new(0, -25, 0, 0)
    NotifyDetail.Size = UDim2.new(0, 25, 1, 0)
    NotifyDetail.Image = ImageAssets.NotifyDetail
    NotifyDetail.ImageColor3 = Color3.fromRGB(15, 15, 14)
    NotifyDetail.ImageTransparency = 0.350

    NotifyIcon.Name = "NotifyIcon"
    NotifyIcon.Parent = Notify2
    NotifyIcon.BackgroundTransparency = 1.000
    NotifyIcon.LayoutOrder = 9
    NotifyIcon.Position = UDim2.new(1, -30, 0.218999997, 0)
    NotifyIcon.Size = UDim2.new(0, 20, 0, 25)
    NotifyIcon.ZIndex = 3
    NotifyIcon.Image = ImageAssets.NotifyIcon
    NotifyIcon.ImageColor3 = Color3.fromRGB(236, 229, 216)
    NotifyIcon.ImageRectOffset = Vector2.new(764, 244)
    NotifyIcon.ImageRectSize = Vector2.new(36, 36)

    NotifyIconFrame.Name = "NotifyIconFrame"
    NotifyIconFrame.Parent = Notify2
    NotifyIconFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    NotifyIconFrame.BackgroundTransparency = 0.550
    NotifyIconFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyIconFrame.BorderSizePixel = 0
    NotifyIconFrame.Position = UDim2.new(0, 10, 0, -5)
    NotifyIconFrame.Rotation = 45.000
    NotifyIconFrame.Size = UDim2.new(0, 50, 0, 50)

    UIStroke.Parent = NotifyIconFrame
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Thickness = 2
    UIStroke.Color = Color3.fromRGB(236, 229, 216)
    UIStroke.Enabled = false

    NotifyImage.Name = "NotifyImage"
    NotifyImage.Parent = NotifyIconFrame
    NotifyImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyImage.BackgroundTransparency = 1.000
    NotifyImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyImage.BorderSizePixel = 0
    NotifyImage.Position = UDim2.new(-0.1, -1, -0.1, -1)
    NotifyImage.Rotation = -45.000
    NotifyImage.Size = UDim2.new(1.2, 2, 1.2, 2)
    NotifyImage.Image = ImageAssets.NotifyPaimon
    
    -- FIX: Kiểm tra kỹ trước khi dùng getasset
    if Setting.Notify and Setting.Notify.CustomIcon and IconFolder ~= "" then
        local success, result = pcall(function()
            if getasset then
                return getasset(IconFolder.."/"..Setting.Notify.Image)
            end
            return ImageAssets.NotifyPaimon
        end)
        if success then
            NotifyImage.Image = result
        end
    end
    
    NotifyImage.Visible = false

    NotifyIcon2.Name = "NotifyIcon2"
    NotifyIcon2.Parent = NotifyIconFrame
    NotifyIcon2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyIcon2.BackgroundTransparency = 1.000
    NotifyIcon2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyIcon2.BorderSizePixel = 0
    NotifyIcon2.Rotation = -45.000
    NotifyIcon2.Size = UDim2.new(1, 0, 1, 0)
    NotifyIcon2.Font = Enum.Font.FredokaOne
    NotifyIcon2.Text = "!"
    NotifyIcon2.TextColor3 = Color3.fromRGB(255, 74, 74)
    NotifyIcon2.TextScaled = true
    NotifyIcon2.TextSize = 14.000
    NotifyIcon2.TextWrapped = true
    NotifyIcon2.Visible = false

    if Configs.Type2 == "Paimon" then
        NotifyImage.Visible = true
        UIStroke.Enabled = true
        NotifyIconFrame.BackgroundColor3 = Color3.fromRGB(159, 154, 145)
        NotifyIconFrame.BackgroundTransparency = 0
    else
        NotifyIcon2.Visible = true
    end

    NotifyDelayFrame1.Name = "NotifyDelayFrame1"
    NotifyDelayFrame1.Parent = Notify2
    NotifyDelayFrame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyDelayFrame1.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyDelayFrame1.BorderSizePixel = 0
    NotifyDelayFrame1.BackgroundTransparency = 1
    NotifyDelayFrame1.Position = UDim2.new(0, 45, 1, -2)
    NotifyDelayFrame1.Size = UDim2.new(1, -45, 0, 2)

    NotifyDelayFrame2.Name = "NotifyDelayFrame2"
    NotifyDelayFrame2.Parent = NotifyDelayFrame1
    NotifyDelayFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyDelayFrame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NotifyDelayFrame2.BorderSizePixel = 0
    NotifyDelayFrame2.Size = UDim2.new(1, 0, 1, 0)

    -- Animation in
    local inTween = Tween(Notify2, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, {
        Position = UDim2.new(1, -frameWidth, 0, 0)
    })
    inTween:Play()

    -- Delay và animation out
    if Configs.Delay and Configs.Delay > 0 then
        local delayTween = Tween(NotifyDelayFrame2, Configs.Delay, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, {
            Size = UDim2.new(0, 0, 1, 0),
            Position = UDim2.new(1, 0, 0, 0)
        })
        delayTween:Play()
        
        delayTween.Completed:Connect(function()
            local outTween = Tween(Notify2, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In, {
                Position = UDim2.new(3, -frameWidth, 0, 0)
            })
            outTween:Play()
            outTween.Completed:Connect(function()
                Notify:Destroy()
            end)
        end)
    end

    -- Click để đóng
    NotifyIcon.MouseButton1Click:Connect(function()
        local outTween = Tween(Notify2, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In, {
            Position = UDim2.new(3, -frameWidth, 0, 0)
        })
        outTween:Play()
        outTween.Completed:Connect(function()
            Notify:Destroy()
        end)
    end)
    
    return Notify
end

-- Thử test
Notify({
    Text = "Hello World!",
    Delay = 3,
    Type2 = "Paimon"
})

return Notify
