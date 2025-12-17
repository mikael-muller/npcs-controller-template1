local ReplicatedStorage = game.ReplicatedStorage
local Remotes = ReplicatedStorage.Remotes.Fight

local TweenService = game.TweenService

return function(owner: Model, target: Humanoid, targetCharacter: Model)
    if (targetCharacter.HumanoidRootPart.Position - owner.HumanoidRootPart.Position).Magnitude > 5 then return  end
    
    if target.Parent ~= targetCharacter then return end
    if owner == targetCharacter then return end
    
    targetCharacter.HumanoidRootPart.Anchored = true
    owner.HumanoidRootPart.Anchored = true
    
	TweenService:Create(targetCharacter.HumanoidRootPart, TweenInfo.new(.25,Enum.EasingStyle.Back), {
		CFrame = targetCharacter.HumanoidRootPart.CFrame + Vector3.new(0,15,0)
	}):Play()
    
    task.wait(.25)
    owner:SetAttribute("IsOnAir", true)   
	Remotes.Effect:FireAllClients("UpperCut", targetCharacter.HumanoidRootPart.CFrame)
	
	local rotation = owner.HumanoidRootPart.CFrame.Rotation
	
	local _t = TweenService:Create(owner.HumanoidRootPart, TweenInfo.new(.15,Enum.EasingStyle.Back), {
		CFrame = CFrame.new(targetCharacter.HumanoidRootPart.Position) * rotation *  CFrame.new(0,0,3)
    })
    
    _t:Play()
	_t.Completed:Wait()   
    
    owner.HumanoidRootPart.CFrame = CFrame.lookAt(
        owner.HumanoidRootPart.Position,
        targetCharacter.HumanoidRootPart.Position
    )
    
    task.delay(1.5, function()
        owner:SetAttribute("IsOnAir", false)
        targetCharacter.HumanoidRootPart.Anchored = false
        owner.HumanoidRootPart.Anchored = false
    end)

    return
end
