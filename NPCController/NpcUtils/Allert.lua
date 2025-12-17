local ReplicatedStorage = game.ReplicatedStorage
local Remotes = ReplicatedStorage.Remotes.Fight

local TweenService = game.TweenService

return function(owner: Model, target: Humanoid)
    
    if owner:GetAttribute("LastWarnAllert") then
        local duration = (os.clock() - owner:GetAttribute("LastWarnAllert"))
        
        if duration <= 40 then
            return false, "timer to small"
        end
    end
	
	local Head = owner:FindFirstChild("Head") or owner:FindFirstChild("HumanoidRootPart")
    local Warn = ReplicatedStorage.Assets.Combat.WarnVFX:Clone()
    Warn.Parent = owner
    Warn.Anchored = true
    Warn.CanCollide = false
    Warn.CanQuery = false
	Warn.CFrame = Head.CFrame * CFrame.new(0,2,0)
    Warn.Warning:Play()
	
    for _, particle in Warn:GetDescendants() do
        if particle:IsA("ParticleEmitter") then
            particle:Emit(particle:GetAttribute("EmitCount") or 1)
        end
    end
    
    owner:SetAttribute("LastWarnAllert", os.clock())
    task.delay(4, Warn.Destroy, Warn)
end
