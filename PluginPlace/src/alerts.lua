--[[
           _      ___     __  ___  __   _____  _
  /\/\    /_\    / _ \ /\ \ \/___\/ /   \_   \/_\
 /    \  //_\\  / /_\//  \/ //  // /     / /\//_\\
/ /\/\ \/  _  \/ /_\\/ /\  / \_// /___/\/ /_/  _  \
\/    \/\_/ \_/\____/\_\ \/\___/\____/\____/\_/ \_/ ALERTSLIB

This alerts library comes from an unreleased library called Magnolia.
If you consider it usefull and you are interessed to a possible release of this library
contact Uniqua.
]]

--// GLOBALS \\--
local TweenService = game:GetService('TweenService');

--// CONST \\--
local RightDistance = 6;
local BotDistance = 3;
local TextDistance = 20;
local Duration = 2;
local TextColor = Color3.new(1, 1, 1);
local BackgroundColor = Color3.fromRGB(32, 34, 37);
local ActiveColor = Color3.fromRGB(52, 152, 219);

local ICONS = {
    Info = "rbxassetid://4057220511",
    Error = "rbxassetid://4057319805",
    Success = "rbxassetid://5774307837",
    Warn = "rbxassetid://5849784138"
};

-- TweenInfos
local Slide = TweenInfo.new(
    0.2,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.In
);
local SlideY = TweenInfo.new(
    0.2,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.Out
);
-- Storages
local Notifications = {}; 	-- keep all online notifications
local IDs = {}; 			-- keep all notifications instance
local Tweening = {}; 		-- keep a bool that let understand if the alert lib is tweening down some alerts

-- dummy alert for clone usage
local Dummy;
do
    -- Instances Creation
    Dummy               = Instance.new('ImageLabel');
    Dummy.Name          = 'MagnoliaAlert';
    Dummy.Image 		= "rbxassetid://3570695787";
    Dummy.ScaleType 	= Enum.ScaleType.Slice;
    Dummy.SliceScale	= 0.12;
    Dummy.SliceCenter 	= Rect.new(100, 100, 100, 100);
    Dummy.Size = UDim2.new(0, 340, 0, 70);
    Dummy.AnchorPoint = Vector2.new(0, 1);
    Dummy.Position = UDim2.new(1, 0, 1, -30);
    Dummy.BorderSizePixel = 0;
    Dummy.BackgroundTransparency = 1;

    local Underline 		= Dummy:Clone();
    Underline.Name			= 'Underline';
    Underline.Parent		= Dummy;
    Underline.AnchorPoint	= Vector2.new(0.5, 1);
    Underline.Position		= UDim2.new(0.5, 0, 1, 0);
    Underline.Size			= UDim2.new(0, 0, 0.06, 0);
    Underline.Rotation		= 180;
    Underline.ImageRectSize = Vector2.new(200, 120);
end;

-- util
local DarkerColor = function(Color:Color3, DecreaseValue)
    local Hue, Sat, Value = Color:ToHSV();
    Value = Value - DecreaseValue;
    if Value < 0 then
        Value = 0;
    end
    return Color3.fromHSV(Hue, Sat, Value);
end;

local function M_ToastAlert(Parent, Settings)
    -- retrive settings
    local TitleText = Settings.Title;
    local TextText 	= Settings.Text or 'None';
    local IconImage = Settings.Icon;
    local Duration 	= Settings.Duration or Duration;
    local TextColor = Settings.TextColor or TextColor;
    local BackgroundColor = Settings.BackgroundColor or BackgroundColor;
    -- get storage
    local Online	 = Notifications[Parent] or {};
    Notifications[Parent] = Online;
    -- create alert
    local Alert = Dummy:Clone();
    local Underline = Alert.Underline;
    local Last = Online[#Online] or Alert;
    -- push online
    Alert.Parent = Parent;
    Online[#Online + 1] = Alert;
    local StartID = #Online;
    IDs[Alert] = StartID; -- store current id
    -- appaerance
    Alert.ImageColor3 = BackgroundColor;
    Underline.ImageColor3 = TextColor;
    local StartXOffset = TextDistance;
    -- icon
    local Icon;
    if IconImage then
        Icon = Instance.new('ImageLabel', Alert);
        Icon.BackgroundTransparency = 1;
        Icon.Image = IconImage;
        Icon.Position = UDim2.new(0, TextDistance, 0.5, 0);
        Icon.AnchorPoint = Vector2.new(0, 0.5);
        local Size = Alert.Size.Y.Offset - Icon.Position.X.Offset*2;
        Icon.Size = UDim2.new(0, Size, 0, Size);
        -- set texts x position
        StartXOffset = TextDistance * 2 + Size;
    end;
    -- title
    local Title;
    local XSize = Alert.Size.X.Offset - StartXOffset - TextDistance/2;
    if TitleText then
        Title = Instance.new('TextLabel', Alert);
        Title.BackgroundTransparency = 1;
        Title.TextXAlignment = Enum.TextXAlignment.Left;
        Title.Text = TitleText;
        Title.TextColor3 = TextColor;
        Title.TextSize = Settings.TitleSize or 13;
        Title.Size = UDim2.new(0, XSize, 0, Title.TextSize);
        Title.Position = UDim2.new(0, StartXOffset, 0,
            TextDistance-5);
    end;
    -- text
    local Text = Instance.new('TextLabel', Alert);
    Text.BackgroundTransparency = 1;
    Text.TextXAlignment = Enum.TextXAlignment.Left;
    Text.TextYAlignment = Enum.TextYAlignment.Top;
    Text.TextWrapped = true;
    Text.TextSize = Settings.TextSize or 10;
    Text.TextColor3 = TextColor;
    Text.AnchorPoint = Vector2.new(0, 0);
    Text.Text = TextText;
    if Title then
        local y = -(Text.TextSize + TextDistance);
        Text.Size = UDim2.new(0, XSize, 0, Alert.AbsoluteSize.Y + y - TextDistance);
        Text.Position = UDim2.new(0, StartXOffset, 1, y);
    else
        -- set text center
        Text.TextYAlignment = Enum.TextYAlignment.Center;
        Text.Size = UDim2.new(0, XSize, 1, -(TextDistance*2));
        Text.AnchorPoint = Vector2.new(0, 0.5);
        Text.Position = UDim2.new(0, StartXOffset, 0.5, 0);
    end;
    -- set icon color
    if Icon then
        Icon.ImageColor3 = DarkerColor(TextColor, 0.2);
    end;
    -- sound
    if Settings.Sound then
        Settings.Sound:Play();
    end;
    --start position
    Alert.Position = UDim2.new(1, Alert.Size.X.Offset + RightDistance, 1, 0);
    -- alert appear
    TweenService:Create(
        Alert,
        Slide,
        {
            Position = UDim2.new(1, -Alert.Size.X.Offset-RightDistance, 1, StartID *  -(Alert.Size.Y.Offset + BotDistance))
        }
    ):Play();
    -- Close transparency sync
    Alert.Changed:Connect(function(Field)
        if Field == 'ImageTransparency' then
            Underline.ImageTransparency = Alert.ImageTransparency;
            -- Texts
            Text.TextTransparency = Alert.ImageTransparency;
            if Title then
                Title.TextTransparency = Alert.ImageTransparency;
            end;
            -- Images
            if Icon then
                Icon.ImageTransparency = Alert.ImageTransparency;
            end;
        end;
    end);
    -- start Underline
    local Tween = TweenService:Create(
        Underline,
        TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0.97, 0, Underline.Size.Y.Scale, 0)
        }
    );
    Tween:Play();
    task.spawn(function()
        Tween.Completed:Wait();
        -- Animations
        TweenService:Create(
            Underline,
            Slide,
            {
                Size = UDim2.new(0, 0, Underline.Size.Y.Scale, 0)
            }
        ):Play();
        TweenService:Create(
            Alert,
            Slide,
            {
                Size = UDim2.new(0, Alert.Size.X.Offset/1.03, 0, Alert.Size.Y.Offset/1.03),
                ImageTransparency = 0.1
            }
        ):Play();
        task.wait(.5);
        local SlideOff = TweenService:Create(
            Alert,
            Slide,
            {
                Position = UDim2.new(1, Alert.Size.X.Offset + RightDistance, 1, Alert.Position.Y.Offset)
            }
        );
        -- Animation
        SlideOff:Play();
        SlideOff.Completed:Wait();
        -- Remove from online
        local CurrentId = IDs[Alert];
        IDs[Alert] = nil;
        table.remove(Online, CurrentId);
        -- update all id of the online alerts
        for ID, Target in next, Online do -- from this id to last id
            -- update IDs table
            IDs[Target] = ID;
            --SlideY
            local Target = Online[ID];
            -- Tween
            TweenService:Create(
                Target,
                SlideY,
                {
                    Position = UDim2.new(1, -Target.Size.X.Offset-RightDistance, 1,
                        ID *  -(Target.Size.Y.Offset + BotDistance)
                    )
                }
            ):Play();
        end;
        -- Destroy
        Alert:Destroy();
    end);
end;

local function Info(ScreenGui, Title, Message, Duration)
    return M_ToastAlert(ScreenGui, {
        Text = Message,
        Title = Title,
        TextColor = ActiveColor,
        BackgroundColor = BackgroundColor,
        Duration = Duration,
        Icon = ICONS.Info;
    })
end;

local function Warn(ScreenGui, Title, Message, Duration)
    return M_ToastAlert(ScreenGui, {
        Text = Message,
        Title = Title,
        BackgroundColor = BackgroundColor,
        TextColor = Color3.fromRGB(241, 196, 15),
        Duration = Duration,
        Icon = ICONS.Warn;
    });
end;

local function Success(ScreenGui, Title, Message, Duration)
    return M_ToastAlert(ScreenGui, {
        Text = Message,
        Title = Title,
        BackgroundColor = BackgroundColor,
        TextColor = Color3.fromRGB(46, 204, 113),
        Duration = Duration,
        Icon = ICONS.Success;
    });
end;

local function Error(ScreenGui, Title, Message, Duration)
    return M_ToastAlert(ScreenGui, {
        Text = Message,
        Title = Title,
        BackgroundColor = BackgroundColor,
        TextColor = Color3.fromRGB(231, 76, 60),
        Duration = Duration,
        Icon = ICONS.Error;
    });
end;


return {
    ToastAlert = M_ToastAlert;
    Info = Info;
    Error = Error;
    Warn = Warn;
    Success = Success;
}