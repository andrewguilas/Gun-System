return function(...)
	local TweenService = game:GetService("TweenService")
	local tween = TweenService:Create(...)
	tween:Play()
	return tween
end