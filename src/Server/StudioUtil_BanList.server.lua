-- polypastel 2019-11-02
-- ban list handler for StudioUtil plugin

local BannedUserIds = game:GetService("ReplicatedStorage"):WaitForChild("StudioUtil_Data"):WaitForChild("BannedUserIds")

game:GetService("Players").PlayerAdded:Connect(function(player)
	if BannedUserIds:FindFirstChild(tostring(player.UserId)) then
		player:Kick("You have been banned from this game via StudioUtil.")
	end
end)
	
