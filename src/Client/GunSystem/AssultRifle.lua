local module = {}
module.__index = module

-- // VARIABLES \\ --

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Settings = require(game.ReplicatedStorage.Settings[script.Name])
local Core = require(game.ReplicatedStorage.Core)
local waitForPath = Core("waitForPath")
local newThread = Core("newThread")
local newTween = Core("newTween")
local playSound = Core("playSound")
local disconnectCon = Core("disconnectCon")
local randomnum = Core("randomnum")

local p = game.Players.LocalPlayer

-- // FUNCTIONS \\ --

function module:invokeRemote(remote, ...)
	local success, msg = remote:InvokeServer(...)
	if msg and Settings.willDebug then
		if success then
			print(msg)
		else
			warn(msg)
		end
	end
	return success, msg
end

-- indirect

function module:updateMouseIcon()
	if self.temp.mouse and not self.tool.tool.Parent:IsA("Backpack") then
		self.temp.mouse.Icon = Settings.mouseIcon
	end
end

function module:shootGun()
	self.temp.timeOfRecentFire = os.clock()
	local success, errorMsg = self:invokeRemote(self.tool.remotes.MouseEvent, self.temp.mouse.Hit.Position)
	if errorMsg ~= "NO_AMMO" then
		self.anims.shootAnim:Play()
	end
end

function module:reloadGun()
	self.anims.reloadAnim:Play()
	self:invokeRemote(self.tool.remotes.ChangeStatus, "reload")
end

function module:initEvents()
	disconnectCon(self.temp.connections)

	self.temp.connections.currentOnInputBegan = UserInputService.InputBegan:Connect(function(...)
		self:onInputBegan(...)
	end)

	if self.tool.fireMode.Value == "auto" then	
		self.temp.connections.currentOnInputEnded = UserInputService.InputEnded:Connect(function(...)
			self:onInputEnded(...)
		end)
	
		self.temp.connections.currentOnStepped = RunService.Stepped:Connect(function(...)
			self:onStepped(...)
		end)
	end
end

-- service events

function module:onStepped()
	if self.temp.isMouseDown and os.clock() - self.temp.timeOfRecentFire >= 60 / Settings.fireRate then
		self:shootGun()
	end
end

function module:onInputBegan(input, gameProcessed)
	if gameProcessed or not self.temp.expectingInput or not self.temp.mouse then
		return
	end

	if input.UserInputType == Settings.keybinds.shoot and self.tool.fireMode.Value ~= "safety" then	
		if self.tool.fireMode.Value == "auto" then
			self.temp.isMouseDown = true
		elseif self.tool.fireMode.Value == "semi" or self.tool.fireMode.Value == "burst" and os.clock() - self.temp.timeOfRecentFire >= 60 / Settings.fireRate then
			self:shootGun()
		end	
	elseif input.KeyCode == Settings.keybinds.reload then
		self.temp.isMouseDown = false
		self:reloadGun()
	elseif input.KeyCode == Settings.keybinds.fireMode then
		local oldFireMode = self.tool.fireMode.Value
		local newFireMode = self.tool.remotes.ChangeFireMode:InvokeServer()
		if newFireMode and newFireMode ~= oldFireMode then
			self:updateUI()
			self:initEvents()
		end
	end		
end

function module:onInputEnded(input, gamehandledEvent)
	if gamehandledEvent or not self.temp.expectingInput or not self.temp.mouse then
		return
	end

	if input.UserInputType == Settings.keybinds.shoot then
		self.temp.isMouseDown = false
	end
end

-- instance events

function module:onToolEquip(playerMouse)
	self.temp.mouse = playerMouse
	self.temp.expectingInput = true
	self.temp.isMouseDown = false

	newThread(function()
		self:updateUI()
	end)

	newTween(self.UI.gunInfoUI, Settings.UI.GunInfo.tweenInfo, {Position = Settings.UI.GunInfo.shownPos})
	self:updateMouseIcon()
	self:invokeRemote(self.tool.remotes.ChangeStatus, "equip")
	self.anims.holdAnim:Play()
	self:initEvents()
end

function module:onToolUnequip()

	self.temp.expectingInput = false
	self.temp.isMouseDown = false

	newTween(self.UI.gunInfoUI, Settings.UI.GunInfo.tweenInfo, {Position = Settings.UI.GunInfo.hiddenPos})
	self:updateMouseIcon()
	self:invokeRemote(self.tool.remotes.ChangeStatus, "unequip")
	self.anims.holdAnim:Stop()
	disconnectCon(self.temp.connections)
end

function module:updateUI()
	local UI = self.UI.gunInfoUI
	local currentAmmoText = '<font size="100"><font color = "rgb(255, 255, 255)">' .. self.tool.ammo.Value .. '</font></font>'
	local currentMaxAmmoText = '<font size="60"><font color = "rgb(200, 200, 200)">/' .. Settings.maxAmmo .. '</font></font>'

	newTween(UI.Ammo, Settings.UI.textFlashTweenInfo, {TextTransparency = 1}).Completed:Wait()
	UI.Ammo.Text = currentAmmoText .. currentMaxAmmoText
	UI.FireMode.Text = self.tool.fireMode.Value:upper()
	UI.Weapon.Text = script.Name:upper()
	newTween(UI.Ammo, Settings.UI.textFlashTweenInfo, {TextTransparency = 0})
end

function module:showDamageDealt(receiver, damageType, amount)
	local root = receiver:FindFirstChild("HumanoidRootPart")
	if root then
		local newIndicator = self.UI.toolUI.DamageIndicator:Clone() do
			newIndicator.TextLabel.Text = amount

			for propertyName, propertyValue in pairs(Settings.UI.DamageIndicator[damageType]) do
				newIndicator.TextLabel[propertyName] = propertyValue
			end

			newIndicator.Enabled = true
			newIndicator.Parent = root 

			local minOffset = Settings.UI.DamageIndicator.minOffset
			local maxOffset = Settings.UI.DamageIndicator.minOffset
			newIndicator.StudsOffset = Vector3.new(
				randomnum(minOffset.X, maxOffset.X, 10),
				randomnum(minOffset.Y, maxOffset.Y, 10),
				0
			)
		end

		playSound(self.sounds.hitSound, self.tool.handle)

		Debris:AddItem(newIndicator, Settings.UI.DamageIndicator.maxduration)
		newTween(newIndicator.TextLabel, Settings.UI.DamageIndicator.tweenInfo, {TextTransparency = 0}).Completed:Wait()
		newTween(newIndicator.TextLabel, Settings.UI.DamageIndicator.tweenInfo, {TextTransparency = 1})
	end	
end

function module:charDied()
	disconnectCon(self.temp.connections)
end

-- // INIT \\ --

function module.init(tool)
	
	-- create dictionary
	
	local self = {}
	self = {
		player = {
			char = p.Character or p.CharacterAdded:Wait(),
			hum = p.Character:WaitForChild("Humanoid"),
		},
		tool = {
			tool = tool,
			handle = tool:WaitForChild("Handle"),
			ammo = waitForPath(tool, "Values.Ammo"),
			fireMode = waitForPath(tool, "Values.FireMode"),
			remotes = tool:WaitForChild("Remotes"),
		},
		anims = {
			holdAnim = p.Character.Humanoid:LoadAnimation(waitForPath(script, "Animations.Hold")),
			shootAnim = p.Character.Humanoid:LoadAnimation(script.Animations:WaitForChild("Shoot")),
			reloadAnim = p.Character.Humanoid:LoadAnimation(script.Animations:WaitForChild("Reload")),
		},		
		UI = {
			gunInfoUI = waitForPath(p.PlayerGui, "GunInfo.Frame"), 
			toolUI = script:WaitForChild("UI"),
		},
		sounds = {
			hitSound = tool.Handle:WaitForChild("Hit")
		},		
		temp = {
			timeOfRecentFire = os.clock(),
			mouse = nil,
			expectingInput = nil,
			isMouseDown = nil,

			connections = {
				currentOnInputBegan = nil,
				currentOnInputEnded = nil,
				currentOnStepped = nil,
			}
		}	
	}
	setmetatable(self, module)
	
	-- events
	
	self.tool.tool.Equipped:Connect(function(...)
		self:onToolEquip(...)
	end)
	
	self.tool.tool.Unequipped:Connect(function(...)
		self:onToolUnequip(...)
	end)
	
	self.tool.ammo.Changed:Connect(function()
		self:updateUI()
	end)
	
	self.tool.remotes:WaitForChild("DamageDealt").OnClientEvent:Connect(function(...)
		self:showDamageDealt(...)
	end)
	
	self.player.hum.Died:Connect(function()
		self:charDied()
	end)

	-- compile

	self:updateUI()
	self.UI.gunInfoUI.Visible = true
	self.UI.gunInfoUI.Position = Settings.UI.GunInfo.hiddenPos
	
end

return module