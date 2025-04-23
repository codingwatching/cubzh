mod = {}

local TEXT_COLOR = Color(200, 200, 200)

mod.createModalContent = function(_, config)
	local time = require("time")
	local theme = require("uitheme").current
	local systemApi = require("system_api", System)
	local api = require("api")

	local defaultConfig = {
		world = {
			id = "",
			title = "…",
			description = "",
			thumbnail = nil,
			likes = nil,
			liked = nil,
		},
		mode = "explore", -- "explore" / "create"
		uikit = require("uikit"),
	}

	local ok, err = pcall(function()
		config = require("config"):merge(defaultConfig, config, {
			acceptTypes = {
				-- TODO: config module should allow checking deeper levels
				-- world = {
				-- 	thumbnail = { "Data" },
				-- 	likes = { "number" },
				-- 	liked = { "boolean" },
				-- },
			},
		})
	end)
	if not ok then
		error("worldDetails:createModalContent(config) - config error: " .. err, 2)
	end

	local ui = config.uikit

	local world = config.world

	local createMode = config.mode == "create"

	local worldDetails = ui:createNode()

	local requests = {}
	local likeRequest
	local refreshTimer
	local listeners = {}

	local privateFields = {}

	local cancelRequestsTimersAndListeners = function()
		for _, req in ipairs(requests) do
			req:Cancel()
		end
		requests = {}

		for _, listener in ipairs(listeners) do
			listener:Remove()
		end
		listeners = {}

		if refreshTimer ~= nil then
			refreshTimer:Cancel()
			refreshTimer = nil
		end
	end

	worldDetails.onRemove = function(_)
		cancelRequestsTimersAndListeners()
	end

	local content = require("modal"):createContent()

	content.title = ""
	content.icon = "🌎"
	content.node = worldDetails

	content.didBecomeActive = function()
		for _, listener in ipairs(listeners) do
			listener:Resume()
		end
	end

	content.willResignActive = function()
		for _, listener in ipairs(listeners) do
			listener:Pause()
		end
	end

	local btnLaunch
	local btnServers

	if not createMode then
		btnLaunch = ui:buttonPositive({ content = "Start", textSize = "big", padding = 10 })
		btnLaunch.onRelease = function()
			System:DebugEvent("User presses Start button to launch world", { ["world-id"] = world.id })
			URL:Open("https://app.cu.bzh?worldID=" .. world.id)
		end
		btnLaunch:setParent(worldDetails)

		-- TODO: only display servers button if multiplayer

		btnServers = ui:buttonNeutral({ content = "Servers", textSize = "default" })
		btnServers.onRelease = function()
			local config = { worldID = world.id, title = world.title, uikit = ui }
			local list = require("server_list"):create(config)
			content:push(list)
		end
		btnServers:setParent(worldDetails)
	end

	local cell = ui:frame() -- { color = Color(100, 100, 100) }
	cell.Height = 100
	cell:setParent(nil)

	local title
	local name
	local editNameBtn
	local by
	local authorBtn
	local author
	local likeBtn
	local editDescriptionBtn
	local editIconBtn
	local nameArea
	local description
	local views
	local creationDate
	local updateDate
	local serverSizeText
	local serverSizeSlider

	local iconRatio = 1 -- 16 / 9

	local iconArea = ui:frame({ color = Color(20, 20, 22) })
	iconArea:setParent(cell)

	if createMode then
		title = ui:createTextInput(config.world.title, "World Name")
	else
		title = ui:createText(config.world.title, { color = Color.White, size = "big", outline = 0.5 })
	end
	title:setParent(cell)
	
	local descriptionTitle = ui:createText("Description", { color = Color.White, size = "default"})
	descriptionTitle:setParent(cell)

	local badgesTitle = ui:createText("Badges", { color = Color.White, size = "default"})
	badgesTitle:setParent(cell)

	local badgesComingSoon = ui:createText("Coming soon", { color = TEXT_COLOR, size = "small"})
	badgesComingSoon:setParent(cell)
	
	if createMode then
		nameArea = ui:frame()
		nameArea:setParent(worldDetails)

		name = ui:createTextInput("", "World Name?")
		name:setParent(cell)
		name.pos = { 0, 0 }

		editNameBtn = ui:buttonSecondary({ content = "✏️" })
		editNameBtn:setParent(cell)

		local function focus()
			name:focus()
		end

		local function submit()
			local sanitized, err = api.checkWorldName(name.Text)
			if err == nil then
				local req = systemApi:patchWorld(world.id, { title = sanitized }, function(err, world)
					if err == nil then
						-- World update succeeded.
						-- Notify that the content has changed.
						if content.onContentUpdate then
							content.onContentUpdate(world)
						end
					end
				end)
				table.insert(requests, req)
			end

			editNameBtn.Text = "✏️"
			editNameBtn.onRelease = focus
		end

		editNameBtn.onRelease = focus

		name.onFocus = function(_)
			editNameBtn.Text = "✅"
			editNameBtn.onRelease = submit
		end

		name.onTextChange = function(self)
			local _, err = api.checkWorldName(self.Text)
			if err ~= nil then
				editNameBtn:disable()
			else
				editNameBtn:enable()
			end
		end

		editIconBtn = ui:buttonSecondary({ content = "✏️ Edit icon", textSize = "small" })
		editIconBtn:setParent(cell)
		editIconBtn.onRelease = function()
			File:OpenAndReadAll(function(success, data)
				if not success then
					print("could not read file")
					return
				end
	
				if data == nil then
					return
				end

				print("setting icon for world id:", world.id)
				systemApi:setWorldIcon(world.id, data, function(err)
					if err ~= nil then
						print("could not set world icon")
					end
					print("icon set!")
				end)
			end)
		end

		serverSizeText = ui:createText("Server Size: …", { color = Color.White, size = "small"})
		serverSizeText:setParent(cell)

		serverSizeSlider = ui:slider({
			min = 1,
			max = 32,
			defaultValue = 1,
			hapticFeedback = true,
			onValueChange = function(value)
				if world.maxPlayers ~= nil then
					world.maxPlayers = value
					serverSizeText.Text = "Server Size: " .. world.maxPlayers
				end
			end,
		})

		serverSizeSlider.onRelease = function()
			if world.maxPlayers ~= nil then
				local req = systemApi:patchWorld(world.id, { maxPlayers = world.maxPlayers }, function(_, _)
					-- not handling response yet
				end)
				table.insert(requests, req)
			end
		end
		
		serverSizeSlider:setParent(cell)
	end

	local secondaryTextColor = Color(150, 150, 150)

	creationDate = ui:createText("🌎 published … ago", secondaryTextColor, "small")
	creationDate:setParent(cell)

	updateDate = ui:createText("✨ updated … ago", secondaryTextColor, "small")
	updateDate:setParent(cell)

	by = ui:createText("🛠️ by ", secondaryTextColor, "small")
	by:setParent(cell)

	if createMode then
		local str = " @" .. Player.Username
		author = ui:createText(str, Color.Green, "small")
		author:setParent(cell)
	else
		authorBtn = ui:buttonLink({ content = "@…", textSize = "small" })
		authorBtn:setParent(cell)
	end

	views = ui:createText("👁 …", secondaryTextColor, "small")
	views:setParent(cell)

	description = ui:createText("description", { color = TEXT_COLOR, size = "small" })
	description:setParent(cell)

	likeBtn = ui:buttonNeutral({ content = "🤍 …", textSize = "small" })
	likeBtn:setParent(cell)

	if createMode then
		editDescriptionBtn = ui:buttonSecondary({ content = "✏️ Edit description", textSize = "small" })
		editDescriptionBtn:setParent(cell)
		editDescriptionBtn.onRelease = function()
			if System.MultilineInput ~= nil then
				if description.empty == true then
					description.Text = ""
				end
				System.MultilineInput(
					description.Text,
					"Description",
					"How would you describe that World?",
					"", -- regex
					10000, -- max chars
					function(text) -- done
						ui:turnOn()
						if text == "" then
							description.empty = true
							description.Text = "Worlds are easier to find with a description!"
							description.Color = theme.textColorSecondary
							local req = systemApi:patchWorld(world.id, { description = "" }, function(_, _)
								-- not handling response yet
							end)
							table.insert(requests, req)
						else
							description.empty = false
							description.Text = text
							description.Color = TEXT_COLOR
							local req = systemApi:patchWorld(world.id, { description = text }, function(_, _)
								-- not handling response yet
							end)
							table.insert(requests, req)
						end
					end,
					function() -- cancel
						ui:turnOn()
					end
				)
				ui:turnOff()
			end
		end
		-- else -- explore mode
	end

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
	scroll:setParent(worldDetails)

	-- refreshes UI with what's in local config.world / world
	privateFields.refreshWorld = function()
		if world.thumbnail ~= nil then
			iconArea:setImage(world.thumbnail)
		end

		if name ~= nil then
			name.Text = world.title or ""
		end

		if config.mode == "create" then
			if world.description == nil or world.description == "" then
				description.empty = true
				description.Text = "Worlds are easier to find with a description!"
				description.Color = theme.textColorSecondary
			else
				description.empty = false
				description.Text = world.description
				description.Color = TEXT_COLOR
			end

			if world.maxPlayers then
				serverSizeText.Text = "Server Size: " .. world.maxPlayers
				serverSizeSlider:setValue(world.maxPlayers)
			end
		else
			description.Text = world.description or ""
			description.Color = TEXT_COLOR
		end

		if likeBtn then
			likeBtn.Text = (world.liked == true and "❤️ " or "🤍 ")
				.. (world.likes and math.floor(world.likes) or 0)

			likeBtn.onRelease = function()
				world.liked = not world.liked

				if world.liked == true then
					world.likes = world.likes ~= nil and world.likes + 1 or 1
				else
					world.likes = world.likes ~= nil and world.likes - 1 or 0
				end

				if likeRequest then
					likeRequest:Cancel()
				end
				likeRequest = systemApi:likeWorld(world.id, world.liked, function(_)
					-- TODO: this request should return the refreshed number of likes
				end)
				table.insert(requests, likeRequest)

				local nbLikes = (world.likes and math.floor(world.likes) or 0)
				likeBtn.Text = (world.liked == true and "❤️ " or "🤍 ") .. nbLikes

				privateFields.alignViewsAndLikes()
			end
		end

		views.Text = "👁 " .. (world.views and math.floor(world.views) or 0)

		if world.created then
			local n, unitType = time.ago(world.created)
			if n == 1 then
				unitType = unitType:sub(1, #unitType - 1)
			end
			if math.floor(n) == n then
				creationDate.Text = string.format("🌎 published %d %s ago", math.floor(n), unitType)
			else
				creationDate.Text = string.format("🌎 published %.1f %s ago", n, unitType)
			end
		end

		if world.updated then
			local n, unitType = time.ago(world.updated)
			if n == 1 then
				unitType = unitType:sub(1, #unitType - 1)
			end
			if math.floor(n) == n then
				updateDate.Text = string.format("✨ updated %d %s ago", math.floor(n), unitType)
			else
				updateDate.Text = string.format("✨ updated %.1f %s ago", n, unitType)
			end
		end

		-- update author text/button
		if author then
			author.Text = " @" .. (world.authorName or "…")
		elseif authorBtn and world.authorName then
			authorBtn.Text = "@" .. world.authorName
			authorBtn.onRelease = function(_)
				local profileConfig = {
					username = world.authorName,
					userID = world.authorId,
					uikit = ui,
				}
				local profileContent = require("profile"):create(profileConfig)
				content:push(profileContent)
			end
		end

		content.title = ""

		-- update description text
		if description ~= nil then
			description.Text = world.description or ""
		end

		local modal = content:getModalIfContentIsActive()
		if modal ~= nil then
			modal:refreshContent()
		end

		worldDetails:refresh()
	end

	-- send request to gather world information
	privateFields.loadWorld = function()
		local req = api:getWorld(world.id, {
			"authorName",
			"authorId",
			"description",
			"liked",
			"likes",
			"views",
			"title",
			"created",
			"updated",
			"maxPlayers",
		}, function(worldInfo, err)
			if err ~= nil then
				-- TODO: handle error (retry button?)
				return
			end

			world.authorName = worldInfo.authorName
			world.authorId = worldInfo.authorId
			world.description = worldInfo.description
			world.title = worldInfo.title
			world.liked = worldInfo.liked
			world.likes = worldInfo.likes
			world.views = worldInfo.views
			world.created = worldInfo.created
			world.updated = worldInfo.updated
			world.maxPlayers = worldInfo.maxPlayers

			privateFields:refreshWorld()
		end)
		table.insert(requests, req)

		if world.thumbnail == nil then
			local req = api:getWorldThumbnail({ 
				worldID = world.id, 
				width = 250,
				callback = function(thumbnail, err)
					if err ~= nil then
						print("error getting world thumbnail:", err)
						return
					end
					world.thumbnail = thumbnail

					privateFields:refreshWorld()
				end
			})
			table.insert(requests, req)
		end
	end

	local w = 400
	local h = 400

	privateFields.scheduleRefresh = function()
		if refreshTimer ~= nil then
			return
		end
		refreshTimer = Timer(0.01, function()
			refreshTimer = nil
			worldDetails:refresh()
		end)
	end

	privateFields.alignViewsAndLikes = function()
		local parent = likeBtn.parent
		if parent == nil then
			return
		end
		local viewAndLikesWidth = views.Width + theme.padding + likeBtn.Width
		views.pos.X = parent.Width * 0.5 - viewAndLikesWidth * 0.5
		likeBtn.pos.X = views.pos.X + views.Width + theme.padding
	end

	worldDetails._width = function(_)
		return w
	end

	worldDetails._height = function(_)
		return h
	end

	worldDetails._setWidth = function(_, v)
		w = v
		privateFields:scheduleRefresh()
	end

	worldDetails._setHeight = function(_, v)
		h = v
		privateFields:scheduleRefresh()
	end

	worldDetails.refresh = function(self)
		if world.thumbnail ~= nil then
			iconArea:setImage(world.thumbnail)
		end

		local padding = theme.padding
		local width = self.Width - theme.padding * 2 -- remove scroll padding
		local iconSize = math.min(100, self.Width * 0.3)

		iconArea.Width = iconSize
		iconArea.Height = iconSize

		description.object.MaxWidth = width - padding * 2

		local viewAndLikesHeight = math.max(views.Height, likeBtn.Height)

		local author = author or authorBtn
		local singleLineHeight = math.max(by.Height, author.Height)

		local widthAsideIcon = width - iconSize - theme.paddingBig

		if createMode then
			title.Width = widthAsideIcon
		else
			title.object.MaxWidth = widthAsideIcon
		end

		by.object.Scale = 1 author.object.Scale = 1
		local w = by.Width + author.Width
		if w > widthAsideIcon then
			local scale = widthAsideIcon / w
			by.object.Scale = scale
			author.object.Scale = scale
		end
		local authorLineHeight = math.max(by.Height, author.Height)

		-- header contains the icon, the title and the author
		-- + edit icon button in create mode
		local headerHeight = title.Height + authorLineHeight + padding
		if editIconBtn then
			headerHeight = headerHeight + editIconBtn.Height + padding
		end
		headerHeight = math.max(headerHeight, iconArea.Height)

		local contentHeight = headerHeight
			+ padding
			+ viewAndLikesHeight -- views and likes
			+ padding
			+ descriptionTitle.Height
			+ padding
			+ description.Height
			+ theme.paddingBig
			+ badgesTitle.Height
			+ padding
			+ badgesComingSoon.Height
			+ theme.paddingBig
			+ singleLineHeight -- publication date
			+ padding
			+ singleLineHeight -- update date

		if name ~= nil then
			contentHeight = contentHeight + name.Height + padding
		end

		if serverSizeText then
			local h = math.max(serverSizeText.Height, serverSizeSlider.Height)
			contentHeight = contentHeight + h + padding
		end

		if editDescriptionBtn then
			contentHeight = contentHeight + editDescriptionBtn.Height + padding
		end

		cell.Height = contentHeight
		cell.Width = width

		local y = contentHeight - iconArea.Height

		-- icon
		iconArea.pos.X = 0
		iconArea.pos.Y = y

		-- title
		y = contentHeight - title.Height
		title.pos = { iconSize + theme.paddingBig, y }

		-- author
		y = y - padding
		by.pos = { iconSize + theme.paddingBig, y - authorLineHeight * 0.5 - by.Height * 0.5 }
		author.pos = { by.pos.X + by.Width, y - authorLineHeight * 0.5 - author.Height * 0.5 }
		y = y - authorLineHeight

		-- edit icon
		if editIconBtn then
			y = y - padding - editIconBtn.Height
			editIconBtn.pos = { iconSize + theme.paddingBig, y }
		end

		y = math.min(iconArea.pos.Y, y)

		-- view and likes
		y = y - padding - viewAndLikesHeight * 0.5
		views.pos.Y = y - views.Height * 0.5
		likeBtn.pos.Y = y - likeBtn.Height * 0.5
		privateFields.alignViewsAndLikes()
		y = y - viewAndLikesHeight * 0.5

		-- server size
		if serverSizeText then
			local h = math.max(serverSizeText.Height, serverSizeSlider.Height)
			y = y - h * 0.5 - padding
			serverSizeText.pos = { padding, y - serverSizeText.Height * 0.5 }
			serverSizeSlider.Width = math.min(width - serverSizeText.Width - theme.paddingBig, 200)
			serverSizeSlider.pos = { width - serverSizeSlider.Width - padding, y - serverSizeSlider.Height * 0.5 }
			y = y - h * 0.5
		end

		-- description
		y = y - padding - descriptionTitle.Height
		descriptionTitle.pos = { padding, y }
		y = y - padding - description.Height
		description.pos = { padding, y }

		if editDescriptionBtn ~= nil then
			y = y - padding - editDescriptionBtn.Height
			editDescriptionBtn.pos = { width * 0.5 - editDescriptionBtn.Width * 0.5, y }
		end

		-- badges
		y = y - theme.paddingBig - badgesTitle.Height
		badgesTitle.pos = { padding, y }
		y = y - padding - badgesComingSoon.Height
		badgesComingSoon.pos = { padding, y }

		-- info
		y = y - theme.paddingBig - singleLineHeight * 0.5
		creationDate.pos = { padding, y - creationDate.Height * 0.5 }
		y = y - singleLineHeight * 0.5

		y = y - padding - singleLineHeight * 0.5
		updateDate.pos = { padding, y - updateDate.Height * 0.5 }
		y = y - singleLineHeight * 0.5

		if name ~= nil then
			y = y - padding - name.Height
			name.pos = { padding, y }

			local h = name.Height
			name.Width = width - h - padding * 3

			editNameBtn.Height = h
			editNameBtn.Width = h
			editNameBtn.pos = { name.pos.X + name.Width + padding, y }
		end

		scroll.Width = self.Width

		if btnLaunch then
			scroll.Height = self.Height - btnLaunch.Height - padding * 2

			local bottomButtonsWidth = btnServers.Width + padding + btnLaunch.Width

			btnServers.pos = {
				width * 0.5 - bottomButtonsWidth * 0.5,
				padding + btnLaunch.Height * 0.5 - btnServers.Height * 0.5,
			}
			btnLaunch.pos = { btnServers.pos.X + btnServers.Width + padding, padding }
			scroll.pos.Y = btnLaunch.pos.Y + btnLaunch.Height + padding
		else
			scroll.Height = self.Height
			scroll.pos.Y = 0
		end

		scroll:flush()
		scroll:refresh()
	end

	privateFields:refreshWorld()
	privateFields:loadWorld()

	return content
end

return mod
