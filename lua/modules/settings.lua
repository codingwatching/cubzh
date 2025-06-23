settings = {}

local loc = require("localize")

--- Creates modal content for app settings
--- config(table): contents "cache" and "logout" keys, set either of these to true to display associated buttons
--- returns: modal
settings.createModalContent = function(_, config)
	-- MODULES
	local modal = require("modal")
	local theme = require("uitheme")

	-- CONSTANTS
	local SENSITIVITY_STEP = 0.1
	local MIN_SENSITIVITY = 0.1
	local MAX_SENSITIVITY = 3.0
	local VOLUME_STEP = 0.05
	local MIN_VOLUME = 0.0
	local MAX_VOLUME = 1.0

	if config ~= nil and type(config) ~= "table" then
		error("setting:create(<config>): config should be a table", 2)
	end

	-- default config
	local _config = {
		account = true,
		clearCache = false,
		uikit = require("uikit"),
	}

	if config then
		for k, v in pairs(_config) do
			if type(config[k]) == type(v) then
				_config[k] = config[k]
			end
		end
	end

	config = _config

	local ui = config.uikit

	local settingsNode = ui:createFrame()

	local content = modal:createContent()
	content.title = loc("Settings")
	content.icon = Data:FromBundle("images/icon-settings.png")
	content.node = settingsNode

	local rows = {}

	-- VOLUME

	local volumeLabel = ui:createText("", {
		color = Color.White,
	})
	local volumeValue = ui:createText("", {
		color = Color.White,
		bold = true,
	})
	local function refreshVolumeLabel()
		volumeLabel.Text = string.format(loc("🔈 Volume:"))
		volumeValue.Text = string.format("%.f%% ", System.MasterVolume * 100)
	end
	refreshVolumeLabel()

	local volumeSlider = ui:slider({
		min = 0.0,
		max = 1.0,
		step = 0.01,
		defaultValue = System.MasterVolume,
		hapticFeedback = false,
		button = ui:buttonNeutral({ content = "  ", padding = theme.padding }),
		onValueChange = function(v)
			System.MasterVolume = v
			refreshVolumeLabel()
		end,
	})
	volumeSlider.isSlider = true
	volumeSlider.Width = 180

	table.insert(rows, { volumeLabel, volumeValue, volumeSlider })

	-- SENSITIVITY

	local sensitivityLabel = ui:createText("", {
		color = Color.White,
	})
	local sensitivityValue = ui:createText("", {
		color = Color.White,
		bold = true,
	})
	local function refreshSensitivityLabel()
		if Client.IsMobile then
			sensitivityLabel.Text = string.format(loc("👆 Sensitivity:"))
		else
			sensitivityLabel.Text = string.format(loc("🖱️ Sensitivity:"))
		end
		sensitivityValue.Text = string.format("%.1f ", System.Sensitivity)
	end
	refreshSensitivityLabel()

	local sensitivitySlider = ui:slider({
		min = MIN_SENSITIVITY,
		max = MAX_SENSITIVITY,
		step = SENSITIVITY_STEP,
		defaultValue = System.Sensitivity,
		hapticFeedback = false,
		button = ui:buttonNeutral({ content = "  ", padding = theme.padding }),
		onValueChange = function(v)
			System.Sensitivity = math.max(MIN_SENSITIVITY, math.min(MAX_SENSITIVITY, v))
			refreshSensitivityLabel()
		end,
	})
	sensitivitySlider.isSlider = true
	sensitivitySlider.Width = 180

	table.insert(rows, { sensitivityLabel, sensitivityValue, sensitivitySlider })

	-- ZOOM SENSITIVITY

	local zoomSensitivityLabel = ui:createText("", {
		color = Color.White,
	})
	local zoomSensitivityValue = ui:createText("", {
		color = Color.White,
		bold = true,
	})

	local function refreshZoomSensitivityLabel()
		zoomSensitivityLabel.Text = string.format(loc("🔍 Zoom Sensitivity:"))
		zoomSensitivityValue.Text = string.format("%.1f ", System.ZoomSensitivity)
	end
	refreshZoomSensitivityLabel()

	local zoomSensitivitySlider = ui:slider({
		min = MIN_SENSITIVITY,
		max = MAX_SENSITIVITY,
		step = SENSITIVITY_STEP,
		defaultValue = System.ZoomSensitivity,
		hapticFeedback = false,
		button = ui:buttonNeutral({ content = "  ", padding = theme.padding }),
		onValueChange = function(v)
			System.ZoomSensitivity = math.max(MIN_SENSITIVITY, math.min(MAX_SENSITIVITY, v))
			refreshZoomSensitivityLabel()
		end,
	})
	zoomSensitivitySlider.isSlider = true
	zoomSensitivitySlider.Width = 180

	table.insert(rows, { zoomSensitivityLabel, zoomSensitivityValue, zoomSensitivitySlider })

	-- RENDER QUALITY

	local renderQualityLabel = ui:createText(loc("✨ Render Quality:"), {
		color = Color.White,
	})
	local renderQualityValue = ui:createText("", {
		color = Color.White,
		bold = true,
	})

	local refreshRenderQualityLabel

	local renderQualitySlider = ui:slider({
		min = 1,
		max = System.MaxRenderQualityTier,
		step = 1,
		defaultValue = System.RenderQualityTier,
		hapticFeedback = true,
		button = ui:buttonNeutral({ content = "  ", padding = theme.padding }),
		onValueChange = function(v)
			System.RenderQualityTier = math.max(System.MinRenderQualityTier, math.min(System.MaxRenderQualityTier, v))
			refreshRenderQualityLabel()
		end,
	})
	renderQualitySlider.isSlider = true
	renderQualitySlider.Width = 180

	refreshRenderQualityLabel = function()
		if System.RenderQualityTiersAvailable then
			renderQualityValue.Text =
				string.format("%d/%d ", System.RenderQualityTier, System.MaxRenderQualityTier)
		else
			renderQualitySlider:disable()
			renderQualityValue.Text = string.format("1/%d ", System.MaxRenderQualityTier)
		end

		local modal = content:getModalIfContentIsActive()
		if modal then
			modal:refreshContent()
		end
	end
	refreshRenderQualityLabel()

	table.insert(rows, { renderQualityLabel, renderQualityValue, renderQualitySlider })

	-- HAPTIC FEEDBACK
	local hapticFeedbackToggle
	if Client.IsMobile then
		local hapticFeedbackLabel = ui:createText(loc("📳 Haptic Feedback:"), Color.White)

		hapticFeedbackToggle = ui:buttonNeutral({ content = "ON" })
		if System.HapticFeedbackEnabled then
			hapticFeedbackToggle.Text = "ON"
			hapticFeedbackToggle:setColor(theme.colorPositive)
		else
			hapticFeedbackToggle.Text = "OFF"
			hapticFeedbackToggle:setColor(theme.colorNegative)
		end

		hapticFeedbackToggle.onRelease = function(_)
			System.HapticFeedbackEnabled = not System.HapticFeedbackEnabled

			if System.HapticFeedbackEnabled then
				hapticFeedbackToggle.Text = "ON"
				hapticFeedbackToggle:setColor(theme.colorPositive)
			else
				hapticFeedbackToggle.Text = "OFF"
				hapticFeedbackToggle:setColor(theme.colorNegative)
			end
		end

		local r = { hapticFeedbackLabel, hapticFeedbackToggle }
		r.align = "center"
		table.insert(rows, r)
	end

	-- FULLSCREEN
	local fullscreenToggle
	if Client.OSName == "Windows" then
		local fullscreenLabel = ui:createText(loc("📺 Fullscreen:"), Color.White)

		fullscreenToggle = ui:buttonNeutral({ content = "ON" })
		if System.Fullscreen then
			fullscreenToggle.Text = "ON"
			fullscreenToggle:setColor(theme.colorPositive)
		else
			fullscreenToggle.Text = "OFF"
			fullscreenToggle:setColor(theme.colorNegative)
		end

		fullscreenToggle.onRelease = function(_)
			System.Fullscreen = not System.Fullscreen

			if System.Fullscreen then
				fullscreenToggle.Text = "ON"
				fullscreenToggle:setColor(theme.colorPositive)
			else
				fullscreenToggle.Text = "OFF"
				fullscreenToggle:setColor(theme.colorNegative)
			end
		end

		local r = { fullscreenLabel, fullscreenToggle }
		r.align = "center"
		table.insert(rows, r)
	end

	-- CACHE

	cacheAndLogoutRow = {}

	if _config.account == true then
		local accountButton = ui:buttonNeutral({ content = loc("Account"), textSize = "small" })
		accountButton.onRelease = function(_)
			local accountContent = modal:createContent()
			accountContent.title = loc("Account")
			accountContent.icon = Data:FromBundle("images/icon-settings.png")

			local node = ui:createFrame()
			accountContent.node = node

			local logoutButton = ui:buttonNegative({ content = loc("Logout", "button"), textSize = "small", padding = theme.padding })
			logoutButton:setColor(theme.colorNegative)
			logoutButton:setParent(node)

			logoutButton.onRelease = function(_)
				local logoutContent = modal:createContent()
				logoutContent.title = loc("Logout", "title")
				logoutContent.icon = "⚙️"

				local node = ui:createFrame()
				logoutContent.node = node

				local text = ui:createText(loc("Are you sure you want to logout now?"), {
					color = Color.White,
					size = "default",
				})
				text:setParent(node)

				text.object.MaxWidth = 300

				logoutContent.idealReducedContentSize = function(_, _, _)
					local w, h = text.Width + theme.padding * 2, text.Height + theme.padding * 2
					return Number2(w, h)
				end

				node.parentDidResize = function(self)
					local w = text.Width
					text.pos.X = self.Width * 0.5 - w * 0.5
					text.pos.Y = self.Height - text.Height - theme.padding
				end

				local yes = ui:buttonNeutral({ content = loc("Yes! 🙂") })
				yes.onRelease = function()
					local modal = logoutContent:getModalIfContentIsActive()
					if modal then
						modal:close()
					end
					System:Logout()
				end
				logoutContent.bottomCenter = { yes }

				accountContent:push(logoutContent)
			end

			local deleteButton = ui:button({
				content = loc("delete account"),
				textSize = "small",
				underline = true,
				color = Color(0, 0, 0, 0),
				borders = false,
				padding = false,
				shadow = false,
			})
			deleteButton:setColor(Color(0, 0, 0, 0), theme.colorNegative)
			deleteButton:setParent(node)

			deleteButton.onRelease = function(_)
				local deleteContent = modal:createContent()
				deleteContent.title = loc("Account Deletion")
				deleteContent.icon = "⚙️"

				local node = ui:createFrame()
				deleteContent.node = node

				local text =
					ui:createText(loc("⚠️ Are you REALLY sure you want to delete your account now?"), Color.White)
				text:setParent(node)

				local text2 = ui:createText(loc("Type your username to confirm:"), Color.White)
				text2:setParent(node)

				text.object.MaxWidth = 300
				text2.object.MaxWidth = 300

				local input = ui:createTextInput("", "", { textSize = "default" })
				input:setParent(node)

				local req

				node.parentDidResize = function(self)
					local w = math.max(text.Width, text2.Width)

					text.pos.X = self.Width * 0.5 - w * 0.5
					text.pos.Y = self.Height - text.Height - theme.padding

					text2.pos.X = self.Width * 0.5 - w * 0.5
					text2.pos.Y = text.pos.Y - text2.Height - theme.padding

					input.Width = w
					input.pos.X = self.Width * 0.5 - w * 0.5
					input.pos.Y = text2.pos.Y - input.Height - theme.padding
				end

				deleteContent.idealReducedContentSize = function(_, _, _, _)
					local w = math.max(text.Width, text2.Width) + theme.padding * 2
					local h = text.Height + text2.Height + input.Height + theme.padding * 4
					return Number2(w, h)
				end

				local yes = ui:buttonNeutral({ content=loc("🗑️ Delete account") })
				yes:disable()
				yes.onRelease = function()
					yes:disable()
					req = require("system_api", System):deleteUser(function(success)
						req = nil
						if success == true then
							local modal = deleteContent:getModalIfContentIsActive()
							if modal then
								modal:close()
							end
							System:Logout()
						else
							if string.lower(input.Text) == string.lower(Player.Username) then
								yes:enable()
							end
						end
					end)
				end

				input.onTextChange = function()
					if req ~= nil then
						req:Cancel()
						req = nil
					end
					if string.lower(input.Text) == string.lower(Player.Username) then
						yes:enable()
					else
						yes:disable()
					end
				end

				deleteContent.bottomCenter = { yes }

				accountContent:push(deleteContent)
			end

			node.parentDidResize = function(self)
				logoutButton.pos.X = self.Width * 0.5 - logoutButton.Width * 0.5
				logoutButton.pos.Y = self.Height - logoutButton.Height - theme.padding

				deleteButton.pos.X = self.Width * 0.5 - deleteButton.Width * 0.5
				deleteButton.pos.Y = logoutButton.pos.Y - deleteButton.Height - theme.padding
			end

			accountContent.idealReducedContentSize = function(_, _, _, minWidth)
				local w = math.max(logoutButton.Width, deleteButton.Width, 250)
				local h = logoutButton.Height + deleteButton.Height + theme.padding * 3
				w = math.max(minWidth, w)
				return Number2(w, h)
			end

			content:push(accountContent)
		end
		table.insert(cacheAndLogoutRow, accountButton)
	end

	if _config.clearCache == true then
		local cacheButton = ui:buttonNeutral({ content = loc("Clear cache"), textSize = "small" })
		cacheButton.onRelease = function(_)
			local clearCacheContent = modal:createContent()
			clearCacheContent.title = loc("Settings")
			clearCacheContent.icon = Data:FromBundle("images/icon-settings.png")

			local node = ui:createFrame()
			clearCacheContent.node = node

			local text = ui:createText(
				loc("⚠️ Clearing all cached data from visited experiences, are you sure about this?"), 
				{
					color = Color.White,
					size = "default",
				}
			)
			text.pos.X = theme.padding
			text.pos.Y = theme.padding
			text:setParent(node)

			text.object.MaxWidth = 300

			clearCacheContent.idealReducedContentSize = function(_, _, _, minWidth)
				local w = text.Width + theme.padding * 2
				local h = text.Height + theme.padding * 2
				w = math.max(minWidth, w)
				return Number2(w, h)
			end

			local yes = ui:buttonNeutral({ content = loc("Yes, delete cache! 💀") })
			yes.onRelease = function()
				System.ClearCache()
				local done = ui:createText("✅ Done!", Color.White)
				clearCacheContent.bottomCenter = { done }
			end
			clearCacheContent.bottomCenter = { yes }

			content:push(clearCacheContent)
		end
		table.insert(cacheAndLogoutRow, cacheButton)
	end

	cacheAndLogoutRow.align = "center"

	if #cacheAndLogoutRow > 0 then
		table.insert(rows, cacheAndLogoutRow)
	end

	-- UI setup

	for _, row in ipairs(rows) do
		for _, element in ipairs(row) do
			element:setParent(settingsNode)
		end
	end

	local refresh = function()
		-- button only used as a min width reference for some buttons
		local btn = ui:button({ content="OFF" })
		local toggleWidth = btn.Width + theme.padding * 2
		btn.Text = "➕"
		local oneEmojiWidth = btn.Width + theme.padding
		btn:remove()

		if hapticFeedbackToggle ~= nil then
			hapticFeedbackToggle.Width = toggleWidth
		end
		if fullscreenToggle ~= nil then
			fullscreenToggle.Width = toggleWidth
		end

		local maxRowWidth = math.min(400, Screen.Width * 0.8)
		local sliderWidth = math.min(180, maxRowWidth * 0.4)
		local totalHeight = 0
		local totalWidth = 0
		local rowHeight
		local rowWidth

		for i, row in ipairs(rows) do
			if row.hidden == true then
				for _, element in ipairs(row) do
					element:hide()
				end
			else
				rowHeight = 0
				rowWidth = 0

				for j, element in ipairs(row) do
					element:show()
					if element.isSlider then
						element.Width = sliderWidth
					end
					element.object.Scale = 1.0
					rowHeight = math.max(rowHeight, element.Height)
					rowWidth = rowWidth + element.Width + (j > 1 and theme.padding or 0)
				end

				if rowWidth > maxRowWidth then
					local firstElement = row[1]
					if firstElement then
						local overflow = rowWidth - maxRowWidth
						local w = firstElement.Width
						firstElement.object.Scale = (w - overflow) / w
						rowWidth -= overflow
					end
				end

				totalHeight = totalHeight + rowHeight + (i > 1 and theme.padding or 0)
				totalWidth = math.max(totalWidth, rowWidth)

				row.height = rowHeight
				row.width = rowWidth
			end
		end

		totalWidth = totalWidth + theme.padding * 2
		totalHeight = totalHeight + theme.padding * 2

		local vCursor = totalHeight - theme.padding

		for _, row in ipairs(rows) do
			if not row.hidden then
				if row.align == "center" then
					local hCursor = totalWidth * 0.5 - row.width * 0.5
					for i, element in ipairs(row) do
						element.pos.Y = vCursor - row.height * 0.5 - element.Height * 0.5
						element.pos.X = hCursor
						hCursor = hCursor + element.Width + theme.padding
					end
				else
					local prevElement = nil
					for i, element in ipairs(row) do
						if i < 3 then
							if prevElement == nil then
								element.pos.X = theme.padding
							else
								element.pos.X = prevElement.pos.X + prevElement.Width + theme.padding
							end
						else 
							element.pos.X = totalWidth - element.Width - theme.padding
						end
						element.pos.Y = vCursor - row.height * 0.5 - element.Height * 0.5
						prevElement = element
					end
				end
				vCursor = vCursor - row.height - theme.padding
			end
		end

		return totalWidth, totalHeight
	end

	content.idealReducedContentSize = function(_, _, _)
		local w, h = refresh()
		return Number2(w, h)
	end

	return content
end

return settings
