local modules = {}

local function loadModule(name)
	return require(script:FindFirstChild(name))
end

local function getModule(name)
	return modules[name] or loadModule(name)
end

return function(name)
	local possibleModule = getModule(name)
	if possibleModule then
		return possibleModule
	else
		warn(name .. " does not exist")
	end	
end