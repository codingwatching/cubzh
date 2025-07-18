--
-- Module for world badges
--

local mod = {}

local system_api = require("system_api", System)

-- Unlock a badge for the current user and world
-- callback(err)
mod.unlockBadge = function(_, badgeTag, callback)
	local worldId = Environment.worldId
	if worldId == nil or worldId == "" then
		error("unlockBadge must be called from a world")
	end

	system_api:unlockBadge(worldId, badgeTag, function(err, unlocked)
		-- err is nil on success
		-- unlocked is true if the badge was just unlocked for the 1st time
		if callback ~= nil then
			callback(err, unlocked)
		end
	end)
end

return mod
