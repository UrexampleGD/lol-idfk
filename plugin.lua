-- # Credits to @187 for the actual code
-- # This was just a fixed version with some improvement.
-- # If this thing has bugs, report it :)
-- # Have fun using this skidded thing!
-- # Your Welcome!

local table_insert = table.insert

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_tasks = {}, _destroyed = false}, Maid)
end

function Maid:GiveTask(task)
    if self._destroyed then self:_cleanupTask(task) return end
    table_insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)
    for _, task in ipairs({...}) do self:GiveTask(task) end
end

function Maid:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then task:Disconnect()
    elseif taskType == "Instance" then task:Destroy()
    elseif taskType == "function" then task()
    elseif taskType == "table" and type(task.Destroy) == "function" then task:Destroy() end
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do self:_cleanupTask(task) end
    self._tasks = {}
end

function Maid:Destroy() self:DoCleaning() end

local RootMaid = Maid.new()

local shared = odh_shared_plugins

task.spawn(function()
    pcall(function()
        shared.load_from_github_url("/aux0on/CrashHandler/refs/heads/main/Prevention.lua")
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

local saveButtonPositions = false
local POSITION_FILE = "bombjump_ui_positions.json"

local function LoadPositions()
    local ok, content = pcall(readfile, POSITION_FILE)
    if ok and content and content ~= "" then
        local decOk, data = pcall(function() return Services.HttpService:JSONDecode(content) end)
        if decOk and type(data) == "table" then return data end
    end
    return {}
end

local function SavePosition(id, pos)
    if not saveButtonPositions then return end
    local positions = LoadPositions()
    positions[id] = {XScale = pos.X.Scale, XOffset = pos.X.Offset, YScale = pos.Y.Scale, YOffset = pos.Y.Offset}
    pcall(function() writefile(POSITION_FILE, Services.HttpService:JSONEncode(positions)) end)
end

local function ApplySavedPosition(gui, id)
    if not saveButtonPositions then return end
    local p = LoadPositions()[id]
    if p then gui.Position = __UD2(p.XScale or 0, p.XOffset or 0, p.YScale or 0, p.YOffset or 0) end
end

local BBSystem = {Buttons = {}, Connections = {}}

local function bb_safecallback(callback)
    if not callback then return end
    xpcall(callback, function(e) return debug.traceback(e) end)
end

local function BB_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then parent = Services.CoreGui end
    if not parent or typeof(parent) ~= "Instance" then parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5) end
    if typeof(parent) ~= "Instance" then parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui") end
    local sg = parent:FindFirstChild("@BBStorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@BBStorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local __BB_GRAD_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __PCLR(0.0784314, 0.0784314, 0.0784314)),
    ColorSequenceKeypoint.new(0.75, __PCLR(0.0784314, 0.0784314, 0.54902)),
    ColorSequenceKeypoint.new(1, __PCLR(0.470588, 0.156863, 0.470588))
})

local function BB_MakeDraggable(gui, func, ripple, sound)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, hasMoved = true, false
            dragStart, startPos = input.Position, gui.Position
            __TS:Create(gui, tInfo, {Size = __UD2(0, 220, 0, 82.5), TextSize = 26.4}):Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            sound:Play()
            __TS:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 300, 0, 300), BackgroundTransparency = 1
            }):Play()
            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    __TS:Create(gui, tInfo, {Size = __UD2(0, 200, 0, 75), TextSize = 24}):Play()
                    if not hasMoved then bb_safecallback(func) end
                    SavePosition(gui.Name, gui.Position)
                    rel:Disconnect()
                end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    __UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            gui.Position = __UD2(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local muteButtonSounds = false

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for _, btn in pairs(BBSystem.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then sound.Volume = volume end
    end
    for _, btn in pairs(BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then sound.Volume = volume end
    end
end

local function AddBigButton(id, text, func, isGold)
    if BBSystem.Buttons[id] then return end
    local storage = BB_GetStorage()
    local bb = Instance.new("TextButton")
    bb.Name = id
    bb.Size = __UD2(0, 200, 0, 75)
    bb.Position = __UD2(0.5, 0, 0.5, 0)
    bb.AnchorPoint = __V2(0.5, 0.5)
    bb.BackgroundColor3 = __RGB(255, 255, 255)
    bb.BackgroundTransparency = 0.9
    bb.BorderSizePixel = 0
    bb.Font = Enum.Font.Jura
    bb.Text = text
    bb.TextSize = 24
    bb.TextColor3 = __RGB(255, 255, 255)
    bb.TextWrapped = true
    bb.ClipsDescendants = true
    bb.AutoButtonColor = false
    bb.ZIndex = 5
    bb.Parent = storage

    Instance.new("UICorner", bb).CornerRadius = __UD(0, 5)
    local stroke = Instance.new("UIStroke")
    stroke.Color = __RGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bb
    local gradient = Instance.new("UIGradient")
    gradient.Color = isGold and ColorSequence.new({
        ColorSequenceKeypoint.new(0, __RGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.5, __RGB(255, 140, 0)),
        ColorSequenceKeypoint.new(1, __RGB(184, 134, 11))
    }) or __BB_GRAD_SEQ
    gradient.Parent = stroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.ZIndex = 4
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.Parent = bb
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = bb

    BB_MakeDraggable(bb, func, ripple, sound)
    BBSystem.Connections[id] = __RS.RenderStepped:Connect(function()
        gradient.Rotation = (gradient.Rotation + 1) % 360
    end)
    BBSystem.Buttons[id] = bb
    ApplySavedPosition(bb, id)
    return bb
end

local function DeleteBigButton(id)
    if BBSystem.Buttons[id] then
        if BBSystem.Connections[id] then
            BBSystem.Connections[id]:Disconnect()
            BBSystem.Connections[id] = nil
        end
        BBSystem.Buttons[id]:Destroy()
        BBSystem.Buttons[id] = nil
    end
end

local BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local __SHAPES = {[0] = "rbxassetid://86221076925479"}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __PCLR(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1, __PCLR(0.501961, 0.501961, 0.501961))
})

local __WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __PCLR(0.827451, 0.133333, 0.133333)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.509804, 0.231373, 0.231373)),
    ColorSequenceKeypoint.new(1, __PCLR(0.501961, 0.501961, 0.501961))
})

local __GOLD_NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __RGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(255, 140, 0)),
    ColorSequenceKeypoint.new(1, __RGB(184, 134, 11))
})

local __GOLD_WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, __RGB(255, 69, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(139, 69, 19)),
    ColorSequenceKeypoint.new(1, __RGB(160, 82, 45))
})

local function bind_safecallback(callback)
    if not callback then return end
    xpcall(callback, function(e) return debug.traceback(e) end)
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then parent = Services.CoreGui end
    if not parent or typeof(parent) ~= "Instance" then parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5) end
    if typeof(parent) ~= "Instance" then parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui") end
    local sg = parent:FindFirstChild("@bindstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@bindstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    maid:GiveTask(gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45), BackgroundTransparency = 1
            }):Play()
            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then bind_safecallback(clickFunc) end
                    SavePosition(gui.Name, gui.Position)
                    rel:Disconnect()
                end
            end)
        end
    end))

    maid:GiveTask(gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    maid:GiveTask(__UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

local function AddBButton(id, text, clickFunc, isGold)
    if BindableButtons.Buttons[id] then return end

    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = __SHAPES[0]
    ImageButton.BackgroundTransparency = 1
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Jura
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 10
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("UIGradient", ImageButton)
    Stroke.Name = "@Stroke"
    Stroke.Color = isGold and __GOLD_NORMAL_COLOR or __NORMAL_COLOR

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)
    buttonMaid:GiveTask(__RS.RenderStepped:Connect(function()
        Stroke.Rotation = (Stroke.Rotation + 1) % 360
    end))

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    ApplySavedPosition(ImageButton, id)
    return ImageButton
end

local function DeleteBButton(id)
    if BindableButtons.Maids[id] then
        BindableButtons.Maids[id]:Destroy()
        BindableButtons.Maids[id] = nil
        BindableButtons.Buttons[id] = nil
    end
end

local function UpdateBButtonText(id, text, isWaiting, isGold)
    local btn = BindableButtons.Buttons[id]
    if not btn then return end
    local textLabel = btn:FindFirstChild("@Text")
    if textLabel then textLabel.Text = text end
    local stroke = btn:FindFirstChild("@Stroke")
    if stroke then
        if isGold then stroke.Color = isWaiting and __GOLD_WAIT_COLOR or __GOLD_NORMAL_COLOR
        else stroke.Color = isWaiting and __WAIT_COLOR or __NORMAL_COLOR end
    end
end

local BombJump = shared.CreateTab("Bomb Jump+", "/aux0on/BJPIcon/refs/heads/main/Untitled163_20260918201001")

local aboutSection = BombJump:AddSection("About", "Information")

aboutSection:AddParagraph("Bomb Jump+", "Plugin Made by @lzzzx")

aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

aboutSection:AddToggle("Save Button Position", function(bool)
    saveButtonPositions = bool
    if bool then
        for id, btn in pairs(BBSystem.Buttons) do ApplySavedPosition(btn, id) end
        for id, btn in pairs(BindableButtons.Buttons) do ApplySavedPosition(btn, id) end
    end
end)

pcall(function() shared.Notify("Bomb Jump+ Loaded", 2) end)

local section = BombJump:AddSection("Bomb Jump+", "MM2 / MMV")

local CONFIG = {
    CooldownTime = 22.0,
    LaunchPower = 58,
    DefaultSize = 90,
    EquipDelay = 0.6
}

local bombJumpEnabled = false
local onCooldown = false
local debounce = false
local autoGetBomb = false
local justRespawned = false
local bigButtonSize = CONFIG.DefaultSize
local bindButtonSize = 0.11
local bjBindButton = nil

local BOMB_NAMES = {"FakeBomb"}

local BombJumpMaid = Maid.new()
RootMaid:GiveTask(BombJumpMaid)

local Sounds = {Click = Instance.new("Sound"), Cooldown = Instance.new("Sound")}
Sounds.Click.SoundId = "rbxassetid://6895079853"
Sounds.Click.Volume = 1.0
Sounds.Cooldown.SoundId = "rbxassetid://138090596"
Sounds.Cooldown.Volume = 1.0

local function PlaySound(snd)
    pcall(function() if snd then Services.SoundService:PlayLocalSound(snd) end end)
end

local function IsPlayerInAir()
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Freefall then
        return true
    end
    return math.abs(rootPart.Velocity.Y) > 0.5
end

local function ResetCooldown()
    onCooldown = false
    local bigBtn = BBSystem.Buttons["bombjump_big"]
    if bigBtn then bigBtn.Text = "Bomb Jump" end
    if bjBindButton then UpdateBButtonText("bombjump_bind", "BJ", false, false) end
end

local function StartCooldown()
    onCooldown = true
    debounce = false
    local bigBtn = BBSystem.Buttons["bombjump_big"]
    if bigBtn then bigBtn.Text = "Wait" end
    if bjBindButton then UpdateBButtonText("bombjump_bind", "Wait", true, false) end
    task.spawn(function()
        for i = CONFIG.CooldownTime, 1, -1 do
            if not onCooldown then break end
            local bigBtn = BBSystem.Buttons["bombjump_big"]
            if bigBtn then bigBtn.Text = tostring(i) end
            if bjBindButton then UpdateBButtonText("bombjump_bind", tostring(i), true, false) end
            task.wait(1)
        end
        if onCooldown then ResetCooldown() end
    end)
end

local function GetCenterPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local camera = Services.Workspace.CurrentCamera
        return character.HumanoidRootPart.Position + (camera.CFrame.LookVector * 5)
    end
    return nil
end

local function MakeCharacterJump()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end

local function UnequipBomb()
    task.spawn(function()
        local character = LocalPlayer.Character
        if character then
            for _, bombName in ipairs(BOMB_NAMES) do
                local bomb = character:FindFirstChild(bombName)
                if bomb then bomb.Parent = LocalPlayer.Backpack or character break end
            end
        end
    end)
end

local function GetAnyBomb()
    local character = LocalPlayer.Character
    if not character then return false, nil end
    for _, bombName in ipairs(BOMB_NAMES) do
        local bomb = character:FindFirstChild(bombName)
        if bomb then return true, bomb end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, bombName in ipairs(BOMB_NAMES) do
            local bomb = backpack:FindFirstChild(bombName)
            if bomb then bomb.Parent = character task.wait(0.05) return true, bomb end
        end
    end
    for attempt = 1, 3 do
        pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
        task.wait(0.1)
        for _, bombName in ipairs(BOMB_NAMES) do
            local bomb = character:FindFirstChild(bombName)
            if bomb then return true, bomb end
            if backpack then
                bomb = backpack:FindFirstChild(bombName)
                if bomb then bomb.Parent = character task.wait(0.05) return true, bomb end
            end
        end
        task.wait(0.2)
    end
    return false, nil
end

local function FastBombJump()
    if not IsPlayerInAir() then return end
    if onCooldown or debounce or justRespawned then return end
    debounce = true
    local success, bomb = GetAnyBomb()
    if success and bomb then
        local position = GetCenterPosition()
        if position then
            local remote = bomb:FindFirstChild("Remote")
            if remote then
                PlaySound(Sounds.Click)
                pcall(function() remote:FireServer(CFrame.new(position), 50) end)
            end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local currentVelocity = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, CONFIG.LaunchPower, currentVelocity.Z)
            end
            MakeCharacterJump()
            task.spawn(function() task.wait(CONFIG.EquipDelay) UnequipBomb() end)
            task.spawn(function() task.wait(0.1) StartCooldown() end)
        end
    end
    task.spawn(function() task.wait(0.5) debounce = false end)
end

local function IsHoldingBomb()
    local character = LocalPlayer.Character
    if not character then return false end
    for _, bombName in ipairs(BOMB_NAMES) do
        if character:FindFirstChild(bombName) then return true end
    end
    return false
end

local activeTouches = {}
local TAP_MOVEMENT_THRESHOLD = 10
local TAP_TIME_THRESHOLD = 0.3

BombJumpMaid:GiveTasks(
    Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeTouches[input] = {startPosition = input.Position, startTime = tick(), moved = false}
        end
    end),
    Services.UserInputService.InputChanged:Connect(function(input)
        local data = activeTouches[input]
        if data and (input.Position - data.startPosition).Magnitude > TAP_MOVEMENT_THRESHOLD then data.moved = true end
    end),
    Services.UserInputService.InputEnded:Connect(function(input, gp)
        if gp then activeTouches[input] = nil return end
        local data = activeTouches[input]
        if data and not data.moved and tick() - data.startTime <= TAP_TIME_THRESHOLD then
            if bombJumpEnabled and not onCooldown and not debounce then
                if IsHoldingBomb() and IsPlayerInAir() then FastBombJump() end
            end
        end
        activeTouches[input] = nil
    end),
    LocalPlayer.CharacterAdded:Connect(function()
        ResetCooldown()
        activeTouches = {}
        justRespawned = true
        task.wait(1)
        justRespawned = false
        if autoGetBomb then
            task.wait(0.2)
            pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
            task.wait(0.1)
            UnequipBomb()
        end
    end)
)

section:AddLabel("Bomb Jump Options")
section:AddToggle("Enable Auto Bomb Jump", function(bool) bombJumpEnabled = bool end)

section:AddToggle("Auto-Get Fake Bomb", function(bool)
    autoGetBomb = bool
    if bool then
        pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
        task.wait(0.1)
        UnequipBomb()
    end
end)

section:AddToggle("Enable BJ Big Button", function(e)
    if e then
        AddBigButton("bombjump_big", "Bomb Jump", FastBombJump, false)
        local btn = BBSystem.Buttons["bombjump_big"]
        if btn then btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375) end
    else
        DeleteBigButton("bombjump_big")
    end
end)

section:AddSlider("BJ Big Button Size", 50, 300, CONFIG.DefaultSize, function(value)
    bigButtonSize = value
    local btn = BBSystem.Buttons["bombjump_big"]
    if btn then btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375) end
end)

section:AddToggle("Enable BJ Bind Button", function(e)
    if e then
        AddBButton("bombjump_bind", "BJ", FastBombJump, false)
        bjBindButton = BindableButtons.Buttons["bombjump_bind"]
        if bjBindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            bjBindButton.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
            UpdateBButtonText("bombjump_bind", onCooldown and "Wait" or "BJ", onCooldown, false)
        end
    else
        DeleteBButton("bombjump_bind")
        bjBindButton = nil
    end
end)

section:AddSlider("BJ Bind Button Size", 5, 25, 11, function(value)
    bindButtonSize = value / 100
    if bjBindButton then
        local screen = Services.Workspace.CurrentCamera.ViewportSize
        bjBindButton.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
    end
end)

section:AddKeybind("Bomb Jump Keybind", "E", FastBombJump)

local gbjSection = BombJump:AddSection("Gold Bomb Jump+", "MMV")

local gbjOnCooldown = false
local goldBombJumpEnabled = false
local gbjDebounce = false
local autoGetGoldBomb = false
local gbjJustRespawned = false
local gbjBigButtonSize = 200
local gbjBindButtonSize = 0.11
local gbjBindButton = nil

local GOLD_BOMB_NAMES = {"GoldFakeBomb", "GoldBomb"}

local GoldBombJumpMaid = Maid.new()
RootMaid:GiveTask(GoldBombJumpMaid)

local function GBJResetCooldown()
    gbjOnCooldown = false
    local bigBtn = BBSystem.Buttons["goldbombjump_big"]
    if bigBtn then bigBtn.Text = "Gold Bomb Jump" end
    if gbjBindButton then UpdateBButtonText("goldbombjump_bind", "GBJ", false, true) end
end

local function GBJStartCooldown()
    gbjOnCooldown = true
    gbjDebounce = false
    local bigBtn = BBSystem.Buttons["goldbombjump_big"]
    if bigBtn then bigBtn.Text = "Wait" end
    if gbjBindButton then UpdateBButtonText("goldbombjump_bind", "Wait", true, true) end
    task.spawn(function()
        for i = 9, 1, -1 do
            if not gbjOnCooldown then break end
            local bigBtn = BBSystem.Buttons["goldbombjump_big"]
            if bigBtn then bigBtn.Text = tostring(i) end
            if gbjBindButton then UpdateBButtonText("goldbombjump_bind", tostring(i), true, true) end
            task.wait(1)
        end
        if gbjOnCooldown then GBJResetCooldown() end
    end)
end

local function GBJGetCenterPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local camera = Services.Workspace.CurrentCamera
        return character.HumanoidRootPart.Position + (camera.CFrame.LookVector * 5)
    end
    return nil
end

local function GBJMakeCharacterJump()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end

local function UnequipGoldBomb()
    task.spawn(function()
        local character = LocalPlayer.Character
        if character then
            for _, goldName in ipairs(GOLD_BOMB_NAMES) do
                local bomb = character:FindFirstChild(goldName)
                if bomb then bomb.Parent = LocalPlayer.Backpack or character break end
            end
        end
    end)
end

local function GetAnyGoldBomb()
    local character = LocalPlayer.Character
    if not character then return false, nil end
    for _, goldName in ipairs(GOLD_BOMB_NAMES) do
        local bomb = character:FindFirstChild(goldName)
        if bomb then return true, bomb end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, goldName in ipairs(GOLD_BOMB_NAMES) do
            local bomb = backpack:FindFirstChild(goldName)
            if bomb then bomb.Parent = character task.wait(0.05) return true, bomb end
        end
    end
    for attempt = 1, 3 do
        for _, goldName in ipairs(GOLD_BOMB_NAMES) do
            pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(goldName) end)
        end
        task.wait(0.1)
        for _, goldName in ipairs(GOLD_BOMB_NAMES) do
            local bomb = character:FindFirstChild(goldName)
            if bomb then return true, bomb end
            if backpack then
                bomb = backpack:FindFirstChild(goldName)
                if bomb then bomb.Parent = character task.wait(0.05) return true, bomb end
            end
        end
        task.wait(0.2)
    end
    return false, nil
end

local function FastGoldBombJump()
    if not IsPlayerInAir() then return end
    if gbjOnCooldown or gbjDebounce or gbjJustRespawned then return end
    gbjDebounce = true
    local success, bomb = GetAnyGoldBomb()
    if success and bomb then
        local position = GBJGetCenterPosition()
        if position then
            local remote = bomb:FindFirstChild("Remote")
            if remote then
                PlaySound(Sounds.Click)
                pcall(function() remote:FireServer(CFrame.new(position), 50) end)
            end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local currentVelocity = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, CONFIG.LaunchPower, currentVelocity.Z)
            end
            GBJMakeCharacterJump()
            task.spawn(function() task.wait(CONFIG.EquipDelay) UnequipGoldBomb() end)
            task.spawn(function() task.wait(0.1) GBJStartCooldown() end)
        end
    end
    task.spawn(function() task.wait(0.5) gbjDebounce = false end)
end

local function IsHoldingGoldBomb()
    local character = LocalPlayer.Character
    if not character then return false end
    for _, goldName in ipairs(GOLD_BOMB_NAMES) do
        if character:FindFirstChild(goldName) then return true end
    end
    return false
end

local gbjActiveTouches = {}

GoldBombJumpMaid:GiveTasks(
    Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            gbjActiveTouches[input] = {startPosition = input.Position, startTime = tick(), moved = false}
        end
    end),
    Services.UserInputService.InputChanged:Connect(function(input)
        local data = gbjActiveTouches[input]
        if data and (input.Position - data.startPosition).Magnitude > TAP_MOVEMENT_THRESHOLD then data.moved = true end
    end),
    Services.UserInputService.InputEnded:Connect(function(input, gp)
        if gp then gbjActiveTouches[input] = nil return end
        local data = gbjActiveTouches[input]
        if data and not data.moved and tick() - data.startTime <= TAP_TIME_THRESHOLD then
            if goldBombJumpEnabled and not gbjOnCooldown and not gbjDebounce then
                if IsHoldingGoldBomb() and IsPlayerInAir() then FastGoldBombJump() end
            end
        end
        gbjActiveTouches[input] = nil
    end),
    LocalPlayer.CharacterAdded:Connect(function()
        GBJResetCooldown()
        gbjActiveTouches = {}
        gbjJustRespawned = true
        task.wait(1)
        gbjJustRespawned = false
        if autoGetGoldBomb then
            task.wait(0.2)
            for _, goldName in ipairs(GOLD_BOMB_NAMES) do
                pcall(function()
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(goldName)
                end)
            end
            task.wait(0.1)
            UnequipGoldBomb()
        end
    end)
)

gbjSection:AddLabel("Gold Bomb Jump Options")
gbjSection:AddToggle("Enable Auto Gold Bomb Jump", function(bool) goldBombJumpEnabled = bool end)

gbjSection:AddToggle("Auto-Get Gold Bomb", function(bool)
    autoGetGoldBomb = bool
    if bool then
        for _, goldName in ipairs(GOLD_BOMB_NAMES) do
            pcall(function()
                Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(goldName)
            end)
        end
        task.wait(0.1)
        UnequipGoldBomb()
    end
end)

gbjSection:AddToggle("Enable GBJ Big Button", function(e)
    if e then
        AddBigButton("goldbombjump_big", "Gold Bomb Jump", FastGoldBombJump, true)
        local btn = BBSystem.Buttons["goldbombjump_big"]
        if btn then btn.Size = __UD2(0, gbjBigButtonSize, 0, gbjBigButtonSize * 0.375) end
    else
        DeleteBigButton("goldbombjump_big")
    end
end)

gbjSection:AddSlider("GBJ Big Button Size", 50, 300, 200, function(value)
    gbjBigButtonSize = value
    local btn = BBSystem.Buttons["goldbombjump_big"]
    if btn then btn.Size = __UD2(0, gbjBigButtonSize, 0, gbjBigButtonSize * 0.375) end
end)

gbjSection:AddToggle("Enable GBJ Bind Button", function(e)
    if e then
        AddBButton("goldbombjump_bind", "GBJ", FastGoldBombJump, true)
        gbjBindButton = BindableButtons.Buttons["goldbombjump_bind"]
        if gbjBindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            gbjBindButton.Size = __UD2(gbjBindButtonSize * (screen.Y / screen.X), 0, gbjBindButtonSize, 0)
            UpdateBButtonText("goldbombjump_bind", gbjOnCooldown and "Wait" or "GBJ", gbjOnCooldown, true)
        end
    else
        DeleteBButton("goldbombjump_bind")
        gbjBindButton = nil
    end
end)

gbjSection:AddSlider("GBJ Bind Button Size", 5, 25, 11, function(value)
    gbjBindButtonSize = value / 100
    if gbjBindButton then
        local screen = Services.Workspace.CurrentCamera.ViewportSize
        gbjBindButton.Size = __UD2(gbjBindButtonSize * (screen.Y / screen.X), 0, gbjBindButtonSize, 0)
    end
end)

gbjSection:AddKeybind("Gold Bomb Jump Keybind", "G", FastGoldBombJump)
