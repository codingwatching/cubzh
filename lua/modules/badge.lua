--
-- Module for world badges
--

local mod = {}

local conf = require("config")
local system_api = require("system_api", System)
local api = require("api", System)

-- Unlock a badge for the current user and world
-- callback(err)
mod.unlock = function(_, badgeTag, callback)
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
mod.unlockBadge = mod.unlock -- legacy

-- returns a Badge Object 
-- thumbnail can be loaded on creation or later with badgeObject:setThumbnail(imageData)
-- returns table with underlying requests in case they need to be cancelled
local badgeUnlockedData = nil
local badgeLockedData = nil
local maskQuadData = nil

local function _setBadgeId(self, badgeId, callback)
	if typeof(self) ~= "Mesh" then
		error("badgeObject:setBadgeId(badgeId) should be called with `:`")
	end
	if self.iconQuad == nil then
		-- badge has no quad to render thumbnail on
		return
	end
	if type(badgeId) ~= "string" then
		error("badgeObject:setBadgeId(badgeId) - badgeId must be a string")
	end
	if callback ~= nil and type(callback) ~= "function" then
		error("badgeObject:setBadgeId(badgeId, callback) - callback must be a function or nil")
	end

	self.badgeId = badgeId
	local iconQuad = self.iconQuad
	local iconQuadBack = self.iconQuadBack

	-- make quad transparent while loading thumbnail
	iconQuad.Color = Color(255, 255, 255, 0) 
	if iconQuadBack ~= nil then
		iconQuadBack.Color = Color(255, 255, 255, 0)
	end

	local req = api:getBadgeThumbnail({
		badgeID = badgeId,
		callback = function(icon, err)
			if err ~= nil then
				if callback ~= nil then
					callback() -- thumbnail not loaded, but trigger callback anyway
				end
				return
			end
			iconQuad.Color = Color(255, 255, 255)
			iconQuad.Image = {
				data = icon,
				filtering = false,
			}
			if iconQuadBack ~= nil then
				iconQuadBack.Color = Color(255, 255, 255)
				iconQuadBack.Image = {
					data = icon,
					filtering = false,
				}
			end
			if callback ~= nil then
				callback()
			end
		end,
	})

	return req
end

mod.createBadgeObject = function(self, config)
	local reqs = {}
	local defaultConfig = {
		frontOnly = false, -- displays thumbnail on front side only
		badgeId = nil,
		locked = false, -- if true, returns design for locked badge
		callback = nil, -- function(badgeObject)
	}

	local ok, err = pcall(function()
		config = conf:merge(defaultConfig, config, {
			acceptTypes = {
				frontOnly = { "boolean" },
				locked = { "boolean" },
				badgeId = { "string" },
				callback = { "function" },
			},
		})
	end)
	if not ok then
		error("badge:createBadgeObject(config) - config error: " .. err)
	end

	local badgeData
	
	if config.locked then
		if badgeLockedData == nil then
			badgeLockedData = Data:FromBundle("shapes/badge-dark.glb")
		end
		badgeData = badgeLockedData
	else
		if badgeUnlockedData == nil then
			badgeUnlockedData = Data:FromBundle("shapes/badge.glb")
		end
		badgeData = badgeUnlockedData
	end

	if maskQuadData == nil then
		maskQuadData = Data:FromBundle("images/mask-round.png")
	end

	if badgeData == nil then
		error("badge:createBadgeObject(config) - badge data not found")
	end

	local req = Object:Load(badgeData, function(o)
		if o == nil then
			error("badge:createBadgeObject(config) - failed to load badge data")
		end

		o.setBadgeId = _setBadgeId

		local maskQuad
		local iconQuad

		local maskQuadBack
		local iconQuadBack

		if not config.locked then
			maskQuad = Quad()
			-- maskQuad.IsDoubleSided = false
			maskQuad.Color = Color(255, 255, 255, 0)
			maskQuad.Image = {
				data = maskQuadData,
				cutout = true,
			}
			maskQuad.Anchor = { 0.5, 0.5 }
			maskQuad.IsMask = true

			iconQuad = Quad()
			iconQuad.IsDoubleSided = false
			iconQuad.Color = Color(255, 255, 255, 0)
			iconQuad.Anchor = { 0.5, 0.5 }

			maskQuad:SetParent(o)
			maskQuad.Width = o.Width * 0.88 * 80
			maskQuad.Height = o.Height * 0.88 * 80
			maskQuad.Scale = 1 / 80
			maskQuad.LocalPosition.Z = -o.Depth * 0.28

			iconQuad:SetParent(maskQuad)
			iconQuad.Width = maskQuad.Width
			iconQuad.Height = maskQuad.Height

			o.iconQuad = iconQuad

			if config.frontOnly == false then
				maskQuadBack = Quad()
				-- maskQuadBack.IsDoubleSided = false
				maskQuadBack.Color = Color(255, 255, 255, 0)
				maskQuadBack.Image = {
					data = maskQuadData,
					cutout = true,
				}
				maskQuadBack.Anchor = { 0.5, 0.5 }
				maskQuadBack.IsMask = true

				iconQuadBack = Quad()
				iconQuadBack.IsDoubleSided = false
				iconQuadBack.Color = Color(255, 255, 255, 0)
				iconQuadBack.Anchor = { 0.5, 0.5 }

				maskQuadBack:SetParent(o)
				maskQuadBack.Width = o.Width * 0.88 * 80
				maskQuadBack.Height = o.Height * 0.88 * 80
				maskQuadBack.Scale = 1 / 80
				maskQuadBack.LocalPosition.Z = o.Depth * 0.28
				maskQuadBack.LocalRotation.Y = math.rad(180)

				iconQuadBack:SetParent(maskQuadBack)
				iconQuadBack.Width = maskQuadBack.Width
				iconQuadBack.Height = maskQuadBack.Height

				o.iconQuadBack = iconQuadBack
			end
		end

		if config.badgeId ~= nil and iconQuad ~= nil then
			local req = o:setBadgeId(config.badgeId, function()
				if config.callback ~= nil then
					config.callback(o) -- badge ready!
				end
			end)
			table.insert(reqs, req)
		else 
			if config.callback ~= nil then
				config.callback(o)
			end
		end
	end)

	table.insert(reqs, req)
	return reqs
end

return mod
