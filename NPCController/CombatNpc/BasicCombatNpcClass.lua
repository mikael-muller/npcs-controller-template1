local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Controller = require(script.Parent.Parent)
local Apparence = require(script.Parent.Parent.ApparenceLoader)
local Names = require(script.Parent.Parent.NpcUtils.Names)
local Utils = require(script.Parent.Parent.NpcUtils.Utils)
local Gameplay = require(ReplicatedStorage.Modules.Gameplay)
local Signals = require(ReplicatedStorage.Modules.Other.Signals)
local Janitor = require(ReplicatedStorage.Modules.Other.Janitor)
local Stun = require(script.Parent.Parent.NpcUtils.Stun)

local BasicCombatNpcClass = {}

@native function BasicCombatNpcClass:CreateReferenceCombatNpc(reference_options: REFERENCE_DEFAULT_OPTIONS)	
	assert(reference_options.ReferenceKillTag, `[COMBAT CLASS]: Error ReferenceKillTag is invalid {reference_options.ReferenceKillTag}`)
	reference_options.ChildAdded = Signals.new()
	reference_options.ChildRemoved = Signals.new()
	
	return function(character: Model, user_level: number)
		assert(character, `{reference_options.CustomErrorTag or script.Name} User level expected as a number got {typeof(user_level)}`)
		assert(type(user_level) == "number", `{reference_options.CustomErrorTag or script.Name} User level expected as a number got {typeof(user_level)}`)
		local combatNpc = setmetatable({}, {__index = reference_options.ReferenceClass})
		local divided_stats_count = math.max((user_level * 3)/4, 1)
		
		combatNpc.Character = character
		combatNpc.Humanoid = character:WaitForChild("Humanoid")
		combatNpc.CustomDetails = {
			MaxHealth = math.floor(
				Utils.CalculateHealth(math.ceil(divided_stats_count) * .7), 
				reference_options.DefaultStatsModifier.BaseHealth),
			Strength = math.max(math.ceil(divided_stats_count * (reference_options.DefaultStatsModifier.Strength or 1)), 1),
			Magic = math.max(math.ceil(divided_stats_count * (reference_options.DefaultStatsModifier.Magic or 1)), 2) 
		}
		
		warn("Npcs created", combatNpc.CustomDetails.MaxHealth)
		
		combatNpc.Scope = Janitor.new()
		combatNpc.ComputedErrors = {}
		
		combatNpc.HitSignal = Instance.new("BindableEvent", character)
		combatNpc.HitSignal.Name = "HitSignal"
		
		combatNpc.StunSignal = Instance.new("BindableEvent", character)
		combatNpc.StunSignal.Name = "StunSignal"
		
		combatNpc.SpawnPoint = character.HumanoidRootPart.Position
		combatNpc.PlayersDamage = Instance.new("Folder", character)
		combatNpc.PlayersDamage.Name = "PlayersDamage"
		
		--References index
		combatNpc.CombatHitIndex = 0
		combatNpc.CombatAnimationRunning = 0
		combatNpc.CanAttack = true
		combatNpc.ReferenceKillTag = reference_options.ReferenceKillTag
		
		--Animations
		local Animator = combatNpc.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", combatNpc.Humanoid)
		combatNpc.Animator = Animator
		combatNpc.CombatAnimations = Utils.loadAnimations(reference_options.ReferenceAnimationsFolder, Animator)
		combatNpc.CombatLimit = #combatNpc.CombatAnimations
		
		--Others
		if reference_options.CreateRunHumanoid then
			self:SetRunHumanoid(combatNpc)
		end
		
		combatNpc.LastHit = os.clock()
		combatNpc.LastNonAttack = os.clock()
		combatNpc.Stun = Stun.new(
			character, reference_options.StunLimit
			--reference_options.StunFactor or 1,
		)	
		combatNpc.LastPlayerHit = tick()
		combatNpc.stunFinish = os.clock()
		
		combatNpc:ConfigureHitbox()
		combatNpc.Controller = Controller
		combatNpc.ReferenceCache = reference_options.ReferenceCache
		
		--Unpacking
		
		for name: string?, value in (reference_options.ExtendedPropertys or {}) do
			combatNpc[name] = value
		end
		
		combatNpc.Character:SetAttribute("SpawnPoint", character.PrimaryPart.Position)
		
		if reference_options.CanLoadApparence then
			task.spawn(function()
				Apparence(character, reference_options.IgnoreCloth)
				local Name = Names[math.random(1, #Names)]

				character.Name = Name.Name
				character:SetAttribute("Name", Name.Name)
				character:SetAttribute("ApparenceLoaded", true)
			end)
		end
		
		if reference_options.ReferenceClass.WhenCreate then
			reference_options.ReferenceClass:WhenCreate(combatNpc)
		end
		
		task.spawn(function()
			repeat
				combatNpc.Humanoid.MaxHealth = combatNpc.CustomDetails.MaxHealth
				task.wait()
			until combatNpc.Humanoid.MaxHealth == combatNpc.CustomDetails.MaxHealth
			repeat
				combatNpc.Humanoid.Health = combatNpc.CustomDetails.MaxHealth
				task.wait()
			until combatNpc.Humanoid.Health == combatNpc.CustomDetails.MaxHealth
		end)
		
		self:SetConnections(combatNpc)
		self:SetValuesToJanitor(combatNpc)
		self:LoadHumanoidRefferences(combatNpc)
		--self:DebugMode(combatNpc)
		
		table.insert(reference_options.ReferenceCache, combatNpc)		
		return combatNpc
	end
end

function BasicCombatNpcClass:DebugMode(combatNpc: CombatNpcDefault)
	local Character = combatNpc.Character :: Model
	local Interface = script.Parent.Parent.NpcUtils.NpcDebug:Clone()
	Interface.Parent = Character:WaitForChild("Head")
	
	Character:GetAttributeChangedSignal("Stunned"):Connect(function()
		if Character:GetAttribute("Stunned") then
			Interface.StateServer.Text = "Stunned: true"
			Interface.StateServer.BackgroundColor3 = Color3.new(0,1,0)
		else
			Interface.StateServer.Text = "Stunned: false"
			Interface.StateServer.BackgroundColor3 = Color3.new(1, 0.423529, 0.431373)
		end
	end)
	
	Character.Humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
		Interface.HumanoidState.Text = `{old.Name}|{new.Name}`
	end)
end

function BasicCombatNpcClass:LoadHumanoidRefferences(combatNpc: CombatNpcDefault)
	local Humanoid = combatNpc.Humanoid :: Humanoid
	local Animator = combatNpc.Animator
	local Scope = combatNpc.Scope
	
	Humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType) 
		if new == Enum.HumanoidStateType.Physics then
			Humanoid:ChangeState(Enum.HumanoidStateType.Running)
			
			if combatNpc.RunHumanoid then
				combatNpc.RunHumanoid:Stop()
			end
		elseif new == Enum.HumanoidStateType.Dead then
			for _, animation in Animator:GetPlayingAnimationTracks() do
				animation:Stop()
			end
			
			task.delay(10, function()
				Scope:Cleanup()
				Scope:Destroy()
			end)
			
		elseif new == Enum.HumanoidStateType.Running then
			if combatNpc.RunHumanoid then
				combatNpc.RunHumanoid:Stop()
			end
		end	
	end)
	
	combatNpc.HitSignal.Event:Connect(function(Player: Player, Damage: number)
		if not Damage then
			return
		end
		
		combatNpc.LastPlayerHit = tick()
		combatNpc.PlayersDamage:SetAttribute(Player.Name, (combatNpc.PlayersDamage:GetAttribute(Player.Name) or 0) + Damage)
		
		local PlayerCharacter = combatNpc:GetNearestPlayerCharacter() :: Model
		
		if PlayerCharacter then
			combatNpc:SetFollowTarget(PlayerCharacter.Humanoid, true)
		end
	end)
	
	combatNpc.StunSignal.Event:Connect(function(duration)
		if duration then
			combatNpc.Stun:Add(duration)
			--print(combatNpc.Stun:Get())
		else
			print("Npc stun signal not received duration", duration, debug.traceback())
		end
	end)
	
	task.spawn(function()
		while task.wait(.5) and Humanoid.Health > 0 do
			if combatNpc.RunHumanoid and Humanoid.MoveDirection.Magnitude == 0 then
				combatNpc.RunHumanoid:Stop()
			end
		end
	end)
end

function BasicCombatNpcClass:SetRunHumanoid(combatNpc: CombatNpcDefault)
	local Humanoid = combatNpc.Humanoid
	combatNpc.RunAnimation = combatNpc.Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Run.Default)
	combatNpc.RunHumanoid = {
		Run = function(self)
			combatNpc.Humanoid.WalkSpeed = 28

			self.RunConnection = Humanoid.Running:Connect(function(speed)
				if speed > 0.001 then
					if not combatNpc.RunAnimation.IsPlaying then
						combatNpc.RunAnimation:Play()
					end
				end
			end)
		end,
		
		Stop = function(self)
			combatNpc.Humanoid.WalkSpeed = 12

			if self.RunConnection then
				self.RunConnection:Disconnect()
			end

			combatNpc.RunAnimation:Stop()
		end,
	}
end

function BasicCombatNpcClass:SetConnections(combatNpc: CombatNpcDefault, reff: REFERENCE_DEFAULT_OPTIONS)
	local Humanoid, Character = combatNpc.Humanoid, combatNpc.Character
	local Cache = combatNpc.ReferenceCache
	
	if combatNpc.CreateRunHumanoid then
		Humanoid.Running:Connect(function(speed: number) 
			Character:SetAttribute("State", "Running")
			Character:SetAttribute("Speed", speed)

			if speed <= 0 then
				combatNpc.RunHumanoid:Stop()
			end
		end)
	end
	
	Humanoid.Died:Once(function()
		table.remove(Cache, table.find(Cache, combatNpc))
		
		for PlayerName: string, Damage: number in combatNpc.PlayersDamage:GetAttributes() do
			local Percantage = math.clamp(Utils.getPercentage(Damage, Humanoid.MaxHealth), 0, Humanoid.MaxHealth)

			if Percantage >= 10 then
				local Player = Players:FindFirstChild(PlayerName)
				
				if Player and Player:IsDescendantOf(Players) then
					local KilledNpc: BindableEvent = Player:FindFirstChild("PlayerKilledNpc")
					Gameplay:RewardPlayer(Player, {
						Exp = Character:GetAttribute("Exp") or math.random(15, 80),
						Yens = Character:GetAttribute("Yens") or math.random(15, 80)
					})
					KilledNpc:Fire(Character, self.ReferenceKillTag)
				end
			end
		end
	end)
end

function BasicCombatNpcClass:SetValuesToJanitor(reff)
	assert(reff.Scope, `Create a janitor object to reference here.`)
		
	for _, object in reff do
		local sucess, wrn = pcall(function()
			if typeof(object) == "table" or typeof(object) == "Vector3" or typeof(object) == "number" or typeof(object) == "string" or typeof(object) == "CFrame" then
				return
			end
			
			reff.Scope:Add(object)
		end)
		
		if not sucess then
			table.insert(reff.ComputedErrors, wrn)
		end
	end
end

export type REFERENCE_DEFAULT_OPTIONS = {
	Scope: typeof(Janitor.new()),
	CustomErrorTag: string,
	ReferenceClass: table,
	ReferenceAnimationsFolder: Folder, -- Combat animations
	ReferenceCache: table,
	RunAnimation: Animation,
	CreateRunHumanoid: boolean,
	IgnoreCloth: boolean,
	LoadApparence: boolean,
	StunFactor: number,
	ReferenceKillTag: string, -- NEED
	DefaultStatsModifier: {
		Strength: number?,
		Magic: number?,
		MaxHealth: number?,
		BaseHealth: number
	},

	ExtendedPropertys: {[string]: any},
	
	ChildAdded: Signals.signal,
	ChildRemoved: Signals.signal
}

export type CombatNpcDefault = typeof(BasicCombatNpcClass:CreateReferenceCombatNpc()())

return BasicCombatNpcClass