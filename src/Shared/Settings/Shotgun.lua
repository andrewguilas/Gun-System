local Settings = {
	
	-- debug
	willDebug = false,
	
	-- gun
	mouseIcon = "rbxassetid://131581677",
	fireMode = {"semi", "safety"}, -- array: safety, semi, burst, auto
	bulletsPerShot = 4,
	burstBulletsPerShot = 3,
	burstShoootDelay = 0.1,
	maxAmmo = 6,
	reloadTime = 1.5,
	minBulletSpreadAngle = 0, -- between 0 and 180, in degrees
	maxBulletSpreadAngle = 0, -- between 0 and 180, in degrees
	fireRate = 100,
	
	-- damage
	headDamage = 30,
	torsoDamage = 24,
	limbDamage = 18,
	
	-- bullets
	bulletSpeed = 1500, -- studs/sec
	bulletMaxDist = 130, -- studs
	bulletGravity = Vector3.new(0, -workspace.Gravity, 0),
	bulletLengthMultiplier = 200,
	
	-- effects
	muzzleFlashTime = 0.2,
	impactParticleDuration = 0.05,
	smokeDuration = 4,
	smokeDespawnDelay = 6,
	
	-- UI
	UI = {
		DamageIndicator = {
			head = {
				TextColor3 = Color3.fromRGB(255, 255, 150),
				TextStrokeColor3 = Color3.fromRGB(55, 45, 0),
				TextStrokeTransparency = 0.7,
				TextTransparency = 1
			},
			torso = {
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0.7,
				TextTransparency = 1
			},
			limb = {
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0.7,
				TextTransparency = 1
			},
			maxduration = 2,
			tweenInfo = TweenInfo.new(0.5),
			minOffset = Vector3.new(-6, -6, 0),
			maxOffset = Vector3.new(6, 6, 0)
		},
		GunInfo = {
			hiddenPos = UDim2.new(1, -420, 1, 0),
			shownPos = UDim2.new(1, -420, 1, -140),
			tweenInfo = TweenInfo.new(0.3)
		},
		textFlashTweenInfo = TweenInfo.new(0.1)
	},
	
	-- bullet props
	bulletProps = {
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 123, 123),
		CanCollide = false,
		Anchored = true,
		Size = Vector3.new(0.05, 0.05, 1)
	},
	
	-- raycast paras
	raycastParas = {
		IgnoreWater = true,
		FilterType = Enum.RaycastFilterType.Blacklist,
		FilterDescendantsInstances = {}
	},
	
	-- keybinds
	keybinds = {
		shoot = Enum.UserInputType.MouseButton1,
		reload = Enum.KeyCode.R,
		fireMode = Enum.KeyCode.V
	}
}

return Settings