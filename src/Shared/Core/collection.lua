local core = require(script.Parent)
local newThread = core("newThread")

return function(tag, func)
	local CollectionService = game:GetService("CollectionService")

	for _,obj in pairs(CollectionService:GetTagged(tag)) do
		newThread(func, obj)
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(function(obj)
		newThread(func, obj)
	end)
end