local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
debug.setmemorycategory("OrdanGuild Behavior")

local Janitor = require(ReplicatedStorage.Modules.Other.Janitor)
local BasicCombatNpcClass = require(script.Parent.Parent.CombatNpc.BasicCombatNpcClass)

local Cache = {}
local ReferenceOptions_OrdanGuildClass = {
	CustomErrorTag = "[Ordan Guild Behavior]",
	ReferenceKillTag = "OrdanGuild",
	ReferenceClass = require(script.Parent.Parent.CombatNpc.BasicCombatSystem),
	ReferenceCache = Cache,
	RunAnimation = ReplicatedStorage.Assets.Animations.Run.Default,
	ReferenceAnimationsFolder = ReplicatedStorage.Assets.Animations.Combat.OrdanGuild,
	CanLoadApparence = true,
	CreateRunHumanoid = true,
	DefaultStatsModifier = {
		Strength = 2,
	},
	StunFactor = 1,
	--StunLimit = 3.3,
	ExtendedPropertys = {
		NpcActivationDistance = 30
	}
} :: BasicCombatNpcClass.REFERENCE_DEFAULT_OPTIONS

local OrdanGuildBehavior = BasicCombatNpcClass:CreateReferenceCombatNpc(ReferenceOptions_OrdanGuildClass)

local function update()
	for _, OrdanGuild in Cache do
		if not OrdanGuild.Character.PrimaryPart then
			table.remove(Cache, table.find(Cache, OrdanGuild))
			continue
		end
		
		if not OrdanGuild.Character:IsDescendantOf(workspace) then continue end
		if OrdanGuild.Humanoid:GetState() == Enum.HumanoidStateType.Dead then continue end
		local nearest = OrdanGuild:GetNearestPlayerCharacter()

		if nearest then
			OrdanGuild:SetFollowTarget(nearest:FindFirstChildOfClass("Humanoid"))
		end
	end
end

RunService.Heartbeat:Connect(update)

return {set = OrdanGuildBehavior}