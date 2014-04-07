-- super awesome actions stuff

function d6(channel)
	say(channel, "Rolling a d6...")
	say(channel, "You rolled a " .. math.random(6) .. "!")
end

function coin(channel)
	action(channel, "flips a coin into the air")
	if math.random(2) == 1 then
		say(channel, "It's heads!")
	else
		say(channel, "It's tails!")
	end
end

function getbitcoin(channel)
	local diff, temp = getURLTitle("http://bitcoindifficulty.com/")
	say(channel, diff)
end

function search(channel, str)
	--TODO
end

function doaction(channel, str)
	local a = switch {
	  ["beep"] = function() say(channel, "Imma bot. Beep.") end,
	  ["d6"] = function() d6(channel) end,
	  ["roll"] = function() d6(channel) end,
	  ["dice"] = function() d6(channel) end,
	  ["die"] = function() d6(channel) end,
	  ["coin"] = function() coin(channel) end,
	  ["quarter"] = function() coin(channel) end,
	  ["flip"] = function() coin(channel) end,
	  ["nickel"] = function() coin(channel) end,
	  ["dime"] = function() coin(channel) end,
	  ["penny"] = function() coin(channel) end,
	  ["bitcoin"] = function() getbitcoin(channel) end,
	  default = function() end,
	}
	
	a:case(str)
end

function saytitle(channel, url)
	local title, temp = getURLTitle(url)
	if string.len(title) > 0 then
		say(channel, "["..title.."]")
	end
end