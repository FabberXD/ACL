--[[

]]--
local ease = {
	instances = {},
	nextID = 1,
	object = Object(), -- used for tick
	c1 = 1.70158,
	c3 = 1.70158 + 1.0,
	c4 = (2 * math.pi) / 3,
	isNumber = function(n) return n ~= nil and (type(n) == "number" or type(n) == "integer") end
}

ease._startIfNeeded = function(self)
	if self.object.Tick == nil then
		World:AddChild(self.object)
		self.object.Tick = function(o, dt)
			local percent
			local done
			local to
			for k, instance in pairs(self.instances) do
				done = false
				instance.dt = instance.dt + dt
				percent = instance.dt / instance.duration
				if percent >= 1.0 then
					percent = 1.0
					done = true
				end
				percent = instance:fn(percent)

				for k,from in pairs(instance.from) do
					to = instance.to[k]
					local p = from + (to - from) * percent
					instance.object[k] = p
				end

				if done then
					if instance.onDone then instance.onDone() end
					self.instances[instance.id] = nil
				end
			end
		end
	end
end

ease.cancel = function(self,object) 
	local toRemove = {}
	for k, instance in pairs(self.instances) do
		if instance.object == object then
			table.insert(toRemove, k)
		end
	end
	for _, k in ipairs(toRemove) do
		self.instances[k] = nil
	end
end

ease._common = function(self,object,duration, config)
	local instance = {}
	instance.id = self.nextID
	self.nextID = self.nextID + 1
	instance.dt = 0.0
	instance.object = object
	instance.duration = duration
	instance.to = {}
	instance.from = {}
	instance.fn = function(self, v) return v end
	instance.speed = 0.0
	instance.amp = 0.0

	if config ~= nil then
		if config.onDone ~= nil and type(config.onDone) == "function" then
			instance.onDone = config.onDone
		end
	end

	self.instances[instance.id] = instance

	local m = {}
	m.__newindex = function(t, k, v)

		if t.object[k] == nil then
			error("ease: can't ease from nil field")
		end
		if v == nil then
			error("ease: can't ease to nil value")
		end

		local fieldType = type(t.object[k])
		if fieldType ~= type(v) then
			
			if (fieldType == "number" and type(v) == "integer") or 
				(fieldType == "integer" and type(v) == "number") then
					-- it's ok in that case
			elseif fieldType == "Number3" and -- see if value can be turned into Number3
				type(v) == "table" and #v == 3 and
				ease.isNumber(v[1]) and ease.isNumber(v[2]) and ease.isNumber(v[3]) then
				v = Number3(v[1], v[2], v[3])
			else
				error("ease: can't ease from " .. fieldType .. " to " .. type(v))	
			end
		end

		if fieldType == "Number3" then
			t.from[k] = t.object[k]:Copy()
			t.to[k] = v:Copy()
		elseif fieldType == "number" then
			t.from[k] = t.object[k]
			t.to[k] = v
		else
			error("ease: type not supported")
		end

		self:_startIfNeeded()
	end

	setmetatable(instance, m)

	return instance
end

ease.inSine = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) return 1.0 - math.cos((v * math.pi) * 0.5) end
	return instance
end

ease.outSine = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) return math.sin((v * math.pi) * 0.5) end
	return instance
end

ease.inOutSine = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) return  -(math.cos(math.pi * v) - 1.0) * 0.5 end
	return instance
end

ease.inBack = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) return ease.c3 * v ^ 3 - ease.c1 * v ^ 2 end
	return instance
end

ease.outBack = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) return 1.0 + ease.c3 * (v - 1.0) ^ 3 + ease.c1 * (v - 1.0) ^ 2 end
	return instance
end

ease.inQuad = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) return v * v end
	return instance
end

ease.outQuad = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) return 1.0 - (1.0 - v) * (1.0 - v) end
	return instance
end

ease.inOutQuad = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) 
		if v < 0.5 then
			return 2 * v * v
		else
			local a = -2 * v + 2
			return 1 - a * a / 2
		end
	end
	return instance
end

ease.outElastic = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) 
		if v == 0 then
			return 0
		elseif v == 1 then
			return 1
		else
			return 2 ^ (-10 * v) * math.sin((v * 10 - 0.75) * ease.c4) + 1
		end
	end
	return instance
end

ease.inElastic = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(self, v) 
		if v == 0 then
			return 0
		elseif v == 1 then
			return 1
		else
			return -(2 ^ (10 * v - 10) * math.sin((v * 10 - 10.75) * ease.c4))
		end
	end
	return instance
end

return ease
