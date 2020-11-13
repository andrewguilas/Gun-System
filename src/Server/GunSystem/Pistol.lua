local module = {}
module.__index = module

-- // VARIABLES \\ --

local RNG = Random.new()
local TAU = math.pi * 2	

local Debris = game:GetService("Debris")

local Settings = require(game.ReplicatedStorage.Settings[script.Name])
local FastCast = require(script.Parent.FastCastRedux)
local Table = require(script.Parent.FastCastRedux.Table)
local PartCacheModule = require(script.Parent.PartCache)

local Core = require(game.ServerScriptService.Core)
local newThread = Core("newThread")
local playSound = Core("playSound")

local cosmeticBulletsFolder = workspace:FindFirstChild("CosmeticBulletsFolder") or Instance.new("Folder", workspace)
cosmeticBulletsFolder.Name = "CosmeticBulletsFolder"

-- // FUNCTIONS \\ --

function module:playSmoke()
	local newSmoke = self.VFX.smoke:Clone()
	newSmoke.Enabled = true
	newSmoke.Parent = self.tool.handle
	Debris:AddItem(newSmoke, Settings.smokeDespawnDelay)

	wait(Settings.smokeDuration)
	newSmoke.Enabled = false
end

function module:playMuzzleLight()
	local newMuzzleLight = self.VFX.muzzleLight:Clone()
	newMuzzleLight.Enabled = true
	newMuzzleLight.Parent = self.tool.handle
	Debris:AddItem(newMuzzleLight, Settings.muzzleFlashTime)
end

function module:playMuzzleFlash()
	local newMuzzleFlash = self.VFX.muzzleFlash:Clone()
	newMuzzleFlash.Enabled = true
	newMuzzleFlash.Parent = self.tool.handle
	Debris:AddItem(newMuzzleFlash, Settings.muzzleFlashTime)
end

function module:playHitFX(part, position, normal)
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.new(position, position + normal)
	attachment.Parent = workspace.Terrain

	local particle = self.VFX.impactParticle:Clone()
	particle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, part.Color),
		ColorSequenceKeypoint.new(0.5, part.Color),
		ColorSequenceKeypoint.new(1, part.Color)
	})
	particle.Parent = attachment
	Debris:AddItem(attachment, particle.Lifetime.Max)

	particle.Enabled = true
	wait(Settings.impactParticleDuration)
	particle.Enabled = false
end

-- indirect

function module:fire(direction, sender)	
	-- random angles
	local directionalCF = CFrame.new(Vector3.new(), direction)
	local direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(math.rad(RNG:NextNumber(Settings.minBulletSpreadAngle, Settings.maxBulletSpreadAngle)), 0, 0)).LookVector

	-- realistic bullet velocity
	local root = self.tool.tool.Parent:WaitForChild("HumanoidRootPart", 1)
	local myMovementSpeed = root.Velocity
	local modifiedBulletSpeed = (direction * Settings.bulletSpeed) + myMovementSpeed

	-- fire bullet
	self.tool.ammo.Value -= Settings.bulletsPerShot
	self.fastCast.caster:Fire(self.tool.firePointObj.WorldPosition, direction, modifiedBulletSpeed, self.fastCast.castBehavior, sender)
	
	newThread(playSound, self.sounds.fireSound, self.tool.handle)
	
	newThread(function()
		self:playMuzzleFlash()
	end)
	
	newThread(function()
		self:playMuzzleLight()
	end)
	
	newThread(function()
		self:playSmoke()
	end)	
end

-- events

function module:onRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject, sender)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal

	-- check if hit
	if hitPart and hitPart.Parent then
		local hum = hitPart.Parent:FindFirstChildOfClass("Humanoid")
		if hum then
			-- deal dmg
			local damageType, amount
			if table.find({"Head"}, hitPart.Name) then
				damageType = "head"
				amount = Settings.headDamage
				hum:TakeDamage(amount)
			elseif table.find({"UpperTorso", "LowerTorso", "HumanoidRootPart"}, hitPart.Name) then
				damageType = "torso"
				amount = Settings.torsoDamage
				hum:TakeDamage(amount)
			else
				damageType = "limb"
				amount = Settings.limbDamage
				hum:TakeDamage(amount)
			end
			self.tool.remotes.DamageDealt:FireClient(sender, hitPart.Parent, damageType, amount)
		end
		self:playHitFX(hitPart, hitPoint, normal)
	end
end

function module:onRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	if not cosmeticBulletObject then 
		return 
	end

	-- adjust bullet size
	local bulletVelocity = (math.abs(segmentVelocity.X) + math.abs(segmentVelocity.Y) + math.abs(segmentVelocity.Z))
	cosmeticBulletObject.Size = Vector3.new(cosmeticBulletObject.Size.X, cosmeticBulletObject.Size.Y, bulletVelocity / Settings.bulletLengthMultiplier)

	-- adjust bullet pos
	local bulletLength = cosmeticBulletObject.Size.Z / 2
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
end

function module:onRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet then
		if self.fastCast.castBehavior.CosmeticBulletProvider then
			self.fastCast.castBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
		else
			cosmeticBullet:Destroy()
		end
	end
end

function module:onMouseEventFired(p, mousePoint)

	-- debounce	
	if not self.temp.canFire or os.clock() - self.temp.timeOfRecentFire < 60 / Settings.fireRate then
		playSound(self.sounds.jamSound, self.tool.handle)
		return false, "GUN_JAMMED"
	end
	self.temp.timeOfRecentFire = os.clock()
	self.temp.canFire = false	

	-- check ammo
	if self.tool.ammo.Value <= 0 then
		self.temp.canFire = true
		playSound(self.sounds.jamSound, self.tool.handle)
		return false, "NO_AMMO"
	end

	-- check if gun is equipped
	if self.tool.tool.Parent:IsA("Backpack") then 
		self.temp.canFire = true
		return false, "TOOL_NOT_EQUIPPED"
	end	

	-- fire gun
	local mouseDirection = (mousePoint - self.tool.firePointObj.WorldPosition).Unit

	local bulletsToShoot
	if self.tool.fireMode.Value == "burst" then
		bulletsToShoot = self.tool.ammo.Value >= Settings.burstBulletsPerShot and Settings.burstBulletsPerShot or self.tool.ammo.Value
	else
		bulletsToShoot = 1
	end

	for i = 1, bulletsToShoot do
		self:fire(mouseDirection, p)

		if self.tool.fireMode.Value == "burst" then
			wait(Settings.burstShoootDelay)
		end	
	end

	-- end debounce
	self.temp.canFire = true
	return true, "FIRED"
end

function module:onChangeStatusFired(p, status)
	if status == "reload" then
		self.temp.canFire = false
		self.sounds.reloadSound:Play()
		wait(Settings.reloadTime)
		self.tool.ammo.Value = Settings.maxAmmo
		self.temp.canFire = true
		return true, "GUN_RELOADED"
	elseif status == "equip" then
		self.temp.canFire = true
		self.fastCast.castParams.FilterDescendantsInstances = {self.tool.tool.Parent, self.fastCast.cosmeticBulletsFolder}
		self.sounds.equipSound:Play()
		return true, "GUN_EQUIPPED"
	elseif status == "unequip" then
		self.temp.canFire = false
		self.sounds.unequipSound:Play()
		return true, "GUN_UNEQUIPPED"
	end
end

function module:onChangeFireMode(p)
	local fireModes = Settings.fireMode
	local oldFireModeIndex = table.find(fireModes, self.tool.fireMode.Value)
	local newFireMode

	if oldFireModeIndex == #fireModes and oldFireModeIndex ~= 1 then
		newFireMode = fireModes[1]
	elseif oldFireModeIndex < #fireModes then
		newFireMode = fireModes[oldFireModeIndex + 1]
	end

	print(newFireMode)
	if newFireMode then
		self.tool.fireMode.Value = newFireMode
		return newFireMode
	end
end

function module.init(tool)
	
	-- create dictionary
	
	local self = {}
	self = {
		tool = {
			tool = tool,
			handle = tool.Handle,
			firePointObj = tool.Handle.GunFirePoint,
			remotes = tool.Remotes,
			values = tool.Values,
			ammo = tool.Values.Ammo,
			fireMode = tool.Values.FireMode
		},
		sounds = {
			sounds = tool.Sounds,
			fireSound = nil,
			equipSound = nil,
			unequipSound = nil,
			reloadSound = nil,
			jamSound = nil,
		},
		VFX = {
			impactParticle = tool.Handle.ImpactParticle,
			muzzleFlash = tool.Handle.MuzzleFlash,
			muzzleLight = tool.Handle.MuzzleLight,
			smoke = tool.Handle.Smoke
		},
		temp = {
			canFire = true,
			timeOfRecentFire = os.clock(),	
		},
		fastCast = {
			caster = FastCast.new(),
			cosmeticBullet = nil,
			castParams = nil,
			castBehavior = nil,
		}
	}
	setmetatable(self, module)
	
	-- set ammo
	
	self.tool.ammo.Value = Settings.maxAmmo

	-- sets sounds
	
	for _,sound in pairs(self.sounds.sounds:GetChildren()) do
		sound.Parent = self.tool.handle
	end

	self.sounds.fireSound = self.tool.handle.Shoot
	self.sounds.equipSound = self.tool.handle.Equip
	self.sounds.unequipSound = self.tool.handle.Unequip
	self.sounds.reloadSound = self.tool.handle.Reload
	self.sounds.jamSound = self.tool.handle.Jam

	self.sounds.sounds:Destroy()

	-- creates bullet
	
	self.fastCast.cosmeticBullet = Instance.new("Part")
	for propertyName, propertyValue in pairs(Settings.bulletProps) do
		self.fastCast.cosmeticBullet[propertyName] = propertyValue
	end

	-- new raycast paras
	
	self.fastCast.castParams = RaycastParams.new()
	for propertyName, propertyValue in pairs(Settings.raycastParas) do
		self.fastCast.castParams[propertyName] = propertyValue
	end

	-- data packets
	
	self.fastCast.castBehavior = FastCast.newBehavior()
	self.fastCast.castBehavior.RaycastParams = self.fastCast.castParams
	self.fastCast.castBehavior.MaxDistance = Settings.bulletMaxDist

	-- part cache
	
	local cosmeticPartProvider = PartCacheModule.new(self.fastCast.cosmeticBullet, 100, cosmeticBulletsFolder)
	self.fastCast.castBehavior.CosmeticBulletProvider = cosmeticPartProvider
	self.fastCast.castBehavior.CosmeticBulletContainer = cosmeticPartProvider
	self.fastCast.castBehavior.Acceleration = Settings.bulletGravity
	self.fastCast.castBehavior.AutoIgnoreContainer = false
	
	-- events
	
	self.fastCast.caster.RayHit:Connect(function(...)
		self:onRayHit(...)
	end)
	
	self.fastCast.caster.LengthChanged:Connect(function(...)
		self:onRayUpdated(...)
	end)
	
	self.fastCast.caster.CastTerminating:Connect(function(...)
		self:onRayTerminated(...)
	end)
	
	self.tool.remotes.MouseEvent.OnServerInvoke = function(...)
		self:onMouseEventFired(...)
	end
	
	self.tool.remotes.ChangeStatus.OnServerInvoke = function(...)
		return self:onChangeStatusFired(...)
	end

	self.tool.remotes.ChangeFireMode.OnServerInvoke = function(...)
		return self:onChangeFireMode(...)
	end

end

-- // COMPILE \\ --

FastCast.DebugLogging = Settings.willDebug
FastCast.VisualizeCasts = Settings.willDebug

return module