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
local WizardsSkillsReference = {
	{
		Name = "Fire",
		Skills = {{Skill = require(SkillFolder.Fire.C), MinimalDistance = 10}, 
		{Skill = require(SkillFolder.Fire.Z), MinimalDistance = 10}, 
		{Skill = require(SkillFolder.Fire.X), MinimalDistance = 10}}
	}
}

function ReferenceClass:Attack(Humanoid: Humanoid)
	if Humanoid.Parent:HasTag("Stunned") then return end 
	if not self.Stun:Finished() then return end
	if not self.CanAttack then return end
	
	local Distance = Utils.Distance(Humanoid.RootPart, self.Character.PrimaryPart)
	
	if self.CanUseSkill then
		self.CanAttack = false
		self.CanUseSkill = false
		
		local Wizard = self :: BasicCombatNpcClass.CombatNpcDefault
		local Grimoire = Wizard.SelectedGrimoire :: typeof(WizardsSkillsReference[1])
		local Skill = Grimoire.Skills[math.random(1,#Grimoire.Skills)] :: typeof(Grimoire.Skills[1])
				
		Skill.Skill(Wizard.MockingPlayer, "Begin", false, Humanoid.RootPart.Position)
		task.wait(.7)
		Skill.Skill(Wizard.MockingPlayer, "End", false, Humanoid.RootPart.Position)
		
		task.wait(3)
		self.CanAttack = true
		self.CanUseSkill = true
	elseif Distance < 5 and not self.CanUseSkill then
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

function ReferenceClass:WhenCreate(Wizard: BasicCombatNpcClass.CombatNpcDefault)
	local SelectedGrimoire = WizardsSkillsReference[math.random(1, #WizardsSkillsReference)]
	Wizard.SelectedGrimoire = SelectedGrimoire
	Wizard.CanUseSkill = true
	
	local MockingData = {
		PlayerStats = Template.PlayerStats,
		Values = {Level = 150}
	}
	
	MockingData.PlayerStats.Magic = Wizard.CustomDetails.Magic
	MockingData.PlayerStats.Melee = Wizard.CustomDetails.Strength
	MockingData.PlayerStats.Defense = Wizard.CustomDetails.Defense
	
	local MockingPlayer = {
		Character = Wizard.Character,
		Data = Conversor.tableToFolder(Template),
		
		GetAttribute = function(self, name: string)
			return self.Character:GetAttribute(name)
		end,
		
		SetAttribute = function(self, name: string, value)
			self.Character:SetAttribute(name, value)
		end,
	}
	
	Wizard.MockingPlayer = MockingPlayer
	Wizard.Scope:Add(MockingPlayer.Data)
end

local Cache = {}
local ReferenceOptions_WizardClass = {
	CustomErrorTag = "[Wizards Behavior]",
	ReferenceKillTag = "Wizard",
	ReferenceClass = ReferenceClass,
	ReferenceCache = Cache,
	RunAnimation = ReplicatedStorage.Assets.Animations.Run.Default,
	ReferenceAnimationsFolder = ReplicatedStorage.Assets.Animations.Combat.M1,
	CanLoadApparence = true,
	IgnoreCloth = true,
	CreateRunHumanoid = true,
	DefaultStatsModifier = {
		MaxHealth = 1.5, Magic = .75, Strength = .5
	},
	StunFactor = 1.2,
	ExtendedPropertys = {
		NpcActivationDistance = 35
	}
} :: BasicCombatNpcClass.REFERENCE_DEFAULT_OPTIONS

local WizardBehavior = BasicCombatNpcClass:CreateReferenceCombatNpc(ReferenceOptions_WizardClass)

local function update()
	for _, Wizard in Cache do
		if not Wizard.Character.PrimaryPart then
			table.remove(Cache, table.find(Cache, Wizard))
			continue
		end

		if not Wizard.Character:IsDescendantOf(workspace) then continue end
		if Wizard.Humanoid:GetState() == Enum.HumanoidStateType.Dead then continue end
		local nearest = Wizard:GetNearestPlayerCharacter()
		
		if nearest then
			Wizard:SetFollowTarget(nearest:FindFirstChildOfClass("Humanoid"))
		end
	end
end

RunService.Heartbeat:Connect(update)

return {set = WizardBehavior}