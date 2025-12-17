-- Dependencies
local OthersModules = script.Parent.Other
local Janitor = require(game.ReplicatedStorage.Libraries.Janitor)
local Signals = require(OthersModules.Signals)
local States = require(OthersModules.States)
local SimplePath = require(script.Parent.SimplePath)

-- Animations
local Conversation = Instance.new("Animation")
Conversation.AnimationId = 'rbxassetid://138410948609968'
local ServerAlive = true
-- Constructor
local Controller = {
    SimplePath = SimplePath,
        
    
    AutoCompletInvalidArguments = true,
    BehaviorErrorTag = "[Npc Controller:] %s !",
    
    DefaultSettings = {
        CanFollowPlayer = false,
        VisibleArea = false,
        CanHitPlayer = false,
        LoadAnimations = true,
        
        HumanoidSettings = {
            RunAfterDamage = true,
            
            WalkSpeed = 10,
            RunSpeed = 18,
            MaxHealth = 100,
            RunDuration = 5,
            
        },
        
        SpawPoint = nil :: Vector3,
        SpawnDelay = 5,
    }
}

local function output(mensage: string, level: number?)
    error(Controller.BehaviorErrorTag:format(mensage), level or 0)
end

local function mount<v>(base: v)
    for index, value in Controller.DefaultSettings do 
        if not base[index] then
            base[index] = value
        end
    end
    
    return base
end

function Controller.GetSettings()
    return table.clone(Controller.DefaultSettings) :: Settings
end

function Controller.Create(Settings: Settings, Body: Model)
    assert(Settings, `invalid settings.`)
    assert(typeof(Settings) == "table", `table expected, got {typeof(Settings)}`)
    assert(Body, `Invalid body paramter<model?>`)
    
    local Humanoid = Body:FindFirstChildOfClass("Humanoid") :: Humanoid
    if not Humanoid then output("Humanoid expected on Character Body", 1) end  
    local Animator = Humanoid:FindFirstChild("Animator")
    
    local controller = {
        Settings = if Controller.AutoCompleteInvalidArguments then mount(Settings) else Settings,
        Character = Body,
        Humanoid = Humanoid,
        Animator = Animator,
        CharacterState = States.new("Standed"),
        Cleanup = Janitor.new()
	}
	
	if Body.Name == "Wizard" or Body.Name == "Mage" then
		warn(Settings)
	end	
	
    controller.Humanoid.MaxHealth = Settings.HumanoidSettings.MaxHealth
    controller.Humanoid.Health = Settings.HumanoidSettings.MaxHealth
    
    setmetatable(controller, {
        __index = Controller,
    })
    
    controller.Cleanup:Add(task.defer(function()
        while task.wait(1/30) do
			if not ServerAlive then return end
			if not controller.Character.PrimaryPart then return end
            if not controller.Character.PrimaryPart:CanSetNetworkOwnership() then continue end
            
            if controller.Character.PrimaryPart:GetNetworkOwner() then
                controller.Character.PrimaryPart:SetNetworkOwner(nil)
            end
        end
    end))
        
    controller.Humanoid.WalkSpeed = Settings.HumanoidSettings.WalkSpeed
    
    return controller
end

function Controller:MoveTo(position: Vector3)
    local Humanoid: Humanoid = self.Humanoid
    
    Humanoid:MoveTo(position)
end

function Controller:Setup()
    for _, object in self do
        if typeof(object) == "table" then continue end
        
        if typeof(object) == "Instance" then self.Cleanup:Add(object) end
    end
end

function Controller:StopTalking()
    if self.awaitingResponseThread then
        pcall(function()
            task.cancel(self.awaitingResponseThread)
        end)
    end
    
    if self.TalkingAnimation then
        self.TalkingAnimation:Stop()
    end
    
    self.Character.PrimaryPart.Anchored = false
    self.Path:Run(self.Target)
    self.IsTalking = false
    
    local _talkingUser = game.Players:FindFirstChild(self.Character:GetAttribute("TalkingTarget"))
    
    if _talkingUser then
        _talkingUser:RemoveTag("Talking") end
    
    self.Character:SetAttribute("TalkingTarget", nil)
end

function Controller:TalkWith(Player: Player)
    if self.IsTalking or Player:HasTag("Talking") then
        return false, `{self.IsTalking} {Player:HasTag("Talking")}`
    end
    
    local playerRoot = Player.Character.PrimaryPart
    
    if (self.Character.PrimaryPart.Position - playerRoot.Position).Magnitude > 10 then return false, "Player to distant" end
    
    self.StartTalking = os.clock()
    self.PlayerTarget = Player
    self.TalkingAnimation = self.Humanoid:LoadAnimation(Conversation)
    self.TalkingAnimation:Play(.1)
    self.Character:SetAttribute("TalkingTarget", Player.Name)
    Player:AddTag("Talking")
	
    self.awaitingResponseThread = task.spawn(function()
        self.Path:Stop()
        self.Character.PrimaryPart.Anchored = true
        local characterPosition = self.Character.PrimaryPart.Position
        local targetPosition = Player.Character.PrimaryPart.Position
        targetPosition = Vector3.new(targetPosition.X, characterPosition.Y, targetPosition.Z)
        
        self.Character.PrimaryPart.CFrame = CFrame.lookAt(characterPosition, targetPosition)
        self.IsTalking = true
        
        while (os.clock() - self.StartTalking) < 10 and (self.Character.PrimaryPart.Position - playerRoot.Position).Magnitude < 10 do
            task.wait()
        end
        
        self.Character.PrimaryPart.Anchored = false
        self.IsTalking = false
        
        self:StopTalking()
        Player:RemoveTag("Talking")
        self.Path:Run(self.Target)
    end)
    
    return true
end

function Controller:Cleanup()
    local janitor = self.Cleanup :: typeof(Janitor.new())
    janitor:Cleanup()
end

game:BindToClose(function()
    ServerAlive = false
end)

export type Settings = typeof(Controller.DefaultSettings)

return Controller