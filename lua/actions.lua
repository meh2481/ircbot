-- super awesome actions stuff

local lastseen = rawget(_G, ".lastseen"); 
if not lastseen then 
	lastseen = {}
	setglobal(".lastseen", lastseen) 
end

local lastmessage = rawget(_G, ".lastmessage")
if not lastmessage then 
	lastmessage = {}
	setglobal(".lastmessage", lastmessage) 
end

local nicks = rawget(_G, ".nicks")
if not nicks then 
	nicks = {}
	setglobal(".nicks", nicks) 
end

local badwords = rawget(_G, ".badwords")
if not badwords then 
	badwords = {}
	setglobal(".badwords", badwords) 
end

local birdwords = rawget(_G, ".birdwords")
if not birdwords then 
	birdwords = {}
	setglobal(".birdwords", birdwords) 
end

local starttime = rawget(_G, ".starttime")
if not starttime then
	starttime = os.time()
	setglobal(".starttime", starttime)
end

local insultadj1 = rawget(_G, ".insultadj1")
if not insultadj1 then
	insultadj1 = {}
	setglobal(".insultadj1", insultadj1)
end

local insultadj2 = rawget(_G, ".insultadj2")
if not insultadj2 then
	insultadj2 = {}
	setglobal(".insultadj2", insultadj2)
end

local insultnoun = rawget(_G, ".insultnoun")
if not insultnoun then
	insultnoun = {}
	setglobal(".insultnoun", insultnoun)
end

local totell = rawget(_G, ".totell")
if not totell then
	totell = {}
	setglobal(".totell", totell)
end

setglobal("lastseen", lastseen)
setglobal("lastmessage", lastmessage)
setglobal("nicks", nicks)
setglobal("badwords", badwords)
setglobal("birdwords", birdwords)
setglobal("starttime", starttime)
setglobal("insultadj1", insultadj1)
setglobal("insultadj2", insultadj2)
setglobal("insultnoun", insultnoun)
setglobal("totell", totell)

local function trim(s)
  return s:match'^%s*(.*%S)' or ''
end

local function seen(channel, user, message)
	--Get second word
	local person = trim(string.gsub(message, "(%S+)%s*(.+)", "%2"))
	if person == "straight" then
		say(channel, "The last time I saw straight was... Hey! I can see perfectly fine, thank you.")
	elseif rawget(_G, "lastseen")[string.lower(person)] then
		local diff = os.time() - rawget(_G, "lastseen")[string.lower(person)]
		local seconds = math.floor(diff % 60)
		local minutes = math.floor(diff / 60) % 60
		local hours = math.floor(diff / (60*60)) % 24
		local days = math.floor(diff / (60*60*24))
		say(channel, "I last saw "..person.." "..days.."d, "..hours.."h, "..minutes.."m, "..seconds.."s ago, "..rawget(_G, "lastmessage")[string.lower(person)])
	else
		say(channel, "I haven't seen "..person.." lately.")
	end
end

local function uptime(channel)
	local upsec = math.floor(os.time() - rawget(_G, "starttime"))
	local seconds = math.floor(upsec % 60)
	local minutes = math.floor(upsec / 60) % 60
	local hours = math.floor(upsec / (60*60)) % 24
	local days = math.floor(upsec / (60*60*24))
	say(channel, "Uptime: "..days.."d, "..hours.."h, "..minutes.."m, "..seconds.."s")
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

local function hug(channel, user, message)
	say(channel, "Setting phasors to hug.")
	local person = string.gsub(message, "%S+", "", 1)	--Remove first word
	person = string.gsub(person, "(%S+).*", "%1")	--Remove trailing words
	person = string.gsub(person, "%s", "")		--Remove whitespace
	if string.len(person) > 0 then
		if rawget(_G, "nicks")[string.lower(person)] then	--Person is here
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

local function GetRandomElement(a)
    return a[math.random(#a)]
end

local function insult(channel, message)
	local insultee = string.gsub(message, "%S+%s", "", 1)
	if insultee == "insult" then
		insultee = "Thou art"
	else
		insultee = insultee.." is"
	end
	local adj1 = GetRandomElement(rawget(_G, "insultadj1"))
	local adj2 = GetRandomElement(rawget(_G, "insultadj2"))
	local noun = GetRandomElement(rawget(_G, "insultnoun"))
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

local function isadmin(user)
	if user == "Daxar" then
		return true	--TODO: Admin list
	end
	return false
end

local function quit(channel, user)
	if isadmin(user) then
		saveall()
		done()
	else
		say(channel, "You wish.")
	end
end

local function search(channel, str)
	local searchquery = string.gsub(str, "%S+%s", "", 1)	--Remove first word
	searchquery = string.gsub(searchquery, "%s", "+")	--Replace all whitespace with +
	local title,url = gettitle("http://www.google.com/search?q="..searchquery.."&btnI")	--Grab the URL and page title
	--Display both, or error if can't fetch
	if string.len(title) > 0 and string.len(url) > 0 then
		say(channel, '['..title..']'..' - '..url)
	else
		say(channel, "Unable to fetch link.")
	end
end

local function lmgtfy(channel, user, str)
	local searchquery = string.gsub(str, "%S+%s", "", 1)	--Remove first word
	searchquery = string.gsub(searchquery, "%s", "+")	--Replace all whitespace with +
	say(channel, "http://lmgtfy.com/?q="..searchquery)	--Say the URL
end

local function addbad(channel, user, str)
	if not isadmin(user) then
		say(channel, "Nope, not gonna do it.")
		return
	end
	for word in str:gmatch("%S+") do 
		if word ~= "addbad" then
			rawget(_G, "badwords")[word] = 1
			rawget(_G, "badwords")[word.."s"] = 1
			rawget(_G, "badwords")[word.."es"] = 1
		end
	end
end

local function addbird(channel, user, str)
	if not isadmin(user) then
		say(channel, "Nope, not gonna do it.")
		return
	end
	for word in str:gmatch("%S+") do 
		if word ~= "addbird" then
			rawget(_G, "birdwords")[word] = 1
			rawget(_G, "birdwords")[word.."s"] = 1
			rawget(_G, "birdwords")[word.."es"] = 1
		end
	end
end

local function removeword(channel, user, str)
	if not isadmin(user) then
		say(channel, "Nope, not gonna do it.")
		return
	end
	for word in str:gmatch("%S+") do 
		if word ~= "removeword" and word ~= "rmword" then
			rawget(_G, "badwords")[word] = nil
			rawget(_G, "badwords")[word.."s"] = nil
			rawget(_G, "badwords")[word.."es"] = nil
			rawget(_G, "birdwords")[word] = nil
			rawget(_G, "birdwords")[word.."s"] = nil
			rawget(_G, "birdwords")[word.."es"] = nil
		end
	end
end

local function updates(channel)
	say(channel, "Get your unofficial update packs right here! http://www.bit-blot.com/forum/index.php?topic=4313.0");
end

local function sayline(channel, user, str)
	if not isadmin(user) then
		say(channel, "You don't have the privileges for this command.")
	else
		local phrase = string.gsub(str, "%S+%s", "", 1)
		say(getchannel(), phrase)
	end
end

local function sayact(channel, user, str)
	if not isadmin(user) then
		say(channel, "You don't have the privileges for this command.")
	else
		local phrase = string.gsub(str, "%S+%s", "", 1)
		action(getchannel(), phrase)
	end
end

local function randxkcd(channel)
	local title,url = gettitle("http://dynamic.xkcd.com/random/comic/")	--Grab the URL and page title of a random xkcd comic
	--Display both, or error if can't fetch
	if string.len(url) > 0 then
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
	person = string.gsub(person, "%s", "")		--Remove whitespace
	if rawget(_G, ".nicks")[person:lower()] then
		say(channel, "Tell them yourself.")
	else
		local whattosay = string.gsub(str, "%S+%s+%S+%s+", "", 1)
		local curstatement = rawget(_G, ".totell")[person:lower()]
		if curstatement then	--If someone already said something, tack onto end of message
			rawget(_G, ".totell")[person:lower()] = curstatement..", and "..user.." says "..whattosay
		else
			rawget(_G, ".totell")[person:lower()] = person..": "..user.." says "..whattosay
		end
	end
end

local help

local functab = {
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
	["cookie"] = 	function(channel, user) botsnack(channel, "cookie", user) end,
	["botsnack"] = 	function(channel, user) botsnack(channel, "botsnack", user) end,
	["snack"] = 	function(channel, user) botsnack(channel, "snack", user) end,
	["ex"] = 		function(channel) insult(channel, "derp Thy ex") end,
	["insult"] = 	function(channel, user, str) insult(channel, str) end,
	["uptime"] = 	uptime,
	["seen"] = 		seen,
	["hug"] =		hug,
	["quit"] =		quit,
	["save"] = 		saveall,
	["restore"] = 	restoreall,
	["addbad"] =	addbad,
	["addbird"] = 	addbird,
	["removeword"] = removeword,
	["rmword"] = 	removeword,
	["ping"] = 		function(channel) say(channel, "pong") end,
	["pong"] = 		function(channel) say(channel, "ping") end,
	["updates"] = 	updates,
	["update"] = 	updates,
	["help"] = 		function(channel, user, str) help(user, str) end,
	["say"] =		sayline,
	["me"] =		sayact,
	["act"] =		sayact,
	["action"] =	sayact,
	["xkcd"] =		randxkcd,
	["lmgtfy"] = 	lmgtfy,
	["tell"] =		settelluser,
}

local funchelp = {
	["beep"] = 		'displays a beep message',
	["d6"] = 		'rolls a 6-sided die and displays the result',
	["roll"] = 		'rolls a 6-sided die and displays the result',
	["dice"] = 		'rolls a 6-sided die and displays the result',
	["die"] = 		'rolls a 6-sided die and displays the result',
	["coin"] = 		'flips a coin and says heads or tails',
	["quarter"] = 	'flips a coin and says heads or tails',
	["flip"] =		'flips a coin and says heads or tails',
	["nickel"] = 	'flips a coin and says heads or tails',
	["dime"] = 		'flips a coin and says heads or tails',
	["penny"] = 	'flips a coin and says heads or tails',
	["bitcoin"] = 	'returns the current bitcoin mining complexity',
	["search"] = 	'searches Google for the given search query and returns the first result (\"I\'m Feeling Lucky\" search)',
	["google"] = 	'searches Google for the given search query and returns the first result (\"I\'m Feeling Lucky\" search)',
	["8ball"] = 	'shakes a Magic 8-ball and says the result',
	["eightball"] = 'shakes a Magic 8-ball and says the result',
	["eight"] = 	'shakes a Magic 8-ball and says the result',
	["8"] = 		'shakes a Magic 8-ball and says the result',
	["shake"] = 	'shakes a Magic 8-ball and says the result',
	["cookie"] = 	'feeds me a cookie',
	["botsnack"] = 	'feeds me a botsnack',
	["snack"] = 	'feeds me a snack',
	["ex"] = 		'insults thy ex in a Shakespearean manner',
	["insult"] = 	'insults anyone or anything in a Shakespearean manner (Usage: \"!insult [thing]\", or just \"!insult\" for thou)',
	["uptime"] = 	'displays how long I\'ve been running',
	["seen"] = 		'says the last time I saw a particular user (Usage: \"!seen [user]\")',
	["hug"] =		'hugs you or a particular user (Usage: \"!hug [user]\")',
	["quit"] =		'tells me to leave (ADMIN ONLY)',
	["addbad"] =	'adds a word to the curse word filter (ADMIN ONLY)',
	["addbird"] = 	'adds a bird to the bird word filter (ADMIN ONLY)',
	["removeword"] = 'removes a word from the bad and bird word filters (ADMIN ONLY)',
	["rmword"] = 	'removes a word from the bad and bird word filters (ADMIN ONLY)',
	["say"] =		'makes me say something (ADMIN ONLY)',
	["me"] =		'makes me say something (ADMIN ONLY)',
	["act"] =		'makes me say something (ADMIN ONLY)',
	["action"] =	'makes me say something (ADMIN ONLY)',
	["ping"] = 		'pongs if you\'re online',
	["pong"] = 		'pings if you\'re online',
	["updates"] = 	'links you to Aquaria\'s unofficial update packs',
	["update"] = 	'links you to Aquaria\'s unofficial update packs',
	["help"] = 		'displays this message',
	["xkcd"] =		'displays a random xkcd comic',
	["lmgtfy"] = 	'lets me google that for you',
	["tell"] = 		'gives a user a message next time they join (Usage: \"!tell [nick] [message]\")'
}

help = function(channel, str)
	local helptopic = string.gsub(str, "%S+", "", 1)	--Remove first word
	helptopic = string.gsub(helptopic, "(%S+).*", "%1")	--Remove trailing words
	helptopic = string.gsub(helptopic, "%s", "")		--Remove whitespace
	if helptopic:len() > 0 then
		--Help for a particular command
		local cmdhelp = funchelp[helptopic]
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
		for k in pairs(funchelp) do
			table.insert(ordered_functab, k)
			if k:len() > longestcommand then
				longestcommand = k:len()
			end
			length = length + 1
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
		
		say(channel, "Type \"!help [command]\" for an explanation of a particular command");
	end
end

local function doaction(channel, str, user)
	--Get command all the way until whitespace
	local act = string.sub(str, string.find(str, "%S+"))
	
	local f = functab[act]
	if f then
		f(channel, user, str)
	end
end
setglobal("doaction", doaction)
