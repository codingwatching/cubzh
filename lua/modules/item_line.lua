--[[
	known categories: "null", "hair", "jacket", "pants", "boots"
]]
--

local itemLine = {}

-- MODULES
local api = require("api")
local theme = require("uitheme").current

-- CONSTANTS
local MIN_CELL_SIZE = 140
local MAX_COLUMNS = 7
local MIN_COLUMNS = 2
local MIN_GRID_SIZE = 50

itemLine.create = function(_, config)
	-- load config (overriding defaults)
	local _config = {
		-- search terms
		search = "",
		-- shows advanced filters button when true
		advancedFilters = false,
		-- used to filter categories when not nil
		categories = nil, -- {"null", "hair" ,"jacket", "pants", "boots"},
		-- line gets items by default, unless this is set to "worlds"
		type = "items",
		-- filter on particular repo
		repo = nil,
		-- mode
		minBlocks = 5,
		-- page
		page = 1,
		-- page
		nbPerPage = 10,
		-- filters for new or featured
		worldsFilter = nil,
		--
		uikit = require("uikit"),
	}

	-- config validation
	if config.repo ~= nil then
		if type(config.repo) ~= Type.string or #config.repo == 0 then
			error("item_line:create(config): config.repo must be a non-empty string, or nil", 2)
		end
	end

	if config ~= nil and type(config) == Type.table then
		if config.advancedFilters ~= nil then
			_config.advancedFilters = config.advancedFilters
		end
		if config.categories ~= nil then
			_config.categories = config.categories
		end
		if config.type ~= nil then
			_config.type = config.type
		end
		if config.repo ~= nil then
			_config.repo = config.repo
		end
		if config.page ~= nil then
			_config.page = config.page
		end
		if config.nbPerPage ~= nil then
			_config.nbPerPage = config.nbPerPage
		end
		if config.minBlocks ~= nil then
			_config.minBlocks = config.minBlocks
		end
		if config.worldsFilter ~= nil and type(config.worldsFilter) == Type.string then
			_config.worldsFilter = config.worldsFilter
		end
		if type(config.uikit) == type(_config.uikit) then
			_config.uikit = config.uikit
		end
	end
	config = _config

	local ui = config.uikit

	local removed = false

	local line = ui:createFrame() -- Color(255,0,0)

	local timers = {}
	local sentRequests = {}
	local function addSentRequest(req)
		table.insert(sentRequests, req)
	end
	local function cancelSentRequest()
		for _, r in pairs(sentRequests) do
			r:Cancel()
		end
		sentRequests = {}
	end

	local cellContentRequests = {}
	local function addCellContentRequest(req)
		table.insert(cellContentRequests, req)
	end
	local function cancelCellContentRequest()
		for _, r in pairs(cellContentRequests) do
			r:Cancel()
		end
		cellContentRequests = {}
	end

	local function addTimer(timer)
		table.insert(timers, timer)
	end

	local function cancelTimers()
		for _, t in pairs(timers) do
			t:Cancel()
		end
		timers = {}
	end

	local function cancelRequestsAndTimers()
		cancelSentRequest()
		cancelTimers()
	end

	-- exposed to the outside, can be called as an optimization
	-- when hiding the line without removing here for example.
	line.cancelRequestsAndTimers = function()
		cancelRequestsAndTimers()
	end

	line.setCategories = function(self, categories, type)
		if self.getItems == nil then
			return
		end
		if type ~= nil then
			config.type = type
		end
		config.categories = categories
		cancelRequestsAndTimers()
		self:getItems()
	end

	line.setWorldsFilter = function(self, filter)
		if self.getItems == nil then
			return
		end
		if filter == nil or type(filter) ~= Type.string then
			error("item_line:setWorldsFilter(filter): filter should be a string", 2)
		end

		config.worldsFilter = filter
		cancelRequestsAndTimers()
		self:getItems()
	end

	line.cellSize = nil
	line.nbCells = 1 -- cells per page
	line.entries = {}

	line.onRemove = function(_)
		cancelRequestsAndTimers()
		line.tickListener:Remove()
		line.tickListener = nil
		removed = true
	end

	line._createCell = function(line, size)
		local idleColor = theme.lineCellColor
		local cell = ui:createFrame(idleColor)
		cell:setParent(line)

		cell.onPress = function()
			-- don't update the color if there's a thumbnail
			if cell.thumbnail ~= nil then
				return
			end
			cell.Color = theme.lineCellColorPressed
		end

		cell.onRelease = function()
			if cell.loaded then
				if line.onOpen then
					line:onOpen(cell)
				end
			end
			if cell.thumbnail ~= nil then
				return
			end
			cell.Color = idleColor
		end

		cell.onCancel = function()
			if cell.thumbnail ~= nil then
				return
			end
			cell.Color = idleColor
		end

		local likesAndViewsFrame = ui:createFrame(theme.lineCellFrameColor)
		likesAndViewsFrame:setParent(cell)
		likesAndViewsFrame.pos.X = 0

		local nbLikes = ui:createText("", Color.White, "small")
		nbLikes:setParent(likesAndViewsFrame)
		nbLikes.pos = { theme.padding, theme.padding }

		cell.layoutLikes = function(self)
			if nbLikes:isVisible() == false then
				return
			end
			likesAndViewsFrame.Width = nbLikes.Width + theme.padding * 2
			likesAndViewsFrame.Height = nbLikes.Height + theme.padding * 2
			likesAndViewsFrame.pos.Y = self.Height - likesAndViewsFrame.Height
		end

		cell.setNbLikes = function(self, n)
			if n > 0 then
				nbLikes.Text = "❤️ " .. math.floor(n)
				nbLikes:show()
				likesAndViewsFrame:show()
				self:layoutLikes()
			else
				nbLikes:hide()
				likesAndViewsFrame:hide()
			end
		end

		cell.hideLikes = function(_)
			likesAndViewsFrame:hide()
			nbLikes:hide()
		end

		local textFrame = ui:createFrame(theme.lineCellFrameColor)
		textFrame:setParent(cell)
		textFrame.LocalPosition.Z = config.uikit.kForegroundDepth

		local tName = ui:createText("", Color.White, "small")
		tName:setParent(textFrame)

		tName.pos = { theme.padding, theme.padding }

		cell.tName = tName

		local loadingCube -- = ui:createFrame(Color.White)

		cell.getOrCreateLoadingCube = function(_)
			if loadingCube == nil then
				loadingCube = ui:createFrame(Color.White)
				loadingCube:setParent(cell)
				loadingCube.Width = 10
				loadingCube.Height = 10
			end
			loadingCube.pos = { cell.Width * 0.5, cell.Height * 0.5, 0 }
			return loadingCube
		end

		cell.getLoadingCube = function(_)
			return loadingCube
		end

		cell.layoutContent = function(self)
			textFrame.Width = cell.Width
			textFrame.Height = tName.Height + theme.padding * 2
			self:layoutLikes()
		end

		cell.setSize = function(self, size)
			self.Width = size
			self.Height = size
			self:layoutContent()
		end

		cell:setSize(size)

		return cell
	end

	line._generateCells = function(self)
		local padding = theme.padding
		local sizeWithPadding = self.cellSize + padding
		if self.cells == nil then
			self.cells = {}
		end
		local cells = self.cells
		local cell

		-- self.nbCells == number of displayed cells
		for i = 1, self.nbCells do
			cell = cells[i]
			if cell == nil then
				cell = self:_createCell(self.cellSize)
				table.insert(cells, cell)
			end
			cell:show()

			local column = (i - 1) % self.columns
			local x = column * sizeWithPadding
			cell.LocalPosition = Number3(x, 0, 0)
		end

		for i = self.nbCells + 1, #cells do
			cells[i]:hide()
		end
	end

	line._setEntry = function(line, cell, entry)
		cell.loaded = false
		cell.type = entry.type

		if cell.type == "item" then
			cell.id = entry.id
			cell.repo = entry.repo
			cell.name = entry.name
			cell.category = entry.category
			cell.description = entry.description
			cell.created = entry.created
			cell.updated = entry.updated
			cell.likes = entry.likes

			local itemName = cell.repo .. "." .. cell.name
			cell.loadedItemName = itemName
			cell.itemFullName = itemName

			if not cell.tName then
				return
			end
			cell:getOrCreateLoadingCube():show()

			cell:setNbLikes(cell.likes)
			cell:setSize(line.cellSize)

			local function transform_string(str)
				local new_str = string.gsub(str, "_%a", string.upper)
				new_str = string.gsub(new_str, "_", " ")
				new_str = string.gsub(new_str, "^%l", string.upper)
				return new_str
			end

			if cell.tName then
				cell.tName.object.MaxWidth = (line.cellSize or MIN_CELL_SIZE) - 2 * theme.padding
				local betterName = transform_string(cell.name)
				cell.tName.Text = betterName
				cell:layoutContent()
			end

			local req = Object:Load(itemName, function(obj)
				if removed then
					return
				end

				if not cell.tName then
					return
				end
				if cell.loadedItemName == nil or cell.loadedItemName ~= itemName then
					return
				end

				if obj == nil then
					-- silent error, no print, just removing loading animation
					local loadingCube = cell:getLoadingCube()
					if loadingCube then
						loadingCube:hide()
					end
					return
				end
				if cell.item then
					cell.item:remove()
					cell.item = nil
				end

				local loadingCube = cell:getLoadingCube()
				if loadingCube then
					loadingCube:hide()
				end

				local item = ui:createShape(obj, { spherized = true })
				cell.item = item
				item:setParent(cell)

				item.pivot.LocalRotation = { -0.1, 0, -0.2 }

				-- setting Width sets Height & Depth as well when spherized
				item.Width = line.cellSize or MIN_CELL_SIZE
				cell.loaded = true
			end)

			addSentRequest(req)
			addCellContentRequest(req)
		elseif cell.type == "world" then
			local loadingCube = cell:getLoadingCube()
			if loadingCube then
				loadingCube:hide()
			end

			-- if entry.thumbnail == nil and cell.item == nil then
			-- 	-- no thumbnail, display default world icon
			-- 	local shape = System.ShapeFromBundle("official.world_icon")
			-- 	local item = ui:createShape(shape, { spherized = true })
			-- 	cell.item = item
			-- 	item:setParent(cell)
			-- 	item.pivot.LocalRotation = { -0.1, 0, -0.2 }
			-- 	-- setting Width sets Height & Depth as well when spherized
			-- 	item.Width = line.cellSize
			-- end

			cell.title = entry.title
			cell.description = entry.description
			cell.thumbnail = entry.thumbnail

			cell.likes = entry.likes
			cell.views = entry.views

			cell.id = entry.id

			cell.created = entry.created
			cell.updated = entry.updated

			if cell.tName then
				cell.tName.object.MaxWidth = line.cellSize - 2 * theme.padding
				cell.tName.Text = cell.title
			end

			cell:setNbLikes(cell.likes)
			cell:setSize(line.cellSize)

			cell:layoutContent()

			cell.loaded = true
		end
	end

	-- update the content of the cells based on line.entries
	line._updateCells = function(self)
		cancelTimers()
		cancelCellContentRequest()

		self:_emptyCells()
		local cells = self.cells
		local nbCells = self.nbCells
		local req

		for i = 1, nbCells do
			local cell = cells[i]
			local entry = self.entries[i]
			cell.IsHidden = entry == nil
			if entry ~= nil then
				local timer = Timer((i - 1) * 0.02, function()
					if self._setEntry then
						self:_setEntry(cell, entry)
					end

					if config.type == "worlds" then
						if entry.id ~= nil then
							req = api:getWorldThumbnail(entry.id, function(err, img)
								if err == nil and cell.setImage ~= nil then
									entry.thumbnail = img

									if cell.item ~= nil then
										cell.item:remove()
										cell.item = nil
									end

									cell.thumbnail = img
									cell:setImage(img)

									if type(entry.onThumbnailUpdate) == "function" then
										entry.onThumbnailUpdate(img)
									end
								end
							end)
							addSentRequest(req)
							addCellContentRequest(req)
						end
					end
				end)
				addTimer(timer)
			end
		end

		collectgarbage("collect")
	end

	-- remove items in cells, keep cells
	line._emptyCells = function(line)
		local cells = line.cells
		if cells ~= nil then
			for _, c in ipairs(cells) do
				c:hideLikes()
				c.tName.Text = ""
				c:setImage(nil)
				if c.item ~= nil and c.item.remove then
					c.item:remove()
				end
				c.item = nil
			end
		end
	end

	line.computeNbCells = function(self)
		local widthPlusMargin = self.Width + theme.padding * 2
		local columns = math.floor(widthPlusMargin / MIN_CELL_SIZE)
		columns = math.max(MIN_COLUMNS, math.min(MAX_COLUMNS, columns))
		return columns
	end

	line.refresh = function(self)
		if removed then
			return
		end
		cancelCellContentRequest()

		if self ~= line then
			error("item_line:refresh(): use `:`", 2)
		end

		if self.Width < MIN_GRID_SIZE or self.Height < MIN_GRID_SIZE then
			return
		end

		local padding = theme.padding

		if
			self.cellSize == nil
			or (self.savedSize and (self.savedSize.width ~= self.Width or self.savedSize.height ~= self.Height))
		then
			local widthPlusMargin = self.Width + padding * 2

			local columns = math.floor(widthPlusMargin / MIN_CELL_SIZE)
			columns = math.max(MIN_COLUMNS, math.min(MAX_COLUMNS, columns))

			self.columns = columns
			self.cellSize = math.floor(widthPlusMargin / columns) - padding

			self.nbCells = self.columns
			-- reduce size
			self.Width = self.columns * (self.cellSize + padding) - padding

			local totalHeight = self.cellSize

			self.Height = totalHeight

			self.savedSize = {
				width = self.Width,
				height = self.Height,
			}
		end

		if self:isVisible() then
			self:_generateCells() -- generated missing cells if needed
			self:_updateCells()
		end
	end

	line.getItems = function(self)
		cancelRequestsAndTimers()

		-- empty list
		if self.setLineEntries ~= nil then
			self:setLineEntries({})
		end

		if config.type == "items" then
			local req = api:getItems({
				minBlock = config.minBlocks,
				repo = config.repo,
				category = config.categories,
				page = config.page,
				perpage = config.nbPerPage,
				search = config.search,
			}, function(err, items)
				if err then
					print("Error: " .. err)
					return
				end
				for _, itm in ipairs(items) do
					itm.type = "item"
				end
				if self.setLineEntries ~= nil and config.type == "items" then
					self:setLineEntries(items)
				end
			end)
			addSentRequest(req)
		elseif config.type == "worlds" then
			local apiCallback = function(err, worlds)
				if err then
					print("Error: " .. err)
					return
				end
				for _, w in ipairs(worlds) do
					w.type = "world"
				end
				if self.setLineEntries ~= nil and config.type == "worlds" then
					self:setLineEntries(worlds)
				end
			end

			-- world filter (nil, featured, recent)
			local worldsFilter = config.worldsFilter
			-- used to filter on the author's name, for "my creations"
			local repoFilter = config.repo

			-- unpublished worlds (world drafts)
			if repoFilter ~= nil then
				local categories = config.categories
				local reqConfig = {
					repo = config.repo,
					category = categories,
					page = config.page,
					perpage = config.nbPerPage,
					search = config.search,
				}
				local req = api:getWorlds(reqConfig, apiCallback)
				addSentRequest(req)
			else -- published worlds
				local req = api:getPublishedWorlds({ list = worldsFilter }, apiCallback)
				addSentRequest(req)
			end
		end
	end

	line.setLineEntries = function(self, entries)
		if self ~= line then
			error("item_line:setLineEntries(entries): use `:`", 2)
		end

		self.entries = entries or {}
		self:refresh()
	end

	line.dt = 0.0
	line.dt4 = 0.0
	line.tickListener = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
		if line.dt == nil then
			return
		end
		line.dt = line.dt + dt
		line.dt4 = line.dt4 + dt * 4
		local cells = line.cells
		if cells ~= nil then
			local loadingCube
			local loadingCubePos
			for _, c in ipairs(cells) do
				loadingCube = c:getLoadingCube()
				if loadingCube ~= nil and loadingCube:isVisible() then
					if loadingCubePos == nil then
						loadingCubePos =
							{ c.Width * 0.5 + math.cos(line.dt4) * 20, c.Height * 0.5 - math.sin(line.dt4) * 20, 0 }
					end
					loadingCube.pos = loadingCubePos
				end
				if c.item ~= nil and c.item.pivot ~= nil then
					c.item.pivot.LocalRotation = { -0.1, line.dt, -0.2 }
				end
			end
		end
	end)

	line:getItems()
	return line
end

return itemLine