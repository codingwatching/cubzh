--
-- Modal content for badge creation and editing
--

local mod = {}

local ICON_SIZE = 100

mod.createModalContent = function(_, config)
	local modal = require("modal")
	local badge = require("badge")
	local theme = require("uitheme")
	local loc = require("localize")
	local system_api = require("system_api", System)

	-- default config
	local defaultConfig = {
		uikit = require("uikit"), -- allows to provide specific instance of uikit
		onOpen = nil,
		mode = nil, -- "create" or "edit"
		badgeId = nil, -- must be provided if mode is "edit"
		worldId = nil, -- must be provided if mode is "create"
	}

	-- merge provided config with default config
	local ok, err = pcall(function()
		config = require("config"):merge(defaultConfig, config, {
			acceptTypes = {
				onOpen = { "function" },
				mode = { "string" },
				badgeId = { "string" },
				worldId = { "string" },
			},
		})
	end)
	if not ok then
		error("badge_modal:createModalContent(config) - config error: " .. err, 2)
	end

	local badgeAnimationListener = nil
	local badgeObject = nil

	local function animateBadge()
		if badgeObject == nil then
			return
		end
		if badgeAnimationListener ~= nil then
			return
		end

		local t = 0
		local r = Rotation()
		badgeAnimationListener = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
			t += dt * 1.5
			r.Y = math.sin(t) * 0.4
			r.X = math.cos(t * 1.1) * 0.3
			badgeObject.LocalRotation:Set(r)
		end)
	end

	local function removeBadgeAnimation()
		if badgeAnimationListener ~= nil then
			badgeAnimationListener:Remove()
			badgeAnimationListener = nil
		end
	end

	-- use uikit from the config
	local ui = config.uikit

	-- modal content variables
	local refreshTimer

	-- define some functions
	local functions = {
		constructNode = function()
			local node = ui:frame()

			-- badge creation form fields
			local iconData
			local tag 
			local name
			local description

			-- unique cell of the scroll
			local cell = ui:frame()
			cell:setParent(nil)

			-- scroll (root element of the modal content)
			local scroll = ui:scroll({
				-- backgroundColor = Color(255, 0, 0),
				backgroundColor = theme.buttonTextColor,
				-- backgroundColor = Color(0, 255, 0, 0.3),
				-- gradientColor = Color(37, 23, 59), -- Color(155, 97, 250),
				padding = {
					top = theme.padding,
					bottom = theme.padding,
					left = theme.padding,
					right = theme.padding,
				},
				cellPadding = theme.padding,
				loadCell = function(index)
					if index == 1 then
						return cell
					end
				end,
				unloadCell = function(_, _) end,
			})
			scroll:setParent(node)

			-- define UI elements

			local badgeShape = ui:frame()
			badgeShape.Width = ICON_SIZE
			badgeShape.Height = ICON_SIZE
			badgeShape:setParent(cell)

			local req = badge:createBadgeObject({
				badgeId = nil,
				locked = false,
				frontOnly = true,
				callback = function(o)
					badgeObject = o

					local s = ui:createShape(badgeObject, { spherized = false, doNotFlip = true })
					s.Width = ICON_SIZE
					s.Height = ICON_SIZE
					s:setParent(cell)

					badgeShape:remove()
					badgeShape = s

					local y = cell.Height - theme.padding - badgeShape.Height
					badgeShape.pos = { theme.padding, y }

					animateBadge()
				end,
			})

			local editIconBtn = ui:buttonSecondary({ content = "✏️ Set Image", textSize = "small" })
			editIconBtn:setParent(cell)

			-- Tag
			local identifierLabel = ui:createText("The identifier is used in code to unlock the badge. (a-z & 0-9 characters only)", { 
				size = "small", 
				color = Color(150, 150, 150),
			})
			identifierLabel:setParent(cell)

			local tagEdit = ui:createTextInput("", "identifier")
			tagEdit:setParent(cell)

			-- Name

			local nameEdit = ui:createTextInput("", "Badge Name")
			nameEdit:setParent(cell)

			-- Description
			local descriptionEdit = ui:createTextInput("", "Description")
			descriptionEdit:setParent(cell)

			-- Create Badge Button
			local createBadgeBtn = ui:buttonPositive({ 
				content = loc("Create"), 
				padding = {
					top = theme.padding,
					bottom = theme.padding,
					left = theme.padding * 2,
					right = theme.padding * 2,
				},
			})
			createBadgeBtn:disable()
			createBadgeBtn:setParent(cell)

			-- Tag value has changed
			tagEdit.onTextChange = function(self)
				-- allow only alphanumeric characters and underscores
				if not self.Text:match("^%w+$") then
					self.onTextChangeSave = self.onTextChange
					self.onTextChange = nil
					self.Text = self.Text:gsub("[^%w]", "")
					self.onTextChange = self.onTextChangeSave
				end

				-- store new value
				tag = self.Text

				-- update create button
				node:refreshCreateButton()
			end

			-- Name value has changed
			nameEdit.onTextChange = function(self)
				name = self.Text
				node:refreshCreateButton()
			end

			-- Description value has changed
			descriptionEdit.onTextChange = function(self)
				description = self.Text
				node:refreshCreateButton()
			end

			node.refreshCreateButton = function()
				if iconData ~= nil and tag ~= nil and tag ~= "" then
					createBadgeBtn:enable()
				else
					createBadgeBtn:disable()
				end
			end

			node.refresh = function(self)
				-- scroll fills the entire modal content
				scroll.Width = self.Width
				scroll.Height = self.Height

				local contentWidth = self.Width - theme.padding * 2
				identifierLabel.object.MaxWidth = contentWidth

				-- compute content height
				local contentHeight = theme.padding
					+ badgeShape.Height
					+ theme.padding
					+ identifierLabel.Height
					+ theme.padding
					+ tagEdit.Height
					+ theme.padding
					+ nameEdit.Height
					+ theme.padding
					+ descriptionEdit.Height
					+ theme.padding
					+ createBadgeBtn.Height
					+ theme.padding

				cell.Width = contentWidth
				cell.Height = contentHeight

				-- compute width values
				tagEdit.Width = cell.Width - theme.padding * 2
				nameEdit.Width = tagEdit.Width
				descriptionEdit.Width = tagEdit.Width

				local y = contentHeight

				-- badge preview
				y = y - theme.padding - badgeShape.Height
				badgeShape.pos = { theme.padding, y }
				editIconBtn.pos = { badgeShape.pos.X + badgeShape.Width + theme.padding, y }

				-- tag edit + button
				y = y - theme.padding - tagEdit.Height
				tagEdit.pos = { theme.padding, y }

				-- identifier label
				y = y - theme.padding - identifierLabel.Height
				identifierLabel.pos = { theme.padding, y }

				-- name edit + button
				y = y - theme.padding - nameEdit.Height
				nameEdit.pos = { theme.padding, y }

				-- description edit
				y = y - theme.padding - descriptionEdit.Height
				descriptionEdit.pos = { theme.padding, y }

				-- create badge button
				y = y - theme.padding - createBadgeBtn.Height
				createBadgeBtn.pos = { (cell.Width - createBadgeBtn.Width) / 2, y }

				-- Update create button state
				self:refreshCreateButton()

				-- TODO: gaetan: is this really necessary?
				scroll:flush()
				scroll:refresh()
			end

			-- Import icon button callback
			editIconBtn.onRelease = function()
				File:OpenAndReadAll(function(success, data)
					if not success then -- TODO: handle error
						iconData = nil -- reset icon data
						return
					end

					if data == nil then -- TODO: handle error
						iconData = nil -- reset icon data
						return
					end

					-- store icon data in a variable
					iconData = data
					if badgeObject ~= nil then
						badgeObject:setBadgeImage(iconData)
					end

					node:refreshCreateButton()
				end)
			end

			-- Create badge button callback
			createBadgeBtn.onRelease = function()
				system_api:createBadge({
					worldID = config.worldId,
					icon = iconData,
					tag = tag,
					name = name,
					description = description,
				}, function(err)
					if err then
						print("error creating badge:", err)
						-- TODO: display error somewhere
					else
						print("badge created successfully")
						-- go back to the previous modal content
						-- TODO: !!!
					end
				end)
			end

			node:refresh()
			return node
		end,
	}

	-- create content
	local content = modal:createContent()
	content.closeButton = true

	content.idealReducedContentSize = function(node, width, height)
		node.Width = width
		node.Height = height
		node:refresh()
		return Number2(width, height)
	end

	content.node = functions.constructNode()
	content.title = "New Badge"
	content.icon = "🏅"

	content.didBecomeActive = function()
		animateBadge()
	end

	content.willResignActive = function()
		removeBadgeAnimation()
	end

	return content
end

return mod
