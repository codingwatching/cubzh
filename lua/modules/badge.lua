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

	-- unlocked, badgeId
	system_api:unlockBadge(worldId, badgeTag, function(err, response)
		-- err is nil on success
		-- unlocked is true if the badge was just unlocked for the 1st time
		if response.unlocked == true then
			-- TODO: gaetan: display badge title instead of tag
			LocalEvent:Send(LocalEvent.Name.BadgeUnlocked, {
				worldId = worldId,
				badgeTag = badgeTag,
				badgeId = response.badgeId,
				badgeName = response.badgeName,
			})
		end
		if callback ~= nil then
			callback(err, response)
		end
	end)
end

return mod
