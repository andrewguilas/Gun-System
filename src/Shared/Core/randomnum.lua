return function(min, max, multiplier)
    if not multiplier then
        multiplier = 1
    end
    return math.random(min * 10 ^ multiplier, max * 10 ^ multiplier) / 10 ^ multiplier
end