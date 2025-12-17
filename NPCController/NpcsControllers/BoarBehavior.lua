local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
debug.setmemorycategory("Boar Behavior")

local Janitor = require(ReplicatedStorage.Modules.Other.Janitor)
local BasicCombatNpcClass = require(script.Parent.Parent.CombatNpc.BasicCombatNpcClass)

local Cache = {}
local ReferenceOptions_BoarClass = {
	CustomErrorTag = "[Boar Behavior]",
	ReferenceKillTag = "Boars",
	ReferenceClass = require(script.Parent.Parent.CombatNpc.BasicCombatSystem),
	ReferenceCache = Cache,
	ReferenceAnimationsFolder = ReplicatedStorage.Assets.Animations.Boar,
	CanLoadApparence = false,
	CreateRunHumanoid = false,
	DefaultStatsModifier = {},
	StunFactor = 1.2,
	ExtendedPropertys = {
		NpcActivationDistance = 22
	}
} :: BasicCombatNpcClass.REFERENCE_DEFAULT_OPTIONS

local BoarBehavior = BasicCombatNpcClass:CreateReferenceCombatNpc(ReferenceOptions_BoarClass)

local function update()
	for _, Boar in Cache do
		if not Boar.Character.PrimaryPart then
			table.remove(Cache, table.find(Cache, Boar))
			continue
		end
		
		if not Boar.Character:IsDescendantOf(workspace) then continue end
		if Boar.Humanoid:GetState() == Enum.HumanoidStateType.Dead then continue end
		local nearest = Boar:GetNearestPlayerCharacter()
		
		if nearest then
			Boar:SetFollowTarget(nearest:FindFirstChildOfClass("Humanoid"))
		end
	end
end

RunService.Heartbeat:Connect(update)

return {set = BoarBehavior}