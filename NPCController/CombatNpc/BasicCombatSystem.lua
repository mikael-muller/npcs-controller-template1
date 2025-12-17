local Replicated = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--Folders
local NpcUtilsFolder = script.Parent.Parent.NpcUtils
local NpcCustomAttacks = script.Parent.Parent.MoreAttackOptions
local PlayersCharacter = workspace:WaitForChild("PlayersCharacter")
local Remotes = Replicated.Remotes.Fight

--Modules
local Utils = require(NpcUtilsFolder.Utils)
local AllertAction = require(NpcUtilsFolder.Allert)
local Signals = require(Replicated.Modules.Other.Signals)
local Gameplay = require(Replicated.Modules.Gameplay)
local Raycast = require(Replicated.Modules.Raycast)
local UpperCut = require(NpcCustomAttacks.UpperCut)

--Str
local PendingTargets = {}
local CombatSystem = {}
CombatSystem.__index = CombatSystem

function CombatSystem:SetFollowTarget(targetHumanoid: Humanoid, isForced: boolean)
	if not PendingTargets[targetHumanoid.Parent] 
	then 
		PendingTargets[targetHumanoid.Parent] =
			{Npc = nil, InFocus = false, IsForced = isForced, OwnerHumanoid = targetHumanoid} 
	end
	
	if PendingTargets[targetHumanoid.Parent].InFocus and 
		self.Character ~= PendingTargets[targetHumanoid.Parent] and 
		self.Character.Parent == PendingTargets[targetHumanoid.Parent].Npc.Parent and 
		not isForced then return end
	if not isForced then PendingTargets[targetHumanoid.Parent] = {Npc = self.Character, InFocus = true, isForced = isForced} end 
	
	if self.Following then return end
	self.Following = true

	local spawnPoint: Vector3 = self.SpawnPoint
	local maxDistance = self.NpcActivationDistance or 100
	
	local target = targetHumanoid.RootPart
	local character = targetHumanoid.Parent
	local playerOwner = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	
	local Stun = self.Stun
	local LastAnimationPlay = self.LastHit
	
	if not playerOwner then
		return 
	end
	
	AllertAction(self.Character, self.Humanoid)
	
	local Step; Step = RunService.Heartbeat:Connect(function(deltaTimeSim: number) 
		if targetHumanoid.Health <= 0 then
			Step:Disconnect()
			Step = nil
			PendingTargets[targetHumanoid.Parent] = nil
			return
		end
		
		if self.Character:FindFirstChild("HumanoidRootPart") and (self.Character.HumanoidRootPart.Position - spawnPoint).Magnitude > 100 then
			PendingTargets[targetHumanoid.Parent] = {Npc = nil, InFocus = false, isForced = false} 
			self.Character:MoveTo(spawnPoint)
			Step:Disconnect()
			Step = nil
			return
		end
		
		if not self.Character or not self.Character.PrimaryPart then
			PendingTargets[targetHumanoid.Parent] = {Npc = nil, InFocus = false, isForced = false} 
			Step:Disconnect()
			Step = nil
			return
		end

		if self.Humanoid:GetState() == Enum.HumanoidStateType.Dead then 
			PendingTargets[targetHumanoid.Parent] = {Npc = nil, InFocus = false, isForced = false} 
			Step:Disconnect()
			Step = nil
			return 
		end
		
		if targetHumanoid:GetState() == Enum.HumanoidStateType.Dead then
			PendingTargets[targetHumanoid.Parent] = {Npc = nil, InFocus = false, isForced = false} 
			self.Humanoid:MoveTo(spawnPoint)
			Step:Disconnect()
			Step = nil
			return
		end
		
		if not Stun:Finished() then
			self.Humanoid.WalkSpeed = 0
			self.Character:SetAttribute("Stunned", true)
			return
		else
			self.Humanoid.WalkSpeed = self.Controller.DefaultSettings.HumanoidSettings.WalkSpeed
			self.Character:SetAttribute("Stunned", false)
		end
		
		local distance = (target.Position - self.Character.HumanoidRootPart.Position).Magnitude
		local spawnDistance = (self.Character.HumanoidRootPart.Position - self.SpawnPoint).Magnitude
		
		if distance > 5 and distance < 13 then
			if self.RunHumanoid then
				self.RunHumanoid:Stop()
			end
			
			self.Humanoid.AutoRotate = true
			self.Humanoid:MoveTo(target.Position)
		elseif distance > 13 then
			if self.RunHumanoid then
				self.RunHumanoid:Run()
			end
			self.Humanoid.AutoRotate = true
			self.Humanoid:MoveTo(target.Position)
			--self.Humanoid:Move((target.Position - self.Character.HumanoidRootPart.Position))
		elseif distance < 5 then
			if self.RunHumanoid then
				self.RunHumanoid:Stop()
			end
			self.Humanoid:Move(Vector3.zero)
		end
		
		if not target:IsDescendantOf(workspace) then 
			Step:Disconnect()
			Step = nil
			return 
		end
		
		if self.CanAttack and self.Stun:Finished() and not self.Character:GetAttribute("Stunned") and (self.Character.HumanoidRootPart.Position - target.Position).Magnitude <= 5 then
			PendingTargets[targetHumanoid.Parent] = {Npc = nil, isForced = false} 
			self:Attack(targetHumanoid)
		else
			--warn("Cant attack because", "Stun is not finished:", 
			--	self.Stun:Finished(), 
			--	"Distance to high:",  (self.Character.HumanoidRootPart.Position - target.Position).Magnitude)
		end
	end)
	
	while Step do
		task.wait(.0005)
	end

	if self.Humanoid:GetState() ~= "Dead" then
		if not self.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		--self.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
		self.Humanoid:MoveTo(spawnPoint)
		self.Following = false

		if self.Character.HumanoidRootPart and (self.Character.HumanoidRootPart.Position - spawnPoint).Magnitude > 100 then
			self.Character:MoveTo(spawnPoint)
		end
	end
end

function CombatSystem:GetNearestPlayerCharacter()
	assert(self.NpcActivationDistance, `Npc activation distance not setted.`)
	
	for _, character: Model in PlayersCharacter:GetChildren() do
		local rootPart: Part = character:FindFirstChild("HumanoidRootPart")
		if rootPart and Utils.Distance(rootPart, self.Character.PrimaryPart) <= self.NpcActivationDistance then
			return character
		end
	end
	
	return nil
end

local thinkingID = {}

function CombatSystem:ConfigureHitbox()
	self._hitBoxStatus = "Loaded"
	self.HitBox = Signals.new("HitboxOfAny")
	self.Loading = false
	
	self.StunSignal.Event:Connect(function()
		if not thinkingID[self.Character] then thinkingID[self.Character] = 0 end
		thinkingID[self.Character] += 1
	end)
	
	self.HitBox:connect(function(Humanoid: Humanoid)	
		if Utils.isDead(Humanoid) or self.Loading or (Humanoid.RootPart.Position - self.Character.PrimaryPart.Position).Magnitude > 6 then
			return
		end
		
		if Humanoid.Parent:HasTag("Invulnerable") then
			return
		end
		
		local _, Player = pcall(function()
			return Players:GetPlayerFromCharacter(Humanoid:FindFirstAncestorOfClass("Model"))
		end)

		if not Player then return end
		local PlayerCharacter = Humanoid.Parent :: Model

		if Gameplay:SkillCounter(Player, self.Character) then return end
		
		if (PlayerCharacter:GetAttribute("TimeDodge") or 0) > 0 then
			return PlayerCharacter:SetAttribute("TimeDodge", PlayerCharacter:GetAttribute("TimeDodge") - 1)
		end
		self.Loading = true
		
		task.delay(.5, function()
			self.Loading = false
		end)
		
		if (os.clock() - self.LastHit) > 1.25 then
			self.CombatHitIndex = 0
		end
		self.CombatHitIndex += 1
		self.LastHit = os.clock()
	
		local Critical = false
		local Damage = Utils.calculateDamage(self.CombatHitIndex, self.CustomDetails.Strength)
		Humanoid.Parent:SetAttribute("LastDamageClock", os.clock())
		
		if Humanoid.Parent:GetAttribute("Blocking") then
			Utils.attackPlayerInBlock(self,Player, Player.Character, Damage)
			return
		end
		
		if self.CanDoUpperCut then
			if self.CombatHitIndex == 4 then
				local chance = math.random(1,6)
				
				if chance >= 5 then
					UpperCut(self.Character, Humanoid, Humanoid.Parent)
					local animator: Animator = self.Humanoid.Animator
					for _, Animation in animator:GetPlayingAnimationTracks() do
						Animation:Stop()
					end
					Gameplay:StunPlayer(PlayerCharacter, 1)

					local animationTrack: AnimationTrack = self.Humanoid.Animator:LoadAnimation(Replicated.Assets.Animations.Combat.Others.DownSlam)
					animationTrack.Priority = Enum.AnimationPriority.Action4
					animationTrack:Play()
				end
			end
		end
		
		task.spawn(function()
			if self.Character:GetAttribute("IsOnAir") then
				Remotes.Effect:FireAllClients("UpperCutDownVector", PlayerCharacter)
				self.Character:SetAttribute("IsOnAir", nil)

				local cast = Raycast.Unilaterally(PlayerCharacter.HumanoidRootPart.Position,(PlayerCharacter.HumanoidRootPart.CFrame.LookVector * -50) + Vector3.new(0,-25,0), {self.Character, PlayerCharacter, workspace:WaitForChild("Npcs"), workspace:WaitForChild("PlayersCharacter")})

				if cast then
					Remotes.Effect:FireAllClients("Explosion", PlayerCharacter)
					PlayerCharacter:MoveTo(cast.Position)
					Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end

				Remotes.Effect:FireAllClients("HeavyMelee", PlayerCharacter)

				task.delay(.4, function()
					self.Character.HumanoidRootPart.Anchored = false
					PlayerCharacter.HumanoidRootPart.Anchored = false
				end)
			end
		end)
		
		if self.CombatHitIndex >= self.CombatLimit then
			self.CombatHitIndex = 0
			Critical = true
			Damage *= 2            
			
			--Remotes.Effect:FireAllClients("NpcCritical", Humanoid.Parent)
			Gameplay:StunPlayer(PlayerCharacter, 0.5)
			Remotes.Effect:FireAllClients("HeavyMelee", PlayerCharacter)

			task.defer(function()
				local dist: number?
				local result = Raycast.Unilaterally(PlayerCharacter.HumanoidRootPart.Position + PlayerCharacter.HumanoidRootPart.CFrame.LookVector * 1, PlayerCharacter.HumanoidRootPart.CFrame.LookVector * -25, {self.Character, PlayerCharacter, workspace:WaitForChild("Npcs"), workspace:WaitForChild("PlayersCharacter")})
				if result then dist = (result.Position - PlayerCharacter.HumanoidRootPart.Position).Magnitude end

				local KnockBack = Tween:Create(PlayerCharacter.HumanoidRootPart,TweenInfo.new(if result then dist / 50 else 0.5),{CFrame = 
					PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0,0,if result then dist else 25)}
				)
				
				KnockBack:Play()

				KnockBack.Completed:Connect(function()
					if result then Remotes.Effect:FireAllClients("Explosion", PlayerCharacter) end
					PlayerCharacter.HumanoidRootPart.Anchored = false
				end)
			end)
			
			self.Stun:Add(1)
			self.StunBecauseHitIndex = true
			
			task.delay(1, function()
				self.StunBecauseHitIndex = false
			end)
		end
		
		Gameplay:StunPlayer(PlayerCharacter, 0.75)
		Humanoid:TakeDamage(math.max(Damage, 5))

		Utils.playSoundOn(self.Humanoid.RootPart, "Punch"..self.CombatHitIndex)

		Remotes.Effect:FireAllClients("DamageSplit", PlayerCharacter, Damage,
			if Critical then Color3.new(1, 0.568627, 0.192157) else nil
		)

		Remotes.Effect:FireAllClients("Hit", Player.Character, "Melee", Damage)
		Remotes.Effect:FireAllClients("Sound", "PunchHit", Player.Character.HumanoidRootPart.Position)
		self.Loading = false
	end)
end

function CombatSystem:Attack(target: Humanoid)
	
	if not thinkingID[self.Character] then thinkingID[self.Character] = 0 end
	
	if self.Character:GetAttribute("Stunned") then 
		return --Do not remove this conditional
	end
	
	if not self.Stun:Finished() then 
		return --print("Stun not finished")
	end
	
	if not self.CanAttack then 
		return --print("Npc cant attack")
	end
	self.CanAttack = false
	local query = false

	if self.CombatHitIndex == 0 and self.CombatAnimationRunning == 1 then self.CombatAnimationRunning = 0 end
	self.CombatAnimationRunning = if self.CombatAnimationRunning >= self.CombatLimit then 1 else self.CombatAnimationRunning + 1 

	if self.CombatAnimationRunning == 1 then 	
		local actualId = thinkingID[self.Character]
		task.wait(0.6) 
		
		if thinkingID[self.Character] ~= actualId then 
			self.CombatAnimationRunning = 0
			self.CanAttack = true
			return
		end
	end 

	if self.CombatAnimationRunning >= self.CombatLimit then
		query = true
	end
	
	local Animation: AnimationTrack = self.CombatAnimations[self.CombatAnimationRunning]
	Animation.Priority = Enum.AnimationPriority.Action4

	Utils.playSoundOn(self.Humanoid.RootPart, "AirSwing"..self.CombatAnimationRunning)

	for _, Animation in self.Humanoid.Animator:GetPlayingAnimationTracks() do
		Animation:Stop()
	end
	Animation:AdjustSpeed(1.5)
	Animation:Play()

	Animation.Looped = false
	Remotes.Effect:FireAllClients("Sound", "PunchSwing", self.Character.HumanoidRootPart.Position, .7)

	if (self.Character.HumanoidRootPart.Position - target.RootPart.Position).Magnitude <= 6 then
		self.HitBox:fire(target)
	end
	task.wait(0.8)
	Animation:Stop(0.05)
	
	if query then
		task.delay(.8, function()
			self.StunBecauseHitIndex = false
		end)
		self.StunBecauseHitIndex = true
		self.Stun:Add(1)
	end
	
	self.CanAttack = true
end

export type CombatControlls = typeof(CombatSystem)

return CombatSystem