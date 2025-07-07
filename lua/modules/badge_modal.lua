--
-- Modal content for badge creation and editing
--

local mod = {}

mod.createModalContent = function(_, config)
	local modal = require("modal")
	local theme = require("uitheme")

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

			local privateFields = {}

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
			local editIconBtn = ui:buttonSecondary({ content = "✏️ edit icon" })
			editIconBtn:setParent(cell)

			-- Name
			local nameEdit = ui:createTextInput(config.world.title, "Badge Name")
			nameEdit:setParent(cell)
			local editNameBtn = ui:buttonSecondary({ content = "✏️" })
			editNameBtn:setParent(cell)

			-- Tag
			local tagEdit = ui:createTextInput(config.world.title, "Badge Tag")
			tagEdit:setParent(cell)
			local editTagBtn = ui:buttonSecondary({ content = "✏️" })
			editTagBtn:setParent(cell)

			-- Create Badge Button
			local createBadgeBtn = ui:createButton("Create Badge")
			createBadgeBtn:setParent(cell)

			node.refresh = function(self)
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
					+ nameEdit.Height
					+ theme.padding
					+ tagEdit.Height
					+ theme.padding
					+ createBadgeBtn.Height
					+ theme.padding

				cell.Width = scroll.Width - theme.padding * 2
				cell.Height = contentHeight

				local y = contentHeight

				-- icon + button
				y = y - theme.padding - iconMask.Height
				iconMask.pos = { theme.padding, y }
				editIconBtn.pos = { theme.padding + iconMask.Width + theme.padding, y }

				-- name edit + button
				y = y - theme.padding - nameEdit.Height
				nameEdit.pos = { theme.padding, y }
				editNameBtn.pos = { theme.padding + nameEdit.Width + theme.padding, y }

				-- tag edit + button
				y = y - theme.padding - tagEdit.Height
				tagEdit.pos = { theme.padding, y }
				editTagBtn.pos = { theme.padding + tagEdit.Width + theme.padding, y }

				-- create badge button
				y = y - theme.padding - createBadgeBtn.Height
				createBadgeBtn.pos = { (cell.Width - createBadgeBtn.Width) / 2, y }

				scroll:flush()
				scroll:refresh()
			end

			createBadgeBtn.onRelease = function()
				print("create badge!")
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
