local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
debug.setmemorycategory("Bandit Behavior")

local Janitor = require(ReplicatedStorage.Modules.Other.Janitor)
local BasicCombatNpcClass = require(script.Parent.Parent.CombatNpc.BasicCombatNpcClass)

local Cache = {}
local ReferenceOptions_BanditClass = {
	CustomErrorTag = "[Bandits Behavior]",
	ReferenceKillTag = "Bandit",
	ReferenceClass = require(script.Parent.Parent.CombatNpc.BasicCombatSystem),
	ReferenceCache = Cache,
	RunAnimation = ReplicatedStorage.Assets.Animations.Run.Default,
	ReferenceAnimationsFolder = ReplicatedStorage.Assets.Animations.Combat.M1,
	CanLoadApparence = true,
	CreateRunHumanoid = true,
	DefaultStatsModifier = {},
	StunFactor = 1,
	--StunLimit = 3.3,
	ExtendedPropertys = {
		NpcActivationDistance = 40
	}
} :: BasicCombatNpcClass.REFERENCE_DEFAULT_OPTIONS

local BanditBehavior = BasicCombatNpcClass:CreateReferenceCombatNpc(ReferenceOptions_BanditClass)

local function update()
	for _, bandit in Cache do
		if not bandit.Character.PrimaryPart then
			table.remove(Cache, table.find(Cache, bandit))
			continue
		end
		
		if not bandit.Character:IsDescendantOf(workspace) then continue end
		if bandit.Humanoid:GetState() == Enum.HumanoidStateType.Dead then continue end
		local nearest = bandit:GetNearestPlayerCharacter()

		if nearest then
			bandit:SetFollowTarget(nearest:FindFirstChildOfClass("Humanoid"))
		end
	end
end

RunService.Heartbeat:Connect(update)

return {set = BanditBehavior}