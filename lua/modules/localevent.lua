--- This module allows to send or listen for local events.
--- The difference with [Event]s is that they're not sent to the server or other clients and only meant to be consumed locally.

--- A local event is sent with a name and any number of arguments, like so:

---@code
--- LocalEvent:Send("some_name", "foo", "bar", 123)

---@text
--- Corresponding listeners can be declared like this:

---@code
--- local l = LocalEvent:Listener("some_name", function(a, b, c)
--- 	-- prints "foo", "bar", 123 when calling
--- 	-- `LocalEvent:Send("some_name", "foo", "bar", 123)`
--- 	print(a, b, c)
--- end)
---
--- -- Listeners created first receive events first by default.
--- -- A listener can return `true` to capture the event
--- -- and prevent next listeners from receiving it too.
--- local l = LocalEvent:Listener("some_name", function(a, b, c)
--- 	print(a, b, c)
--- 	return true
--- end)
---
--- -- An optional config table can be provided when creating a listener
--- -- For now the only supported config field is `topPriority`.
--- -- Setting `config.topPriority` allows to be become the first receiving
--- -- listener even if not created first.
--- local l = LocalEvent:Listener("some_name", function(a, b, c)
--- 	print(a, b, c) -- print happens before other "some_name" listener callbacks
--- end, { topPriority = true })

-- indexed by event name,
-- each entry contains listeners in insertion order
listeners = {}

-- indexed by event name,
-- each entry contains listeners in insertion order
topPrioritySystemListeners = {}

localevent = {}

mt = {
	__tostring = function()
		return "[LocalEvent]"
	end,
	__type = "LocalEvent",
}
setmetatable(localevent, mt)

-- A list of reserved platform event names.
-- Event names can be anything (any variable, of any type)
localevent.name = {
	Tick = 1,
	AvatarLoaded = 2,
	KeyboardInput = 3, -- callback: function(char, keyCode, modifiers, down)
	VirtualKeyboardShown = 4, -- callback: function(keyboardHeight)
	VirtualKeyboardHidden = 5, -- callback: function()
	ScreenDidResize = 6, -- callback: function(width, height)
	ClientFieldSet = 7, -- callback: function(fieldName)
	PointerShown = 8, -- callback: function()
	PointerHidden = 9, -- callback: function()
	PointerDown = 10,
	PointerUp = 11,
	PointerDragBegin = 12,
	PointerDrag = 13,
	PointerDragEnd = 14,
	HomeMenuOpened = 15,
	HomeMenuClosed = 16,
	PointerClick = 17, -- down then up without moving
	PointerWheel = 18, -- callback function: function(delta)
	PointerCancel = 19, -- happens when pointer leaves the screen without proper release event
	PointerLongPress = 20,
	PointerMove = 21, -- happens only with a mouse
	Action1Set = 22, -- called when Client.Action1 is set, callback: function(fn) (fn can be nil)
	Action2Set = 23, -- called when Client.Action2 is set, callback: function(fn) (fn can be nil)
	Action3Set = 24, -- called when Client.Action3 is set, callback: function(fn) (fn can be nil)
	Action1ReleaseSet = 25, -- called when Client.Action1Release is set, callback: function(fn) (fn can be nil)
	Action2ReleaseSet = 26, -- called when Client.Action2Release is set, callback: function(fn) (fn can be nil)
	Action3ReleaseSet = 27, -- called when Client.Action3Release is set, callback: function(fn) (fn can be nil)
	DirPadSet = 28,
	AnalogPadSet = 29,
	AnalogPad = 30, -- callback function: function(dx,dy)
	DirPad = 31, -- callback function: function(x,y) x & y between -1 & 1
	-- CloseChat = 32, -- REMOVED AFTER 0.0.53
	OnPlayerJoin = 33,
	OnPlayerLeave = 34,
	DidReceiveEvent = 35,
	InfoMessage = 36,
	WarningMessage = 37,
	ErrorMessage = 38,
	SensitivityUpdated = 39,
	OnChat = 40, -- triggered when a chat message is submitted by the local user
	OnStart = 41, -- triggered when world starts, after everything has been loaded
	CppMenuStateChanged = 42, -- needed while Cubzh still uses a few C++ menus (code editor & multiline inputs)
	LocalAvatarUpdate = 43,
	ReceivedEnvironmentToLaunch = 44,
	-- ChatMessage can only be sent by system.
	-- callback: function(message, sender, status, uuid, localUUID) -- status: "pending", "error", "ok", "reported"
	ChatMessage = 45,
	FailedToLoadWorld = 46, -- callback: function(msgInfo)
	ServerConnectionSuccess = 47,
	ServerConnectionLost = 48,
	ServerConnectionFailed = 49,
	ServerConnectionStart = 50, -- called when starting to establish connection
	OnWorldObjectLoad = 51,
	Log = 52, -- callback({type = info(1)|warning(2)|error(3), message = "...", date = "%m-%d-%YT%H:%M:%SZ"})
	ChatMessageACK = 53, -- callback: function(uuid, localUUID, status) -- status: "error", "ok", "reported"
	ActiveTextInputUpdate = 54, -- callback: function(string, cursorStart, cursorEnd)
	ActiveTextInputClose = 55, -- callback: function()
	ActiveTextInputDone = 56, -- callback: function()
	ActiveTextInputNext = 57, -- callback: function()
	AppDidBecomeActive = 58, -- callback: function()
	DidReceivePushNotification = 59, -- callback: function(title, body, category, badge)
	NotificationCountDidChange = 60, -- callback: function() -- doesn't provide count, API request should be sent to obtain it.
	WorldRequested = 61, -- callback: function() -- doesn't provide information about what world for privacy purposes

	Action1 = 62,
	Action1Release = 63,
	Action2 = 64,
	Action2Release = 65,
	Action3 = 66,
	Action3Release = 67,
}
localevent.Name = localevent.name

local names = localevent.name

local limited = {}
limited[names.Tick] = true
limited[names.AvatarLoaded] = true
limited[names.KeyboardInput] = true
limited[names.VirtualKeyboardShown] = true
limited[names.VirtualKeyboardHidden] = true
limited[names.ScreenDidResize] = true
limited[names.ClientFieldSet] = true
limited[names.PointerShown] = true
limited[names.PointerHidden] = true
limited[names.PointerDown] = true
limited[names.PointerUp] = true
limited[names.PointerClick] = true
limited[names.PointerDragBegin] = true
limited[names.PointerDrag] = true
limited[names.PointerDragEnd] = true
limited[names.HomeMenuOpened] = true
limited[names.HomeMenuClosed] = true
limited[names.PointerWheel] = true
limited[names.PointerCancel] = true
limited[names.PointerLongPress] = true
limited[names.PointerMove] = true
limited[names.Action1Set] = true
limited[names.Action2Set] = true
limited[names.Action3Set] = true
limited[names.Action1ReleaseSet] = true
limited[names.Action2ReleaseSet] = true
limited[names.Action3ReleaseSet] = true
limited[names.DirPadSet] = true
limited[names.AnalogPadSet] = true
limited[names.AnalogPad] = true
limited[names.DirPad] = true
limited[names.OnPlayerJoin] = true
limited[names.OnPlayerLeave] = true
limited[names.DidReceiveEvent] = true
limited[names.InfoMessage] = true
limited[names.WarningMessage] = true
limited[names.ErrorMessage] = true
limited[names.OnChat] = true
limited[names.CppMenuStateChanged] = true
limited[names.LocalAvatarUpdate] = true
limited[names.OnWorldObjectLoad] = true
limited[names.NotificationCountDidChange] = true

-- event that can only be posted by System:
reservedToSystem = {}
reservedToSystem[names.KeyboardInput] = true
reservedToSystem[names.LocalAvatarUpdate] = true
reservedToSystem[names.ServerConnectionSuccess] = true
reservedToSystem[names.ServerConnectionLost] = true
reservedToSystem[names.ServerConnectionFailed] = true
reservedToSystem[names.ServerConnectionStart] = true
reservedToSystem[names.ChatMessage] = true
reservedToSystem[names.ChatMessageACK] = true
reservedToSystem[names.DidReceivePushNotification] = true
reservedToSystem[names.OnStart] = true

mt = {
	__tostring = function()
		return "[LocalEventName]"
	end,
	__type = "LocalEventName",
}
setmetatable(localevent.name, mt)

-- returns true if event has been consumed, false otherwise
local sendEventToListeners = function(self, listenersArray, name, ...)
	if self ~= localevent then
		error("LocalEvent.sendEventToListeners must receive module as 1st argument")
	end

	local listeners = listenersArray[name]
	if listeners == nil then
		-- Not a single listener for this event name,
		-- so the event could not have been consumed.
		return false
	end

	local args = { ... }
	local captured = false
	local listener
	local err
	local listenersToRemove = {}
	local isSystemProvided = false

	-- extract `System` from `args` if present
	if rawequal(args[1], System) then
		isSystemProvided = true
		local newArgs = {}
		for i, v in ipairs(args) do
			if i > 1 then
				table.insert(newArgs, v)
			end
		end
		args = newArgs
	end

	-- check if System is required to notify listeners
	if reservedToSystem[name] == true and isSystemProvided == false then
		error("not allowed to send this localevent without access to System", 3)
	end

	for i = 1, #listeners do -- why not using ipairs?
		listener = listeners[i]
		if not listener.paused then
			if listener.callback ~= nil then
				if limited[name] then
					err, captured = Dev:ExecutionLimiter(function()
						-- return 1,2,3 -- limiterStart returns nil, 1, 2, 3
						return listener.callback(table.unpack(args))
					end)

					if err then
						if listener.system == true then
							-- only display error if system listener, do not remove
							print("❌", err)
						else
							-- remove listener + display error
							table.insert(listenersToRemove, listener)
							print("❌", err, "(function disabled)")
						end
						-- goto continue -- continue for loop
						continue
					end
				else
					captured = listener.callback(table.unpack(args))
				end

				if captured == true then
					break
				end -- event captured, exit!

				-- ::continue::

				-- else
				-- TODO: remove listeners with nil callbacks
			end
		end
	end

	-- remove listeners that have been flagged
	for _, listener in ipairs(listenersToRemove) do
		listener:Remove()
	end

	return captured
end

---@function Send Sends an event with provided name and any number of arguments.
--- It returns a [boolean], true if the event has been captured by one of the listeners.
---@param self localevent
---@param name string
---@param ... any
---@return boolean
---@code
--- local localevent = require("localevent")
--- localevent:Send("some_name", "foo", "bar", 123)
---
--- local captured = localevent:Send("some_other_name", math.random(1,10))
--- print("event has been captured:", captured == true and "YES" or "NO")
localevent.Send = function(self, name, ...)
	if self ~= localevent then
		error("LocalEvent:Send should be called with `:`", 2)
	end

	local args = { ... }

	-- dispatch event to SYSTEM listeners
	local captured = sendEventToListeners(self, topPrioritySystemListeners, name, table.unpack(args))
	if captured == true then
		return captured
	end

	-- dispatch event to REGULAR listeners
	captured = sendEventToListeners(self, listeners, name, table.unpack(args))

	return captured
end
localevent.send = localevent.Send

local listenerMT = {
	__tostring = function()
		return "[LocalEventListener]"
	end,
	__type = "LocalEventListener",
	__index = {
		Remove = function(self)
			local matchingListeners = listeners[self.name]
			if matchingListeners ~= nil then
				for i, listener in ipairs(matchingListeners) do
					if listener == self then
						table.remove(matchingListeners, i)
						break
					end
				end
			end
		end,
		Pause = function(self)
			self.paused = true
		end,
		Resume = function(self)
			self.paused = false
		end,
	},
}
listenerMT.__index.remove = listenerMT.__index.Remove
listenerMT.__index.pause = listenerMT.__index.Pause
listenerMT.__index.resume = listenerMT.__index.Resume

-- metatable for top priority System listeners
local topPrioritySystemListenerMT = {
	__tostring = function()
		return "[LocalEventSystemListener]"
	end,
	__type = "LocalEventSystemListener",
	__index = {
		Remove = function(self)
			local matchingListeners = topPrioritySystemListeners[self.name]
			if matchingListeners ~= nil then
				for i, listener in ipairs(matchingListeners) do
					if listener == self then
						table.remove(matchingListeners, i)
						break
					end
				end
			end
		end,
		Pause = function(self)
			self.paused = true
		end,
		Resume = function(self)
			self.paused = false
		end,
	},
}
topPrioritySystemListenerMT.__index.remove = topPrioritySystemListenerMT.__index.Remove
topPrioritySystemListenerMT.__index.pause = topPrioritySystemListenerMT.__index.Pause
topPrioritySystemListenerMT.__index.resume = topPrioritySystemListenerMT.__index.Resume

-- config is optional
-- config.topPriority can be used to insert listener in front of others
-- (can't prevent other top priority listeners to be added in front afterwards)
-- LocalEvent:Listen("eventName", callback, { topPriority = true })
-- config.system can be set to System table to register listener as "system listener".

---@function Listen Listen returns a new [listener] for the provided event name.
--- The [listener] will trigger the provided callback when the event is sent.
---
--- [listener]s created first receive events first by default.
---
--- The optional `config` parameter allows to request top priority delivery through `config.topPriority`.
---@param self localevent
---@param name string
---@param callback function
---@param config? table
---@return listener
---@code
--- local localevent = require("localevent")
--- local l = localevent:Listen("some_name", function(a, b, c)
--- 	print(a, b, c)
--- )
--- localevent:Send("some_name", "foo", "bar", 123)
--- -- prints "foo bar 123"
localevent.Listen = function(self, name, callback, config)
	if self ~= localevent then
		error("LocalEvent:Listen should be called with `:`", 2)
	end
	if type(callback) ~= "function" then
		error("LocalEvent:Listen - callback should be a function", 2)
	end

	local listener = { name = name, callback = callback, system = rawequal(config.system, System) }

	-- top priority System listeners
	if listener.system == true and config.topPriority == true then
		setmetatable(listener, topPrioritySystemListenerMT)

		if topPrioritySystemListeners[name] == nil then
			topPrioritySystemListeners[name] = {}
		end

		-- always insert top priority system listeners in front
		table.insert(topPrioritySystemListeners[name], 1, listener)
	else
		setmetatable(listener, listenerMT)

		if listeners[name] == nil then
			listeners[name] = {}
		end

		if config.topPriority == true then
			table.insert(listeners[name], 1, listener)
		else
			table.insert(listeners[name], listener)
		end
	end

	return listener
end
localevent.listen = localevent.Listen

---@type listener

---@function Remove Removes the listener.
---@param self listener
---@code
--- local localevent = require("localevent")
--- local listener = localevent:Listen(LocalEvent.Name.Tick, function(dt)
--- 	-- execute something in loop
--- end)
--- listener:Remove() -- callback will never be called again after this

---@function Pause Pauses the listener.
---@param self listener
---@code
--- local localevent = require("localevent")
--- local listener = localevent:Listen(LocalEvent.Name.Tick, function(dt)
--- 	-- execute something in loop
--- end)
--- listener:Pause()
--- -- callback will not be triggered again until listener:Resume()

---@function Resume Makes the listener listen for events again if it was paused.
---@param self listener
---@code
--- local localevent = require("localevent")
--- local listener = localevent:Listen(LocalEvent.Name.Tick, function(dt)
--- 	-- execute something in loop
--- end)
--- listener:Pause()
--- -- callback not be triggered when events are sent
--- listener:Resume()
--- -- callback triggered as soon as an new event is sent

return localevent
