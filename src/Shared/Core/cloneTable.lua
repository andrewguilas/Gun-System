local core = require(script.Parent)
local cloneTable = core("cloneTable")

return function(OriginalTable)
	local copy = {}
	for k, v in pairs(OriginalTable) do
		if type(v) == "table" then
			v = cloneTable(v)
		end
		copy[k] = v
	end
	return copy
end