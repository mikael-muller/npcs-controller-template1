local Controller = require(script.Parent)
local Names = require(script.Parent.NpcUtils.Names)
local Mensages = require(script.Parent.NpcUtils.ChatsContents)
local Signals = require(script.Parent.Parent.Other.Signals)
local MissionsMensages = require(script.Parent.MissionsContents)
local Apparence = require(script.Parent.ApparenceLoader)
local Utils = require(script.Parent.NpcUtils.Utils)
local RoyalControll = require(script.Parent.NpcsControllers.RoyalBehavior)

local HookId = 'https://discord.com/api/webhooks/1397728893380858019/hXYt5ndjjUXE7dcjN6x4WcSd_0-cVmbvapi4X6HBdcNoGmBL2Bz3Zv9_dAKTl2xtq-fg'
local Players = game:GetService("Players") :: {[string]: Player}

local NonPlayer = {}
NonPlayer.Cache = setmetatable({}, {__mode = "v"})

local Settings = Controller.GetSettings()
Settings.HumanoidSettings.RunAfterDamage = true

local Summoneds = {}

debug.setmemorycategory("Humans-Behavior")

local Offsets = {
	Vector3.new(10, 0, 0),
	Vector3.new(-10, 0, 0),
	Vector3.new(0, 0, 10),
	Vector3.new(0, 0, -10),
	Vector3.new(10, 0, 5),
}

local function GetPositionFromArea(area: CFrame, size, factor: number)
	factor = factor or 4
	return area:ToWorldSpace(CFrame.new(
		math.random(-size*factor, size*factor),
		0,
		math.random(-size*factor, size*factor)
		)).Position
end

local function IsPositionAboveGround(pos)
	local rayOrigin = pos + Vector3.new(0, 5, 0)
	local rayDirection = Vector3.new(0, -10, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {workspace:WaitForChild("PlayersCharacter")}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	return result ~= nil
end

local function GetValidPositionsAroundPlayer(player: Player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end

	local origin = character.HumanoidRootPart.Position
	local validPositions = {}
	
	for i = 1, 3 do
		table.insert(validPositions, GetPositionFromArea(character.PrimaryPart.CFrame, 100, 4))
	end
	
	return validPositions
end

local HUMAN_PATH_DATA = {
	AgentRadius = 2,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 4,
	Costs = {
		Snow = 3,
		Grass = 0,
		Sand = 1,
		Slate = 5,
		Water = math.huge,
		Blocked = math.huge,
		Neon = math.huge
	}
}																										


function NonPlayer:set(character: Model, area: Vector3)
	assert(character, `invalid character`)
	assert(typeof(character) == "Instance", `Expected instance {debug.traceback()}`)

	--warn("---PHASE1", "NPC SETTINGS")

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local controlled = Controller.Create(Settings, character)
	local path = Controller.SimplePath.new(character, HUMAN_PATH_DATA)
	local startPos = character.PrimaryPart.CFrame

	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

	local HitSignal = Instance.new("BindableEvent", character)
	HitSignal.Name = "HitSignal"

	local PlayersDamage = Instance.new("Folder", character)
	PlayersDamage.Name = "PlayersDamage"

	controlled.StartTalking = Signals.new("StartTalking")
	controlled.Target = GetPositionFromArea(startPos, area)

	controlled.Cleanup:Add(path, "Destroy", "Path")
	controlled.IsRunning = false
	controlled.Path = controlled.Cleanup:Get("Path")
	path.Visualize = false

	path.Blocked:Connect(function()
		if controlled.IsTalking then return end

		path:Run(controlled.Target)
	end)

	path.Error:Connect(function()
		if controlled.IsTalking then return end

		controlled.Target = GetPositionFromArea(startPos, area)
		path:Run(controlled.Target)
	end)

	path.Reached:Connect(function()
		if controlled.IsTalking then return end

		task.wait(math.random(3,10))
		controlled.Target = GetPositionFromArea(startPos, area)
		path:Run(controlled.Target)
	end)

	local hp = humanoid.Health

	humanoid.HealthChanged:Connect(function(health: number)
		if health <= hp then
			Utils.playSoundOn(humanoid.RootPart, "NpcDamaged")

			repeat
				local InCombat = character:GetAttribute("InCombat")
				task.wait()
			until character:GetAttribute("InCombat")

			character:SetAttribute("InCombat", nil)

			if humanoid.Health <= 0 then return end
			if controlled.IsRunning then return end

			controlled.IsRunning = true
			humanoid.WalkSpeed = controlled.Settings.HumanoidSettings.RunSpeed 

			path:Run(GetPositionFromArea(startPos, area, 15))

			task.wait(controlled.Settings.HumanoidSettings.RunDuration)
			humanoid.WalkSpeed = controlled.Settings.HumanoidSettings.WalkSpeed
			controlled.IsRunning = false
		end

		hp = health
	end)

	humanoid.Died:Once(function()
		Utils.playSoundOn(humanoid.RootPart, "DeathSound")

		local highest = ""
		local actual = 1

		for name, number in PlayersDamage:GetAttributes() do
			if number > actual then
				actual = number
				highest = name
			end
		end

		if Players:FindFirstChild(highest) then
			if Summoneds[Players[highest]] then
				return
			end
			
			Summoneds[Players[highest]] = true
			
			Players[highest].Data.Values:SetAttribute("Honour", 
				Players[highest].Data.Values:GetAttribute("Honour") - 120)
			
			Players[highest]:SetAttribute("UnderRisk", true)
			
			local sucessGettingPhoto, photo = pcall(function()
				return game.HttpService:GetAsync(`https://api.newstargeted.com/roblox/users/v1/avatar-headshot.php?userid={Players[highest].UserId}&size=150x150&format=Png&isCircular=false`)
			end)
			
			local pic = "https://media.discordapp.net/attachments/1275537771573805128/1397731609435967488/image-removebg-preview_15.png?ex=6882ca80&is=68817900&hm=7c2bd75db8fb2081ccc702d1f531e4939be7825322470ec6401b3dce2303c929&=&format=webp&quality=lossless"
			
			local image = nil
			
			--if sucessGettingPhoto then
			--	image = {
			--		url = photo
			--	}
			--end

			local sucess, call = pcall(function()
				game.HttpService:PostAsync(HookId, game.HttpService:JSONEncode({
					content = ("## **Player under arest:** %s"):format(Players[highest].DisplayName);
					embeds = {
						{
							image = image;
							footer = {
								text = `A Mage named {Players[highest].Name}, attacks a village, and killed {Players[highest]:GetAttribute("NpcsKilleds") or 1} villagers`;
							}
						};
						
						{
							image = {
								url = pic;
							};
							
							description = "## The royal guard is on its way!"
						}
					}
				}))
			end)
			
			--warn(sucess, call)
			
			task.delay(4, function()
				local playerCharacter = Players[highest].Character
				local humanoid = playerCharacter:FindFirstChild("Humanoid")

				if not humanoid or (humanoid.Health <= 0) then
					return
				end
				
				local generated_position = GetValidPositionsAroundPlayer(Players[highest])
				
				for _, position: Vector3 in pairs(generated_position) do
					local clone = game.ReplicatedStorage.NpcsCache.RoyalGuard.RoyalGuard:Clone()
					clone.Parent = workspace.Npcs.RoyalGuard
					clone:MoveTo(position)
					
					local result = RoyalControll.set(
						clone, 
						Players[highest].Data.Values:GetAttribute("Level")
					)
					
					result:SetFollowTarget(humanoid)
					
					humanoid.Died:Once(function()
						clone:Destroy()
						Summoneds[Players[highest]] = nil
						Players[highest]:SetAttribute("UnderRisk", false)
					end)
					
					task.delay(120, function()
						clone:Destroy()
						Summoneds[Players[highest]] = nil
						Players[highest]:SetAttribute("UnderRisk", false)
					end)
				end
			end)
			
			task.delay(120, function()
				Players[highest]:SetAttribute("UnderRisk", false)
			end)

			Players[highest]:SetAttribute("NpcsKilleds", (Players[highest]:GetAttribute("NpcsKilleds") or 0) + 1)
		end

		warn("Killed by", highest)
		task.wait(15)
		controlled:Cleanup()    
	end)

	if not character:HasTag("IgnoreApparence") then
		Apparence(character)
	end

	--warn("---PHASE4", "NPC SETTINGS")
	controlled.Tag = tostring(controlled)

	path:Run(controlled.Target)
	controlled:Setup()

	controlled.Character:SetAttribute("Tag", controlled.Tag)
	NonPlayer.Cache[controlled.Tag] = controlled
	--warn("---PHASE5", "NPC SETTINGS")

	return controlled
end

game.ReplicatedStorage.Remotes.TalkWithHuman.OnServerInvoke = function(Player: Player, Target: Model)
	local id = Target:GetAttribute("Tag")
	local npc =  NonPlayer.Cache[id]

	if npc and npc.Character.Parent ~= workspace.Npcs.HumansMissions then
		local sucess = npc:TalkWith(Player)
		if not sucess then return end

		local npcContainMission = npc.Character:GetAttribute("MissionName") ~= nil
		local mensage

		if npcContainMission then
			local missionQuery = npc.Character:GetAttribute("MissionQuery")

			if missionQuery then
				missionQuery = MissionsMensages[missionQuery]
				mensage = missionQuery[math.random(1, #missionQuery)] :: typeof(MissionsMensages.Bandits)
			end
		else
			mensage = Mensages[math.random(1, #Mensages)] 
		end

		return true, npcContainMission, mensage.Content, mensage.Response, mensage.FormattedText
	end

	return false
end

game.ReplicatedStorage.Remotes.CancelTalk.OnServerInvoke = function(Player: Player, Target: Model)
	local id = Target:GetAttribute("Tag")
	local npc = NonPlayer.Cache[id]

	if npc then
		if npc.PlayerTarget == Player then
			npc:StopTalking()

			return true
		end

		return false, "you are not the talking player"
	end

	return false, "any"
end

game.ReplicatedStorage.Remotes.Mission.GetMissionTalkContent.OnServerInvoke = function(player: Player, npc: Model)
	local missionQuery = npc:GetAttribute("MissionQuery")

	if missionQuery then
		missionQuery = MissionsMensages[missionQuery]
		if not missionQuery then
			return print("-----------Npc dont have a query respost", npc)
		end

		local mensage = missionQuery[math.random(1, #missionQuery)] :: typeof(MissionsMensages.Wizard)

		return mensage
	end
end

return NonPlayer