local module = {}
module.__index = module

-- // VARIABLES \\ --

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Settings = require(game.ReplicatedStorage.Settings[script.Name])
local Core = require(game.ReplicatedStorage.Core)
local waitForPath = Core("waitForPath")
local newTween = Core("newTween")
local playSound = Core("playSound")
local disconnectCon = Core("disconnectCon")

local p = game.Players.LocalPlayer

-- // FUNCTIONS \\ --

function module:invokeRemote(remote, ...)
	local success, errorMsg = remote:InvokeServer(...)
	if errorMsg and Settings.willDebug then
		if success then
			print(errorMsg)
		else
			warn(errorMsg)
		end
	end
	return success, errorMsg
end

-- indirect

function module:showDamageDealt(receiver, damageType, amount)
	local root = receiver:FindFirstChild("HumanoidRootPart")
	if root then
		local newIndicator = self.UI.toolUI.DamageIndicator:Clone() do
			newIndicator.TextLabel.Text = amount
			newIndicator.TextLabel.TextColor3 = Settings.DamageIndicator[damageType].color
			newIndicator.TextLabel.TextStrokeTransparency = Settings.DamageIndicator[damageType].stroke
			newIndicator.TextLabel.TextStrokeColor3 = Settings.DamageIndicator[damageType].strokeColor
			newIndicator.TextLabel.TextTransparency = 1
			newIndicator.Enabled = true
			newIndicator.Parent = root 
			newIndicator.StudsOffset = Vector3.new(
				math.random(Settings.DamageIndicator.minOffset.X * 10, Settings.DamageIndicator.maxOffset.X * 10) / 10, 
				math.random(Settings.DamageIndicator.minOffset.Y * 10, Settings.DamageIndicator.maxOffset.Y * 10) / 10, 
				0
			)
		end

		if damageType == "head" then
			playSound(self.sounds.headHitSound, self.tool.handle)
		else
			playSound(self.sounds.nonheadHitSound, self.tool.handle)
		end

		Debris:AddItem(newIndicator, Settings.DamageIndicator.maxduration)
		newTween(newIndicator.TextLabel, Settings.DamageIndicator.tweenInfo, {TextTransparency = 0}).Completed:Wait()
		newTween(newIndicator.TextLabel, Settings.DamageIndicator.tweenInfo, {TextTransparency = 1})
	end	
end

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
	if Settings.fireType == "auto" then	
		disconnectCon({self.temp.currentOnInputBegan, self.temp.currentOnInputEnded, self.temp.currentOnStepped})
		
		self.temp.currentOnInputBegan = UserInputService.InputBegan:Connect(function(...)
			self:onInputBegan(...)
		end)
		
		self.temp.currentOnInputEnded = UserInputService.InputEnded:Connect(function(...)
			self:onInputEnded(...)
		end)
	
		self.temp.currentOnStepped = RunService.Stepped:Connect(function(...)
			self:onStepped(...)
		end)
	elseif Settings.fireType == "semi" then
		disconnectCon({self.temp.currentOnInputBegan})
	
		self.temp.currentOnInputBegan = UserInputService.InputBegan:Connect(function(...)
			self:onInputBegan(...)
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

	if input.UserInputType == Settings.keybinds.shoot then	
		isMouseDown = true
		if Settings.fireType == "semi" and os.clock() - self.temp.timeOfRecentFire >= 60 / Settings.fireRate then
			self:shootGun()
		end	
	elseif input.KeyCode == Settings.keybinds.reload then
		isMouseDown = false
		self:reloadGun()
	end		
end

function module:onInputEnded(input, gamehandledEvent)
	if gamehandledEvent or not self.temp.expectingInput or not self.temp.mouse then
		return
	end

	if input.UserInputType == Settings.keybinds.shoot then
		isMouseDown = false
	end
end

-- instance events

function module:onDamageDealtFired(...)
	self:showDamageDealt(...)
end

function module:onAmmoChanged(val)
	self.UI.gunInfoUI.Ammo.Text = '<font size="90">' .. val .. '</font><font size="50">/' .. Settings.maxAmmo .. '</font>'
end

function module:onToolUnequip()
	self.UI.gunInfoUI.Enabled = false
	self:invokeRemote(self.tool.remotes.ChangeStatus, "unequip")
	self.anims.holdAnim:Stop()

	self.temp.expectingInput = false
	self.temp.isMouseDown = false
	self:updateMouseIcon()
end

function module:onToolEquip(playerMouse)
	self.UI.gunInfoUI.Enabled = true
	self:onAmmoChanged(self.tool.ammo.Value)
	self:invokeRemote(self.tool.remotes.ChangeStatus, "equip")
	self.anims.holdAnim:Play()

	self.temp.mouse = playerMouse
	self.temp.expectingInput = true
	self.temp.isMouseDown = false

	self:updateMouseIcon()
	self:initEvents()
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
			Settings = require(game.ReplicatedStorage.Settings[tool.Name]),
			handle = tool:WaitForChild("Handle"),
			ammo = waitForPath(tool, "Values.Ammo"),
			remotes = tool:WaitForChild("Remotes"),
		},
		anims = {
			anims = script:WaitForChild("Animations"),
			holdAnim = p.Character.Humanoid:LoadAnimation(script.Animations:WaitForChild("Hold")),
			shootAnim = p.Character.Humanoid:LoadAnimation(script.Animations:WaitForChild("Shoot")),
			reloadAnim = p.Character.Humanoid:LoadAnimation(script.Animations:WaitForChild("Reload")),
		},		
		UI = {
			gunInfoUI = p.PlayerGui:WaitForChild("GunInfo"),
			toolUI = script:WaitForChild("UI"),
		},
		sounds = {
			headHitSound = tool.Handle:WaitForChild("HeadHit"),
			nonheadHitSound = tool.Handle:WaitForChild("NonheadHit"),
		},		
		temp = {
			timeOfRecentFire = os.clock(),
			mouse = nil,
			expectingInput = nil,
			isMouseDown = nil,

			currentOnInputBegan = nil,
			currentOnInputEnded = nil,
			currentOnStepped = nil,
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
	
	self.tool.ammo.Changed:Connect(function(...)
		self:onAmmoChanged(...)
	end)
	
	self.tool.remotes:WaitForChild("DamageDealt").OnClientEvent:Connect(function(...)
		self:onDamageDealtFired(...)
	end)
	
	-- compile

	self.UI.gunInfoUI:WaitForChild("FireType").Text = Settings.fireType:upper()
	
end

return module