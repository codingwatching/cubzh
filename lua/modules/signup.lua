local signup = {}

signup.startFlow = function(self, config)
	local sfx = require("sfx")
	local passkey = require("passkey")

	if self ~= signup then
		error("signup:startFlow(config) should be called with `:`", 2)
	end

	local conf = require("config")

	local defaultConfig = {
		ui = require("uikit"),
		onCancel = function() end,
		checkAppVersionAndCredentialsStep = function() end,
		signUpOrLoginStep = function() end,
		avatarPreviewStep = function() end,
		avatarEditorStep = function() end,
		loginStep = function() end,
		loginSuccess = function() end,
		dobStep = function() end,
		usernameStep = function() end,
		-- phoneNumberStep = function() end,
		-- verifyPhoneNumberStep = function() end,
		pushNotificationsStep = function() end,
	}

	local ok, err = pcall(function()
		config = conf:merge(defaultConfig, config)
	end)
	if not ok then
		error("signup:startFlow(config) - config error: " .. err, 2)
	end

	local flowConfig = config

	local api = require("system_api", System)
	local ui = config.ui
	local flow = require("flow")
	local drawerModule = require("drawer")
	local ease = require("ease")
	local loc = require("localize")
	local str = require("str")

	local theme = require("uitheme").current
	local padding = theme.padding

	local signupFlow = flow:create()

	local animationTime = 0.3

	-- local backFrame
	local backButton
	local coinsButton
	local drawer
	local loginBtn
	local titleLogo

	local cache = {
		dob = {
			month = nil,
			day = nil,
			year = nil,
			monthIndex = nil,
			dayIndex = nil,
			yearIndex = nil,
		},
		phoneNumber = nil,
		nbAvatarPartsChanged = 0,
	}

	local callLoginSuccess = function()
		System:DebugEvent("User logs in")
		flowConfig.loginSuccess()
	end

	local function removeCoinsButton()
		if coinsButton ~= nil then
			coinsButton:remove()
			coinsButton = nil
		end
	end

	local function showBackButton()
		if backButton == nil then
			local icon = ui:frame({
				image = {
					data = Data:FromBundle("images/icon-back.png"),
					alpha = true,
				},
			})
			local textRef = ui:createText("X")
			local size = math.max(textRef.Width, textRef.Height)
			textRef:remove()
			icon.Width = size
			icon.Height = size
			backButton = ui:buttonNegative({
				content = icon,
				textSize = "default",
				padding = theme.padding,
			})
			backButton.parentDidResize = function(self)
				ease:cancel(self)
				self.pos = {
					padding,
					Screen.Height - Screen.SafeArea.Top - self.Height - padding,
				}
			end
			backButton.onRelease = function(_)
				System:DebugEvent("User presses BACK button")
				signupFlow:back()
			end
			backButton.pos = { -backButton.Width, Screen.Height - Screen.SafeArea.Top - backButton.Height - padding }
			ease:outSine(backButton, animationTime).pos =
				Number3(padding, Screen.Height - Screen.SafeArea.Top - backButton.Height - padding, 0)
		end
	end

	local function removeBackButton()
		if backButton ~= nil then
			backButton:remove()
			backButton = nil
		end
	end

	local steps = {}

	steps.createMagicKeyInputStep = function(config)
		local defaultConfig = {
			usernameOrEmail = "",
		}
		config = conf:merge(defaultConfig, config)

		local requests = {}
		local frame
		local step = flow:createStep({
			onEnter = function()
				frame = ui:frameGenericContainer()

				local title = ui:createText(str:upperFirstChar(loc("magic key", "title")) .. " 🔑", Color.White)
				title:setParent(frame)

				local loadingLabel = ui:createText(str:upperFirstChar(loc("loading...")), Color.White)
				loadingLabel:setParent(frame)
				loadingLabel:hide()

				local magicKeyLabel = ui:createText("✉️ What code did you get?", Color.White, "default")
				magicKeyLabel:setParent(frame)

				local magicKeyInput = ui:createTextInput("", str:upperFirstChar(loc("000000")), {
					textSize = "default",
					keyboardType = "oneTimeDigicode",
				})

				magicKeyInput:setParent(frame)

				local magicKeyButton = ui:buttonNeutral({ content = "✅" })
				magicKeyButton:setParent(frame)

				local resendCodeButton = ui:buttonNeutral({
					content = "Send me a new code",
					textSize = "small",
				})
				resendCodeButton:setParent(frame)

				local function showLoading()
					loadingLabel:show()
					magicKeyLabel:hide()
					magicKeyInput:hide()
					magicKeyButton:hide()
					resendCodeButton:hide()
				end

				local function hideLoading()
					loadingLabel:hide()
					magicKeyLabel:show()
					magicKeyInput:show()
					magicKeyButton:show()
					resendCodeButton:show()
				end

				magicKeyButton.onRelease = function()
					showLoading()
					if magicKeyInput.Text ~= "" then
						local req = api:login(
							{ usernameOrEmail = config.usernameOrEmail, magickey = magicKeyInput.Text },
							function(err, accountInfo)
								if err == nil then
									local userID = accountInfo.credentials["user-id"]
									local token = accountInfo.credentials.token

									System.AskedForMagicKey = false
									System:StoreCredentials(userID, token)

									-- flush signup flow and restart credential checks (should go through now)
									signupFlow:flush()
									signupFlow:push(
										steps.createCheckAppVersionAndCredentialsStep({ onlyCheckUserInfo = true })
									)
								else
									magicKeyLabel.Text = "❌ " .. err
									hideLoading()
								end
							end
						)
						table.insert(requests, req)
					else
						-- text input is empty
						magicKeyLabel.Text = "❌ Please enter a magic key"
						hideLoading()
					end
				end

				resendCodeButton.onRelease = function(_)
					-- ask the API server to send a new magic key to the user (via email or SMS)
					showLoading()
					local req = api:getMagicKey(config.usernameOrEmail, function(err, _)
						hideLoading()
						if err ~= nil then
							magicKeyLabel.Text = "❌ Sorry, failed to send magic key"
						end
					end)
					table.insert(requests, req)
				end

				frame.parentDidResize = function(self)
					self.Width = math.min(
						400,
						Screen.Width - Screen.SafeArea.Right - Screen.SafeArea.Left - theme.paddingBig * 2
					)
					self.Height = title.Height
						+ theme.padding
						+ magicKeyLabel.Height
						+ theme.paddingTiny
						+ magicKeyInput.Height
						+ theme.padding
						+ resendCodeButton.Height
						+ theme.paddingBig * 2

					title.pos = {
						self.Width * 0.5 - title.Width * 0.5,
						self.Height - theme.paddingBig - title.Height,
					}

					magicKeyButton.Height = magicKeyInput.Height

					magicKeyLabel.pos.X = theme.paddingBig
					magicKeyLabel.pos.Y = title.pos.Y - theme.padding - magicKeyLabel.Height

					magicKeyInput.Width = self.Width - theme.paddingBig * 2 - magicKeyButton.Width - theme.paddingTiny
					magicKeyInput.pos.X = theme.paddingBig
					magicKeyInput.pos.Y = magicKeyLabel.pos.Y - theme.paddingTiny - magicKeyInput.Height

					magicKeyButton.pos.X = magicKeyInput.pos.X + magicKeyInput.Width + theme.paddingTiny
					magicKeyButton.pos.Y = magicKeyInput.pos.Y

					resendCodeButton.pos.X = self.Width * 0.5 - resendCodeButton.Width * 0.5
					resendCodeButton.pos.Y = magicKeyInput.pos.Y - theme.padding - resendCodeButton.Height

					loadingLabel.pos = {
						self.Width * 0.5 - loadingLabel.Width * 0.5,
						self.Height * 0.5 - loadingLabel.Height * 0.5,
					}
					self.pos = { Screen.Width * 0.5 - self.Width * 0.5, Screen.Height * 0.5 - self.Height * 0.5 }
				end

				frame:parentDidResize()
				targetPos = frame.pos:Copy()
				frame.pos.Y = frame.pos.Y - 50
				ease:outBack(frame, animationTime).pos = targetPos
				-- autofocus text input
				Timer(0.2, function()
					magicKeyInput:focus()
				end)
			end,
			onExit = function()
				for _, req in ipairs(requests) do
					req:Cancel()
				end
				frame:remove()
				frame = nil
			end,
			onRemove = function() end,
		})
		return step
	end

	-- Step shown when user has clicked on "login" button on the splash screen
	steps.createLoginOptionsStep = function(config)
		local defaultConfig = {
			username = "",
			password = false,
			magickey = false,
		}
		config = conf:merge(defaultConfig, config)

		local requests = {}
		local frame
		local step = flow:createStep({
			onEnter = function()
				frame = ui:frameGenericContainer()

				local title = ui:createText(str:upperFirstChar(loc("authentication", "title")) .. " 🔑", Color.White)
				title:setParent(frame)

				local errorLabel = ui:createText("", Color.Red)
				errorLabel:setParent(frame)
				errorLabel:hide()

				local loadingLabel = ui:createText(str:upperFirstChar(loc("loading...")), Color.White)
				loadingLabel:setParent(frame)
				loadingLabel:hide()

				local passwordLabel
				local passwordInput
				local passwordButton
				local magicKeyLabel
				local magicKeyButton

				local function showLoading()
					loadingLabel:show()
					if config.password then
						passwordLabel:hide()
						passwordInput:hide()
						passwordButton:hide()
					end
					if config.magickey then
						magicKeyLabel:hide()
						magicKeyButton:hide()
					end
				end

				local function hideLoading()
					loadingLabel:hide()
					if config.password then
						passwordLabel:show()
						passwordInput:show()
						passwordButton:show()
					end
					if config.magickey then
						magicKeyLabel:show()
						magicKeyButton:show()
					end
				end

				if config.password then
					passwordLabel = ui:createText("🔑 " .. str:upperFirstChar(loc("password")), Color.White, "small")
					passwordLabel:setParent(frame)

					passwordInput = ui:createTextInput(
						"",
						str:upperFirstChar(loc("password")),
						{ textSize = "default", password = true }
					)
					passwordInput:setParent(frame)

					passwordButton = ui:buttonNeutral({ content = "✅" })
					passwordButton:setParent(frame)
					passwordButton.onRelease = function()
						showLoading()
						if passwordInput.Text ~= "" then
							local req = api:login(
								{ usernameOrEmail = config.username, password = passwordInput.Text },
								function(err, accountInfo)
									if err == nil then
										local userID = accountInfo.credentials["user-id"]
										local token = accountInfo.credentials.token

										System.AskedForMagicKey = false
										System:StoreCredentials(userID, token)

										-- flush signup flow and restart credential checks (should go through now)
										signupFlow:flush()
										signupFlow:push(
											steps.createCheckAppVersionAndCredentialsStep({ onlyCheckUserInfo = true })
										)
									else
										errorLabel.Text = "❌ " .. err
										hideLoading()
									end
								end
							)
							table.insert(requests, req)
						else
							-- text input is empty
							errorLabel.Text = "❌ Please enter a password"
							hideLoading()
						end
					end
				end

				if config.magickey then
					magicKeyLabel =
						ui:createText(config.password and "or, send me a:" or "send me a:", Color.White, "default")
					magicKeyLabel:setParent(frame)

					magicKeyButton = ui:buttonPositive({
						content = str:upperFirstChar(loc("✨ magic key ✨")),
						padding = theme.padding,
					})
					magicKeyButton:setParent(frame)

					magicKeyButton.onRelease = function()
						showLoading()
						local req = api:getMagicKey(config.username, function(err, _)
							hideLoading()
							if err == nil then
								System.AskedForMagicKey = true
								local step = steps.createMagicKeyInputStep({ usernameOrEmail = config.username })
								signupFlow:push(step)
							else
								errorLabel.Text = "❌ Sorry, failed to send magic key"
							end
						end)
						table.insert(requests, req)
					end
				end

				frame.parentDidResize = function(self)
					self.Width = math.min(
						400,
						Screen.Width - Screen.SafeArea.Right - Screen.SafeArea.Left - theme.paddingBig * 2
					)
					self.Height = title.Height + theme.paddingBig * 2

					if config.password then
						self.Height = self.Height + passwordLabel.Height + theme.paddingTiny + passwordInput.Height
					end
					if config.magickey then
						self.Height = self.Height + magicKeyLabel.Height + theme.paddingTiny + magicKeyButton.Height
					end
					if config.password and config.magickey then
						self.Height = self.Height + theme.padding
					end

					title.pos = {
						self.Width * 0.5 - title.Width * 0.5,
						self.Height - theme.paddingBig - title.Height,
					}

					local y = title.pos.Y

					if config.password then
						passwordButton.Height = passwordInput.Height

						passwordLabel.pos.Y = y - passwordLabel.Height
						passwordLabel.pos.X = theme.paddingBig

						passwordInput.Width = self.Width
							- passwordButton.Width
							- theme.paddingTiny
							- theme.paddingBig * 2

						passwordInput.pos.X = theme.paddingBig
						passwordInput.pos.Y = passwordLabel.pos.Y - theme.paddingTiny - passwordInput.Height

						passwordButton.pos.X = passwordInput.pos.X + passwordInput.Width + theme.paddingTiny
						passwordButton.pos.Y = passwordInput.pos.Y

						y = passwordButton.pos.Y - theme.paddingTiny
					end

					if config.magickey then
						magicKeyLabel.pos.X = self.Width * 0.5 - magicKeyLabel.Width * 0.5
						magicKeyLabel.pos.Y = y - magicKeyLabel.Height

						magicKeyButton.Width = self.Width - theme.paddingBig * 2
						magicKeyButton.pos.X = theme.paddingBig
						magicKeyButton.pos.Y = magicKeyLabel.pos.Y - theme.paddingTiny - magicKeyButton.Height
					end

					loadingLabel.pos = {
						self.Width * 0.5 - loadingLabel.Width * 0.5,
						self.Height * 0.5 - loadingLabel.Height * 0.5,
					}
					self.pos = { Screen.Width * 0.5 - self.Width * 0.5, Screen.Height * 0.5 - self.Height * 0.5 }
				end
				frame:parentDidResize()
				targetPos = frame.pos:Copy()
				frame.pos.Y = frame.pos.Y - 50
				ease:outBack(frame, animationTime).pos = targetPos
			end,
			onExit = function()
				for _, req in ipairs(requests) do
					req:Cancel()
				end
				frame:remove()
				frame = nil
			end,
			onRemove = function() end,
		})

		return step
	end

	steps.createLoginStep = function()
		local requests = {}
		local frame

		local step = flow:createStep({
			onEnter = function()
				config.loginStep()

				-- BACK BUTTON
				showBackButton()

				frame = ui:frameGenericContainer()

				local title = ui:createText(loc("Who are you? 🙂"), Color.White)
				title:setParent(frame)

				local errorLabel = ui:createText("", Color.Red)
				errorLabel:setParent(frame)
				errorLabel:hide()

				local loadingLabel = ui:createText(str:upperFirstChar(loc("loading...")), Color.White)
				loadingLabel:setParent(frame)
				loadingLabel:hide()

				local usernameInput = ui:createTextInput("", loc("Username or email"))
				usernameInput:setParent(frame)

				local didStartTyping = false
				usernameInput.onTextChange = function(self)
					local backup = self.onTextChange
					self.onTextChange = nil

					local s = str:normalize(self.Text)
					s = str:lower(s)

					self.Text = s
					self.onTextChange = backup

					if not didStartTyping and self.Text ~= "" then
						didStartTyping = true
						System:DebugEvent("User starts editing username")
					end
				end

				local loginButton = ui:buttonPositive({
					content = "✨ " .. str:upperFirstChar(loc("login", "button")) .. " ✨",
					padding = 10,
				})
				loginButton:setParent(frame)

				frame.parentDidResize = function(self)
					self.Height = title.Height
						+ usernameInput.Height
						+ loginButton.Height
						+ theme.padding * 2
						+ theme.paddingBig * 2

					if errorLabel.Text ~= "" then
						self.Height = self.Height + errorLabel.Height + theme.padding
					end

					self.Width = math.min(
						400,
						Screen.Width - Screen.SafeArea.Right - Screen.SafeArea.Left - theme.paddingBig * 2
					)

					title.pos = {
						self.Width * 0.5 - title.Width * 0.5,
						self.Height - theme.paddingBig - title.Height,
					}

					local y = title.pos.Y
					if errorLabel.Text ~= "" then
						errorLabel:show()
						errorLabel.pos = {
							self.Width * 0.5 - errorLabel.Width * 0.5,
							y - theme.padding - errorLabel.Height,
						}
						y = errorLabel.pos.Y
					else
						errorLabel:hide()
					end

					usernameInput.Width = self.Width - theme.paddingBig * 2
					usernameInput.pos = {
						theme.paddingBig,
						y - theme.padding - usernameInput.Height,
					}

					loginButton.Width = self.Width - theme.paddingBig * 2
					loginButton.pos = { theme.paddingBig, theme.paddingBig }

					loadingLabel.pos = {
						self.Width * 0.5 - loadingLabel.Width * 0.5,
						self.Height * 0.5 - loadingLabel.Height * 0.5,
					}

					self.pos = { Screen.Width * 0.5 - self.Width * 0.5, Screen.Height * 0.5 - self.Height * 0.5 }
				end
				frame:parentDidResize()
				targetPos = frame.pos:Copy()
				frame.pos.Y = frame.pos.Y - 50
				ease:outBack(frame, animationTime).pos = targetPos

				local function showLoading()
					loadingLabel:show()
					usernameInput:hide()
					loginButton:hide()
				end

				local function hideLoading()
					loadingLabel:hide()
					usernameInput:show()
					loginButton:show()
					frame:parentDidResize()
				end

				loginButton.onRelease = function()
					-- save in case user comes back with magic key after closing app
					System.SavedUsernameOrEmail = usernameInput.Text

					-- if user asked for magic key in the past, this is the best time to forget about it.
					-- if System.AskedForMagicKey == false then
					-- 	print("[STATEMENT NOT NEEDED] System.AskedForMagicKey = false")
					-- end
					System.AskedForMagicKey = false

					errorLabel.Text = ""
					showLoading()

					local req = api:getLoginOptions(usernameInput.Text, function(err, loginOptions)
						if err ~= nil then
							errorLabel.Text = "❌ " .. err
							hideLoading()
							return
						end

						-- NOTE: res.username is sanitized
						signupFlow:push(steps.createLoginOptionsStep({
							username = loginOptions.username,
							password = loginOptions.password,
							magickey = loginOptions.magickey,
						}))
					end)
					table.insert(requests, req)
				end

				-- If passkey is available on the device,
				-- start the passkey login process without any user interaction
				if System.PasskeySupported then
					System:PasskeyLogin(
						function(
							credentialIDBase64,
							authenticatorDataBase64,
							rawClientDataJSONString,
							signatureBase64,
							userIDString,
							err
						)
							if err ~= nil and err ~= "" then
								-- native Passkey login flow error
								-- do nothing?
								return
							end

							-- Try to login using the passkey
							local req = api:login({
								passkeyCredentialIDBase64 = credentialIDBase64,
								passkeyAuthenticatorDataBase64 = authenticatorDataBase64,
								passkeyRawClientDataJSONString = rawClientDataJSONString,
								passkeySignatureBase64 = signatureBase64,
								passkeyUserIDString = userIDString,
							}, function(err, accountInfo)
								if err ~= nil then
									-- login to Blip account failed
									-- do nothing?
									return
								end

								local userID = accountInfo.credentials["user-id"]
								local token = accountInfo.credentials.token

								System.AskedForMagicKey = false
								System:StoreCredentials(userID, token)

								-- flush signup flow and restart credential checks (should go through now)
								signupFlow:flush()
								signupFlow:push(
									steps.createCheckAppVersionAndCredentialsStep({ onlyCheckUserInfo = true })
								)
							end)
							table.insert(requests, req)
						end
					)
				end
			end, -- onEnter
			onExit = function()
				for _, req in ipairs(requests) do
					req:Cancel()
				end
				frame:remove()
				frame = nil
			end,
			onRemove = function()
				removeBackButton()
			end,
		})
		return step
	end

	steps.createPushNotificationsStep = function()
		local appDidBecomeActiveListener
		-- local skipOnFirstEnter = System.HasUnverifiedPhoneNumber
		local step = flow:createStep({
			onEnter = function()
				System:DebugEvent("App shows signup notification step")
				config.pushNotificationsStep()
				showBackButton()

				-- DRAWER
				if drawer ~= nil then
					drawer:clear()
				else
					drawer = drawerModule:create({ ui = ui })
				end

				local okBtn

				local functions = {}

				functions.layout = function()
					drawer:layout()
					drawer:show()
				end

				functions.createOpenSettingsBtn = function()
					local padding = theme.padding
					local buttonContent = ui:frame()
					local line1 = ui:createText("⚙️ Open Settings", { font = Font.Pixel, size = "default" })
					line1:setParent(buttonContent)
					local line2 = ui:createText("➡️ Turn ON Notifications", { font = Font.Pixel, size = "default" })
					line2:setParent(buttonContent)
					buttonContent.parentDidResize = function(self)
						line1.object.MaxWidth = self.parent.Width - padding * 2
						line2.object.MaxWidth = self.parent.Width - padding * 2
						self.Width = math.max(line1.Width, line2.Width)
						self.Height = line1.Height + padding + line2.Height
						line2.pos = {
							self.Width * 0.5 - line2.Width * 0.5,
							0,
						}
						line1.pos = {
							self.Width * 0.5 - line1.Width * 0.5,
							line2.pos.Y + line2.Height + padding,
						}
					end

					local btn = ui:buttonNeutral({
						content = buttonContent,
						padding = 10,
					})

					btn.onRelease = function()
						System:DebugEvent("User presses OPEN SETTINGS button", { context = "signup" })
						System:OpenAppSettings()
					end

					return btn
				end

				functions.createTurnOnPushNotificationsBtn = function()
					local padding = theme.padding
					local buttonContent = ui:frame()
					local line1 = ui:createText("Turn ON Notifications!", { font = Font.Pixel, size = "big" })
					line1:setParent(buttonContent)
					local line2 = ui:createText("+100 🇵 reward!", { font = Font.Pixel, size = "default" })
					line2:setParent(buttonContent)
					buttonContent.parentDidResize = function(self)
						line1.object.MaxWidth = self.parent.Width - padding * 2
						line2.object.MaxWidth = self.parent.Width - padding * 2
						self.Width = math.max(line1.Width, line2.Width)
						self.Height = line1.Height + padding + line2.Height
						line2.pos = {
							self.Width * 0.5 - line2.Width * 0.5,
							0,
						}
						line1.pos = {
							self.Width * 0.5 - line1.Width * 0.5,
							line2.pos.Y + line2.Height + padding,
						}
					end

					local btn = ui:buttonPositive({
						content = buttonContent,
						padding = 10,
					})

					btn.onRelease = function()
						btn:disable()
						System:DebugEvent("User presses TURN ON notifications button", { context = "signup" })
						System:NotificationRequestAuthorization(function(response)
							System:DebugEvent(
								"App receives notification authorization response",
								{ response = response, context = "signup" }
							)
							Timer(0.1, functions.refreshNotificationBtn)
							-- functions.refreshNotificationBtn()
						end)
					end

					return btn
				end

				local previousNotificationStatus
				functions.refreshNotificationBtn = function()
					System:NotificationGetStatus(function(status)
						if status == previousNotificationStatus then
							return
						end

						previousNotificationStatus = status

						if okBtn then
							okBtn:remove()
							okBtn = nil
						end

						if status == "underdetermined" then
							okBtn = functions.createTurnOnPushNotificationsBtn()
							okBtn:setParent(drawer)
						elseif status == "denied" then
							okBtn = functions.createOpenSettingsBtn()
							okBtn:setParent(drawer)
						else
							-- done asking about notifications
							signupFlow:flush()
							signupFlow:push(steps.createCheckAppVersionAndCredentialsStep({ onlyCheckUserInfo = true }))
							return
						end

						functions.layout()
					end)
				end
				functions.refreshNotificationBtn()

				if appDidBecomeActiveListener == nil then
					appDidBecomeActiveListener = LocalEvent:Listen(LocalEvent.Name.AppDidBecomeActive, function()
						functions.refreshNotificationBtn()
					end)
				end

				local laterBtn = ui:buttonNegative({
					content = "I'll do it later.",
					textSize = "small",
					padding = 10,
				})
				laterBtn:setParent(drawer)
				laterBtn.onRelease = function()
					System:DebugEvent("User presses LATER button in signup notification step")
					System:NotificationPostponeAuthorization()
					-- flush signup flow and restart credential checks (should go through now)
					signupFlow:flush()
					signupFlow:push(steps.createCheckAppVersionAndCredentialsStep({ onlyCheckUserInfo = true }))
				end

				local title = ui:createText("One last thing! 💬", {
					color = Color.White,
					font = Font.Pixel,
					size = "big",
				})
				title:setParent(drawer)

				local text = ui:createText("You'll get a much better experience with push notifications. ❗️", {
					color = Color.White,
					alignment = "center",
				})
				text:setParent(drawer)

				drawer:updateConfig({
					layoutContent = function(self)
						local padding = theme.paddingBig

						local maxWidth = math.min(300, self.Width - padding * 2)
						text.object.MaxWidth = maxWidth
						title.object.MaxWidth = maxWidth

						local okBtnWidth = 0
						if okBtn then
							okBtnWidth = okBtn.Width
						end

						local w = math.min(self.Width, math.max(text.Width, okBtnWidth, 300) + padding * 2)

						self.Width = w
						self.Height = Screen.SafeArea.Bottom
							+ laterBtn.Height
							+ text.Height
							+ title.Height
							+ padding * 4

						if okBtn then
							self.Height = self.Height + okBtn.Height + padding
						end

						laterBtn.pos = {
							self.Width * 0.5 - laterBtn.Width * 0.5,
							Screen.SafeArea.Bottom + padding,
						}
						local previous = laterBtn
						if okBtn then
							okBtn.pos = {
								self.Width * 0.5 - okBtn.Width * 0.5,
								laterBtn.pos.Y + laterBtn.Height + padding,
							}
							previous = okBtn
						end
						text.pos = {
							self.Width * 0.5 - text.Width * 0.5,
							previous.pos.Y + previous.Height + padding,
						}
						title.pos = {
							self.Width * 0.5 - title.Width * 0.5,
							text.pos.Y + text.Height + padding,
						}
						LocalEvent:Send("signup_drawer_height_update", self.Height)
					end,
				})

				drawer:show()
			end,
			onExit = function()
				if appDidBecomeActiveListener then
					appDidBecomeActiveListener:Remove()
					appDidBecomeActiveListener = nil
				end
			end,
			onRemove = function() end,
		})

		return step
	end

	steps.createDOBStep = function()
		local skipOnFirstEnter = System.HasDOB or System.HasEstimatedDOB
		local requests = {}
		local step = flow:createStep({
			onEnter = function()
				config.dobStep()

				showBackButton()

				-- DRAWER
				if drawer ~= nil then
					drawer:clear()
				else
					drawer = drawerModule:create({ ui = ui })
				end

				cache.age = cache.age ~= nil and cache.age or -1

				local okBtn = ui:buttonPositive({ content = loc("OK"), textSize = "big", padding = 10 })
				okBtn:setParent(drawer)
				if cache.age == -1 then
					okBtn:disable()
				end

				local text = ui:createText(loc("My age is…"), {
					color = Color.White,
					size = "big",
				})
				text:setParent(drawer)

				local secondaryText = ui:createText(loc("Please tell us your age,\nit will not affect gameplay."), {
					color = Color(200, 200, 200),
					size = "small",
					alignment = "center",
				})
				secondaryText:setParent(drawer)

				local function setAgeStr()
					if cache.age == -1 then
						cache.ageStr = "?"
					elseif cache.age >= 22 then
						cache.ageStr = "21+"
					else
						cache.ageStr = "" .. cache.age
					end
				end
				setAgeStr()

				local age = ui:createText("🎂  " .. cache.ageStr .. "  🎂", {
					color = Color.White,
					size = "big",
				})

				age:setParent(drawer)

				local ageSlider = ui:slider({
					min = -1,
					max = 22,
					step = 1,
					defaultValue = cache.age,
					hapticFeedback = true,
					button = ui:buttonNeutral({ content = "🙂", padding = theme.padding }),
					onValueChange = function(v)
						sfx("keydown_1", { Volume = 0.3 })
						cache.age = v
						setAgeStr()
						age.Text = "🎂 " .. cache.ageStr .. " 🎂"
						age.pos.X = drawer.Width * 0.5 - age.Width * 0.5
						if v > -1 then
							okBtn:enable()
						else
							okBtn:disable()
						end
					end,
				})
				ageSlider:setParent(drawer)

				local loading = require("ui_loading_animation"):create({ ui = ui })
				loading:setParent(drawer)
				loading:hide()

				local termsAndPrivacyText = ui:createText("By tapping OK you accept our", {
					color = Color(200, 200, 200),
					size = "small",
				})
				termsAndPrivacyText:setParent(drawer)

				local termsBtn = ui:buttonLink({ content = "Terms of Service", textSize = "small" })
				termsBtn.onRelease = function()
					System:DebugEvent("User presses Terms button")
					URL:Open("https://blip.game/terms")
				end
				termsBtn:setParent(drawer)

				local termsAndPrivacyAnd = ui:createText(" and ", {
					color = Color(200, 200, 200),
					size = "small",
				})
				termsAndPrivacyAnd:setParent(drawer)

				local privacyBtn = ui:buttonLink({ content = "Privacy Policy", textSize = "small" })
				privacyBtn.onRelease = function()
					System:DebugEvent("User presses Privacy button")
					URL:Open("https://blip.game/privacy")
				end
				privacyBtn:setParent(drawer)

				okBtn.onRelease = function()
					loading:show()
					ageSlider:hide()
					okBtn:disable()

					-- NOTE: keeping "DOB" and not "age" in event name to compare with previous versions
					System:DebugEvent("User presses OK button on DOB form", { age = cache.age, ageStr = cache.ageStr })

					-- send API request to update user's age
					local req = api:patchUserInfo({ age = cache.age }, function(err)
						loading:hide()
						ageSlider:show()
						okBtn:enable()

						if err ~= nil then
							System:DebugEvent("Request to set DOB fails")
							return
						end

						-- user DOB has been updated successfully on the server

						-- update local value of System.IsUserUnder13
						System.IsUserUnder13 = cache.age < 13

						-- TODO: gaetan: should we update the local System field HasDOB or HasEstimatedDOB?
						-- update local value of System.HasEstimatedDOB
						-- System.HasEstimatedDOB = true

						-- Next step: ask user to pick a username
						signupFlow:push(steps.createUsernameStep())

						-- TODO: gaetan: this block is the step next to the username input step
						-- -- Next signup flow step: ask user for push notifications grant
						-- System:NotificationGetStatus(function(status)
						-- 	System:DebugEvent("App gets notification status", { status = status })

						-- 	if status == "underdetermined" then
						-- 		-- Go to next step
						-- 		-- signupFlow:push(steps.createUsernameInputStep())
						-- 		signupFlow:push(steps.createPushNotificationsStep())
						-- 		sfx("whooshes_small_1", { Volume = 0.5 })
						-- 	else
						-- 		-- notifications not supported or status already established
						-- 		-- flush signup flow and restart credential checks (should go through now)
						-- 		signupFlow:flush()
						-- 		signupFlow:push(
						-- 			steps.createCheckAppVersionAndCredentialsStep({ onlyCheckUserInfo = true })
						-- 		)
						-- 	end
						-- end)
					end)
					table.insert(requests, req)
				end

				drawer:updateConfig({
					layoutContent = function(self)
						-- here, self.Height can be reduced, but not increased
						-- TODO: enforce this within drawer module

						local padding = theme.paddingBig

						local maxWidth = math.min(300, self.Width - padding * 2)
						text.object.MaxWidth = maxWidth
						secondaryText.object.MaxWidth = maxWidth

						local w = math.min(self.Width, math.max(text.Width, okBtn.Width, 300) + padding * 2)

						self.Width = w
						self.Height = Screen.SafeArea.Bottom
							+ okBtn.Height
							+ ageSlider.Height
							+ age.Height
							+ text.Height
							+ secondaryText.Height
							+ termsAndPrivacyText.Height
							+ termsBtn.Height
							+ padding * 7

						local termsWidth = termsBtn.Width + termsAndPrivacyAnd.Width + privacyBtn.Width
						local x = self.Width * 0.5 - termsWidth * 0.5
						local y = Screen.SafeArea.Bottom + padding

						termsBtn.pos = {
							x,
							y,
						}
						x = x + termsBtn.Width

						termsAndPrivacyAnd.pos = {
							x,
							y,
						}
						x = x + termsAndPrivacyAnd.Width

						privacyBtn.pos = {
							x,
							y,
						}

						termsAndPrivacyText.pos = {
							self.Width * 0.5 - termsAndPrivacyText.Width * 0.5,
							privacyBtn.pos.Y + privacyBtn.Height,
						}

						okBtn.pos = {
							self.Width * 0.5 - okBtn.Width * 0.5,
							termsAndPrivacyText.pos.Y + termsAndPrivacyText.Height + padding,
						}

						ageSlider.Width = self.Width - padding * 2
						ageSlider.pos = {
							self.Width * 0.5 - ageSlider.Width * 0.5,
							okBtn.pos.Y + okBtn.Height + padding,
						}

						loading.pos = {
							ageSlider.pos.X + ageSlider.Width * 0.5 - loading.Width * 0.5,
							ageSlider.pos.Y + ageSlider.Height * 0.5 - loading.Height * 0.5,
						}

						age.pos = {
							self.Width * 0.5 - age.Width * 0.5,
							ageSlider.pos.Y + ageSlider.Height + padding,
						}

						secondaryText.pos = {
							self.Width * 0.5 - secondaryText.Width * 0.5,
							age.pos.Y + age.Height + padding,
						}

						text.pos = {
							self.Width * 0.5 - text.Width * 0.5,
							secondaryText.pos.Y + secondaryText.Height + padding,
						}

						LocalEvent:Send("signup_drawer_height_update", self.Height)
					end,
				})

				drawer:show()

				if skipOnFirstEnter then
					skipOnFirstEnter = false
					signupFlow:push(steps.createUsernameStep())
				end
			end,
			onExit = function()
				for _, req in ipairs(requests) do
					req:Cancel()
				end
				drawer:updateConfig({
					layoutContent = function(_) end,
				})
				drawer:hide()
			end,
			onRemove = function()
				removeBackButton()
				if drawer ~= nil then
					drawer:remove()
					drawer = nil
				end
				if config.onCancel ~= nil then
					config.onCancel() -- TODO: can't stay here (step also removed when completing flow)
				end
			end,
		})

		return step
	end

	steps.createUsernameStep = function()
		local skipOnFirstEnter = System.Username ~= nil and System.Username ~= "" -- skip this step if user already has a username
		local requests = {}
		local step = flow:createStep({
			onEnter = function()
				config.usernameStep()

				showBackButton()

				-- DRAWER

				if drawer ~= nil then
					drawer:clear()
				else
					drawer = drawerModule:create({ ui = ui })
				end

				-- DATA

				local username
				local usernameKey

				-- REQUESTS

				local usernameCheckRequest
				local userCheckTimer
				local usernameSetRequest

				local function cancelTimersAndRequests()
					if usernameCheckRequest ~= nil then
						usernameCheckRequest:Cancel()
						usernameCheckRequest = nil
					end

					if userCheckTimer ~= nil then
						userCheckTimer:Cancel()
						userCheckTimer = nil
					end
					if usernameSetRequest then
						usernameSetRequest:Cancel()
						usernameSetRequest = nil
					end
				end

				-- UI

				local text = ui:createText(loc("Pick a Username!"), {
					color = Color.White,
					size = "default",
					alignment = "center",
				})
				text:setParent(drawer)

				local instructions =
					ui:createText(loc("Must start with a letter, followed by letters (a-z) and numbers (0-9) only."), {
						color = Color(150, 150, 150),
						size = "small",
						alignment = "center",
					})
				instructions:setParent(drawer)

				local statusMessage = ui:createText("...", {
					color = Color.White,
					size = "small",
					alignment = "center",
				})
				statusMessage:setParent(nil)

				local loading = require("ui_loading_animation"):create({ ui = ui })
				loading:setParent(nil)

				local function showStatusMessage(str)
					statusMessage.Text = str
					statusMessage.pos = {
						instructions.pos.X + instructions.Width * 0.5 - statusMessage.Width * 0.5,
						instructions.pos.Y + instructions.Height * 0.5 - statusMessage.Height * 0.5,
					}
					instructions:setParent(nil)
					loading:setParent(nil)
					statusMessage:setParent(drawer)
				end

				local function showLoading()
					instructions:setParent(nil)
					loading:setParent(drawer)
					statusMessage:setParent(nil)
				end

				local function showInstructions()
					instructions:setParent(drawer)
					loading:setParent(nil)
					statusMessage:setParent(nil)
				end

				-- Warning message
				local warning = ui:createText(loc("⚠️ Choose carefully, you can't change it later!"), {
					color = Color(251, 206, 0),
					size = "small",
					alignment = "center",
				})
				warning:setParent(drawer)

				-- Button
				local confirmButton = ui:buttonPositive({
					content = loc("This is it!"),
					padding = 10,
				})
				confirmButton:setParent(drawer)
				confirmButton:disable()

				-- Text input
				local usernameInput = ui:createTextInput(
					"",
					loc("Don't use your real name!"),
					{ textSize = "default", bottomMargin = confirmButton.Height + theme.padding * 2 }
				)
				usernameInput:setParent(drawer)

				-- Text input onTextChange
				usernameInput.onTextChange = function(self)
					confirmButton:disable()

					-- disable onTextChange while we normalize the text
					local backup = self.onTextChange
					self.onTextChange = nil

					local s = str:normalize(self.Text)
					s = str:lower(s)
					self.Text = s

					-- re-enable onTextChange
					self.onTextChange = backup

					showLoading()
					cancelTimersAndRequests()

					if s == "" then
						showInstructions()
					else
						-- use timer to avoid spamming the API
						userCheckTimer = Timer(1.0, function()
							-- check username
							usernameCheckRequest = api:checkUsername(s, function(ok, response)
								statusMessage:setParent(node)
								loading:setParent(nil)

								if ok == false or response == nil then
									showStatusMessage(loc("❌ failed to validate username"))
								else
									if response.format == false then
										showStatusMessage(loc("❌ invalid format"))
									elseif response.available == false then
										showStatusMessage(loc("❌ username already taken"))
									elseif response.appropriate == false then
										showStatusMessage(loc("❌ username is inappropriate"))
									else
										showStatusMessage(loc("✅ username is available"))
										username = s
										usernameKey = response.key
										confirmButton:enable()
									end
								end
							end)
						end)
					end
					-- System:DebugEvent("User edits username in text input", { username = self.Text })
				end

				-- Button onRelease
				confirmButton.onRelease = function()
					cancelTimersAndRequests()
					showLoading()
					usernameInput:disable()

					System:DebugEvent("User presses OK button to submit username", { username = usernameInput.Text })

					usernameSetRequest = api:patchUserInfo({
						username = username,
						usernameKey = usernameKey,
					}, function(err)
						if err ~= nil then
							System:DebugEvent("Request to set username fails")
							showStatusMessage("❌ " .. err)
							usernameInput:enable()
							return
						end
						-- success
						System.Username = username
						LocalEvent:Send("username_set")

						System:DebugEvent("User did set username in signup flow")

						-- User did choose a username successfully
						if passkey:isSupported() then
							passkey:getChallenge(function(challenge, error)
								if error ~= nil then
									-- For now, on passkey creation error, we just skip to the home screen.
									signupFlow:push(steps.createPushNotificationsStep())
									return
								end

								passkey:createPasskey(challenge, function(error)
									-- For now, on passkey creation error, we just skip to the home screen.
									-- if error ~= nil then
									-- Passkey creation failed.
									-- When user cancels passkey creation, we get an error here.
									-- ⚠️ TODO: gaetan: show fallback screen (with passkey creation retry button & password form)
									-- return
									-- end
									signupFlow:push(steps.createPushNotificationsStep())
								end)
							end)
						else
							-- passkey is not supported on this device,
							-- let's show the screen to choose a password
							signupFlow:push(steps.createPushNotificationsStep())
						end
					end)
				end

				drawer:updateConfig({
					layoutContent = function(self)
						-- here, self.Height can be reduced, but not increased
						-- TODO: enforce this within drawer module

						local padding = theme.paddingBig

						-- local maxWidth = math.min(300, self.Width - padding * 2)
						-- text.object.MaxWidth = maxWidth
						-- secondaryText.object.MaxWidth = maxWidth

						-- TODO: gaetan: compute width
						-- local w = math.min(self.Width, math.max(text.Width, okBtn.Width, 300) + padding * 2)
						-- self.Width = w

						self.Height = Screen.SafeArea.Bottom
							+ text.Height
							+ warning.Height
							+ instructions.Height
							+ usernameInput.Height
							+ confirmButton.Height
							+ padding * 6

						-- Position of text
						text.object.MaxWidth = self.Width - padding * 2
						text.pos = {
							self.Width * 0.5 - text.Width * 0.5,
							self.Height - text.Height - padding,
						}

						-- Position of warning
						warning.object.MaxWidth = self.Width - padding * 2
						warning.pos = {
							self.Width * 0.5 - warning.Width * 0.5,
							text.pos.Y - warning.Height - padding,
						}

						-- Position of instructions
						instructions.object.MaxWidth = self.Width - padding * 2
						instructions.pos = {
							self.Width * 0.5 - instructions.Width * 0.5,
							warning.pos.Y - instructions.Height - padding,
						}

						-- Position of usernameInput
						usernameInput.Width = self.Width - padding * 2
						usernameInput.pos = {
							self.Width * 0.5 - usernameInput.Width * 0.5,
							instructions.pos.Y - usernameInput.Height - padding,
						}

						-- Position of confirmButton
						confirmButton.pos = {
							self.Width * 0.5 - confirmButton.Width * 0.5,
							usernameInput.pos.Y - confirmButton.Height - padding,
						}

						loading.pos = {
							instructions.pos.X + instructions.Width * 0.5 - loading.Width * 0.5,
							instructions.pos.Y + instructions.Height * 0.5 - loading.Height * 0.5,
						}

						-- Position of statusMessage is already set in showStatusMessage() function.
						-- We don't need to set it here.
						-- statusMessage.pos = {
						-- 	instructions.pos.X + instructions.Width * 0.5 - statusMessage.Width * 0.5,
						-- 	instructions.pos.Y + instructions.Height * 0.5 - statusMessage.Height * 0.5,
						-- }

						LocalEvent:Send("signup_drawer_height_update", self.Height)
					end,
				})

				drawer:show()

				if skipOnFirstEnter then
					skipOnFirstEnter = false
					signupFlow:push(steps.createPushNotificationsStep())
				end
			end,
			onExit = function()
				for _, req in ipairs(requests) do
					req:Cancel()
				end
				drawer:updateConfig({
					layoutContent = function(_) end,
				})
				drawer:hide()
			end,
			onRemove = function()
				removeBackButton()
				if drawer ~= nil then
					drawer:remove()
					drawer = nil
				end
				if config.onCancel ~= nil then
					config.onCancel() -- TODO: can't stay here (step also removed when completing flow)
				end
			end,
		})

		return step
	end

	steps.createSignUpOrLoginStep = function()
		local skipOnFirstEnter = System.HasDOB or System.HasEstimatedDOB
		local createAccountBtn
		local step = flow:createStep({
			onEnter = function()
				if not skipOnFirstEnter then
					System:DebugEvent("App starts signup or login step")
				end

				config.signUpOrLoginStep()

				titleLogo = ui:frame({
					image = {
						data = Data:FromBundle("images/blip-logo.png"),
						alpha = true,
					},
				})

				loginBtn = ui:buttonSecondary({ content = loc("Sign In"), textSize = "small" })
				loginBtn.onRelease = function()
					signupFlow:push(steps.createLoginStep())
				end

				createAccountBtn =
					ui:buttonPositive({ content = loc("Create Account"), textSize = "default", padding = 10 })

				createAccountBtn.parentDidResize = function(self)
					ease:cancel(self)
					ease:cancel(loginBtn)

					createAccountBtn.Width = nil
					createAccountBtn.Width = math.min(400, math.max(createAccountBtn.Width, Screen.Width * 0.8))
					loginBtn.Width = createAccountBtn.Width

					loginBtn.pos = {
						Screen.Width * 0.5 - loginBtn.Width * 0.5,
						Menu.BottomBar.pos.Y + Menu.BottomBar.Height + theme.paddingBig * 2,
					}

					self.pos = {
						Screen.Width * 0.5 - self.Width * 0.5,
						loginBtn.pos.Y + loginBtn.Height + padding,
					}

					titleLogo.Width = math.min(300, Screen.Width * 0.5)
					titleLogo.Height = math.floor(titleLogo.Width / 2.295)

					titleLogo.pos = {
						Screen.Width * 0.5 - titleLogo.Width * 0.5,
						Screen.Height - Screen.SafeArea.Top - titleLogo.Height - padding,
					}
				end

				createAccountBtn:parentDidResize()

				-- login btn animation
				local targetPos = loginBtn.pos:Copy()
				loginBtn.pos.Y = loginBtn.pos.Y - 50
				ease:outSine(loginBtn, animationTime).pos = targetPos

				-- start btn animation
				targetPos = createAccountBtn.pos:Copy()
				createAccountBtn.pos.Y = createAccountBtn.pos.Y - 50
				ease:outBack(createAccountBtn, animationTime).pos = targetPos

				-- create account button callback
				createAccountBtn.onRelease = function()
					System:DebugEvent("User presses Create Account button")
					signupFlow:push(steps.createDOBStep())
					sfx("whooshes_small_1", { Volume = 0.5 })
				end

				if skipOnFirstEnter then
					skipOnFirstEnter = false
					signupFlow:push(steps.createDOBStep())
				end
			end,
			onExit = function()
				createAccountBtn:remove()
				createAccountBtn = nil
				loginBtn:remove()
				loginBtn = nil
				titleLogo:remove()
				titleLogo = nil
			end,
			onRemove = function() end,
		})
		return step
	end

	steps.createCheckAppVersionAndCredentialsStep = function(config)
		config = config or { onlyCheckUserInfo = false }

		local loadingFrame
		local step = flow:createStep({
			onEnter = function()
				removeBackButton()
				removeCoinsButton()

				if loadingFrame == nil then
					loadingFrame = ui:frameTextBackground()

					local text = ui:createText("", {
						color = Color.White,
					})
					text:setParent(loadingFrame)
					text.pos = { theme.padding, theme.padding }

					loadingFrame.parentDidResize = function(self)
						ease:cancel(self)

						loadingFrame.Width = text.Width + theme.padding * 2
						loadingFrame.Height = text.Height + theme.padding * 2

						self.pos = {
							Screen.Width * 0.5 - self.Width * 0.5,
							Screen.Height / 5.0 - self.Height * 0.5,
						}
					end
					loadingFrame:parentDidResize()

					local function parseVersion(versionStr)
						local maj, min, patch = versionStr:match("(%d+)%.(%d+)%.(%d+)")
						maj = math.floor(tonumber(maj))
						min = math.floor(tonumber(min))
						patch = math.floor(tonumber(patch))
						return maj, min, patch
					end

					text.Text = "Checking app version..."
					loadingFrame:parentDidResize()

					local checks = {}

					--
					--                                    minAppVersion()
					--                                        |        \
					--                                     Ok |         \
					--                                        |        error("app needs updating")
					--                                        |
					--                               userAccountExists()?
					--                                     /      \
					--                                Yes /        \ No
					--                                   /          \
					--                                  /            \
					--                       askedMagicKey()?      createAccount()
					--                          /      \               /       \
					--                     Yes /        \ No          / Ok      \ Error
					--                        /          \           /           \
					--                       /            \         /             \
					--     displayMagicKeyPrompt()  checkUserAccountComplete()   error("account creation failed")
					--        (can be cancelled)          /        \
					--         TODO: next step           /          \
					--                |                 /            \
					--              ?????           No /              \ Yes
					--                                /                \
					--                               /                  \
					--            pushStep("SignUpOrLoginStep")     goToMainHomeScreen()
					--

					checks.error = function(optionalErrorMsg)
						text.Text = ""
						loadingFrame:hide()

						local msgStr = "Sorry, something went wrong. 😕"
						if type(optionalErrorMsg) == "string" and optionalErrorMsg ~= "" then
							msgStr = optionalErrorMsg
						end

						-- Show error message with retry button
						-- Click on button should call checks.minAppVersion()

						local errorBox = ui:frameTextBackground()
						local errorText = ui:createText(msgStr, { color = Color.White, size = "default" })
						errorText:setParent(errorBox)
						local retryBtn = ui:buttonNeutral({ content = "Retry", padding = theme.padding })
						retryBtn:setParent(errorBox)

						errorBox.parentDidResize = function(self)
							ease:cancel(self)
							self.Width = math.max(errorText.Width, retryBtn.Width) + theme.paddingBig * 2
							self.Height = errorText.Height + theme.padding + retryBtn.Height + theme.paddingBig * 2

							retryBtn.pos = {
								self.Width * 0.5 - retryBtn.Width * 0.5,
								theme.paddingBig,
							}

							errorText.pos = {
								self.Width * 0.5 - errorText.Width * 0.5,
								retryBtn.pos.Y + retryBtn.Height + padding,
							}

							self.pos = {
								Screen.Width * 0.5 - self.Width * 0.5,
								Screen.Height / 5.0 - self.Height * 0.5,
							}
						end

						errorBox:parentDidResize()

						retryBtn.onRelease = function()
							-- hide the error box
							errorBox:remove()
							-- call the first sub-step again
							checks.minAppVersion()
						end

						local targetPos = errorBox.pos:Copy()
						errorBox.pos.Y = errorBox.pos.Y - 50
						ease:outBack(errorBox, animationTime).pos = targetPos
					end

					checks.minAppVersion = function()
						System:DebugEvent("App performs initial checks")
						api:getMinAppVersion(function(error, minVersion)
							if error ~= nil then
								System:DebugEvent("Request to get min app version fails", { error = error })
								checks.error() -- Show error message with retry button
								return
							end

							local major, minor, patch = parseVersion(Client.AppVersion)
							local minMajor, minMinor, minPatch = parseVersion(minVersion)
							local appIsUpToDate = (major > minMajor)
								or (major == minMajor and minor > minMinor)
								or (major == minMajor and minor == minMinor and patch >= minPatch)

							if appIsUpToDate then
								-- call next sub-step
								checks.userAccountExists()
							else
								-- App is not up-to-date
								checks.error("Cubzh app needs to be updated!")
							end
						end)
					end

					-- Checks whether a user account exists locally.
					checks.userAccountExists = function()
						-- Update loading message
						text.Text = "Looking for user account..."
						loadingFrame:parentDidResize()

						if System.HasCredentials == false then
							-- Not user account is present locally
							-- Cleanup, just to be sure
							System.AskedForMagicKey = false
							-- Next sub-step: create new empty account
							checks.createAccount()
						else
							-- User account is present
							-- Next sub-step: check if a magic key has been asked
							checks.askedMagicKey()
						end
					end

					checks.createAccount = function()
						System:DebugEvent("App creates new empty user account")

						-- Update loading message
						text.Text = "Creating user account..."
						loadingFrame:parentDidResize()

						api:signUp(nil, nil, nil, function(err, credentials)
							if err ~= nil then
								checks.error("Account creation failed")
							else
								-- save credentials in local storage
								System:StoreCredentials(credentials["user-id"], credentials.token)
								--
								System:DebugEvent("App receives account credentials")

								-- Next sub-step: check if user account is complete
								checks.checkUserAccountComplete()
							end
						end)
					end

					-- Checks whether a magic key has been requested.
					checks.askedMagicKey = function()
						System:DebugEvent("App checks if magic key has been requested")

						text.Text = "Checking magic key..."
						loadingFrame:parentDidResize()

						-- Cleanup: remove `AskedForMagicKey` flag if it's still set while we have valid credentials
						if System.HasCredentials and System.Authenticated and System.AskedForMagicKey then
							System.AskedForMagicKey = false
						end

						if System.AskedForMagicKey then
							-- Magic key has been requested by user in a previous session
							System:DebugEvent("App shows magic key prompt")

							-- retrieve username or email that has been stored
							local usernameOrEmail = System.SavedUsernameOrEmail
							if type(usernameOrEmail) == "string" and usernameOrEmail ~= "" then
								-- show magic key prompt
								local step = steps.createMagicKeyInputStep({ usernameOrEmail = usernameOrEmail })
								signupFlow:push(step)
							else
								checks.error("failed to resume login with magic key")
							end
						else
							-- No magic key has been asked
							-- Next sub-step: check if user account is complete
							checks.checkUserAccountComplete()
						end
					end

					checks.checkUserAccountComplete = function()
						text.Text = "Checking user info..."
						loadingFrame:parentDidResize()

						-- System.HasCredentials should always be true here because
						-- an empty user account is automatically created if none is found
						if System.HasCredentials == false then
							checks.error("No credentials found, this should not happen.")
							return
						end

						-- Request user account info
						api:getUserInfo(System.UserID, {
							"username",
							"hasEmail",
							"hasPassword",
							"hasPasskey",
							"hasDOB",
							"hasEstimatedDOB",
							"isUnder13",
							"isParentApproved",
							"didCustomizeAvatar",
							"hasVerifiedPhoneNumber",
							"hasUnverifiedPhoneNumber",
							"isPhoneExempted",
							"isChatEnabled",
							"blockedUsers",
						}, function(userInfo, err)
							if err ~= nil then
								System:DebugEvent(
									"Request to obtain user info with credentials fails",
									{ statusCode = err.statusCode, error = err.message }
								)

								-- if unauthorized, it means credentials aren't valid,
								-- removing them to start fresh with account creation or login
								if err.statusCode == 401 then
									System:RemoveCredentials()
									checks.minAppVersion() -- restart from beginning now without credentials
									return
								end

								checks.error() -- Show error message with retry button
								return
							end

							-- No error. Meaning credentials are valid.
							System.Authenticated = true -- [gaetan] not sure this field is useful...

							-- Update values in System
							System.Username = userInfo.username or ""
							System.HasEmail = userInfo.hasEmail
							System.HasVerifiedPhoneNumber = userInfo.hasVerifiedPhoneNumber
							System.HasUnverifiedPhoneNumber = userInfo.hasUnverifiedPhoneNumber
							System.IsPhoneExempted = userInfo.isPhoneExempted
							System.HasDOB = userInfo.hasDOB
							System.HasEstimatedDOB = userInfo.hasEstimatedDOB
							System.IsUserUnder13 = userInfo.isUnder13
							System.IsParentApproved = userInfo.isParentApproved
							System.IsChatEnabled = userInfo.isChatEnabled
							System.HasPasskey = userInfo.hasPasskey
							System.HasPassword = userInfo.hasPassword
							System.BlockedUsers = userInfo.blockedUsers or {}

							-- print("user id:", System.UserID)
							-- print("userInfo.username:", userInfo.username)
							-- print("userInfo.hasEmail:", userInfo.hasEmail)
							-- print("userInfo.hasVerifiedPhoneNumber:", userInfo.hasVerifiedPhoneNumber)
							-- print("userInfo.hasUnverifiedPhoneNumber:", userInfo.hasUnverifiedPhoneNumber)
							-- print("userInfo.isPhoneExempted:", userInfo.isPhoneExempted)
							-- print("userInfo.hasDOB:", userInfo.hasDOB)
							-- print("userInfo.hasEstimatedDOB:", userInfo.hasEstimatedDOB)
							-- print("userInfo.isUnder13:", userInfo.isUnder13)
							-- print("userInfo.isParentApproved:", userInfo.isParentApproved)
							-- print("userInfo.isChatEnabled:", userInfo.isChatEnabled)
							-- print("userInfo.hasPasskey:", userInfo.hasPasskey)
							-- print("userInfo.hasPassword:", userInfo.hasPassword)

							System:NotificationGetStatus(function(status)
								if Client.LoggedIn and status ~= "underdetermined" then
									if status == "authorized" then
										System:NotificationRefreshPushToken()
									end
									callLoginSuccess()
								else
									signupFlow:push(steps.createSignUpOrLoginStep())
								end
							end)
						end)
					end

					-- Start with the first sub-step
					if config.onlyCheckUserInfo then
						checks.checkUserAccountComplete()
					else
						checks.minAppVersion()
					end
				end
				loadingFrame:parentDidResize()
			end,
			onExit = function()
				loadingFrame:remove()
				loadingFrame = nil
			end,
			onRemove = function() end,
		})
		return step
	end

	signupFlow:push(steps.createCheckAppVersionAndCredentialsStep())

	return signupFlow
end

return signup
