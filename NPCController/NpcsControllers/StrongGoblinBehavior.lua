local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
debug.setmemorycategory("Goblin Behavior")

local Janitor = require(ReplicatedStorage.Modules.Other.Janitor)
local BasicCombatNpcClass = require(script.Parent.Parent.CombatNpc.BasicCombatNpcClass)

local Cache = {}
local ReferenceOptions_GoblinClass = {
	CustomErrorTag = "[Goblins Behavior]",
	ReferenceKillTag = "Goblin",
	ReferenceClass = require(script.Parent.Parent.CombatNpc.BasicCombatSystem),
	ReferenceCache = Cache,
	RunAnimation = ReplicatedStorage.Assets.Animations.Run.Default,
	ReferenceAnimationsFolder = ReplicatedStorage.Assets.Animations.Combat.GoblinM1,
	CanLoadApparence = false,
	CreateRunHumanoid = true,
	DefaultStatsModifier = {MaxHealth = 1.5,},
	StunFactor = 1.4,
	ExtendedPropertys = {
		NpcActivationDistance = 15
	}
} :: BasicCombatNpcClass.REFERENCE_DEFAULT_OPTIONS

local GoblinBehavior = BasicCombatNpcClass:CreateReferenceCombatNpc(ReferenceOptions_GoblinClass)

local function update()
	for _, Goblin in Cache do
		if not Goblin.Character.PrimaryPart then
			table.remove(Cache, table.find(Cache, Goblin))
			continue
		end
		
		if not Goblin.Character:IsDescendantOf(workspace) then continue end
		if Goblin.Humanoid:GetState() == Enum.HumanoidStateType.Dead then continue end
		local nearest = Goblin:GetNearestPlayerCharacter()

		if nearest then
			Goblin:SetFollowTarget(nearest:FindFirstChildOfClass("Humanoid"))
		end
	end
end

RunService.Heartbeat:Connect(update)

return {set = GoblinBehavior}