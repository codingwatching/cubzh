--
-- Modal content for badge creation and editing
--

local mod = {}

mod.createModalContent = function(_, config)
	local modal = require("modal")
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

	-- use uikit from the config
	local ui = config.uikit

	-- modal content variables
	local refreshTimer

	-- define some functions
	local functions = {
		constructNode = function()
			local node = ui:createNode()

			local privateFields = {
				-- badge creation form fields
				iconData = nil,
				tag = nil,
				name = nil,
				description = nil,
			}

			privateFields.scheduleRefresh = function()
				if refreshTimer ~= nil then
					return
				end
				refreshTimer = Timer(0.01, function()
					refreshTimer = nil
					node:refresh()
				end)
			end

			local w = 400
			local h = 400

			node._width = function(_)
				return w
			end

			node._height = function(_)
				return h
			end

			node._setWidth = function(_, v)
				w = v
				privateFields:scheduleRefresh()
			end

			node._setHeight = function(_, v)
				h = v
				privateFields:scheduleRefresh()
			end

			-- unique cell of the scroll
			local cell = ui:frame() -- { color = Color(100, 100, 100) }
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

			-- Icon (+ mask)
			local iconMask = ui:frame({
				image = {
					data = Data:FromBundle("images/round-corner-mask.png"),
					slice9 = { 0.5, 0.5 },
					slice9Scale = 1.0,
					slice9Width = 20,
					-- alpha = true,
					cutout = true, -- mask only seem to work with cutout, not alpha
				},
				mask = true,
			})
			-- iconMask.IsMask = true
			iconMask:setParent(cell)
			local iconArea = ui:frame({ color = Color(20, 20, 22) })
			iconArea:setParent(iconMask)
			local editIconBtn = ui:buttonSecondary({ content = "✏️" })
			editIconBtn:setParent(cell)

			-- Tag
			local tagEdit = ui:createTextInput("", "Identifier")
			tagEdit:setParent(cell)
			local tagStatus = ui:createText("⚠️", theme.textColor)
			tagStatus:setParent(cell)

			-- Name
			local nameEdit = ui:createTextInput("", "Name")
			nameEdit:setParent(cell)

			-- Description
			local descriptionEdit = ui:createTextInput("", "Description")
			descriptionEdit:setParent(cell)

			-- Create Badge Button
			local createBadgeBtn = ui:buttonPositive({ content = loc("Create Badge") })
			createBadgeBtn:setParent(cell)

			-- update tag status icon based on the tag value
			privateFields.refreshTagStatusIcon = function()
				if privateFields.tag ~= nil and privateFields.tag ~= "" then
					tagStatus.Text = "✅"
				else
					tagStatus.Text = "⚠️"
				end
			end

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
				privateFields.tag = self.Text

				-- update tag status icon
				privateFields:refreshTagStatusIcon()

				-- update create button
				node:refreshCreateButton()
			end

			-- Name value has changed
			nameEdit.onTextChange = function(self)
				privateFields.name = self.Text
				node:refreshCreateButton()
			end

			-- Description value has changed
			descriptionEdit.onTextChange = function(self)
				privateFields.description = self.Text
				node:refreshCreateButton()
			end

			node.refreshCreateButton = function()
				-- refresh create button state
				if privateFields.iconData ~= nil and privateFields.tag ~= nil and privateFields.tag ~= "" then
					-- make button active
					createBadgeBtn.disabled = false
					-- TODO: update button color
				else
					-- make button inactive
					createBadgeBtn.disabled = true -- not clickable
					-- TODO: update button color
				end
			end

			node.refresh = function(self)
				-- update tag status icon
				privateFields:refreshTagStatusIcon()

				-- recompute the layout

				-- scroll fills the entire modal content
				scroll.Width = self.Width
				scroll.Height = self.Height

				-- icon size
				local iconSize = math.min(100, self.Width * 0.3)
				iconArea.Width = iconSize
				iconArea.Height = iconSize
				iconMask.Width = iconSize
				iconMask.Height = iconSize

				-- compute content height
				local contentHeight = theme.padding
					+ iconMask.Height
					+ theme.padding
					+ tagEdit.Height
					+ theme.padding
					+ nameEdit.Height
					+ theme.padding
					+ createBadgeBtn.Height
					+ theme.padding

				cell.Width = scroll.Width - theme.padding * 2
				cell.Height = contentHeight

				-- compute width values
				tagEdit.Width = cell.Width - tagStatus.Width - theme.padding * 2
				nameEdit.Width = tagEdit.Width
				descriptionEdit.Width = tagEdit.Width

				local y = contentHeight

				-- icon + edit button
				y = y - theme.padding - iconMask.Height
				iconMask.pos = { theme.padding, y }
				editIconBtn.pos = iconMask.pos -- + (iconMask.size * 0.5) - (editIconBtn.size * 0.5) -- wrong arithmetic operation (*0.5)

				-- tag edit + button
				y = y - theme.padding - tagEdit.Height
				tagEdit.pos = { theme.padding, y }
				tagStatus.pos = tagEdit.pos
					+ { tagEdit.Width + theme.padding, tagEdit.Height * 0.5 - tagStatus.Height * 0.5 }

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
						privateFields.iconData = nil -- reset icon data
						return
					end

					if data == nil then -- TODO: handle error
						privateFields.iconData = nil -- reset icon data
						return
					end

					-- store icon data in a variable
					privateFields.iconData = data

					-- update icon in the UI
					iconArea:setImage(privateFields.iconData)

					-- refresh create button state
					node:refreshCreateButton()
				end)
			end

			-- Create badge button callback
			createBadgeBtn.onRelease = function()
				system_api:createBadge({
					worldID = config.worldId,
					icon = privateFields.iconData,
					tag = privateFields.tag,
					name = privateFields.name,
					description = privateFields.description,
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

	content.idealReducedContentSize = function(_, width, height)
		return Number2(width, height)
	end

	content.node = functions.constructNode()
	content.title = "New Badge"
	content.icon = "🏅"

	return content
end

return mod
