local GUN_TAG = "Gun"
local CollectionService = game:GetService("CollectionService")
local core = require(game.ServerScriptService.Core)
local collection = core("collection")

function init(tool)
	if tool.Parent:IsA("Backpack") then
		local tags = CollectionService:GetTags(tool)
		local gunModule
		for _,tag in pairs(tags) do
			gunModule = script:FindFirstChild(tag)
			if gunModule then
				require(gunModule).init(tool)
				break
			end
		end
	end
end

collection(GUN_TAG, init)