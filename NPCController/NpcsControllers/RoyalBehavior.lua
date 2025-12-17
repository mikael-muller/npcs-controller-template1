local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerScript = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

debug.setmemorycategory("Wizard Behavior")

local Utils = require(script.Parent.Parent.NpcUtils.Utils)
local Janitor = require(ReplicatedStorage.Modules.Other.Janitor)
local BasicCombatNpcClass = require(script.Parent.Parent.CombatNpc.BasicCombatNpcClass)
local Template = require(ServerStorage.Modules.ServerModules.DataStore.Template)
local Conversor = require(ServerStorage.Modules.ServerModules.DataStore.Convert)
local SkillFolder = ServerScript.WorldServer.Character.SkillController.Grimoires

local ReferenceClass = setmetatable({}, {__index = require(script.Parent.Parent.CombatNpc.BasicCombatSystem)})
local RoyalsSkillsReference = {
	{
		Name = "Water",
		Skills = {
			{Skill = require(SkillFolder.Water.C), MinimalDistance = 10}, 
			{Skill = require(SkillFolder.Water.Z), MinimalDistance = 10}, 
			{Skill = require(SkillFolder.Water.X), MinimalDistance = 10},
			{Skill = require(SkillFolder.Water.E), MinimalDistance = 10}	
		}
	},
	
	{
		Name = "Fire",
		Skills = {
			{Skill = require(SkillFolder.Fire.C), MinimalDistance = 10}, 
			{Skill = require(SkillFolder.Fire.Z), MinimalDistance = 10}, 
			{Skill = require(SkillFolder.Fire.X), MinimalDistance = 10},
			{Skill = require(SkillFolder.Fire.E), MinimalDistance = 10}
		}
	}
}

function ReferenceClass:SetFollowTarget(targetHumanoid: Humanoid, isForced: boolean)
	if self.Following then return end
	self.Following = true

	local spawnPoint: Vector3 = self.SpawnPoint
	local maxDistance = self.NpcActivationDistance or 100

	local target = targetHumanoid.RootPart
	local character = targetHumanoid.Parent
	local playerOwner = game.Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	
	local Stun = self.Stun
	local LastAnimationPlay = self.LastHit

	if not playerOwner then
		return 
	end

	local Step; Step = RunService.Heartbeat:Connect(function(deltaTimeSim: number) 
		if targetHumanoid.Health <= 0 then
			Step:Disconnect()
			Step = nil
			return
		end
		
		if not self.Character or not self.Character.PrimaryPart then
			Step:Disconnect()
			Step = nil
			return
		end

		if self.Humanoid:GetState() == Enum.HumanoidStateType.Dead then 
			Step:Disconnect()
			Step = nil
			return 
		end

		if targetHumanoid:GetState() == Enum.HumanoidStateType.Dead then
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
			self:Attack(targetHumanoid)
		else
			--warn("Cant attack because", "Stun is not finished:", 
			--	self.Stun:Finished(), 
			--	"Distance to high:",  (self.Character.HumanoidRootPart.Position - target.Position).Magnitude)
		end
	end)
end

function ReferenceClass:Attack(Humanoid: Humanoid)
	if Humanoid.Parent:HasTag("Stunned") then return end 
	if not self.Stun:Finished() then return end
	if not self.CanAttack then return end
	
	local Distance = Utils.Distance(Humanoid.RootPart, self.Character.PrimaryPart)
	
	if self.CanUseSkill and self.CanAttack then
		self.CanAttack = false
		self.CanUseSkill = false
		
		local Royal = self :: BasicCombatNpcClass.CombatNpcDefault
		local Grimoire = Royal.SelectedGrimoire :: typeof(RoyalsSkillsReference[1])
		local Skill = Grimoire.Skills[math.random(1,#Grimoire.Skills)] :: typeof(Grimoire.Skills[1])
				
		Skill.Skill(Royal.MockingPlayer, "Begin", false, Humanoid.RootPart.Position)
		task.wait(.7)
		Skill.Skill(Royal.MockingPlayer, "End", false, Humanoid.RootPart.Position)
		
		task.wait(3)
		
		self.CanAttack = true
		self.CanUseSkill = true
	elseif Distance < 10 and not self.CanUseSkill then
		self.CanAttack = false
		local query = false
		
		if self.CombatAnimationRunning >= self.CombatLimit then
			query = true
		end
		
		self.CombatAnimationRunning = if self.CombatAnimationRunning >= self.CombatLimit then 1 else self.CombatAnimationRunning + 1 

		local Animation: AnimationTrack = self.CombatAnimations[self.CombatAnimationRunning]
		Animation.Priority = Enum.AnimationPriority.Action4

		Utils.playSoundOn(self.Humanoid.RootPart, "AirSwing"..self.CombatAnimationRunning)

		for _, Animation in self.Humanoid.Animator:GetPlayingAnimationTracks() do
			Animation:Stop()
		end

		Animation:AdjustSpeed(1.5)
		Animation:Play()
		
		Animation.Looped = false

		if (self.Character.HumanoidRootPart.Position - Humanoid.RootPart.Position).Magnitude <= 5 then
			self.HitBox:fire(Humanoid)
		end
		
		task.wait(0.6)
		Animation:Stop(0.05)

		if query then
			task.delay(1.4, function()
				self.StunBecauseHitIndex = false
			end)
			self.StunBecauseHitIndex = true
			self.Stun:Add(1.4)
		end
		
		self.CanAttack = true
	end
end

function ReferenceClass:WhenCreate(Royal: BasicCombatNpcClass.CombatNpcDefault)
	local SelectedGrimoire = RoyalsSkillsReference[math.random(1, #RoyalsSkillsReference)]
	Royal.SelectedGrimoire = SelectedGrimoire
	Royal.CanUseSkill = true
	
	local MockingData = {
		PlayerStats = Template.PlayerStats,
		Values = {Level = 200}
	}
	
	MockingData.PlayerStats.Magic = Royal.CustomDetails.Magic
	MockingData.PlayerStats.Melee = Royal.CustomDetails.Strength
	MockingData.PlayerStats.Defense = Royal.CustomDetails.Defense
	
	local MockingPlayer = {
		Character = Royal.Character,
		Data = Conversor.tableToFolder(Template),
		
		GetAttribute = function(self, name: string)
			return self.Character:GetAttribute(name)
		end,
		
		SetAttribute = function(self, name: string, value)
			self.Character:SetAttribute(name, value)
		end,
	}
	
	Royal.MockingPlayer = MockingPlayer
	Royal.Scope:Add(MockingPlayer.Data)
end

local Cache = {}

local ReferenceOptions_RoyalClass = {
	CustomErrorTag = "[Royals Behavior]",
	ReferenceKillTag = "Royal",
	ReferenceClass = ReferenceClass,
	ReferenceCache = Cache,
	RunAnimation = ReplicatedStorage.Assets.Animations.Run.Default,
	ReferenceAnimationsFolder = ReplicatedStorage.Assets.Animations.Combat.M1,
	CanLoadApparence = true,
	IgnoreCloth = false,
	CreateRunHumanoid = true,
	DefaultStatsModifier = {
		MaxHealth = 1.5, Magic = 3, Strength = 1
	},
	StunFactor = 1.2,
	ExtendedPropertys = {
		NpcActivationDistance = 35
	}
} :: BasicCombatNpcClass.REFERENCE_DEFAULT_OPTIONS

local RoyalBehavior = BasicCombatNpcClass:CreateReferenceCombatNpc(ReferenceOptions_RoyalClass)

local function update()
	for _, Royal in Cache do
		if not Royal.Character.PrimaryPart then
			table.remove(Cache, table.find(Cache, Royal))
			continue
		end

		if not Royal.Character:IsDescendantOf(workspace) then continue end
		if Royal.Humanoid:GetState() == Enum.HumanoidStateType.Dead then continue end
		local nearest = Royal:GetNearestPlayerCharacter()
		
		if nearest then
			Royal:SetFollowTarget(nearest:FindFirstChildOfClass("Humanoid"))
		end
	end
end

RunService.Heartbeat:Connect(update)

return {set = RoyalBehavior}