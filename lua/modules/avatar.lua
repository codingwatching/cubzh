mod = {}

-- storage for avatar instances' private fields
-- (allows to check if a table is in fact an avatar)
-- { config = {},
--   equipments = { equipmentType = { request = onGoingRequest, shapes = {} }, ... },
--   requests = {},
--   palette = Palette()
-- }
avatarPrivateFields = setmetatable({}, { __mode = "k" })

-- MODULES
api = require("api")
bundle = require("bundle")

function emptyFunc() end

local SKIN_1_PALETTE_INDEX = 1
local SKIN_2_PALETTE_INDEX = 2
local CLOTH_PALETTE_INDEX = 3
local MOUTH_PALETTE_INDEX = 4
local EYES_WHITE_PALETTE_INDEX = 5
local EYES_PALETTE_INDEX = 6
local NOSE_PALETTE_INDEX = 7
local EYES_DARK_PALETTE_INDEX = 8

-- bodyPartsNames = {
-- 	"Head",
-- 	"Body",
-- 	"RightArm",
-- 	"RightHand",
-- 	"LeftArm",
-- 	"LeftHand",
-- 	"RightLeg",
-- 	"LeftLeg",
-- 	"RightFoot",
-- 	"LeftFoot",
-- 	"EyeLidRight",
-- 	"EyeLidLeft",
-- }

cachedHead = bundle:Shape("shapes/head_skin2_v2")

mod.eyeColors = {
	Color(80, 80, 80),
	Color(166, 142, 163),
	Color(68, 172, 229),
	Color(61, 204, 141),
	Color(127, 80, 51),
	Color(51, 38, 29),
	Color(229, 114, 189),
	Color(80, 80, 80),
}

local DEFAULT_EYES_COLOR_INDEX = 1
mod.defaultEyesColorIndex = DEFAULT_EYES_COLOR_INDEX

mod.skinColors = {
	{
		skin1 = Color(246, 227, 208),
		skin2 = Color(246, 216, 186),
		nose = Color(246, 210, 175),
		mouth = Color(220, 188, 157),
	},
	{
		skin1 = Color(252, 202, 156),
		skin2 = Color(252, 186, 129),
		nose = Color(249, 167, 117),
		mouth = Color(216, 162, 116),
	},
	{
		skin1 = Color(255, 194, 173),
		skin2 = Color(255, 178, 152),
		nose = Color(255, 162, 133),
		mouth = Color(217, 159, 140),
	},
	{
		skin1 = Color(182, 129, 108),
		skin2 = Color(183, 117, 94),
		nose = Color(189, 114, 80),
		mouth = Color(153, 102, 79),
	},
	{
		skin1 = Color(156, 92, 88),
		skin2 = Color(136, 76, 76),
		nose = Color(135, 64, 68),
		mouth = Color(109, 63, 61),
	},
	{
		skin1 = Color(140, 96, 64),
		skin2 = Color(124, 82, 52),
		nose = Color(119, 76, 45),
		mouth = Color(104, 68, 43),
	},
	{
		skin1 = Color(59, 46, 37),
		skin2 = Color(53, 41, 33),
		nose = Color(47, 33, 25),
		mouth = Color(47, 36, 29),
	},
	{ -- 8
		skin1 = Color(108, 194, 231),
		skin2 = Color(100, 158, 192),
		nose = Color(98, 147, 189),
		mouth = Color(113, 169, 200),
	},
}

local DEFAULT_BODY_COLOR_INDEX = 8
mod.defaultSkinColorIndex = DEFAULT_BODY_COLOR_INDEX

mod.eyes = {
	{
		-- right eye
		{ x = 1, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 1, c = EYES_PALETTE_INDEX },
		{ x = 3, y = 1, c = EYES_PALETTE_INDEX },

		{ x = 1, y = 2, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 2, c = EYES_PALETTE_INDEX },
		{ x = 3, y = 2, c = EYES_DARK_PALETTE_INDEX },

		{ x = 1, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 3, c = EYES_PALETTE_INDEX },
		{ x = 3, y = 3, c = EYES_DARK_PALETTE_INDEX },

		{ x = 1, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 3, y = 4, c = EYES_WHITE_PALETTE_INDEX },

		-- left eye
		{ x = 9, y = 1, c = EYES_PALETTE_INDEX },
		{ x = 10, y = 1, c = EYES_PALETTE_INDEX },
		{ x = 11, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 10, y = 2, c = EYES_PALETTE_INDEX },
		{ x = 11, y = 2, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 3, c = EYES_DARK_PALETTE_INDEX },
		{ x = 10, y = 3, c = EYES_PALETTE_INDEX },
		{ x = 11, y = 3, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 11, y = 4, c = EYES_WHITE_PALETTE_INDEX },
	},
	{
		-- right eye
		{ x = 1, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 3, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 1, y = 2, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 2, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 1, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 3, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 3, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 1, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 3, y = 4, c = EYES_WHITE_PALETTE_INDEX },

		-- left eye
		{ x = 9, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 11, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 2, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 11, y = 2, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 3, c = EYES_DARK_PALETTE_INDEX },
		{ x = 11, y = 3, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 11, y = 4, c = EYES_WHITE_PALETTE_INDEX },
	},
	{
		-- right eye
		{ x = 1, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 1, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 1, y = 2, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 2, c = EYES_PALETTE_INDEX },
		{ x = 3, y = 2, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 1, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 3, c = EYES_PALETTE_INDEX },
		{ x = 3, y = 3, c = EYES_WHITE_PALETTE_INDEX },

		-- left eye
		{ x = 9, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 1, c = EYES_DARK_PALETTE_INDEX },
		{ x = 11, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 2, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 2, c = EYES_PALETTE_INDEX },
		{ x = 11, y = 2, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 3, c = EYES_PALETTE_INDEX },
		{ x = 11, y = 3, c = EYES_WHITE_PALETTE_INDEX },
	},
	{
		-- right eye
		{ x = 1, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 3, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 1, y = 2, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 2, c = EYES_DARK_PALETTE_INDEX },

		{ x = 1, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 3, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 3, c = EYES_DARK_PALETTE_INDEX },

		{ x = 1, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 3, y = 4, c = EYES_WHITE_PALETTE_INDEX },

		-- left eye
		{ x = 9, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 11, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 10, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 11, y = 2, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 3, c = EYES_DARK_PALETTE_INDEX },
		{ x = 10, y = 3, c = EYES_DARK_PALETTE_INDEX },
		{ x = 11, y = 3, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 4, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 11, y = 4, c = EYES_WHITE_PALETTE_INDEX },
	},
	{
		-- right eye
		{ x = 2, y = 1, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 1, c = EYES_DARK_PALETTE_INDEX },

		{ x = 2, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 2, c = EYES_DARK_PALETTE_INDEX },

		-- left eye
		{ x = 9, y = 1, c = EYES_DARK_PALETTE_INDEX },
		{ x = 10, y = 1, c = EYES_DARK_PALETTE_INDEX },

		{ x = 9, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 10, y = 2, c = EYES_DARK_PALETTE_INDEX },
	},
	{
		-- right eye
		{ x = 1, y = 1, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 1, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 1, c = EYES_DARK_PALETTE_INDEX },

		{ x = 1, y = 2, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 3, y = 2, c = EYES_PALETTE_INDEX },

		{ x = 1, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 2, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 3, y = 3, c = EYES_WHITE_PALETTE_INDEX },

		-- left eye
		{ x = 9, y = 1, c = EYES_DARK_PALETTE_INDEX },
		{ x = 10, y = 1, c = EYES_DARK_PALETTE_INDEX },
		{ x = 11, y = 1, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 2, c = EYES_PALETTE_INDEX },
		{ x = 10, y = 2, c = EYES_DARK_PALETTE_INDEX },
		{ x = 11, y = 2, c = EYES_WHITE_PALETTE_INDEX },

		{ x = 9, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 10, y = 3, c = EYES_WHITE_PALETTE_INDEX },
		{ x = 11, y = 3, c = EYES_WHITE_PALETTE_INDEX },
	},
}

local DEFAULT_EYES_INDEX = 1
mod.defaultEyesIndex = DEFAULT_EYES_INDEX

mod.noses = {
	{
		{ x = 1, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 1, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 3, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
	},
	{},
	{
		{ x = 1, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 1, c = NOSE_PALETTE_INDEX },

		{ x = 1, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 2, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 1, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 1, c = NOSE_PALETTE_INDEX },

		{ x = 1, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 2, c = NOSE_PALETTE_INDEX },

		{ x = 2, y = 3, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 1, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 1, c = NOSE_PALETTE_INDEX },

		{ x = 1, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 2, c = NOSE_PALETTE_INDEX },

		{ x = 1, y = 3, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 3, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 3, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 1, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 1, c = NOSE_PALETTE_INDEX },

		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },

		{ x = 2, y = 3, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 1, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 1, c = NOSE_PALETTE_INDEX },

		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },

		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },

		{ x = 1, y = 3, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 3, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 3, c = NOSE_PALETTE_INDEX },
	},
	{
		{ x = 2, y = 1, c = NOSE_PALETTE_INDEX },

		{ x = 1, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 2, y = 2, c = NOSE_PALETTE_INDEX },
		{ x = 3, y = 2, c = NOSE_PALETTE_INDEX },
	},
}

local DEFAULT_NOSE_INDEX = 1
mod.defaultNoseIndex = DEFAULT_NOSE_INDEX

avatarPalette = Palette()
avatarPalette:AddColor(mod.skinColors[DEFAULT_BODY_COLOR_INDEX].skin1) -- skin 1
avatarPalette:AddColor(mod.skinColors[DEFAULT_BODY_COLOR_INDEX].skin2) -- skin 2
avatarPalette:AddColor(Color(231, 230, 208)) -- cloth
avatarPalette:AddColor(mod.skinColors[DEFAULT_BODY_COLOR_INDEX].mouth) -- mouth
avatarPalette:AddColor(Color(255, 255, 255)) -- eyes white
avatarPalette:AddColor(Color(50, 50, 50)) -- eyes
avatarPalette:AddColor(mod.skinColors[DEFAULT_BODY_COLOR_INDEX].nose) -- nose
avatarPalette:AddColor(Color(10, 10, 10)) -- eyes dark

function initAnimations(avatar)
	local leftLegOrigin = avatar.LeftLeg.LocalPosition:Copy()
	local rightLegOrigin = avatar.RightLeg.LocalPosition:Copy()

	local animWalk = Animation("Walk", { speed = 1.8, loops = 0, priority = 2 })
	local walk_llegK = {
		{ time = 0.0, rotation = { -1.1781, 0, 0 } },
		{ time = 1 / 6, rotation = { -0.785398, 0, 0 } },
		{ time = 1 / 3, rotation = { 0.785398, 0, 0 } },
		{ time = 1 / 2, rotation = { 1.1781, 0, 0 } },
		{ time = 2 / 3, rotation = { 0.392699, 0, 0 } },
		{ time = 5 / 6, rotation = { -1.1781, 0, 0 } },
		{ time = 1.0, rotation = { -1.1781, 0, 0 } },
	}
	local walk_lfootK = {
		{ time = 0.0, rotation = { 0, 0, 0 } },
		{ time = 1 / 6, rotation = { 0.687223, 0, 0 } },
		{ time = 1 / 3, rotation = { -0.392699, 0, 0 } },
		{ time = 1 / 2, rotation = { 0.785398, 0, 0 } },
		{ time = 2 / 3, rotation = { 1.1781, 0, 0 } },
		{ time = 5 / 6, rotation = { 1.9635, 0, 0 } },
		{ time = 1.0, rotation = { 0, 0, 0 } },
	}
	local walk_rlegK = {
		{ time = 0.0, rotation = { 1.1781, 0, 0 } },
		{ time = 1 / 6, rotation = { 0.392699, 0, 0 } },
		{ time = 1 / 3, rotation = { -1.1781, 0, 0 } },
		{ time = 1 / 2, rotation = { -1.1781, 0, 0 } },
		{ time = 2 / 3, rotation = { -0.785398, 0, 0 } },
		{ time = 5 / 6, rotation = { 0.785398, 0, 0 } },
		{ time = 1.0, rotation = { 1.1781, 0, 0 } },
	}
	local walk_rfootK = {
		{ time = 0.0, rotation = { 0.785398, 0, 0 } },
		{ time = 1 / 6, rotation = { 1.1781, 0, 0 } },
		{ time = 1 / 3, rotation = { 1.9635, 0, 0 } },
		{ time = 1 / 2, rotation = { 0, 0, 0 } },
		{ time = 2 / 3, rotation = { 0.687223, 0, 0 } },
		{ time = 5 / 6, rotation = { -0.392699, 0, 0 } },
		{ time = 1.0, rotation = { 0.785398, 0, 0 } },
	}
	local walk_larmK = {
		{ time = 0.0, rotation = { 1.1781, 0, 1.0472 } },
		{ time = 1 / 6, rotation = { 0.589049, 0.19635, 1.0472 } },
		{ time = 1 / 3, rotation = { 0.19635, 0, 1.0472 } },
		{ time = 1 / 2, rotation = { -1.37445, 0.19635, 1.0472 } },
		{ time = 2 / 3, rotation = { -0.589049, 0, 1.0472 } },
		{ time = 5 / 6, rotation = { 0.19635, 0, 1.0472 } },
		{ time = 1.0, rotation = { 1.1781, 0, 1.0472 } },
	}
	local walk_lhandK = {
		{ time = 0.0, rotation = { 0, 0.245437, 0.294524 } },
		{ time = 1 / 6, rotation = { 0, 0.785398, 0 } },
		{ time = 1 / 3, rotation = { 0, 1.1781, 0 } },
		{ time = 1 / 2, rotation = { 0, 0.19635, 0 } },
		{ time = 2 / 3, rotation = { 0, 0.589049, 0 } },
		{ time = 5 / 6, rotation = { 0, 0.392699, 0.0981748 } },
		{ time = 1.0, rotation = { 0, 0.245437, 0.294524 } },
	}
	local walk_rarmK = {
		{ time = 0.0, rotation = { -1.37445, -0.19635, -1.0472 } },
		{ time = 1 / 6, rotation = { -0.589049, 0, -1.0472 } },
		{ time = 1 / 3, rotation = { 0.19635, 0, -1.0472 } },
		{ time = 1 / 2, rotation = { 1.1781, 0, -1.0472 } },
		{ time = 2 / 3, rotation = { 0.589049, 0.19635, -1.0472 } },
		{ time = 5 / 6, rotation = { 0.19635, 0, -1.0472 } },
		{ time = 1.0, rotation = { -1.37445, -0.19635, -1.0472 } },
	}
	local walk_rhandK = {
		{ time = 0.0, rotation = { 0, -0.19635, 0 } },
		{ time = 1 / 6, rotation = { 0, -0.589049, 0 } },
		{ time = 1 / 3, rotation = { 0, -0.392699, -0.0981748 } },
		{ time = 1 / 2, rotation = { 0, -0.245437, -0.294524 } },
		{ time = 2 / 3, rotation = { 0, -0.785398, 0 } },
		{ time = 5 / 6, rotation = { 0, -1.1781, 0 } },
		{ time = 1.0, rotation = { 0, -0.19635, 0 } },
	}
	local walk_bodyK = {
		{ time = 0.0, position = { 0.0, 15.0, 0.0 }, rotation = { 0, 0, 0 } },
		{ time = 1 / 6, position = { 0.0, 12.0, 0.0 }, rotation = { 0, 0, 0 } },
		{ time = 1 / 3, position = { 0.0, 14.0, 0.0 }, rotation = { 0, 0, 0 } },
		{ time = 1 / 2, position = { 0.0, 15.0, 0.0 }, rotation = { 0, 0, 0 } },
		{ time = 2 / 3, position = { 0.0, 12.0, 0.0 }, rotation = { 0, 0, 0 } },
		{ time = 5 / 6, position = { 0.0, 14.0, 0.0 }, rotation = { 0, 0, 0 } },
		{ time = 1.0, position = { 0.0, 15.0, 0.0 }, rotation = { 0, 0, 0 } },
	}
	local walkConfig = {
		RightArm = walk_rarmK,
		RightHand = walk_rhandK,
		LeftArm = walk_larmK,
		LeftHand = walk_lhandK,
		RightLeg = walk_rlegK,
		RightFoot = walk_rfootK,
		LeftLeg = walk_llegK,
		LeftFoot = walk_lfootK,
		Body = walk_bodyK,
	}

	local owner
	for name, v in pairs(walkConfig) do
		for _, frame in ipairs(v) do
			owner = (name == "Body" and not avatar[name]) and avatar or avatar[name]
			if owner ~= nil then
				animWalk:AddFrameInGroup(name, frame.time, { position = frame.position, rotation = frame.rotation })
				animWalk:Bind(name, owner)
			end
		end
	end

	local yOffset = 0.4
	local animIdle = Animation("Idle", { speed = 0.5, loops = 0, priority = 0 })
	local idle_keyframes_data = {
		{ name = "LeftLeg", time = 0.0, position = leftLegOrigin, rotation = { 0, 0, 0 } },
		{ name = "LeftLeg", time = 0.5, position = leftLegOrigin + { 0.0, yOffset, 0.0 }, rotation = { 0, 0, 0 } },
		{ name = "LeftLeg", time = 1.0, position = leftLegOrigin, rotation = { 0, 0, 0 } },
		{ name = "LeftFoot", time = 0.0, rotation = { 0, 0, 0 } },
		{ name = "LeftFoot", time = 0.5, rotation = { 0, 0, 0 } },
		{ name = "LeftFoot", time = 1.0, rotation = { 0, 0, 0 } },
		{ name = "RightLeg", time = 0.0, position = rightLegOrigin, rotation = { 0, 0, 0 } },
		{ name = "RightLeg", time = 0.5, position = rightLegOrigin + { 0.0, yOffset, 0.0 }, rotation = { 0, 0, 0 } },
		{ name = "RightLeg", time = 1.0, position = rightLegOrigin, rotation = { 0, 0, 0 } },
		{ name = "RightFoot", time = 0.0, rotation = { 0, 0, 0 } },
		{ name = "RightFoot", time = 0.5, rotation = { 0, 0, 0 } },
		{ name = "RightFoot", time = 1.0, rotation = { 0, 0, 0 } },
		{ name = "LeftArm", time = 0.0, rotation = { 0, 0, 1.14537 + 0.1 } },
		{ name = "LeftArm", time = 0.5, rotation = { 0, 0, 1.14537 } },
		{ name = "LeftArm", time = 1.0, rotation = { 0, 0, 1.14537 + 0.1 } },
		{ name = "LeftHand", time = 0.0, rotation = { 0, 0.294524, -0.0981748 } },
		{ name = "LeftHand", time = 0.5, rotation = { 0, 0.19635, -0.0981748 } },
		{ name = "LeftHand", time = 1.0, rotation = { 0, 0.294524, -0.0981748 } },
		{ name = "RightArm", time = 0.0, rotation = { 0, 0, -1.14537 - 0.1 } },
		{ name = "RightArm", time = 0.5, rotation = { 0, 0, -1.14537 } },
		{ name = "RightArm", time = 1.0, rotation = { 0, 0, -1.14537 - 0.1 } },
		{ name = "RightHand", time = 0.0, rotation = { 0, -0.294524, 0 } },
		{ name = "RightHand", time = 0.5, rotation = { 0, -0.19635, 0 } },
		{ name = "RightHand", time = 1.0, rotation = { 0, -0.294524, 0 } },
		-- can't move head first person if head is set in animations
		-- { name = "Head", time = 0.0, rotation = { 0, 0, 0 } },
		-- { name = "Head", time = 0.5, rotation = { 0, 0, 0 } },
		-- { name = "Head", time = 1.0, rotation = { 0, 0, 0 } },
		{ name = "Body", time = 0.0, position = { 0.0, 12.0, 0.0 }, rotation = { 0, 0, 0 } },
		{ name = "Body", time = 0.5, position = { 0.0, 12.0 - yOffset, 0.0 }, rotation = { 0, 0, 0 } },
		{ name = "Body", time = 1.0, position = { 0.0, 12.0, 0.0 }, rotation = { 0, 0, 0 } },
	}

	for _, frame in ipairs(idle_keyframes_data) do
		animIdle:AddFrameInGroup(frame.name, frame.time, { position = frame.position, rotation = frame.rotation })
		animIdle:Bind(frame.name, (frame.name == "Body" and not avatar[frame.name]) and avatar or avatar[frame.name])
	end

	local animSwingRight = Animation("SwingRight", { speed = 3, priority = 3 })
	local swingRight_rightArm = {
		{ time = 0.0, rotation = { 0, 0, -1.0472 } },
		{ time = 1 / 3, rotation = { -0.785398, 0.392699, 0.1309 } },
		{ time = 2 / 3, rotation = { 0.392699, -1.9635, -0.261799 } },
		{ time = 1.0, rotation = { 0, 0, -1.0472 } },
	}
	local swingRight_rightHand = {
		{ time = 0.0, rotation = { 0, -0.392699, 0 } },
		{ time = 1 / 3, rotation = { -1.5708, -0.392699, 0 } },
		{ time = 2 / 3, rotation = { -2.74889, -1.5708, 0 } },
		{ time = 1.0, rotation = { 0, -0.392699, 0 } },
	}
	local swingRightConfig = {
		RightArm = swingRight_rightArm,
		RightHand = swingRight_rightHand,
	}
	for name, v in pairs(swingRightConfig) do
		for _, frame in ipairs(v) do
			animSwingRight:AddFrameInGroup(name, frame.time, { position = frame.position, rotation = frame.rotation })
			animSwingRight:Bind(name, (name == "Body" and not avatar[name]) and avatar or avatar[name])
		end
	end

	local animSwingLeft = Animation("SwingLeft", { speed = 3, priority = 3 })
	local swingLeft_leftArm = {
		{ time = 0.0, rotation = { 0, 0, -1.0472 } },
		{ time = 1 / 3, rotation = { -0.785398, 0.392699, 0.1309 } },
		{ time = 2 / 3, rotation = { 0.392699, -1.9635, -0.261799 } },
		{ time = 1.0, rotation = { 0, 0, -1.0472 } },
	}
	local swingLeft_leftHand = {
		{ time = 0.0, rotation = { 0, -0.392699, 0 } },
		{ time = 1 / 3, rotation = { -1.5708, -0.392699, 0 } },
		{ time = 2 / 3, rotation = { -2.74889, -1.5708, 0 } },
		{ time = 1.0, rotation = { 0, -0.392699, 0 } },
	}
	local swingLeftConfig = {
		LeftHand = swingLeft_leftHand,
		LeftArm = swingLeft_leftArm,
	}
	for name, v in pairs(swingLeftConfig) do
		for _, frame in ipairs(v) do
			animSwingLeft:AddFrameInGroup(name, frame.time, { position = frame.position, rotation = frame.rotation })
			animSwingLeft:Bind(name, (name == "Body" and not avatar[name]) and avatar or avatar[name])
		end
	end

	local anims = require("animations")()
	anims.Walk = animWalk
	anims.Idle = animIdle
	anims.SwingRight = animSwingRight
	anims.SwingLeft = animSwingLeft

	avatar.Animations = anims

	anims.Idle:Play()
end

avatarDefaultConfig = {
	usernameOrId = "", -- item repo and name (like "aduermael.hair")
	didLoad = emptyFunc, -- function(err) end
	eyeBlinks = true,
	defaultAnimations = true,
	loadEquipments = true,
	hiddenEquipments = {}, -- forces some equipments to be hidden e.g. hiddenEquipments = { "hair" }
}

-- Returns sent requests
-- /!\ return table of requests does not contain all requests right away
-- reference should be kept, not copying entries right after function call.
mod.getPlayerHead = function(self, config)
	if self ~= mod then
		error("avatar:getPlayerHead(config) should be called with `:`", 2)
	end

	-- LEGACY
	if type(config) == "string" then
		config = {
			usernameOrId = config, -- parameter used to be usernameOrId
		}
	end

	ok, err = pcall(function()
		config = require("config"):merge(avatarDefaultConfig, config)
	end)
	if not ok then
		error("avatar:getPlayerHead(config) - config error: " .. err, 2)
	end

	local head = MutableShape(cachedHead)
	-- need custom functions for heads
	-- head.load = avatar_load
	-- head.loadEquipment = avatar_loadEquipment
	head.setColors = avatar_setColors
	head.getColors = avatar_getColors
	head.setEyes = avatar_setEyes
	head.setNose = avatar_setNose

	local requests = {}
	local palette = avatarPalette:Copy()

	avatarPrivateFields[head] =
		{ config = config, equipments = {}, requests = requests, palette = palette, isHead = true }

	-- error("REVIEW getPlayerHead")
	head.Name = "Head"
	head:Recurse(function(o)
		o.Physics = PhysicsMode.Disabled
		o.Palette = palette
	end, { includeRoot = true })

	-- head:setEyes({ index = 1 })
	-- head:setNose({ index = DEFAULT_NOSE_INDEX })

	-- local requests = self:prepareHead(head, usernameOrId, callback)
	return head, requests
end

-- returns MutaleShape + sent requests (table)
-- /!\ return table of requests does not contain all requests right away
-- reference should be kept, not copying entries right after function call.
-- replaced is optional, but can be provided to replace an existing avatar instead of creating a new one.
-- LEGACY: config used to be usernameOrId
mod.get = function(self, config, _, didLoadCallback_deprecated)
	if self ~= mod then
		error("avatar:get(config) should be called with `:`", 2)
	end

	-- LEGACY
	if type(config) == "string" then
		config = {
			usernameOrId = config, -- parameter used to be usernameOrId
		}
	end
	if type(didLoadCallback_deprecated) == "function" then
		if config == nil then
			config = {}
		end
		config.didLoad = didLoadCallback_deprecated
	end

	ok, err = pcall(function()
		config = require("config"):merge(avatarDefaultConfig, config)
	end)
	if not ok then
		error("avatar:get(config) - config error: " .. err, 2)
	end

	local avatar = Object()

	local mt = System.GetMetatable(avatar)
	mt.Shadow = false

	local objectIndex = mt.__index
	mt.__index = function(t, k)
		if k == "Shadow" then
			return mt[k]
		elseif k == "LeftArm" then
			return t:FindFirst(function(o) return o.Name == "LeftArm" end)
		elseif k == "RightArm" then
			return t:FindFirst(function(o) return o.Name == "RightArm" end)
		elseif k == "LeftLeg" then
			return t:FindFirst(function(o) return o.Name == "LeftLeg" end)
		elseif k == "RightLeg" then
			return t:FindFirst(function(o) return o.Name == "RightLeg" end)
		elseif k == "LeftFoot" then
			return t:FindFirst(function(o) return o.Name == "LeftFoot" end)
		elseif k == "RightFoot" then
			return t:FindFirst(function(o) return o.Name == "RightFoot" end)
		elseif k == "Body" then
			return t:FindFirst(function(o) return o.Name == "Body" end)
		elseif k == "Head" then
			return t:FindFirst(function(o) return o.Name == "Head" end)
		elseif k == "LeftHand" then
			return t:FindFirst(function(o) return o.Name == "LeftHand" end)
		elseif k == "RightHand" then
			return t:FindFirst(function(o) return o.Name == "RightHand" end)
		elseif k == "EyeLidRight" then
			return t:FindFirst(function(o) return o.Name == "EyeLidRight" end)
		elseif k == "EyeLidLeft" then
			return t:FindFirst(function(o) return o.Name == "EyeLidLeft" end)
		end
		return objectIndex(t, k)
	end

	local objectNewIndex = mt.__newindex
	mt.__newindex = function(t, k, v)
		if k == "Shadow" then
			t:Recurse(function(o)
				if o.Shadow == nil then
					return
				end
				o.Shadow = v
			end, { includeRoot = false })
			mt.Shadow = v
			return
		end
		objectNewIndex(t, k, v)
	end

	avatar.load = avatar_load
	avatar.loadEquipment = avatar_loadEquipment
	avatar.setColors = avatar_setColors
	avatar.getColors = avatar_getColors
	avatar.setEyes = avatar_setEyes
	avatar.setNose = avatar_setNose
	avatar.updateConfig = avatar_update_config

	local requests = {}
	local palette = avatarPalette:Copy()

	avatarPrivateFields[avatar] =
		{ config = config, equipments = {}, equipments_requested = {}, requests = requests, palette = palette }

	local body = bundle:MutableShape("shapes/avatar.3zh")
	body.Name = "Body"
	body:Recurse(function(o)
		o.Physics = PhysicsMode.Disabled
	end, { includeRoot = true })

	avatar:AddChild(body)
	body.LocalPosition.Y = 12

	if config.defaultAnimations then
		initAnimations(avatar)
	end

	avatar:setEyes({ index = DEFAULT_EYES_INDEX, color = mod.eyeColors[DEFAULT_EYES_COLOR_INDEX] })
	avatar:setNose({ index = DEFAULT_NOSE_INDEX })

	local eyeLidRight = MutableShape()
	eyeLidRight.Physics = PhysicsMode.Disabled
	eyeLidRight.Palette = palette
	eyeLidRight:AddBlock(1, 0, 0, 0)

	eyeLidRight = Shape(eyeLidRight)
	eyeLidRight.Name = "EyeLidRight"
	eyeLidRight:SetParent(avatar.Head)
	eyeLidRight.Pivot = { 0.5, 1, 0.5 }
	eyeLidRight.Scale.Z = 1
	eyeLidRight.Scale.X = 3.2
	eyeLidRight.Scale.Y = 0 -- 4.2
	eyeLidRight.IsHidden = true
	eyeLidRight.LocalPosition:Set(4, 5.1, 5.1)

	local eyeLidLeft = Shape(eyeLidRight)
	eyeLidLeft.Name = "EyeLidLeft"
	eyeLidLeft:SetParent(avatar.Head)
	eyeLidLeft.Pivot = { 0.5, 1, 0.5 }
	eyeLidLeft.Scale.Z = 1
	eyeLidLeft.Scale.X = 3.2
	eyeLidLeft.Scale.Y = 0 -- 4.2
	eyeLidLeft.IsHidden = true
	eyeLidLeft.LocalPosition:Set(-4, 5.1, 5.1)

	body:Recurse(function(o)
		o.Palette = palette
	end, { includeRoot = true })

	avatar:updateConfig()
	avatar:load()

	return avatar, requests
end

function avatar_load(self, config)
	local fields = avatarPrivateFields[self]
	if fields == nil then
		error("avatar:load(config) should be called with `:`", 2)
	end

	-- if config parameter isn't nil: load provided field,
	-- load avatar's config otherwise
	if config == nil then
		config = fields.config
	end

	fields.equipments_requested = {}

	if config.usernameOrId ~= nil and config.usernameOrId ~= "" then
		local req = api.getAvatar(config.usernameOrId, function(err, data)
			if err and config.didLoad then
				config.didLoad(err, nil)
				return
			end
			if self.IsDestroyed then
				return
			end
			-- eyes type (index)
			local eyesTypeIndex = data.eyesIndex
			if eyesTypeIndex == nil or eyesTypeIndex == 0 then
				eyesTypeIndex = DEFAULT_EYES_INDEX
			end

			-- nose type (index)
			local noseTypeIndex = data.noseIndex
			if noseTypeIndex == nil or noseTypeIndex == 0 then
				noseTypeIndex = DEFAULT_NOSE_INDEX
			end

			-- body colors (index)
			local bodyColorsIndex = data.skinColorIndex
			if bodyColorsIndex == nil or bodyColorsIndex == 0 then
				bodyColorsIndex = DEFAULT_BODY_COLOR_INDEX
			end
			local colorValues = mod.skinColors[bodyColorsIndex]
			local skinColor = colorValues.skin1
			local skinColor2 = colorValues.skin2
			local noseColor = colorValues.nose
			local mouthColor = colorValues.mouth

			-- eyes color (index)
			local eyesColorIndex = data.eyesColorIndex
			if eyesColorIndex == nil or eyesColorIndex == 0 then
				eyesColorIndex = DEFAULT_EYES_COLOR_INDEX
			end
			local eyesColor = mod.eyeColors[eyesColorIndex]

			-- override colors
			if data.skinColorIndex == 0 and data.skinColor then
				skinColor =
					Color(math.floor(data.skinColor.r), math.floor(data.skinColor.g), math.floor(data.skinColor.b))
			end
			if data.skinColorIndex == 0 and data.skinColor2 then
				skinColor2 =
					Color(math.floor(data.skinColor2.r), math.floor(data.skinColor2.g), math.floor(data.skinColor2.b))
			end
			if data.skinColorIndex == 0 and data.noseColor then
				noseColor =
					Color(math.floor(data.noseColor.r), math.floor(data.noseColor.g), math.floor(data.noseColor.b))
			end
			if data.skinColorIndex == 0 and data.mouthColor then
				mouthColor =
					Color(math.floor(data.mouthColor.r), math.floor(data.mouthColor.g), math.floor(data.mouthColor.b))
			end
			if data.eyesColorIndex == 0 and data.eyesColor then
				eyesColor =
					Color(math.floor(data.eyesColor.r), math.floor(data.eyesColor.g), math.floor(data.eyesColor.b))
			end

			-- Apply colors and eye/nose types

			self:setColors({
				skin1 = skinColor,
				skin2 = skinColor2,
				nose = noseColor,
				mouth = mouthColor,
				eyes = eyesColor,
			})

			-- eyes index
			self:setEyes({ index = eyesTypeIndex, color = eyesColor })

			-- nose index
			self:setNose({ index = noseTypeIndex, color = noseColor })

			-- print("data:", JSON:Encode(data))

			if data.jacket and fields.equipments_requested["jacket"] ~= true then
				self:loadEquipment({ type = "jacket", item = data.jacket })
			end
			if data.pants and fields.equipments_requested["pants"] ~= true then
				self:loadEquipment({ type = "pants", item = data.pants })
			end
			if data.hair and fields.equipments_requested["hair"] ~= true then
				self:loadEquipment({ type = "hair", item = data.hair })
			end
			if data.boots and fields.equipments_requested["boots"] ~= true then
				self:loadEquipment({ type = "boots", item = data.boots })
			end
		end)

		table.insert(fields.requests, req)
	end

	-- args: error, avatar
	if config.didLoad ~= nil then
		config.didLoad(nil, self)
	end

	return fields.requests
end

function _attachEquipmentToBodyPart(bodyPart, equipment, scale)
	if equipment == nil or bodyPart == nil then
		return
	end
	equipment.Physics = PhysicsMode.Disabled
	equipment.LocalRotation:Set(0, 0, 0)

	equipment:SetParent(bodyPart)
	equipment.Shadow = bodyPart.Shadow
	equipment.IsUnlit = bodyPart.IsUnlit
	System:SetLayersElevated(equipment, System:GetLayersElevated(bodyPart))

	local coords = bodyPart:GetPoint("origin").Coords
	if coords == nil then
		print("can't get parent coords for equipment")
		return
	end

	local localPos = bodyPart:BlockToLocal(coords)
	local origin = Number3(0, 0, 0)
	local point = equipment:GetPoint("origin")
	if point ~= nil then
		origin = point.Coords
	end
	equipment.Pivot = origin
	equipment.LocalPosition = localPos

	equipment.Scale = scale or 1
end

function avatar_loadEquipment(self, config)
	local fields = avatarPrivateFields[self]
	if fields == nil then
		error("avatar:loadEquipment(config) should be called with `:`", 2)
	end

	local requests = fields.requests

	local defaultConfig = {
		type = "",
		item = "", -- item repo and name (like "aduermael.hair")
		avatar = nil, -- avatar to be equipped (can remain nil)
		mutable = false, -- equipment shape(s) made mutable when true
		didLoad = emptyFunc, -- function(shape, equipmentType) end
		-- allows to provide shape that's already been loaded
		-- /!\ shape then managed by avatar, provide copy if needed
		shape = nil,
		bumpAnimation = false,
		didAttachEquipmentParts = nil, -- function(equipmentParts)
		preventAvatarLoadOverride = true, -- prevents overrides from ongoing avatar load (loading all equipments)
	}

	ok, err = pcall(function()
		config = require("config"):merge(defaultConfig, config, {
			acceptTypes = {
				shape = { "Shape", "MutableShape" },
				didAttachEquipmentParts = { "function" },
			},
		})
	end)
	if not ok then
		error("loadEquipment(config) - config error: " .. err, 2)
	end

	if config.preventAvatarLoadOverride then
		fields.equipments_requested[config.type] = true
	end

	local currentEquipment = fields.equipments[config.type]
	if currentEquipment == nil then
		currentEquipment = {}
		fields.equipments[config.type] = currentEquipment
	end

	if currentEquipment.request ~= nil then
		currentEquipment.request:Cancel()
		currentEquipment.request = nil
	end

	local attachEquipment = function(equipment)
		-- remove current equipment
		if currentEquipment.shapes ~= nil then
			for i, previousEquipment in ipairs(currentEquipment.shapes) do
				if i > 1 then
					previousEquipment:SetParent(currentEquipment.shapes[i - 1])
				else
					previousEquipment:RemoveFromParent()
				end
			end
		end
		if equipment == nil then
			-- no equipment to attach
			return
		end

		if config.type == "jacket" then
			local rightSleeve
			local leftSleeve
			rightSleeve = equipment:GetChild(1)
			if rightSleeve then
				leftSleeve = rightSleeve:GetChild(1)
			end
			currentEquipment.shapes = { equipment, rightSleeve, leftSleeve }
			_attachEquipmentToBodyPart(self.Body, equipment)
			if rightSleeve then
				_attachEquipmentToBodyPart(self.RightArm, rightSleeve)
			end
			if leftSleeve then
				_attachEquipmentToBodyPart(self.LeftArm, leftSleeve)
			end

			if config.didAttachEquipmentParts then
				config.didAttachEquipmentParts({ equipment, rightSleeve, leftSleeve })
			end
		elseif config.type == "pants" then
			local leftLeg = equipment:GetChild(1)
			currentEquipment.shapes = { equipment, leftLeg }
			_attachEquipmentToBodyPart(self.RightLeg, equipment, 1.05)
			_attachEquipmentToBodyPart(self.LeftLeg, leftLeg, 1.05)

			if config.didAttachEquipmentParts then
				config.didAttachEquipmentParts({ equipment, leftLeg })
			end
		elseif config.type == "boots" then
			local leftFoot = equipment:GetChild(1)
			currentEquipment.shapes = { equipment, leftFoot }
			_attachEquipmentToBodyPart(self.RightFoot, equipment)
			_attachEquipmentToBodyPart(self.LeftFoot, leftFoot)

			if config.didAttachEquipmentParts then
				config.didAttachEquipmentParts({ equipment, leftFoot })
			end
		elseif config.type == "hair" then
			currentEquipment.shapes = { equipment }
			_attachEquipmentToBodyPart(self.Head, equipment)

			if config.didAttachEquipmentParts then
				config.didAttachEquipmentParts({ equipment })
			end
		end

		if fields.hiddenEquipments and fields.hiddenEquipments[config.type] == true then
			for _, s in ipairs(currentEquipment.shapes) do
				s.IsHidden = true
			end
		end
	end

	if config.shape then
		attachEquipment(config.shape)
	elseif config.item == "" then
		attachEquipment(nil)
	else
		local req = Object:Load(config.item, function(equipment)
			currentEquipment.request = nil

			if equipment == nil then
				-- TODO: keep retrying
				return
			end

			attachEquipment(equipment)
		end)

		currentEquipment.request = req

		table.insert(requests, req)
	end
end

function avatar_getColors(self, config)
	local fields = avatarPrivateFields[self]
	if fields == nil then
		error("avatar:getColor(config) should be called with `:`", 2)
	end
	return {
		skin1 = fields.palette[SKIN_1_PALETTE_INDEX].Color,
		skin2 = fields.palette[SKIN_2_PALETTE_INDEX].Color,
		cloth = fields.palette[CLOTH_PALETTE_INDEX].Color,
		mouth = fields.palette[MOUTH_PALETTE_INDEX].Color,
		eyes = fields.palette[EYES_PALETTE_INDEX].Color,
		eyesWhite = fields.palette[EYES_WHITE_PALETTE_INDEX].Color,
		eyesDark = fields.palette[EYES_DARK_PALETTE_INDEX].Color,
		nose = fields.palette[NOSE_PALETTE_INDEX].Color,
	}
end

function avatar_setColors(self, config)
	local fields = avatarPrivateFields[self]
	if fields == nil then
		error("avatar:load(config) should be called with `:`", 2)
	end

	config = require("config"):merge({}, config, {
		acceptTypes = {
			skin1 = { "Color" },
			skin2 = { "Color" },
			cloth = { "Color" },
			mouth = { "Color" },
			eyes = { "Color" },
			eyesWhite = { "Color" },
			eyesDark = { "Color" },
			nose = { "Color" },
		},
	})

	local palette = fields.palette

	if config.skin1 then
		palette[SKIN_1_PALETTE_INDEX].Color = config.skin1
	end
	if config.skin2 then
		palette[SKIN_2_PALETTE_INDEX].Color = config.skin2
	end
	if config.cloth then
		palette[CLOTH_PALETTE_INDEX].Color = config.cloth
	end
	if config.mouth then
		palette[MOUTH_PALETTE_INDEX].Color = config.mouth
	end
	if config.eyes then
		palette[EYES_PALETTE_INDEX].Color = config.eyes
		if config.eyesDark == nil then
			config.eyesDark = Color(palette[EYES_PALETTE_INDEX].Color)
			config.eyesDark:ApplyBrightnessDiff(-0.2)
		end
	end
	if config.eyesWhite then
		palette[EYES_WHITE_PALETTE_INDEX].Color = config.eyesWhite
	end
	if config.eyesDark then
		palette[EYES_DARK_PALETTE_INDEX].Color = config.eyesDark
	end
	if config.nose then
		palette[NOSE_PALETTE_INDEX].Color = config.nose
	end
end

function avatar_setEyes(self, config)
	local fields = avatarPrivateFields[self]
	if fields == nil then
		error("avatar:setEyes(config) should be called with `:`", 2)
	end

	config = require("config"):merge({}, config, {
		acceptTypes = {
			index = { "number" },
			color = { "Color" },
		},
	})

	if config.index ~= nil then
		-- remove current eyes
		local head
		if fields.isHead == true then
			head = self
		else
			head = self.Head
		end

		local eyeBlocksDepth = head.Depth - 2
		if head.Depth == 12 then -- special case without nose
			eyeBlocksDepth = head.Depth - 1
		end

		local b
		for x = 4, head.Width - 5 do -- width -> left side when looking at face
			for y = 3, head.Height - 5 do
				b = head:GetBlock(x, y, eyeBlocksDepth)
				if b then
					b:Replace(SKIN_1_PALETTE_INDEX)
				end
			end
		end

		local eyes = mod.eyes[config.index]
		for _, e in ipairs(eyes) do
			b = head:GetBlock(15 - e.x, e.y + 2, eyeBlocksDepth)
			if b then
				b:Replace(e.c)
			end
		end
	end

	if config.color ~= nil then
		self:setColors({
			eyes = config.color,
		})
	end
end

function avatar_setNose(self, config)
	local fields = avatarPrivateFields[self]
	if fields == nil then
		error("avatar:setNose(config) should be called with `:`", 2)
	end

	config = require("config"):merge({}, config, {
		acceptTypes = {
			index = { "number" },
			color = { "Color" },
		},
	})

	if config.index ~= nil then
		local nodeBlocks = {}

		local nose = mod.noses[config.index]
		for _, n in ipairs(nose) do
			local x = 11 - n.x
			local y = n.y + 2
			if nodeBlocks[x] == nil then
				nodeBlocks[x] = {}
			end
			nodeBlocks[x][y] = n.c
		end

		-- remove current nose
		local head
		if fields.isHead == true then
			head = self
		else
			head = self.Head
		end
		local b
		local depth = 12
		for x = 8, head.Width - 9 do -- width -> left side when looking at face
			for y = 3, head.Height - 5 do
				if nodeBlocks[x][y] == nil then
					-- quick fix for blocks beneath nose blocks,
					-- they may not be using the correct palette index
					local blockBeneath = head:GetBlock(x, y, depth - 1)
					if blockBeneath ~= nil then
						blockBeneath:Replace(SKIN_1_PALETTE_INDEX)
					end

					b = head:GetBlock(x, y, depth)
					if b ~= nil then
						b:Remove()
					end
				else
					b = head:GetBlock(x, y, depth)
					if b == nil then
						head:AddBlock(nodeBlocks[x][y], x, y, depth)
					end
				end
			end
		end

		-- NOTE: there seems to be an issue when removing then adding block at same position
	end

	if config.color ~= nil then
		-- self:setColors({
		-- 	eyes = config.color,
		-- })
	end
end

function avatar_update_config(self, config)
	local fields = avatarPrivateFields[self]
	if fields == nil then
		error("avatar:updateConfig(config) should be called with `:`", 2)
	end

	config = require("config"):merge(fields.config, config)

	if config.eyeBlinks then
		if fields.eyeBlinksTimer == nil then
			local eyeLidRight = self.EyeLidRight
			local eyeLidLeft = self.EyeLidLeft
			if eyeLidRight == nil or eyeLidLeft == nil then
				return
			end

			local eyeBlinks = {}
			eyeBlinks.close = function()
				if eyeLidRight.IsDestroyed then
					eyeBlinks = nil
					return
				end
				-- removing eyelids when head loses its parent
				-- not ideal, but no easy way currently to detect when the avatar is destroyed
				if eyeLidRight:GetParent() == nil or eyeLidRight:GetParent():GetParent() == nil then
					eyeBlinks = nil
					eyeLidRight:RemoveFromParent()
					eyeLidLeft:RemoveFromParent()
					return
				end
				eyeLidRight.Scale.Y = 4.2
				eyeLidRight.IsHidden = false
				eyeLidLeft.Scale.Y = 4.2
				eyeLidLeft.IsHidden = false
				fields.eyeBlinksTimer = Timer(0.1, eyeBlinks.open)
			end
			eyeBlinks.open = function()
				if eyeLidRight.IsDestroyed then
					eyeBlinks = nil
					return
				end

				eyeLidRight.Scale.Y = 0
				eyeLidRight.IsHidden = true
				eyeLidLeft.Scale.Y = 0
				eyeLidLeft.IsHidden = true
				eyeBlinks.schedule()
			end
			eyeBlinks.schedule = function()
				fields.eyeBlinksTimer = Timer(3.0 + math.random() * 1.0, eyeBlinks.close)
			end
			eyeBlinks.schedule()
		end
	else
		if fields.eyeBlinksTimer ~= nil then
			fields.eyeBlinksTimer:Cancel()
			fields.eyeBlinksTimer = nil
			local eyeLidRight = self.EyeLidRight
			local eyeLidLeft = self.EyeLidLeft
			if eyeLidRight == nil or eyeLidLeft == nil then
				return
			end
			eyeLidRight.IsHidden = true
			eyeLidLeft.IsHidden = true
		end
	end

	fields.hiddenEquipments = {}

	for _, equipment in ipairs(config.hiddenEquipments) do
		fields.hiddenEquipments[equipment] = true
	end

	local hidden
	for equipmentType, equipment in pairs(fields.equipments) do
		if equipment.shapes then
			hidden = fields.hiddenEquipments[equipmentType] == true
			for _, s in ipairs(equipment.shapes) do
				s.IsHidden = hidden
			end
		end
	end

	fields.config = config
end

-- EQUIPMENTS

equipmentTypes = {
	"hair",
	"jacket",
	"pants",
	"boots",
}

equipmentIndex = {}
for _, e in ipairs(equipmentTypes) do
	equipmentIndex[e] = true
end

return mod
