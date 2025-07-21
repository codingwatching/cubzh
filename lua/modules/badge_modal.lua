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
		badgeObj = nil, -- must be provided if mode is "edit"
		worldId = nil, -- must be provided if mode is "create"
	}

	-- merge provided config with default config
	local ok, err = pcall(function()
		config = require("config"):merge(defaultConfig, config, {
			acceptTypes = {
				onOpen = { "function" },
				mode = { "string" },
				badgeObj = { "table" },
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

	-- create content
	local content = modal:createContent()

	-- define some functions
	local functions = {
		constructNode = function()
			local node = ui:frame()

			-- badge creation form fields
			-- local iconData
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

			local badgeId = nil
			if config.badgeObj ~= nil then
				badgeId = config.badgeObj.badgeID
			end
			local req = badge:createBadgeObject({
				badgeId = badgeId,
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

					node:refreshCreateButton()

					animateBadge()
				end,
			})

			local editIconBtn = ui:buttonSecondary({ content = "✏️ Set Image", textSize = "small" })
			editIconBtn:setParent(cell)

			-- Tag
			local identifierLabel =
				ui:createText("The identifier is used in code to unlock the badge. (a-z & 0-9 characters only)", {
					size = "small",
					color = Color(150, 150, 150),
				})
			identifierLabel:setParent(cell)

			local tagTextOrEdit = nil
			if config.mode == "create" then
				tagTextOrEdit = ui:createTextInput("", "identifier")
			elseif config.mode == "edit" then
				-- config.badgeObj.tag must exist in this case
				tag = config.badgeObj.tag
				tagTextOrEdit = ui:createText("Identifier: " .. tag, {
					size = "small",
					color = Color.White,
				})
			end
			tagTextOrEdit:setParent(cell)

			-- Name
			local nameEdit = ui:createTextInput("", "Badge Name")
			nameEdit:setParent(cell)
			if config.badgeObj ~= nil then
				name = config.badgeObj.name
				nameEdit.Text = name
			end

			-- Description
			local descriptionEdit = ui:createTextInput("", "Description")
			descriptionEdit:setParent(cell)
			if config.badgeObj ~= nil then
				description = config.badgeObj.description
				descriptionEdit.Text = description
			end

			-- Create Badge Button
			local submitBtnText = nil
			if config.mode == "create" then
				submitBtnText = loc("Create")
			elseif config.mode == "edit" then
				submitBtnText = loc("Update")
			else
				error("badge_modal:createModalContent(config): invalid mode: " .. config.mode)
			end
			local submitFormBtn = ui:buttonPositive({
				content = submitBtnText,
				padding = {
					top = theme.padding,
					bottom = theme.padding,
					left = theme.padding * 2,
					right = theme.padding * 2,
				},
			})
			submitFormBtn:disable()
			submitFormBtn:setParent(cell)

			-- Tag value has changed
			if config.mode == "create" then
				tagTextOrEdit.onTextChange = function(self)
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
				if badgeObject ~= nil and badgeObject:getBadgeImageData() ~= nil and tag ~= nil and tag ~= "" then
					submitFormBtn:enable()
				else
					submitFormBtn:disable()
				end
			end

			node.refresh = function(self)
				scroll.Width = self.Width

				local contentWidth = self.Width - theme.padding * 2
				identifierLabel.object.MaxWidth = contentWidth

				-- compute content height
				local contentHeight = theme.padding
					+ badgeShape.Height
					+ theme.padding
					+ identifierLabel.Height
					+ theme.padding
					+ tagTextOrEdit.Height
					+ theme.padding
					+ nameEdit.Height
					+ theme.padding
					+ descriptionEdit.Height
					+ theme.padding
					+ submitFormBtn.Height
					+ theme.padding

				cell.Width = contentWidth
				cell.Height = contentHeight

				-- shrink to fit content if possible
				self.Height = math.min(contentHeight + theme.padding * 2, self.Height)
				scroll.Height = self.Height

				-- compute width values
				local formFieldWidth = cell.Width - theme.padding * 2
				tagTextOrEdit.Width = formFieldWidth
				nameEdit.Width = formFieldWidth
				descriptionEdit.Width = formFieldWidth

				local y = contentHeight

				-- badge preview
				y = y - theme.padding - badgeShape.Height
				badgeShape.pos = { theme.padding, y }
				editIconBtn.pos = { badgeShape.pos.X + badgeShape.Width + theme.padding, y }

				-- tag edit + button
				y = y - theme.padding - tagTextOrEdit.Height
				tagTextOrEdit.pos = { theme.padding, y }

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
				y = y - theme.padding - submitFormBtn.Height
				submitFormBtn.pos = { (cell.Width - submitFormBtn.Width) / 2, y }

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
						-- iconData = nil -- reset icon data
						return
					end

					if data == nil then -- TODO: handle error
						-- iconData = nil -- reset icon data
						return
					end

					-- store icon data in a variable
					-- iconData = data
					if badgeObject ~= nil then
						badgeObject:setBadgeImage(data)
					end

					node:refreshCreateButton()
				end)
			end

			-- Create badge button callback
			submitFormBtn.onRelease = function()
				if config.mode == "create" then
					system_api:createBadge({
						worldID = config.worldId,
						icon = badgeObject:getBadgeImageData(),
						tag = tag,
						name = name,
						description = description,
					}, function(err)
						if err then
							Menu:ShowAlert({
								message = loc("Sorry, something went wrong. 😕"),
								neutralLabel = loc("OK"),
								neutralCallback = function() end,
							}, System)
						else
							-- badge created successfully, going back to world details
							Menu:ShowAlert({
								message = loc("Badge Created! ✅"),
								neutralLabel = loc("OK"),
								neutralCallback = function()
									content:pop()
								end,
							}, System)
						end
					end)
				elseif config.mode == "edit" then
					system_api:updateBadge({
						badgeID = config.badgeObj.badgeID,
						icon = badgeObject:getBadgeImageData(),
						name = name,
						description = description,
					}, function(err)
						print("[🐞][EDIT BADGE][RESPONSE] err:", err)
						-- if err then
						-- 	Menu:ShowAlert({
						-- 		message = loc("Sorry, something went wrong. 😕"),
						-- 		neutralLabel = loc("OK"),
						-- 		neutralCallback = function() end,
						-- 	}, System)
						-- end
					end)
				end
			end

			node:refresh()
			return node
		end,
	}

	content.idealReducedContentSize = function(node, width, height)
		node.Width = width
		node.Height = height
		node:refresh()
		return Number2(node.Width, node.Height)
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
