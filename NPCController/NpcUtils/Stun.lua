--local Stun do
--	Stun = {}

--	function Stun.new(StunFactor: number?, limit: number?)
--		local self = setmetatable({}, {__index = Stun})
--		self.Total = os.clock()
--		self.StunFactor = StunFactor or 1
--		self.Limit = limit or math.huge

--		return self :: typeof(Stun)
--	end

--	function Stun:Add(count: number)
--		if (self:Get() + count) >=  self.Limit then
--			return print("Limit reached", self:Get())
--		end
		
--		count *= self.StunFactor
--		self.Total = os.clock() 
--			+ count + math.max(0, (self.Total) - os.clock())
--	end
	
--	function Stun:Get(): number
--		return math.max(0, math.abs(os.clock() - self.Total))
--	end
	
--	function Stun:Finished(): boolean
--		return os.clock() > self.Total
--	end
--end

local Stun do
	Stun = {}
	Stun.Cache = {}
	
	function Stun.new(owner, limit: number?)
		local result = setmetatable({}, {__index = Stun})
		result.Owner = owner
		result.Total = 0
		result.Limit = limit or math.huge
		
		return result
	end
	
	function Stun:Add(total: number)
		self.Total += total
		
		if not Stun.Cache[self.Owner] then
			Stun.Cache[self.Owner] = task.spawn(function()
				local start = os.clock()
				
				self.Owner:SetAttribute("Stunned", true)
				
				repeat
					task.wait()
				until (os.clock() - start) >= self.Total
				
				Stun.Cache[self.Owner] = nil
				self.Total = 0
				self.Owner:SetAttribute("Stunned", false)
			end)
		end
	end
	
	function Stun:Get()
		return self.Total
	end
	
	function Stun:Finished()
		--print(self.Total, Stun.Cache[self.Owner], Stun.Cache)
		return not (Stun.Cache[self.Owner] ~= nil)
	end	
end

return Stun