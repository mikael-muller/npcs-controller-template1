
local Utils = {}
local Remotes = game.ReplicatedStorage.Remotes
local TweenService = game.TweenService
local FastTween = TweenInfo.new(.15, Enum.EasingStyle.Back)
local FightRemotes = Remotes.Fight

local function breakBlockPlayer(player)
	warn("block breaked")
	player.Character:SetAttribute("Blocking", false)
	player.Character:SetAttribute("StartBlocking", nil)
	FightRemotes.Effect:FireAllClients("BlockEnd", player.Character)
	FightRemotes.Effect:FireAllClients("BreakBlock", player.Character)
	FightRemotes.Stun:FireClient(player, 2)
	
	player.Character:SetAttribute("State", "Idle")
	player.Character:SetAttribute("ClientState", "Idle")
	FightRemotes.BreakBlock:InvokeClient(player)
end

local function CalculateDamage(BaseDamage: number, StatValue: number, HitIndex: number, Critical: boolean, isPrimaryAttack: boolean): number
	local damage = BaseDamage + (StatValue * (if isPrimaryAttack then 0.25 else 1.15))
	local CriticalMultiplier = (Critical and 1.25 or 1)

	--HitIndex = HitIndex or 1 
	--local HitMultiplier = (HitIndex and HitIndex * 0.65 or 1)
	return math.clamp(damage * CriticalMultiplier, 1, math.huge)
end

local function CalculateHealth(stat: number): number
	return math.max((stat * 5) * .5, 80)
end

local function CalculateDefense(stat: number): number
	return 25 + (stat * 3)
end

local function CalculateMana(stat: number): number
	return 100 + (stat * 10)
end

function Utils.Distance(p0: Part, p1: Part)
	return (p0.Position - p1.Position).Magnitude
end

function Utils.CalculateHealth(healthFactor: number, BaseHealth): number
	return CalculateHealth(healthFactor)
end

function Utils.foreach<v>(list, callback: (v)->any)
	local new = {}
	for _, value in list do
		local nv = callback(value)
		table.insert(new, nv)
	end

	return new
end

function Utils.attackPlayerInBlock(self, IsPlayer: Player, Target, UserDamage)
	if Target:GetAttribute("Blocking") and IsPlayer then
		
		if IsPlayer:GetAttribute("BlockHealth") <= (0) then
			breakBlockPlayer(IsPlayer)
		else
			if Target:GetAttribute("StartBlocking") then
				local duration = os.clock() - Target:GetAttribute("StartBlocking")
				
				if duration <= .5 then
					Utils.playSoundOn(Target.PrimaryPart, "Stun")
					--Remotes.Effect:FireAllClients("Sound", "BreakActivate", Target.PrimaryPart.Position)
					FightRemotes.Effect:FireAllClients("PerfectBlock", Target)
					self.Stun:Add(3)
					--FightRemotes.Stun:FireClient(IsPlayer, 2)
				else
					Utils.playSoundOn(Target.PrimaryPart, "BlockedPunch"..(IsPlayer.Character:GetAttribute("HitIndex") or 1))
					FightRemotes.Effect:FireAllClients("Sound", "BlockedPunchUsable", Target.PrimaryPart.Position)
					FightRemotes.Effect:FireAllClients("HitOnBlock", IsPlayer.Character)
					IsPlayer:SetAttribute("BlockHealth", math.max((IsPlayer:GetAttribute("BlockHealth")) - UserDamage, 0))
				end
			end
			
			return false, "Blocking"
		end
	end
end

function Utils.calculateDamage(hitIndex: number, strength: number)
	return CalculateDamage(6, strength, hitIndex, false, true)
end

function Utils.loadAnimations(AnimationsList, Animator)
	local Tracks = {}

	for _, Animation in AnimationsList:GetChildren() do
		local track = Animator:LoadAnimation(Animation)

		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = false

		table.insert(Tracks, track)
	end

	return Tracks
end

function Utils.gyro(part: BasePart, force)
	TweenService:Create(part, FastTween, {
		AssemblyLinearVelocity = -(part.CFrame.LookVector * (force or 60))
	}):Play()
end

function Utils.breakBlockPlayer(player)
	player.Character:SetAttribute("Blocking", false)
	player.Character:SetAttribute("StartBlocking", nil)
	FightRemotes.Effect:FireAllClients("BlockEnd", player.Character)
	FightRemotes.BreakBlock:InvokeClient(player)
end

function Utils.isDead(humanoid: Humanoid)
	return humanoid:GetState() == Enum.HumanoidStateType.Dead
end

function Utils.getPercentage(part, total)
	return (part / total) * 100
end

function Utils.playSoundOn(part: BasePart, soundName: string)
	if not part then
		return
	end

	local sound: Sound = game.SoundService:FindFirstChild(soundName, true)

	if sound then
		sound = sound:Clone()
		sound.Parent = part
		sound:Play()

		task.delay(sound.TimeLength, sound.Destroy, sound)
	end
end

local Chances = {}
Chances.__index = Chances

function Chances.new(percentage, targetName: string, category: string)
	assert(type(percentage) == "number", "A porcentagem deve ser um número.")
	assert(percentage >= 0 and percentage <= 100, "A porcentagem deve estar entre 0 e 100.")

	local self = setmetatable({}, Chances)
	self.percentage = percentage
	self.category = category
	self.name = targetName

	return self
end

function Chances:roll()
	local randomValue = math.random(0, 100)
	return randomValue <= self.percentage
end

Utils.Chance = Chances

return Utils
