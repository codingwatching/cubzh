--- This module allows you to modify values over a given period of time and following different variation curves.
---@code -- A few examples:
---	local t = {x = 0.0}
--- -- All ease functions return an instance controlling how
--- -- values change over time, and on what duration:
--- local instance = ease:inSine(t, 1.0)
--- instance.x = 10.0 -- x will go from 0 to 10 in 1 second following inSine curve
---	--- -- It's also possible to do this in one line:	--- ease:inSine(t, 1.0).x = 10.0
---	--- -- The returned instance is useful to cancel the movement:
--- local instance = ease:outBack(someShape, 12.0)
--- instance.Position = {10, 10, 10}
--- instance:cancel()
---	--- -- An optional easeConfig table can be provided when creating easing instances:	--- local callback = function() print("done animating") end
--- local config = { onDone = callback }
--- -- triggers `callback` when done (after 1 second)
--- ease:inSine(t, 1.0, config)
--- -- You can also pause and resume animations:
--- local instance = ease:inSine(t, 1.0)
--- instance.x = 10.0
--- instance:pause() -- pauses the animation
--- instance:resume() -- resumes the animation

---@type ease

local ease = {}

-- Pre-computed constants for improved performance
local HALF_PI = math.pi * 0.5
local PI = math.pi
local TWO_PI_DIV_3 = (2 * math.pi) / 3
local C1 = 1.70158
local C3 = C1 + 1.0
local NEXT_ID = 1
local INSTANCES = {}
local TICK_LISTENER = nil

local rotation = Rotation()
local color = Color(0, 0, 0)
local percent
local done
local to
local p

local function startTickListenerIfNeeded()
	if TICK_LISTENER == nil then
		TICK_LISTENER = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
			for _, instance in pairs(INSTANCES) do
				done = false
				instance.dt = instance.dt + dt
				percent = instance.dt / instance.duration
				if percent >= 1.0 then
					percent = 1.0
					done = true
				end
				percent = instance:fn(percent)

				for k, from in pairs(instance.from) do
					to = instance.to[k]
					if typeof(from) == "Rotation" then
						p = rotation
						p:Lerp(from, to, percent)
					elseif typeof(from) == "Color" then
						p = color
						p:Lerp(from, to, percent)
					else
						p = from + (to - from) * percent
					end
					instance.object[k] = p
				end

				if instance.onUpdate then
					instance.onUpdate(instance.object)
				end

				if done then
					if instance.onDone then
						instance.onDone(instance.object)
					end
					INSTANCES[instance.id] = nil
				end
			end
		end)
	end
end

ease._common = function(self, object, duration, config)
	local instance = {}
	instance.id = NEXT_ID
	NEXT_ID = NEXT_ID + 1
	instance.dt = 0.0
	instance.object = object
	instance.duration = duration
	instance.to = {}
	instance.from = {}
	instance.fn = function(_, v)
		return v
	end
	instance.speed = 0.0
	instance.amp = 0.0

	if config ~= nil then
		if config.onDone ~= nil and type(config.onDone) == "function" then
			instance.onDone = config.onDone
		end
		if config.onUpdate ~= nil and type(config.onUpdate) == "function" then
			instance.onUpdate = config.onUpdate
		end
	end

	INSTANCES[instance.id] = instance

	local m = {}
	m.__newindex = function(t, k, v)
		if t.object[k] == nil then
			error("ease: can't ease from nil field")
		end
		if v == nil then
			error("ease: can't ease to nil value")
		end

		local fieldType = typeof(t.object[k])
		if fieldType ~= typeof(v) then
			if fieldType == "Number3" and typeof(v) == "table" then -- see if table can be turned into Number3
				local len = #v
				if len == 1 and type(v[1]) == "number" then
					v = Number3(v[1], t.object[k].Y, t.object[k].Z)
				elseif len == 2 and type(v[1]) == "number" and type(v[2]) == "number" then
					v = Number3(v[1], v[2], t.object[k].Z)
				elseif len == 3 and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" then
					v = Number3(v[1], v[2], v[3])
				else
					error("ease: can't ease from " .. fieldType .. " to " .. typeof(v))
				end
			elseif fieldType == "Rotation" and typeof(v) == "table" then -- see if table can be turned into Rotation
				local len = #v
				if len == 1 and type(v[1]) == "number" then
					v = Rotation(v[1], t.object[k].Y, t.object[k].Z)
				elseif len == 2 and type(v[1]) == "number" and type(v[2]) == "number" then
					v = Rotation(v[1], v[2], t.object[k].Z)
				elseif len == 3 and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" then
					v = Rotation(v[1], v[2], v[3])
				else
					error("ease: can't ease from " .. fieldType .. " to " .. typeof(v))
				end
			else
				error("ease: can't ease from " .. fieldType .. " to " .. typeof(v))
			end
		end

		if fieldType == "Number3" or fieldType == "Rotation" then
			t.from[k] = t.object[k]:Copy()
			t.to[k] = v:Copy()
		elseif fieldType == "number" then
			t.from[k] = t.object[k]
			t.to[k] = v
		elseif fieldType == "Color" then
			local c = t.object[k]
			t.from[k] = Color(c.R, c.G, c.B, c.A)
			t.to[k] = Color(v.R, v.G, v.B, v.A)
		else
			error("ease: type not supported")
		end

		startTickListenerIfNeeded()
	end

	setmetatable(instance, m)

	return instance
end

---@function linear Go to target value(s) following linear curve.
---@code ease:linear(someObject, 1.0).Position = {10, 10, 10}
ease.linear = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		return v
	end
	return instance
end

---@function inSine Go to target value(s) following inSine curve.
---@param self ease
---@param t table
---@param duration number
---@param config? easeConfig
---@return easeInstance
---@code local t = {x = 0.0}
--- local instance = ease:inSine(t, 1.0)
--- intance.x = 2.0 -- x will go from 0 to 2 in 1 second
--- -- in one line:
--- ease:inSine(someObject, 1.0).Position = {10, 10, 10}
ease.inSine = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		return 1.0 - math.cos(v * HALF_PI)
	end
	return instance
end

---@function outSine Go to target value(s) following outSine curve.
---@code ease:outSine(someObject, 1.0).Position = {10, 10, 10}
ease.outSine = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		return math.sin(v * HALF_PI)
	end
	return instance
end

---@function inOutSine Go to target value(s) following inOutSine curve.
---@code ease:inOutSine(someObject, 1.0).Position = {10, 10, 10}
ease.inOutSine = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		return -(math.cos(PI * v) - 1.0) * 0.5
	end
	return instance
end

---@function inBack Go to target value(s) following inBack curve.
---@code ease:inBack(someObject, 1.0).Position = {10, 10, 10}
ease.inBack = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		return C3 * v ^ 3 - C1 * v ^ 2
	end
	return instance
end

---@function outBack Go to target value(s) following outBack curve.
---@code ease:outBack(someObject, 1.0).Position = {10, 10, 10}
ease.outBack = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		local vm1 = v - 1.0
		return 1.0 + C3 * vm1 ^ 3 + C1 * vm1 ^ 2
	end
	return instance
end

---@function inQuad Go to target value(s) following inQuad curve.
---@code ease:inQuad(someObject, 1.0).Position = {10, 10, 10}
ease.inQuad = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		return v ^ 2
	end
	return instance
end

---@function outQuad Go to target value(s) following outQuad curve.
---@code ease:outQuad(someObject, 1.0).Position = {10, 10, 10}
ease.outQuad = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		local vm1 = 1.0 - v
		return 1.0 - vm1 * vm1
	end
	return instance
end

---@function inOutQuad Go to target value(s) following inOutQuad curve.
---@code ease:inOutQuad(someObject, 1.0).Position = {10, 10, 10}
ease.inOutQuad = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		if v < 0.5 then
			return 2 * v * v
		else
			local a = -2 * v + 2
			return 1 - a * a / 2
		end
	end
	return instance
end

---@function outElastic Go to target value(s) following outElastic curve.
---@code ease:outElastic(someObject, 1.0).Position = {10, 10, 10}
ease.outElastic = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		if v == 0 then
			return 0
		elseif v == 1 then
			return 1
		else
			return 2 ^ (-10 * v) * math.sin((v * 10 - 0.75) * TWO_PI_DIV_3) + 1
		end
	end
	return instance
end

---@function inElastic Go to target value(s) following inElastic curve.
---@code ease:inElastic(someObject, 1.0).Position = {10, 10, 10}
ease.inElastic = function(self, object, duration, config)
	local instance = self:_common(object, duration, config)
	instance.fn = function(_, v)
		if v == 0 then
			return 0
		elseif v == 1 then
			return 1
		else
			return -(2 ^ (10 * v - 10) * math.sin((v * 10 - 10.75) * TWO_PI_DIV_3))
		end
	end
	return instance
end

---@type easeInstance
--- An [easeInstance] is a [table] returned by all ease functions to provide control over the ongoing animation.

---@function cancel Cancels easing when called.
---@code local instance = ease:outBack(someObject, 1.0).Position = {10, 10, 10}
--- instance:cancel()
ease.cancel = function(self, object)
	local toRemove = {}
	for k, instance in pairs(INSTANCES) do
		if instance.object == object then
			table.insert(toRemove, k)
		end
	end
	for _, k in ipairs(toRemove) do
		INSTANCES[k] = nil
	end
end

---@type easeConfig
---@property onDone function

return ease
