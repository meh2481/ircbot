-- super awesome actions stuff

--From http://lua-users.org/wiki/SwitchStatement
local function switch(t)
  t.case = function (self,x)
    local f=self[x] or self.default
    if f then
      if type(f)=="function" then
        f(x,self)
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return t
end

local function eightball(channel)
	local results = {
		[20] = "It is certain",
		[1] = "It is decidedly so",
		[2] = "Without a doubt",
		[3] = "Definitely",
		[4] = "You may rely on it",
		[5] = "As I see it, yes",
		[6] = "Most likely",
		[7] = "Outlook good",
		[8] = "Yes",
		[9] = "Signs point to yes",
		[10] = "Reply hazy. Try again",
		[11] = "Ask again later",
		[12] = "I'd better not tell you now",
		[13] = "Cannot predict now",
		[14] = "Concentrate and ask again",
		[15] = "Don't count on it",
		[16] = "No",
		[17] = "My sources say no",
		[18] = "Outlook not so good",
		[19] = "Very doubtful",
	}
	say(channel, results[math.random(20)])
end

local function botsnack(channel, act, user)
	--Some kid's starving in Japan, so just eat it
	local eatit = {
		[1] = "happily grabs "..act.." from "..user.." and runs away to bury it",
		[2] = "grabs "..act.." and scarfs it down hungrily",
		[3] = "goes om nom nom",
	}
	action(channel, eatit[math.random(3)])
end

local function insultex(channel, message, nick)
	local words = {}
	local count = 0
	for word in message:gmatch("%w+") do 
		if word ~= nick and word ~= "\001action" and string.len(word) >= 4 then
			table.insert(words, word)
			count = count + 1
		end
	end
	local randomword = words[math.random(#words)]
	if randomword then
		say(channel, "Your ex is "..randomword)
	end
end

local function d6(channel)
	say(channel, "Rolling a d6...")
	say(channel, "You rolled a " .. math.random(6) .. "!")
end

local function coin(channel)
	action(channel, "flips a coin into the air")
	if math.random(2) == 1 then
		say(channel, "It's heads!")
	else
		say(channel, "It's tails!")
	end
end

local function getbitcoin(channel)
	local diff, temp = getURLTitle("http://bitcoindifficulty.com/")
	say(channel, diff)
end

local function search(channel, str)
	local searchquery = string.gsub(str, "%S+%s", "", 1)	--Remove first word
	searchquery = string.gsub(searchquery, "%s", "+")	--Replace all whitespace with +
	local title,url = getURLTitle("http://www.google.com/search?q="..searchquery.."&btnI")	--Grab the URL and page title
	--Display both, or error if can't fetch
	if string.len(title) > 0 and string.len(url) > 0 then
		say(channel, '['..title..']'..' - '..url)
	else
		say(channel, "Unable to fetch link.")
	end
end

local function doaction(channel, str, user)
	local regexp = "%S+"	--Get command all the way until whitespace
	local act = string.sub(str, string.find(str, regexp));

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
		["search"] = function() search(channel, str) end,
		["google"] = function() search(channel, str) end,
		["8ball"] = function() eightball(channel) end,
		["eightball"] = function() eightball(channel) end,
		["eight"] = function() eightball(channel) end,
		["8"] = function() eightball(channel) end,
		["shake"] = function() eightball(channel) end,
		["cookie"] = function() botsnack(channel, act, user) end,
		["botsnack"] = function() botsnack(channel, act, user) end,
		["snack"] = function() botsnack(channel, act, user) end,
		["ex"] = function() insultex(channel, str, getnick()) end,
		default = function() end,
	}
	
	a:case(act)
end
setglobal("doaction", doaction)

local function saytitle(channel, url)
	local title, temp = getURLTitle(url)
	if string.len(title) > 0 then
		say(channel, "["..title.."]")
	end
end