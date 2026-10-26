-- # Credits to @187 for the actual code
-- # This was just a fixed version with some improvement.
-- # If this thing has bugs, report it :)
-- # Have fun using this skidded thing!
-- # Your Welcome!

local Insert = table.insert

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({Tasks = {}, Destroyed = false}, Maid)
end

function Maid:GiveTask(Task)
    if self.Destroyed then self:CleanTask(Task) return end
    Insert(self.Tasks, Task)
    return Task
end

function Maid:GiveTasks(...)
    for _, Task in ipairs({...}) do
        self:GiveTask(Task)
    end
end

function Maid:CleanTask(Task)
    local TaskType = typeof(Task)
    if TaskType == "RBXScriptConnection" then Task:Disconnect()
    elseif TaskType == "Instance" then Task:Destroy()
    elseif TaskType == "function" then Task()
    elseif TaskType == "table" and type(Task.Destroy) == "function" then Task:Destroy() end
end

function Maid:DoCleaning()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, Task in ipairs(self.Tasks) do
        self:CleanTask(Task)
    end
    self.Tasks = {}
end

function Maid:Destroy()
    self:DoCleaning()
end

local RootMaid = Maid.new()

local Shared = odh_shared_plugins
if not Shared and getgenv then
    local Genv = getgenv()
    if type(Genv) == "table" and type(Genv.shared) == "table" then
        Shared = Genv.shared
    end
end

if not Shared or type(Shared.CreateTab) ~= "function" then
    return
end

task.spawn(function()
    pcall(function()
        Shared.loadfromurl("/aux0on/CrashHandler/refs/heads/main/Prevention.lua")
    end)
end)

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    SoundService = game:GetService("SoundService"),
    HttpService = game:GetService("HttpService"),
    CoreGui = game:GetService("CoreGui")
}

local LocalPlayer = Services.Players.LocalPlayer

local __PCLR = Color3.new
local __RGB = Color3.fromRGB
local __UD2 = UDim2.new
local __UD = UDim.new
local __V2 = Vector2.new

local __RS = Services.RunService
local __UIS = Services.UserInputService
local __PLRS = Services.Players
local __TS = Services.TweenService

local SaveButtonPositions = false
local PositionFile = "bombjump_ui_positions.json"

local function LoadPositions()
    local Ok, Content = pcall(readfile, PositionFile)
    if Ok and Content and Content ~= "" then
        local DecOk, Data = pcall(function() return Services.HttpService:JSONDecode(Content) end)
        if DecOk and type(Data) == "table" then return Data end
    end
    return {}
end

local function SavePosition(Id, Pos)
    if not SaveButtonPositions then return end
    local Positions = LoadPositions()
    Positions[Id] = {XScale = Pos.X.Scale, XOffset = Pos.X.Offset, YScale = Pos.Y.Scale, YOffset = Pos.Y.Offset}
    pcall(function() writefile(PositionFile, Services.HttpService:JSONEncode(Positions)) end)
end

local function ApplySavedPosition(Gui, Id)
    if not SaveButtonPositions then return end
    local P = LoadPositions()[Id]
    if P then Gui.Position = __UD2(P.XScale or 0, P.XOffset or 0, P.YScale or 0, P.YOffset or 0) end
end

local BBSystem = {Buttons = {}, Connections = {}}

local function BBSafeCallback(Callback)
    if not Callback then return end
    xpcall(Callback, function(E) return debug.traceback(E) end)
end

local function BBGetStorage()
    local Parent = gethui and gethui()
    if not Parent or typeof(Parent) ~= "Instance" then Parent = Services.CoreGui end
    if not Parent or typeof(Parent) ~= "Instance" then Parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5) end
    if typeof(Parent) ~= "Instance" then Parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui") end
    local SG = Parent:FindFirstChild("@BBStorage")
    if not SG then
        SG = Instance.new("ScreenGui")
        SG.Name = "@BBStorage"
        SG.ResetOnSpawn = false
        SG.IgnoreGuiInset = true
        pcall(function() SG.ScreenInsets = Enum.ScreenInsets.None end)
        SG.Parent = Parent
    end
    return SG
end

local BBGradSeq = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __PCLR(0.0784314, 0.0784314, 0.0784314)),
    ColorSequenceKeypoint.new(0.75, __PCLR(0.0784314, 0.0784314, 0.54902)),
    ColorSequenceKeypoint.new(1, __PCLR(0.470588, 0.156863, 0.470588))
})

local function BBMakeDraggable(Gui, Func, Ripple, Sound)
    local Dragging, DragInput, DragStart, StartPos
    local HasMoved = false
    local TInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    Gui.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging, HasMoved = true, false
            DragStart, StartPos = Input.Position, Gui.Position
            local RestingSize = __UD2(0, Gui.Size.X.Offset, 0, Gui.Size.Y.Offset)
            local RestingTextSize = Gui.TextSize
            __TS:Create(Gui, TInfo, {Size = __UD2(0, RestingSize.X.Offset + 20, 0, RestingSize.Y.Offset + 7.5), TextSize = RestingTextSize + 2.4}):Play()
            local AbsPos = Gui.AbsolutePosition
            Ripple.Position = __UD2(0, Input.Position.X - AbsPos.X, 0, Input.Position.Y - AbsPos.Y)
            Ripple.Size = __UD2(0, 0, 0, 0)
            Ripple.BackgroundTransparency = 0.5
            Ripple.Visible = true
            Sound:Play()
            __TS:Create(Ripple, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 300, 0, 300), BackgroundTransparency = 1
            }):Play()
            local Rel
            Rel = __UIS.InputEnded:Connect(function(EndInput)
                if EndInput.UserInputType == Input.UserInputType then
                    Dragging = false
                    __TS:Create(Gui, TInfo, {Size = RestingSize, TextSize = RestingTextSize}):Play()
                    if not HasMoved then BBSafeCallback(Func) end
                    SavePosition(Gui.Name, Gui.Position)
                    Rel:Disconnect()
                end
            end)
        end
    end)
    Gui.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end)
    __UIS.InputChanged:Connect(function(Input)
        if Input == DragInput and Dragging then
            local Delta = Input.Position - DragStart
            if Delta.Magnitude > 7 then HasMoved = true end
            Gui.Position = __UD2(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)
end

local MuteButtonSounds = false

local function UpdateAllButtonSounds()
    local Volume = MuteButtonSounds and 0 or 0.5
    for _, Btn in pairs(BBSystem.Buttons) do
        local Sound = Btn:FindFirstChild("Sound")
        if Sound then Sound.Volume = Volume end
    end
    for _, Btn in pairs(BindableButtons.Buttons) do
        local Sound = Btn:FindFirstChild("Sound")
        if Sound then Sound.Volume = Volume end
    end
end

local function AddBigButton(Id, Text, Func, IsGold)
    if BBSystem.Buttons[Id] then return end
    local Storage = BBGetStorage()
    local BB = Instance.new("TextButton")
    BB.Name = Id
    BB.Size = __UD2(0, 200, 0, 75)
    BB.Position = __UD2(0.5, 0, 0.5, 0)
    BB.AnchorPoint = __V2(0.5, 0.5)
    BB.BackgroundColor3 = __RGB(255, 255, 255)
    BB.BackgroundTransparency = 0.9
    BB.BorderSizePixel = 0
    BB.Font = Enum.Font.Jura
    BB.Text = Text
    BB.TextSize = 24
    BB.TextColor3 = __RGB(255, 255, 255)
    BB.TextWrapped = true
    BB.ClipsDescendants = true
    BB.AutoButtonColor = false
    BB.ZIndex = 5
    BB.Parent = Storage

    Instance.new("UICorner", BB).CornerRadius = __UD(0, 5)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = __RGB(255, 255, 255)
    Stroke.Thickness = 1.5
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = BB
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = IsGold and ColorSequence.new({
        ColorSequenceKeypoint.new(0, __RGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.5, __RGB(255, 140, 0)),
        ColorSequenceKeypoint.new(1, __RGB(184, 134, 11))
    }) or BBGradSeq
    Gradient.Parent = Stroke

    local Ripple = Instance.new("Frame")
    Ripple.Name = "@ripple"
    Ripple.BackgroundColor3 = IsGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    Ripple.BackgroundTransparency = 0.5
    Ripple.ZIndex = 4
    Ripple.Size = __UD2(0, 0, 0, 0)
    Ripple.AnchorPoint = __V2(0.5, 0.5)
    Ripple.Visible = false
    Ripple.Parent = BB
    Instance.new("UICorner", Ripple).CornerRadius = __UD(1, 0)

    local Sound = Instance.new("Sound")
    Sound.SoundId = "rbxassetid://3868133279"
    Sound.Volume = MuteButtonSounds and 0 or 0.5
    Sound.Parent = BB

    BBMakeDraggable(BB, Func, Ripple, Sound)
    BBSystem.Connections[Id] = __RS.RenderStepped:Connect(function()
        Gradient.Rotation = (Gradient.Rotation + 1) % 360
    end)
    BBSystem.Buttons[Id] = BB
    ApplySavedPosition(BB, Id)
    return BB
end

local function DeleteBigButton(Id)
    if BBSystem.Buttons[Id] then
        if BBSystem.Connections[Id] then
            BBSystem.Connections[Id]:Disconnect()
            BBSystem.Connections[Id] = nil
        end
        BBSystem.Buttons[Id]:Destroy()
        BBSystem.Buttons[Id] = nil
    end
end

local BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local Shapes = {[0] = "rbxassetid://86221076925479"}

local NormalColor = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __PCLR(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1, __PCLR(0.501961, 0.501961, 0.501961))
})

local WaitColor = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __PCLR(0.827451, 0.133333, 0.133333)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.509804, 0.231373, 0.231373)),
    ColorSequenceKeypoint.new(1, __PCLR(0.501961, 0.501961, 0.501961))
})

local GoldNormalColor = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __RGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(255, 140, 0)),
    ColorSequenceKeypoint.new(1, __RGB(184, 134, 11))
})

local GoldWaitColor = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __RGB(255, 69, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(139, 69, 19)),
    ColorSequenceKeypoint.new(1, __RGB(160, 82, 45))
})

local function BindSafeCallback(Callback)
    if not Callback then return end
    xpcall(Callback, function(E) return debug.traceback(E) end)
end

local function BindGetStorage()
    local Parent = gethui and gethui()
    if not Parent or typeof(Parent) ~= "Instance" then Parent = Services.CoreGui end
    if not Parent or typeof(Parent) ~= "Instance" then Parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5) end
    if typeof(Parent) ~= "Instance" then Parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui") end
    local SG = Parent:FindFirstChild("@bindstorage")
    if not SG then
        SG = Instance.new("ScreenGui")
        SG.Name = "@bindstorage"
        SG.ResetOnSpawn = false
        SG.IgnoreGuiInset = true
        pcall(function() SG.ScreenInsets = Enum.ScreenInsets.None end)
        SG.Parent = Parent
    end
    return SG
end

local function BindMakeDraggable(Gui, Maid, Ripple, Sound, ClickFunc)
    local Dragging, DragInput, DragStart, StartPos
    local HasMoved = false

    Maid:GiveTask(Gui.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging, DragStart, StartPos = true, Input.Position, Gui.Position
            HasMoved = false
            Sound:Play()
            local AbsPos = Gui.AbsolutePosition
            Ripple.Position = __UD2(0, Input.Position.X - AbsPos.X, 0, Input.Position.Y - AbsPos.Y)
            Ripple.Size = __UD2(0, 0, 0, 0)
            Ripple.BackgroundTransparency = 0.5
            Ripple.Visible = true
            __TS:Create(Ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45), BackgroundTransparency = 1
            }):Play()
            local Rel
            Rel = __UIS.InputEnded:Connect(function(EndInput)
                if EndInput.UserInputType == Input.UserInputType then
                    Dragging = false
                    if not HasMoved then BindSafeCallback(ClickFunc) end
                    SavePosition(Gui.Name, Gui.Position)
                    Rel:Disconnect()
                end
            end)
        end
    end))

    Maid:GiveTask(Gui.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end))

    Maid:GiveTask(__UIS.InputChanged:Connect(function(Input)
        if Input == DragInput and Dragging then
            local Delta = Input.Position - DragStart
            if Delta.Magnitude > 7 then HasMoved = true end
            local Screen = Gui.Parent.AbsoluteSize
            Gui.Position = __UD2(StartPos.X.Scale + (Delta.X / Screen.X), 0, StartPos.Y.Scale + (Delta.Y / Screen.Y), 0)
        end
    end))
end

local function AddBButton(Id, Text, ClickFunc, IsGold)
    if BindableButtons.Buttons[Id] then return end

    local ButtonMaid = Maid.new()
    local Camera = workspace.CurrentCamera
    local Screen = Camera.ViewportSize
    local ButtonSizeY = 0.11
    local WidthScale = ButtonSizeY * (Screen.Y / Screen.X)
    local XPos = 0.1 + ((BindableButtons.Count % 8) * (WidthScale + 0.005))
    local YPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (ButtonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = Id
    ImageButton.Size = __UD2(WidthScale, 0, ButtonSizeY, 0)
    ImageButton.Position = __UD2(XPos, 0, YPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = Shapes[0]
    ImageButton.BackgroundTransparency = 1
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.Parent = BindGetStorage()
    ButtonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Jura
    TextLabel.Text = Text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 10
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("UIGradient", ImageButton)
    Stroke.Name = "@Stroke"
    Stroke.Color = IsGold and GoldNormalColor or NormalColor

    local Ripple = Instance.new("Frame")
    Ripple.Name = "@ripple"
    Ripple.BackgroundColor3 = IsGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    Ripple.BackgroundTransparency = 0.5
    Ripple.Size = __UD2(0, 0, 0, 0)
    Ripple.AnchorPoint = __V2(0.5, 0.5)
    Ripple.Visible = false
    Ripple.ZIndex = 2
    Ripple.Parent = ImageButton
    Instance.new("UICorner", Ripple).CornerRadius = __UD(1, 0)

    local Sound = Instance.new("Sound")
    Sound.SoundId = "rbxassetid://3868133279"
    Sound.Volume = MuteButtonSounds and 0 or 0.5
    Sound.Parent = ImageButton

    BindMakeDraggable(ImageButton, ButtonMaid, Ripple, Sound, ClickFunc)
    ButtonMaid:GiveTask(__RS.RenderStepped:Connect(function()
        Stroke.Rotation = (Stroke.Rotation + 1) % 360
    end))

    BindableButtons.Buttons[Id] = ImageButton
    BindableButtons.Maids[Id] = ButtonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    ApplySavedPosition(ImageButton, Id)
    return ImageButton
end

local function DeleteBButton(Id)
    if BindableButtons.Maids[Id] then
        BindableButtons.Maids[Id]:Destroy()
        BindableButtons.Maids[Id] = nil
        BindableButtons.Buttons[Id] = nil
    end
end

local function UpdateBButtonText(Id, Text, IsWaiting, IsGold)
    local Btn = BindableButtons.Buttons[Id]
    if not Btn then return end
    local TextLabel = Btn:FindFirstChild("@Text")
    if TextLabel then TextLabel.Text = Text end
    local Stroke = Btn:FindFirstChild("@Stroke")
    if Stroke then
        if IsGold then Stroke.Color = IsWaiting and GoldWaitColor or GoldNormalColor
        else Stroke.Color = IsWaiting and WaitColor or NormalColor end
    end
end

-- The icon is placed back in
local BombJump = Shared.CreateTab("Bomb Jump+", "/UrexampleGD/ok-icon/refs/heads/main/images__2_-removebg-preview")

local AboutSection = BombJump:AddSection("About", "Information")

AboutSection:AddParagraph("Bomb Jump+", "Plugin Made by @lzzzx")

AboutSection:AddToggle("Mute Button SFX", function(Bool)
    MuteButtonSounds = Bool
    UpdateAllButtonSounds()
end)

AboutSection:AddToggle("Save Button Position", function(Bool)
    SaveButtonPositions = Bool
    if Bool then
        for Id, Btn in pairs(BBSystem.Buttons) do ApplySavedPosition(Btn, Id) end
        for Id, Btn in pairs(BindableButtons.Buttons) do ApplySavedPosition(Btn, Id) end
    end
end)

pcall(function() Shared.Notify("Bomb Jump+ Loaded", 2) end)

local Section = BombJump:AddSection("Bomb Jump+", "MM2 / MMV")

local Config = {
    CooldownTime = 22.0,
    LaunchPower = 58,
    DefaultSize = 200,
    EquipDelay = 0.6
}

local BombJumpEnabled = false
local OnCooldown = false
local Debounce = false
local AutoGetBomb = false
local JustRespawned = false
local BigButtonSize = Config.DefaultSize
local BindButtonSize = 0.11
local BjBindButton = nil

local BombNames = {"FakeBomb"}

local BombJumpMaid = Maid.new()
RootMaid:GiveTask(BombJumpMaid)

local Sounds = {Click = Instance.new("Sound"), Cooldown = Instance.new("Sound")}
Sounds.Click.SoundId = "rbxassetid://6895079853"
Sounds.Click.Volume = 1.0
Sounds.Cooldown.SoundId = "rbxassetid://138090596"
Sounds.Cooldown.Volume = 1.0

local function PlaySound(Snd)
    pcall(function() if Snd then Services.SoundService:PlayLocalSound(Snd) end end)
end

-- FIXED: Strict air check to prevent jumping on stairs/slopes
local function IsPlayerInAir()
    local Character = LocalPlayer.Character
    if not Character then return false end

    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then return false end

    -- If touching ground (stairs, slope, floor), do not allow.
    if Humanoid.FloorMaterial ~= Enum.Material.Air then
        return false
    end

    -- Must actually be in a jumping state
    local State = Humanoid:GetState()
    if State == Enum.HumanoidStateType.Jumping or 
       State == Enum.HumanoidStateType.Freefall then
        return true
    end

    return false
end

local function ResetCooldown()
    OnCooldown = false
    local BigBtn = BBSystem.Buttons["bombjump_big"]
    if BigBtn then BigBtn.Text = "Bomb Jump" end
    if BindableButtons.Buttons["bombjump_bind"] then
        UpdateBButtonText("bombjump_bind", "BJ", false, false)
    end
end

local function StartCooldown()
    OnCooldown = true
    Debounce = false
    local BigBtn = BBSystem.Buttons["bombjump_big"]
    if BigBtn then BigBtn.Text = "Wait" end
    if BindableButtons.Buttons["bombjump_bind"] then
        UpdateBButtonText("bombjump_bind", "Wait", true, false)
    end
    task.spawn(function()
        for I = Config.CooldownTime, 1, -1 do
            if not OnCooldown then break end
            local BigBtn = BBSystem.Buttons["bombjump_big"]
            if BigBtn then BigBtn.Text = tostring(I) end
            if BindableButtons.Buttons["bombjump_bind"] then
                UpdateBButtonText("bombjump_bind", tostring(I), true, false)
            end
            task.wait(1)
        end
        if OnCooldown then ResetCooldown() end
    end)
end

local function GetCenterPosition()
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local Camera = Services.Workspace.CurrentCamera
        return Character.HumanoidRootPart.Position + (Camera.CFrame.LookVector * 5)
    end
    return nil
end

local function MakeCharacterJump()
    local Character = LocalPlayer.Character
    if Character then
        local Humanoid = Character:FindFirstChild("Humanoid")
        if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end

local function UnequipBomb()
    task.spawn(function()
        local Character = LocalPlayer.Character
        if Character then
            for _, BombName in ipairs(BombNames) do
                local Bomb = Character:FindFirstChild(BombName)
                if Bomb then Bomb.Parent = LocalPlayer.Backpack or Character break end
            end
        end
    end)
end

local function GetAnyBomb()
    local Character = LocalPlayer.Character
    if not Character then return false, nil end
    for _, BombName in ipairs(BombNames) do
        local Bomb = Character:FindFirstChild(BombName)
        if Bomb then return true, Bomb end
    end
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if Backpack then
        for _, BombName in ipairs(BombNames) do
            local Bomb = Backpack:FindFirstChild(BombName)
            if Bomb then Bomb.Parent = Character task.wait(0.05) return true, Bomb end
        end
    end
    for Attempt = 1, 3 do
        pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
        task.wait(0.1)
        for _, BombName in ipairs(BombNames) do
            local Bomb = Character:FindFirstChild(BombName)
            if Bomb then return true, Bomb end
            if Backpack then
                Bomb = Backpack:FindFirstChild(BombName)
                if Bomb then Bomb.Parent = Character task.wait(0.05) return true, Bomb end
            end
        end
        task.wait(0.2)
    end
    return false, nil
end

local function FastBombJump()
    if not IsPlayerInAir() then return end
    if OnCooldown or Debounce or JustRespawned then return end
    Debounce = true
    local Success, Bomb = GetAnyBomb()
    if Success and Bomb then
        local Position = GetCenterPosition()
        if Position then
            local Remote = Bomb:FindFirstChild("Remote")
            if Remote then
                PlaySound(Sounds.Click)
                pcall(function() Remote:FireServer(CFrame.new(Position), 50) end)
            end
            local Char = LocalPlayer.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if Root then
                local CurrentVelocity = Root.AssemblyLinearVelocity
                Root.AssemblyLinearVelocity = Vector3.new(CurrentVelocity.X, Config.LaunchPower, CurrentVelocity.Z)
            end
            MakeCharacterJump()
            task.spawn(function() task.wait(Config.EquipDelay) UnequipBomb() end)
            task.spawn(function() task.wait(0.1) StartCooldown() end)
        end
    end
    task.spawn(function() task.wait(0.5) Debounce = false end)
end

local function IsHoldingBomb()
    local Character = LocalPlayer.Character
    if not Character then return false end
    for _, BombName in ipairs(BombNames) do
        if Character:FindFirstChild(BombName) then return true end
    end
    return false
end

local ActiveTouches = {}
local TapMovementThreshold = 10
local TapTimeThreshold = 0.3

-- FIXED: Uses GiveTasks (PascalCase) to prevent the crash
BombJumpMaid:GiveTasks(
    Services.UserInputService.InputBegan:Connect(function(Input, Gp)
        if Gp then return end
        if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
            ActiveTouches[Input] = {StartPosition = Input.Position, StartTime = tick(), Moved = false}
        end
    end),
    Services.UserInputService.InputChanged:Connect(function(Input)
        local Data = ActiveTouches[Input]
        if Data and (Input.Position - Data.StartPosition).Magnitude > TapMovementThreshold then Data.Moved = true end
    end),
    Services.UserInputService.InputEnded:Connect(function(Input, Gp)
        if Gp then ActiveTouches[Input] = nil return end
        local Data = ActiveTouches[Input]
        if Data and not Data.Moved and tick() - Data.StartTime <= TapTimeThreshold then
            if BombJumpEnabled and not OnCooldown and not Debounce then
                if IsHoldingBomb() and IsPlayerInAir() then FastBombJump() end
            end
        end
        ActiveTouches[Input] = nil
    end),
    LocalPlayer.CharacterAdded:Connect(function()
        ResetCooldown()
        ActiveTouches = {}
        JustRespawned = true
        task.wait(1)
        JustRespawned = false
        if AutoGetBomb then
            task.wait(0.2)
            pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
            task.wait(0.1)
            UnequipBomb()
        end
    end)
)

Section:AddLabel("Bomb Jump Options")
Section:AddToggle("Enable Auto Bomb Jump", function(Bool) BombJumpEnabled = Bool end)

Section:AddToggle("Auto-Get Fake Bomb", function(Bool)
    AutoGetBomb = Bool
    if Bool then
        pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
        task.wait(0.1)
        UnequipBomb()
    end
end)

Section:AddToggle("Enable BJ Big Button", function(E)
    if E then
        AddBigButton("bombjump_big", "Bomb Jump", FastBombJump, false)
        local Btn = BBSystem.Buttons["bombjump_big"]
        if Btn then Btn.Size = __UD2(0, BigButtonSize, 0, BigButtonSize * 0.375) end
    else
        DeleteBigButton("bombjump_big")
    end
end)

Section:AddSlider("BJ Big Button Size", 50, 300, Config.DefaultSize, function(Value)
    BigButtonSize = Value
    local Btn = BBSystem.Buttons["bombjump_big"]
    if Btn then Btn.Size = __UD2(0, BigButtonSize, 0, BigButtonSize * 0.375) end
end)

Section:AddToggle("Enable BJ Bind Button", function(E)
    if E then
        AddBButton("bombjump_bind", "BJ", FastBombJump, false)
        BjBindButton = BindableButtons.Buttons["bombjump_bind"]
        if BjBindButton then
            local Screen = Services.Workspace.CurrentCamera.ViewportSize
            BjBindButton.Size = __UD2(BindButtonSize * (Screen.Y / Screen.X), 0, BindButtonSize, 0)
            UpdateBButtonText("bombjump_bind", OnCooldown and "Wait" or "BJ", OnCooldown, false)
        end
    else
        DeleteBButton("bombjump_bind")
        BjBindButton = nil
    end
end)

Section:AddSlider("BJ Bind Button Size", 5, 25, 11, function(Value)
    BindButtonSize = Value / 100
    if BjBindButton then
        local Screen = Services.Workspace.CurrentCamera.ViewportSize
        BjBindButton.Size = __UD2(BindButtonSize * (Screen.Y / Screen.X), 0, BindButtonSize, 0)
    end
end)

Section:AddKeybind("Bomb Jump Keybind", "E", FastBombJump)
