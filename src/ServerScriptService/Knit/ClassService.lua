-- src/ServerScriptService/Knit/ClassService.lua
-- Morph players into published class models by AssetId, clone default Animate scripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local InsertService     = game:GetService("InsertService")
local StarterPlayer     = game:GetService("StarterPlayer")
local Workspace         = game:GetService("Workspace")

local Knit      = require(ReplicatedStorage.Knit.Knit)
local ClassDefs = require(ReplicatedStorage.SharedModules.ClassDefinitions)
local AssetMap  = require(ReplicatedStorage.ClassModelAssets)

local ClassService = Knit.CreateService {
    Name = "ClassService",
    Client = {
        SelectClass = function() end,
    },
}

function ClassService:KnitInit()
    -- build sorted list of class names
    self.available = {}
    for name in pairs(ClassDefs) do
        table.insert(self.available, name)
    end
    table.sort(self.available)
    self._conns = {}
end

function ClassService:KnitStart()
    -- cache DataService once Knit is live
    self.DataService = Knit.GetService("DataService")
end

function ClassService.Client:SelectClass(player, className)
    local service = self.Server
    if not table.find(service.available, className) then
        return false
    end

    -- save selection
    local prof = service.DataService.Profiles[player]
    if prof then
        prof.Data.selectedClass = className
    end

    -- hook spawn once
    if not service._conns[player] then
        service._conns[player] = player.CharacterAdded:Connect(function(char)
            service:_onCharacterSpawn(player, char)
            service._conns[player]:Disconnect()
            service._conns[player] = nil
        end)
    end

    -- respawn to trigger morph
    player:LoadCharacter()
    return true
end

function ClassService:_onCharacterSpawn(player, oldChar)
    -- get chosen class
    local prof      = self.DataService.Profiles[player]
    local className = prof and prof.Data.selectedClass
    if not className then return end

    -- get asset ID
    local assetId = AssetMap[className]
    if not assetId then return end

    -- record spawn CFrame
    local root = oldChar.PrimaryPart or oldChar:FindFirstChild("HumanoidRootPart")
    local cf   = root and root.CFrame or CFrame.new(0,5,0)

    -- remove default avatar
    oldChar:Destroy()

    -- try InsertService
    local ok, folder = pcall(InsertService.LoadAsset, InsertService, assetId)
    local model = ok and folder and folder:FindFirstChildWhichIsA("Model")

    -- fallback to GetObjects
    if not model then
        local arr = game:GetObjects("rbxassetid://"..assetId)
        model = arr[1]:IsA("Model") and arr[1] or nil
    end
    if not model then return end

    -- position & parent
    model.Name = player.Name
    if model.PrimaryPart then
        model:SetPrimaryPartCFrame(cf)
    end
    model.Parent = Workspace
    player.Character = model

    -- clone Animate scripts so default animations run
    local scs = StarterPlayer:WaitForChild("StarterCharacterScripts")
    for _, script in ipairs(scs:GetChildren()) do
        script:Clone().Parent = model
    end

    -- apply base stats
    local stats   = ClassDefs[className].Stats or {}
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = stats.MaxHealth or humanoid.MaxHealth
        humanoid.Health    = humanoid.MaxHealth
        humanoid.WalkSpeed = stats.WalkSpeed or humanoid.WalkSpeed
        humanoid.JumpPower = stats.JumpPower or humanoid.JumpPower
    end
end

return ClassService
