-- Camera is an engine component that has some of its implementation in C++ and the rest in Luau. 
-- This module is the Luau part.

local mod = {}

-- cameraBehaviors is a table that contains behavior configurations for each camera.
-- each entry is a table of that format:
-- {
	-- config = { camera, target, targetIsPlayer, ... },
	-- listeners = {},
-- }
cameraBehaviors = {}

conf = require("config")

worldObject = Object() -- object in World used to compute positions
worldObject:SetParent(World)

function clearListeners(entry)
	if type(entry.listeners) ~= "table" then
		error("camera - internal error (1)")
	end
	for _, listener in ipairs(entry.listeners) do
		listener:Remove()
	end
	entry.listeners = {}
end

function remove(entry)
	clearListeners(entry)
	cameraBehaviors[entry.config.camera] = nil
end

function insert(config)
	local camera = config.camera

	if typeof(camera) ~= "Camera" then
		error("camera - internal error (2)")
	end

	local c = cameraBehaviors[camera]
	if c then
		remove(c)
	end

	camera.Tick = nil

	local entry = {
		config = config,
		listeners = {},
	}
	cameraBehaviors[camera] = entry

	return entry
end

function showAvatar(entry)
	if not entry.config.targetIsPlayer then
		return
	end

	local player = entry.config.target
	
	player.Head.IsHidden = false
	player.Head.IsHiddenSelf = false
	player.Body.IsHiddenSelf = false
	player.RightArm.IsHiddenSelf = false
	player.LeftArm.IsHiddenSelf = false
	player.RightHand.IsHiddenSelf = false
	player.LeftHand.IsHiddenSelf = false
	player.RightLeg.IsHiddenSelf = false
	player.LeftLeg.IsHiddenSelf = false
	player.RightFoot.IsHiddenSelf = false
	player.LeftFoot.IsHiddenSelf = false

	player.Avatar:updateConfig({
		eyeBlinks = true,
		hiddenEquipments = {},
	})
end

function hideAvatar(entry)
	if not entry.config.targetIsPlayer then
		return
	end

	local player = entry.config.target

	player.Head.IsHidden = false
	player.Head.IsHiddenSelf = true
	player.Body.IsHiddenSelf = true
	player.RightArm.IsHiddenSelf = true
	player.LeftArm.IsHiddenSelf = true
	player.RightHand.IsHiddenSelf = true
	player.LeftHand.IsHiddenSelf = true
	player.RightLeg.IsHiddenSelf = true
	player.LeftLeg.IsHiddenSelf = true
	player.RightFoot.IsHiddenSelf = true
	player.LeftFoot.IsHiddenSelf = true

	player.Avatar:updateConfig({
		eyeBlinks = false,
		hiddenEquipments = { "hair", "jacket", "pants", "boots" },
	})
end

function turnOffPhysics(camera)
	camera.Physics = PhysicsMode.Disabled
	camera.CollisionGroups = {}
	camera.CollidesWithGroups = {}
end

mod.setFree = function(self, config)
	if self ~= mod then
		error("camera:setFree(config) should be called with `:`", 2)
	end
	if config ~= nil and type(config) ~= "table" then
		error("camera:setFree(config) - config should be a table", 2)
	end

	config = { camera = config.camera or Camera }
	local camera = config.camera

	insert(config)

	turnOffPhysics(config.camera)

	-- `true` parameter allows to maintain the World position
	camera:SetParent(World, true)
end

mod.setSatellite = function(self, config)
	if self ~= mod then
		error("camera:setSatellite(config) should be called with `:`", 2)
	end
	if type(config) ~= "table" then
		error("camera:setSatellite(config) - config should be a table", 2)
	end
	local _config = { -- default config
		camera = Camera, -- main Camera by default
		target = nil, -- must be set
		distance = 30,
	}

	if config then
		for k, v in pairs(_config) do
			if typeof(config[k]) == typeof(v) then
				_config[k] = config[k]
			end
		end
		_config.target = config.target
	end

	if _config.target == nil then
		error("camera:setSatellite(config) - config.target can't be nil", 2)
	end

	if
		type(_config.target) == "table"
		and type(_config.target[1]) == "number"
		and type(_config.target[2]) == "number"
		and type(_config.target[3]) == "number"
	then
		_config.target = Number3(_config.target)
	end

	config = _config

	local entry = insert(config)

	local camera = config.camera

	turnOffPhysics(camera)
	camera:SetParent(World, true)

	local refresh = function()
		local target = config.target.Position or config.target
		camera.Position = target - camera.Forward * config.distance
	end

	listener = LocalEvent:Listen(LocalEvent.Name.Tick, function()
		refresh()
	end)
	table.insert(entry.listeners, listener)
	refresh()
end

mod.setFirstPerson = function(self, config)
	if self ~= mod then
		error("camera:setFirstPerson(config) should be called with `:`", 2)
	end
	if type(config) ~= "table" then
		error("camera:setFirstPerson(config) - config should be a table", 2)
	end

	local _config = { -- default config
		showPointer = false,
		camera = Camera, -- main Camera by default
		target = nil, -- must be set
		offset = Number3(0, 0, 0),
	}

	if config then
		for k, v in pairs(_config) do
			if typeof(config[k]) == typeof(v) then
				_config[k] = config[k]
			end
		end
		_config.target = config.target
	end

	if _config.target == nil then
		error("camera:setFirstPerson(config) - config.target can't be nil", 2)
	end

	_config.targetIsPlayer = typeof(_config.target) == "Player"

	config = _config
	local camera = config.camera

	local entry = insert(config)

	turnOffPhysics(camera)

	if config.targetIsPlayer then
		camera:SetParent(config.target.Head)
	else
		camera:SetParent(config.target)
	end

	if config.offset then
		camera.LocalPosition:Set(config.offset)
	else
		camera.LocalPosition:Set(Number3.Zero)
	end

	camera.LocalRotation:Set(0, 0, 0)

	if config.showPointer then
		Pointer:Show()
	else
		Pointer:Hide()
	end

	hideAvatar(entry)
end

mod.setThirdPerson = function(self, config)
	if self ~= mod then
		error("camera:setThirdPerson(config) should be called with `:`", 2)
	end

	local defaultConfig = { -- default config
		showPointer = true,
		distance = 40,
		minDistance = 0,
		maxDistance = 75,
		camera = Camera, -- main Camera by default
		target = nil, -- must be set
		offset = nil, -- offset from target
		rotationOffset = nil,
		rotation = nil,
		rigidity = 0.5,
		collidesWithGroups = Map.CollisionGroups,
		rotatesWithTarget = true,
	}

	config = conf:merge(defaultConfig, config, {
		acceptTypes = {
			target = { "Object", "Shape", "MutableShape", "Number3", "Player", "Quad" },
			offset = { "Number3" },
			rotationOffset = { "Rotation", "Number3", "table" },
			rotation = { "Rotation", "Number3", "table" },
			collidesWithGroups = { "CollisionGroups", "table" },
		},
	})

	if config.target == nil then
		error("camera:setThirdPerson(config) - config.target can't be nil", 2)
	end

	-- NOTE (aduermael): it would be nice to remove this hardcoded system for Players
	config.targetIsPlayer = typeof(config.target) == "Player"

	local entry = insert(config)

	turnOffPhysics(config.camera)

	local camera = config.camera
	local showPointer = config.showPointer
	local minDistance = config.minDistance
	local maxDistance = config.maxDistance
	local target = config.target
	local collidesWithGroups = config.collidesWithGroups
	local offset = config.offset or Number3.Zero
	local rotationOffset = config.rotationOffset or Rotation(0, 0, 0)
	local targetIsPlayer = typeof(target) == "Player"
	local targetHasRotation = typeof(target) == "Object"
		or typeof(target) == "Shape"
		or typeof(target) == "MutableShape"
	local rotatesWithTarget = config.rotatesWithTarget

	camera:SetParent(World)
	if config.rotation then
		if not pcall(function()
			worldObject.Rotation:Set(config.rotation)
		end) then
			error("can't set camera rotation", 2)
		end
	end

	if showPointer then
		Pointer:Show()
	else
		Pointer:Hide()
	end

	local camDistance = config.distance
	local listener

	listener = LocalEvent:Listen(LocalEvent.Name.PointerWheel, function(delta)
		camDistance = camDistance + delta * 0.1
		camDistance = math.min(maxDistance, camDistance)
		camDistance = math.max(minDistance, camDistance)
	end)
	table.insert(entry.listeners, listener)

	local boxHalfSize = Number3(1, 1, 1)
	local box = Box()
	local impact
	local distance
	local rigidityFactor = config.rigidity * 60.0
	local lerpFactor

	listener = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
		worldObject.Position:Set(target.Position + offset)

		if targetIsPlayer then
			worldObject.Position.Y = worldObject.Position.Y + target.CollisionBox.Max.Y * target.Scale.Y
			if rotatesWithTarget then
				worldObject.Rotation:Set(target.Head.Rotation * rotationOffset)
			end
		elseif targetHasRotation then
			if rotatesWithTarget then
				worldObject.Rotation:Set(target.Rotation * rotationOffset)
			else
				worldObject.Rotation:Set(rotationOffset)
			end
		else
			worldObject.Rotation:Set(rotationOffset)
		end

		box.Min = worldObject.Position - boxHalfSize -- box.Min:Set doesn't work
		box.Max = worldObject.Position + boxHalfSize -- box.Max:Set doesn't work

		impact = box:Cast(Number3.Up, 3, collidesWithGroups)

		distance = 3
		if impact and impact.Distance < distance then
			distance = impact.Distance
		end

		worldObject.Position = worldObject.Position + Number3.Up * distance

		box.Min = worldObject.Position - boxHalfSize -- box.Min:Set doesn't work
		box.Max = worldObject.Position + boxHalfSize -- box.Max:Set doesn't work

		impact = box:Cast(camera.Backward, camDistance, collidesWithGroups)

		if camDistance < 4 then -- in Head, make it invisible
			if targetIsPlayer then
				hideAvatar(entry)
				if target.equipments.hair then
					target.equipments.hair.IsHiddenSelf = true
				end
			end
		else
			if targetIsPlayer then
				showAvatar(entry)
				if target.equipments.hair then
					target.equipments.hair.IsHiddenSelf = false
				end
			end
		end

		distance = camDistance
		if impact and impact.Distance < distance then
			distance = impact.Distance * 0.95
		end

		lerpFactor = math.min(rigidityFactor * dt, 1.0)
		camera.Position:Lerp(camera.Position, worldObject.Position + worldObject.Backward * distance, lerpFactor)
		camera.Rotation:Slerp(camera.Rotation, worldObject.Rotation, lerpFactor)
	end)
	table.insert(entry.listeners, listener)
end

mod.unsetBehavior = function(self, camera)
	if typeof(camera) ~= "Camera" then
		error("unsetBehavior(camera) - camera should be a Camera")
	end

	local c = cameraBehaviors[camera]
	if c then
		remove(c)
	end
end

-- setBehavior is used when setting camera.Behavior
mod.setBehavior = function(self, config)
	if self ~= mod then
		error("camera:setConfig(config) should be called with `:`", 2)
	end

	local defaultConfig = {
		camera = Camera, -- main Camera by default
		positionTarget = nil, -- target to follow
		positionTargetOffset = nil, -- offset from the target
		positionTargetBackoffDistance = 40, -- distance from the target
		positionTargetMinBackoffDistance = 0, -- minimum distance from the target
		positionTargetMaxBackoffDistance = 75, -- maximum distance from the target
		rotationTarget = nil, -- target to rotate to (if target has a rotation then rotates to target.Rotation)
		rotationTargetOffset = nil, -- offset from the rotation target
		rigidity = 0.5, -- rigidity of the camera
		collidesWithGroups = nil, -- doesn't collide with anything by default
		collisionBoxSize = Number3(2, 2, 2),
		zoom = true, -- if true, camera zooms in/out with pinch gesture and mouse wheel automatically
	}

	config = conf:merge(defaultConfig, config, {
		acceptTypes = {
			camera = { "Camera" },
			positionTarget = { "Object", "Shape", "MutableShape", "Number3", "Player", "Quad", "Mesh" },
			positionTargetOffset = { "Number3", "table" },
			rotationTarget = { "Object", "Shape", "MutableShape", "Number3", "Player", "Quad", "Mesh", "Rotation" },
			rotationTargetOffset = { "Rotation", "Number3", "table" },
			collidesWithGroups = { "CollisionGroups", "table" },
		},
		modifyOverrides = true,
	})

	config.version = 2

	local entry = insert(config)

	turnOffPhysics(config.camera)

	local camera = config.camera

	-- position
	local positionTarget
	if config.positionTarget ~= nil then
		if typeof(config.positionTarget) == "Number3" then
			positionTarget = config.positionTarget
		elseif typeof(config.positionTarget.Position) == "Number3" then
			positionTarget = config.positionTarget.Position
		else
			error("can't assign position target", 2)
		end
	end
	local positionTargetOffset = config.positionTargetOffset or Number3.Zero
	
	-- rotation
	local rotationTarget
	if config.rotationTarget ~= nil then
		if typeof(config.rotationTarget) == "Rotation" then
			rotationTarget = config.rotationTarget
		elseif typeof(config.rotationTarget) == "Number3" then
			rotationTarget = Rotation(config.rotationTarget)
		elseif typeof(config.rotationTarget.Rotation) == "Rotation" then
			rotationTarget = config.rotationTarget.Rotation
		else
			error("can't assign rotation target", 2)
		end
	end
	local rotationTargetOffset = Rotation(0, 0, 0)
	if config.rotationTargetOffset ~= nil then
		if typeof(config.rotationTargetOffset) == "Rotation" then
			rotationTargetOffset = config.rotationTargetOffset
		elseif typeof(config.rotationTargetOffset) == "Number3" then
			rotationTargetOffset = Rotation(config.rotationTargetOffset)
		elseif typeof(config.rotationTargetOffset) == "table" then
			rotationTargetOffset = Rotation(config.rotationTargetOffset[1], config.rotationTargetOffset[2], config.rotationTargetOffset[3])
		else
			error("can't assign rotation target offset", 2)
		end
	end
	
	-- others
	local rigidity = config.rigidity
	local collidesWithGroups = config.collidesWithGroups
	local collisionBoxSize = config.collisionBoxSize

	camera:SetParent(World)

	local function clampDistance()
		config.positionTargetBackoffDistance = math.max(config.positionTargetMinBackoffDistance, math.min(config.positionTargetMaxBackoffDistance, config.positionTargetBackoffDistance))
	end
	clampDistance()
	
	local listener
	listener = LocalEvent:Listen(LocalEvent.Name.PointerWheel, function(delta)
		config.positionTargetBackoffDistance += delta * 0.1
		clampDistance()
	end)
	table.insert(entry.listeners, listener)

	if Client.HasTouchScreen and config.zoom then
		local touch1 = nil
		local touch2 = nil
		local pinchInitialDistance = nil
		local pinchInitialTan = nil

		listener = LocalEvent:Listen(LocalEvent.Name.PointerDown, function(pe)
			if pe.Index == 1 then
				touch1 = pe
			elseif pe.Index == 2 then
				touch2 = pe
			end
			if touch1 ~= nil and touch2 ~= nil then
				pinchInitialDistance = config.positionTargetBackoffDistance
				pinchInitialTan = math.tan(touch1.Direction:Angle(touch2.Direction))
			end
		end)
		table.insert(entry.listeners, listener)

		listener = LocalEvent:Listen(LocalEvent.Name.PointerDrag, function(pe)
			if pe.Index == 1 then
				touch1 = pe
			elseif pe.Index == 2 then
				touch2 = pe
			end
			if pinchInitialTan ~= nil and pinchInitialDistance ~= nil then 
				local angle = touch1.Direction:Angle(touch2.Direction)
				config.positionTargetBackoffDistance = pinchInitialDistance * pinchInitialTan / math.tan(angle)
				clampDistance()
			end
		end)
		table.insert(entry.listeners, listener)

		listener = LocalEvent:Listen(LocalEvent.Name.PointerUp, function(pe)
			if pe.Index == 1 then
				touch1 = nil
			elseif pe.Index == 2 then
				touch2 = nil
			end
			if touch1 == nil or touch2 == nil then
				pinchInitialDistance = nil
				pinchInitialTan = nil
			end
		end)
		table.insert(entry.listeners, listener)
	end

	local boxHalfSize = collisionBoxSize * 0.5
	local box = Box()
	local rigidityFactor = config.rigidity * 60.0
	local impact
	local lerpFactor
	local backoffDistance

	listener = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)

		if rotationTarget ~= nil then
			worldObject.Rotation:Set(rotationTarget * rotationTargetOffset)
		else
			worldObject.Rotation:Set(camera.Rotation * rotationTargetOffset)
		end

		if positionTarget ~= nil then
			worldObject.Position:Set(positionTarget + positionTargetOffset)

			box.Min = worldObject.Position - boxHalfSize -- box.Min:Set doesn't work
			box.Max = worldObject.Position + boxHalfSize -- box.Max:Set doesn't work
			
			impact = box:Cast(worldObject.Backward, distance, collidesWithGroups)
			
			backoffDistance = config.positionTargetBackoffDistance
			if impact and impact.Distance < backoffDistance then
				backoffDistance = impact.Distance
			end

			lerpFactor = math.min(rigidityFactor * dt, 1.0)

			camera.Position:Lerp(camera.Position, worldObject.Position + worldObject.Backward * backoffDistance, lerpFactor)
			camera.Rotation:Slerp(camera.Rotation, worldObject.Rotation, lerpFactor)
		end
	end)
	table.insert(entry.listeners, listener)

	return entry
end
-- legacy funtion name
mod.setConfig = mod.setBehavior

return mod
