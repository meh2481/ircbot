-- super awesome actions stuff

local function trim(s)
  return s:match'^%s*(.*%S)' or ''
end
setglobal("trim", trim)

local function seen(channel, user, message)
	--Get second word
	local person = trim(string.gsub(message, "(%S+)%s*(.+)", "%2"))
	if person == "straight" then
		say(channel, "The last time I saw straight was... Hey! I can see perfectly fine, thank you.")
	elseif person == getnick() then
		action(channel, "finds mirror")
		say(channel, "Oh, who IS that handsome fellow?")
	elseif G_LASTSEEN[string.lower(person)] then
		local diff = os.time() - G_LASTSEEN[string.lower(person)]
		local seconds = math.floor(diff % 60)
		local minutes = math.floor(diff / 60) % 60
		local hours = math.floor(diff / (60*60)) % 24
		local days = math.floor(diff / (60*60*24))
		say(channel, "I last saw "..person.." "..days.."d, "..hours.."h, "..minutes.."m, "..seconds.."s ago, "..G_LASTMESSAGE[string.lower(person)])
	else
		say(channel, "I haven't seen "..person.." lately.")
	end
end

local function uptime(channel)
	local upsec = math.floor(os.time() - G_STARTTIME)
	local seconds = math.floor(upsec % 60)
	local minutes = math.floor(upsec / 60) % 60
	local hours = math.floor(upsec / (60*60)) % 24
	local days = math.floor(upsec / (60*60*24))
	say(channel, "Uptime: "..days.."d, "..hours.."h, "..minutes.."m, "..seconds.."s")
end

local function eightball(channel)
	local results = {
		"It is certain",
		"It is decidedly so",
		"Without a doubt",
		"Definitely",
		"You may rely on it",
		"As I see it, yes",
		"Most likely",
		"Outlook good",
		"Yes",
		"Signs point to yes",
		"Reply hazy. Try again",
		"Ask again later",
		"I'd better not tell you now",
		"Cannot predict now",
		"Concentrate and ask again",
		"Don't count on it",
		"No",
		"My sources say no",
		"Outlook not so good",
		"Very doubtful",
	}
	say(channel, results[math.random(#results)])
end

local function hug(channel, user, message)
	say(channel, "Setting phasors to hug.")
	local person = string.gsub(message, "%S+", "", 1)	--Remove first word
	person = string.gsub(person, "(%S+).*", "%1")	--Remove trailing words
	person = string.gsub(person, "%s", "")		--Remove whitespace
	if string.len(person) > 0 then
		if G_NICKS[string.lower(person)] then	--Person is here
			action(channel, "hugs "..person.." a little too tightly")
		else
			local halfperson = string.sub(person, 0, -math.ceil(string.len(person)/2))
			action(channel, "hugs "..halfperson.."...")
			sleep(2)
			say(channel, person.." isn't here!")
			sleep(1)
			action(channel, "flops onto couch and sighs dejectedly")
		end
	else
		action(channel, "hugs "..user.." a little too tightly")
	end
end

local function botsnack(channel, act, user)
	--Some kid's starving in Japan, so just eat it
	local eatit = {
		"happily grabs "..act.." from "..user.." and runs away to bury it",
		"grabs "..act.." and scarfs it down hungrily",
		"goes om nom nom",
	}
	action(channel, eatit[math.random(#eatit)])
end

local function insult(channel, message)
	local insultee = string.gsub(message, "%S+%s", "", 1)
	if insultee == "insult" then
		insultee = "Thou art"
	else
		insultee = insultee.." is"
	end
	local adj1 = G_INSULTADJ1[math.random(#G_INSULTADJ1)]
	local adj2 = G_INSULTADJ2[math.random(#G_INSULTADJ2)]
	local noun = G_INSULTNOUN[math.random(#G_INSULTNOUN)]
	local pt1 = " a "
	if string.find("aeiou", adj1:sub(1,1)) then
		pt1 = " an "	--If first adjective starts with vowel, use proper grammar
	end
	say(channel, insultee..pt1..adj1..", "..adj2.." "..noun)
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

local function gettitle(url)
	local unformatted,page = getURLTitle(url)
	unformatted = trim(unformatted:gsub("\r",""):gsub("\n",""))	--Remove whitespace and newlines
	local formatted = unformatted
	for special in unformatted:gmatch("&#%d+;") do	--Parse &#nnnn; numbers back to characters (TODO: HTML-special characters also)
		local val = string.gsub(special, "&#(%d+);", "%1")
		formatted = formatted:gsub(special, string.char(val))
	end
	return formatted,page
end
setglobal("gettitle", gettitle)

local function getbitcoin(channel)
	local diff, temp = gettitle("http://bitcoindifficulty.com/")
	say(channel, diff)
end

local function search(channel, str, startstr, endstr)
	local searchquery = string.gsub(str, "%S+%s", "", 1)		--Remove first word
	searchquery = string.gsub(searchquery, "%s", "+")			--Replace all whitespace with +
	local title,url = gettitle(startstr..searchquery..endstr)	--Grab the URL and page title
	--Display both, or error if can't fetch
	if string.len(title) > 0 and string.len(url) > 0 then
		say(channel, '['..title..']'..' - '..url)
	else
		say(channel, "Unable to fetch link.")
	end
end

local function googlesearch(channel, user, str)
	search(channel, str, "http://www.google.com/search?q=", "&btnI")
end

local function lmgtfy(channel, user, str)
	local searchquery = string.gsub(str, "%S+%s", "", 1)	--Remove first word
	searchquery = string.gsub(searchquery, "%s", "+")	--Replace all whitespace with +
	say(channel, "http://lmgtfy.com/?q="..searchquery)	--Say the URL
end

local function randxkcd(channel)
	local title,url = gettitle("http://dynamic.xkcd.com/random/comic/")	--Grab the URL and page title of a random xkcd comic
	if url and string.len(url) > 0 then
		local xtitle = gettitle(url)	--For some reason, the title breaks, so fetch again
		if string.len(xtitle) > 0 then
			say(channel, '['..xtitle..']'..' - '..url)
		else
			say(channel, "Unable to fetch link.")
		end
	else
		say(channel, "Unable to fetch link.")
	end
end

local function settelluser(channel, user, str)
	local person = string.gsub(str, "%S+", "", 1)	--Remove first word
	person = string.gsub(person, "(%S+).*", "%1")	--Remove trailing words
	person = string.gsub(person, "%s", "")			--Remove whitespace
	if G_NICKS[person:lower()] then
		say(channel, "Tell them yourself.")
	else
		local whattosay = string.gsub(str, "%S+%s+%S+%s+", "", 1)
		local curstatement = G_TOTELL[person:lower()]
		if curstatement then	--If someone already said something, tack onto end of message
			G_TOTELL[person:lower()] = curstatement..", and "..user.." says "..whattosay
		else
			G_TOTELL[person:lower()] = person..": "..user.." says "..whattosay
		end
	end
end

local function wikisearch(channel, user, str)
	search(channel, str, "http://en.wikipedia.org/wiki/Special:Search?search=", "&go=Go")
end


local function updates(channel)
	say(channel, "Get your unofficial update packs right here! http://www.bit-blot.com/forum/index.php?topic=4313.0")
end

local help

local functab = {
	["beep"] = 		function(channel) say(channel, "Imma bot. Beep.") end,
	["d6"] = 		d6,
	["dice"] = 		d6,
	["coin"] = 		coin,
	["bitcoin"] = 	getbitcoin,
	["search"] = 	googlesearch,
	["google"] = 	googlesearch,
	["8ball"] = 	eightball,
	["cookie"] = 	function(channel, user) botsnack(channel, "cookie", user) end,
	["botsnack"] = 	function(channel, user) botsnack(channel, "botsnack", user) end,
	["snack"] = 	function(channel, user) botsnack(channel, "snack", user) end,
	["ex"] = 		function(channel) insult(channel, "derp Thy ex") end,
	["insult"] = 	function(channel, user, str) insult(channel, str) end,
	["uptime"] = 	uptime,
	["seen"] = 		seen,
	["hug"] =		hug,
	["save"] = 		saveall,
	["restore"] = 	restoreall,
	["ping"] = 		function(channel) say(channel, "pong") end,
	["pong"] = 		function(channel) say(channel, "ping") end,
	["updates"] = 	updates,
	["update"] = 	updates,
	["help"] = 		function(channel, user, str) testadmin_thenfunc(channel, user, str, help) end,
	["xkcd"] =		randxkcd,
	["lmgtfy"] = 	lmgtfy,
	["tell"] =		settelluser,
	["wp"] = 		wikisearch,
	["picnic"] =	function(channel) say(channel, "[Problem In Chair, Not In Computer] - http://en.wikipedia.org/wiki/User_error") end,
}

local funchelp = {
	["beep"] = 		'displays a beep message',
	["d6"] = 		'rolls a 6-sided die and displays the result',
	["dice"] = 		'rolls a 6-sided die and displays the result',
	["coin"] = 		'flips a coin and says heads or tails',
	["bitcoin"] = 	'returns the current bitcoin mining complexity',
	["search"] = 	'searches Google for the given search query and returns the first result (\"I\'m Feeling Lucky\" search)',
	["google"] = 	'searches Google for the given search query and returns the first result (\"I\'m Feeling Lucky\" search)',
	["wp"] =		'searches Wikipedia for the given search query',
	["8ball"] = 	'shakes a Magic 8-ball and says the result',
	["cookie"] = 	'feeds me a cookie',
	["botsnack"] = 	'feeds me a botsnack',
	["snack"] = 	'feeds me a snack',
	["ex"] = 		'insults thy ex in a Shakespearean manner',
	["insult"] = 	'insults anyone or anything in a Shakespearean manner (Usage: \"!insult [thing]\", or just \"!insult\" for thou)',
	["uptime"] = 	'displays how long I\'ve been running',
	["seen"] = 		'says the last time I saw a particular user (Usage: \"!seen [user]\")',
	["hug"] =		'hugs you or a particular user (Usage: \"!hug [user]\")',
	["ping"] = 		'pongs if you\'re online',
	["pong"] = 		'pings if you\'re online',
	["updates"] = 	'links you to Aquaria\'s unofficial update packs',
	["update"] = 	'links you to Aquaria\'s unofficial update packs',
	["help"] = 		'displays this message',
	["xkcd"] =		'displays a random xkcd comic',
	["lmgtfy"] = 	'lets me google that for you',
	["tell"] = 		'gives a user a message next time they join (Usage: \"!tell [nick] [message]\")',
	["picnic"] = 	'alerts the user as to what REALLY is the problem',
}

help = function(unused, channel, str, admin)
	local helptopic = string.gsub(str, "%S+", "", 1)	--Remove first word
	helptopic = string.gsub(helptopic, "(%S+).*", "%1")	--Remove trailing words
	helptopic = string.gsub(helptopic, "%s", "")		--Remove whitespace
	if helptopic:len() > 0 and helptopic ~= "admin" and helptopic ~= "user" then
		--Help for a particular command
		local cmdhelp = funchelp[helptopic]
		if not cmdhelp and admin then cmdhelp = adminfunchelp[helptopic] end
		if cmdhelp then
			say(channel, "The \"!"..helptopic.."\" command "..cmdhelp)
		else
			say(channel, "\"!"..helptopic.."\" isn't a command I recognize, sorry.")
		end
	else
		--Print supported commands
		say(channel, "Supported commands are:")
		local num = 1				--Number of commands we're printing this loop
		local maxnum = 6			--Maximum number of commands to print in a single loop
		local length = 0			--How many items total are in the table
		local longestcommand = 0	--Longest command
		local printstr = ""			--String to print this loop
		
		--Sort function table by name
		local ordered_functab = {}
		if helptopic ~= "admin" or not admin then
			for k in pairs(funchelp) do
				table.insert(ordered_functab, k)
				if k:len() > longestcommand then
					longestcommand = k:len()
				end
				length = length + 1
			end
		end
		if admin and helptopic ~= "user" then
			for k in pairs(adminfunchelp) do
				table.insert(ordered_functab, k)
				if k:len() > longestcommand then
					longestcommand = k:len()
				end
				length = length + 1
			end
		end
		table.sort(ordered_functab)
		
		--Iterate over sorted table
		for i = 1, length do
			local funcname = ordered_functab[i]
			printstr = printstr..funcname
			for i = funcname:len(), longestcommand + 1 do	--Force tab sorta thing by hand
				printstr = printstr.." "
			end
			num = num + 1
			--If we're long enough, go ahead and print
			if num > maxnum then
				say(channel, printstr)
				num = 1
				printstr = ""
			end
		end
		
		--Print any leftover commands
		if printstr:len() then
			say(channel, printstr)
		end
		
		if not (helptopic:len() > 0) then
			say(channel, "Type \"!help [command]\" for an explanation of a particular command")
			if admin then
				say(channel, "Type \"!help user\" for user-only commands, or \"!help admin\" for admin-only commands")
			end
		end
	end
end

local function doaction(channel, str, user)
	--Get command all the way until whitespace
	local act = string.sub(str, string.find(str, "%S+"))
	
	local f = functab[act]
	if f then
		f(channel, user, str, nil)
	else
		f = adminfunctab[act]
		if f then
			testadmin_thenfunc(channel, user, str, f)
		end
	end
end
setglobal("doaction", doaction)