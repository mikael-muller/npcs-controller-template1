local Player = game:GetService("Players")
local MemoryHeap = ""

task.spawn(function()
	while task.wait() do
		local stunned = Player.LocalPlayer.Character:HasTag("Stunned")

		if stunned then
			script.Parent.Stunned.BackgroundColor3 = Color3.fromRGB(85, 255, 0)
		else
			script.Parent.Stunned.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end	
	end
end)

task.defer(function()
	local start = os.clock()
	while task.wait(2) do
		local date = os.date("!*t", os.time())
		MemoryHeap ..= ("%s.%s, %sgb \n"):format(date.hour,date.min, game:GetService("Stats"):GetTotalMemoryUsageMb()/1000)
		script.Parent.MemoryHistory.Text = MemoryHeap	
		
		if os.clock() - start >= 15 then
			MemoryHeap = ""
			start = os.clock()
		end
	end
end)

Player.LocalPlayer.Character:GetAttributeChangedSignal("ClientState"):Connect(function()
	local clientState = Player.LocalPlayer.Character:GetAttribute("ClientState")
	script.Parent.StateClient.Text = "ClientState: "..clientState
end)

Player.LocalPlayer.Character:GetAttributeChangedSignal("State"):Connect(function()
	local serveState = Player.LocalPlayer.Character:GetAttribute("State")
	script.Parent.StateServer.Text = "ServerState: "..serveState
end)

script.Parent.MemoryUsage.Activated:Connect(function(inputObject: InputObject, clickCount: number) 
	script.Parent.MemoryHistory.Visible = not script.Parent.MemoryHistory.Visible	
end)

game.ContextActionService:BindAction("Aaaaaa", function(_, start)
	if start == Enum.UserInputState.Begin then
		script.Parent.Enabled = not script.Parent.Enabled
	end
end, false, Enum.KeyCode.B)