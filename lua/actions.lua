-- super awesome actions stuff

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

local function hug(channel, message, user)
	say(channel, "Setting phasors to hug.")
	sleep(math.random(5))
	
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
	if count > 0 then
		local randomword = words[math.random(#words)]
		if randomword then
			say(channel, "Your ex is "..randomword)
		end
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

	local tab = {
		["beep"] = 		function(channel) say(channel, "Imma bot. Beep.") end,
		["d6"] = 		d6,
		["roll"] = 		d6,
		["dice"] = 		d6,
		["die"] = 		d6,
		["coin"] = 		coin,
		["quarter"] = 	coin,
		["flip"] =		coin,
		["nickel"] = 	coin,
		["dime"] = 		coin,
		["penny"] = 	coin,
		["bitcoin"] = 	getbitcoin,
		["search"] = 	function(channel, user, str) search(channel, str) end,
		["google"] = 	function(channel, user, str) search(channel, str) end,
		["8ball"] = 	eightball,
		["eightball"] = eightball,
		["eight"] = 	eightball,
		["8"] = 		eightball,
		["shake"] = 	eightball,
		["cookie"] = 	function(channel, user) botsnack(channel, act, user) end,
		["botsnack"] = 	function(channel, user) botsnack(channel, act, user) end,
		["snack"] = 	function(channel, user) botsnack(channel, act, user) end,
		["ex"] = 		function(channel, user, str) insultex(channel, str, getnick()) end,
	}
	
	local f = tab[act]
	if f then
		f(channel, user, str)
	end
end
setglobal("doaction", doaction)

local function saytitle(channel, url)
	local title, temp = getURLTitle(url)
	if string.len(title) > 0 then
		say(channel, "["..title.."]")
	end
end