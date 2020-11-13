-- // VARIABLES \\ --

-- constants

local RUN_SPEED = 24
local WALK_SPEED = 16
local CROUCH_SPEED = 8

local MAX_FOV = 70 + (RUN_SPEED / 5)
local NORMAL_FOV = 70
local MIN_FOV = 70 - (CROUCH_SPEED / 5)

local SPRINT_KEY = Enum.KeyCode.LeftShift
local CROUCH_KEY = Enum.KeyCode.LeftControl
local ROLL_KEY = Enum.KeyCode.C

local POV_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Sine)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- instances

local Core = require(game.ReplicatedStorage.Core)
local newTween = Core("newTween")
local disconnectCon = Core("disconnectCon")

local p = game.Players.LocalPlayer
local charCon

-- // FUNCTIONS \\ --

function onInputBegan(info, input, gameProcessed)
	if gameProcessed then
		return
	end
	
	if input.KeyCode == SPRINT_KEY then
		info.hum.WalkSpeed = RUN_SPEED
		newTween(info.camera, POV_TWEEN_INFO, {FieldOfView = MAX_FOV})
	elseif input.KeyCode == CROUCH_KEY then
		info.hum.WalkSpeed = CROUCH_SPEED
		newTween(info.camera, POV_TWEEN_INFO, {FieldOfView = MIN_FOV})
		info.crouchAnim:Play()	
	elseif input.KeyCode == ROLL_KEY then
		info.rollAnim:Play()
	end
end

function onInputEnded(info, input)
	if input.KeyCode == SPRINT_KEY or CROUCH_KEY then
		info.hum.WalkSpeed = WALK_SPEED
		newTween(info.camera, POV_TWEEN_INFO, {FieldOfView = NORMAL_FOV})
	end

	if input.KeyCode == CROUCH_KEY then
		info.crouchAnim:Stop()		
	end
end

-- // EVENTS \\ --

function charAdded(char)
	
	disconnectCon({charCon})
	
	local info = {
		camera = workspace.CurrentCamera,
		char = script.Parent,
		hum = char:WaitForChild("Humanoid"),
		crouchAnim = char.Humanoid:LoadAnimation(script:WaitForChild("Crouch")),
		rollAnim = char.Humanoid:LoadAnimation(script:WaitForChild("Roll"))
	}
	
	local onInputBeganCon = UserInputService.InputBegan:Connect(function(...)
		onInputBegan(info, ...)
	end)
	
	local onInputEndCon = UserInputService.InputEnded:Connect(function(...)
		onInputEnded(info, ...)
	end)
	
	charCon = info.hum.Died:Connect(function()
		onInputBeganCon:Disconnect()
		onInputEndCon:Disconnect()
		p.CharacterAdded:Connect(charAdded)
	end)
end

charCon = p.CharacterAdded:Connect(charAdded)