-- visuals.lua
-- FPS Boost: оптимизация графики для повышения FPS
local function FPSBoost()
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") then
            effect.Enabled = false
        end
    end
    -- Дополнительно можно выставить cap FPS, если такая функция доступна:
    if setfpscap then
        setfpscap(60)
    end

    local Terrain = workspace.Terrain
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0
end

FPSBoost()

-- All Neon Glow: перебор всех BasePart и установка материала Neon
local function ApplyNeonGlow()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Neon
            -- При желании можно задать единый неоновый цвет:
            -- obj.Color = Color3.fromRGB(0, 170, 255)
        end
    end
end

ApplyNeonGlow()

-- 3D Jump Circles: создаёт неоновый круг при прыжке
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function CreateJumpCircle(position)
    local circle = Instance.new("Part")
    circle.Anchored = true
    circle.CanCollide = false
    circle.Transparency = 0.5
    circle.Material = Enum.Material.Neon
    circle.Color = Color3.new(1, 1, 0) -- Жёлтый цвет
    circle.Shape = Enum.PartType.Cylinder
    circle.Size = Vector3.new(1, 0.2, 1)
    -- Размещаем плоскость круга горизонтально:
    circle.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
    circle.Parent = workspace

    -- Эффект расширения и исчезания (Tween-подобный эффект)
    local tweenTime = 1.5
    local initialSize = circle.Size
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed < tweenTime then
            local scale = 1 + (5 - 1) * (elapsed / tweenTime)
            circle.Size = Vector3.new(initialSize.X * scale, initialSize.Y, initialSize.Z * scale)
            circle.Transparency = 0.5 + 0.5 * (elapsed / tweenTime)
        else
            connection:Disconnect()
            circle:Destroy()
        end
    end)
end

-- Отслеживание прыжков персонажа
local function OnCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                CreateJumpCircle(root.Position)
            end
        end
    end)
end

if LocalPlayer.Character then
    OnCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- Movement History 3D Line: запись позиций и отрисовка линии истории перемещений
local lastPositions = {}
local maxHistory = 50  -- Максимальное число сохранённых позиций
local historyFolder = Instance.new("Folder", workspace)
historyFolder.Name = "MovementHistoryLines"

-- Запись текущей позиции персонажа
local function RecordMovement()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        table.insert(lastPositions, hrp.Position)
        if #lastPositions > maxHistory then
            table.remove(lastPositions, 1)
        end
    end
end

-- Создание 3D линии между двумя точками с помощью Beam
local function CreateBeam(fromPos, toPos)
    local part0 = Instance.new("Part")
    part0.Name = "BeamPart"
    part0.Size = Vector3.new(0.2, 0.2, 0.2)
    part0.Transparency = 1
    part0.Anchored = true
    part0.CanCollide = false
    part0.Parent = historyFolder

    local part1 = part0:Clone()
    part1.Parent = historyFolder

    part0.CFrame = CFrame.new(fromPos)
    part1.CFrame = CFrame.new(toPos)

    local attachment0 = Instance.new("Attachment", part0)
    local attachment1 = Instance.new("Attachment", part1)

    local beam = Instance.new("Beam", part0)
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.FaceCamera = true
    beam.Width0 = 0.5
    beam.Width1 = 0.5
    beam.LightEmission = 1
    beam.Color = ColorSequence.new(Color3.new(0, 1, 1)) -- Голубой цвет
    beam.Transparency = NumberSequence.new(0)
    beam.Parent = part0

    -- Удаляем через несколько секунд, чтобы не засорять игру
    game:GetService("Debris"):AddItem(part0, 3)
    game:GetService("Debris"):AddItem(part1, 3)
end

RunService.RenderStepped:Connect(function()
    RecordMovement()
    -- Рисуем линии между последовательно записанными позициями
    for i = 1, #lastPositions - 1 do
        CreateBeam(lastPositions[i], lastPositions[i + 1])
    end
end)

print("visuals.lua загружен!")