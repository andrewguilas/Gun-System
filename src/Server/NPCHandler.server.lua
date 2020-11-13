local NPC_TAG = "NPC"
local Core = require(game.ServerScriptService.Core)
local collection = Core("collection")

function onDied(NPC, newClone)
	newClone.Parent = workspace
	NPC:Destroy()
end

function init(NPC)
	local hum = NPC.Humanoid
	local newClone = NPC:Clone()
	
	hum.Died:Connect(function()
		onDied(NPC, newClone)
	end)
end

collection(NPC_TAG, init)

