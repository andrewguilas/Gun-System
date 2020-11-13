local Settings = {
	
	-- debug
	willDebug = false,
	
	-- gun
	mouseIcon = "rbxassetid://131581677",
	fireType = "semi", -- auto/semi
	bulletsPerShot = 1,
	maxAmmo = 12,
	reloadTime = 3,
	minBulletSpreadAngle = 0, -- between 0 and 180, in degrees
	maxBulletSpreadAngle = 0, -- between 0 and 180, in degrees
	fireRate = 720,
	
	-- damage
	headDamage = 35,
	torsoDamage = 28,
	limbDamage = 20,
	
	-- bullets
	bulletSpeed = 1500, -- studs/sec
	bulletMaxDist = 55, -- studs
	bulletGravity = Vector3.new(0, -workspace.Gravity, 0),
	bulletLengthMultiplier = 200,
	
	-- effects
	muzzleFlashTime = 0.1,
	impactParticleDuration = 0.05,
	smokeDuration = 3,
	smokeDespawnDelay = 5,
	
	-- UI
	DamageIndicator = {
		head = {
			color = Color3.fromRGB(255, 255, 150),
			strokeColor = Color3.fromRGB(55, 45, 0),
			stroke = 0.7
		},
		torso = {
			color = Color3.fromRGB(255, 255, 255),
			strokeColor = Color3.fromRGB(0, 0, 0),
			stroke = 0.7
		},
		limb = {
			color = Color3.fromRGB(255, 255, 255),
			strokeColor = Color3.fromRGB(0, 0, 0),
			stroke = 0.7
		},
		maxduration = 2,
		tweenInfo = TweenInfo.new(0.5),
		minOffset = Vector3.new(-6, -6, 0),
		maxOffset = Vector3.new(6, 6, 0)
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
		reload = Enum.KeyCode.R
	}
}

return Settings