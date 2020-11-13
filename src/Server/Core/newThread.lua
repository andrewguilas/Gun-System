return function(func,...)
	local a = coroutine.wrap(func)
	a(...)
end