-- super awesome actions stuff

if not G_LASTSEEN then 
	G_LASTSEEN = {}
end

if not G_LASTMESSAGE then 
	G_LASTMESSAGE = {}
end

if not G_NICKS then 
	G_NICKS = {}
end

if not G_BADWORDS then 
	G_BADWORDS = {}
end

if not G_BIRDWORDS then 
	G_BIRDWORDS = {}
end

if not G_STARTTIME then
	G_STARTTIME = os.time()
end

if not G_INSULTADJ1 then
	G_INSULTADJ1 = {}
end

if not G_INSULTADJ2 then
	G_INSULTADJ2 = {}
end

if not G_INSULTNOUN then
	G_INSULTNOUN = {}
end

if not G_TOTELL then
	G_TOTELL = {}
end

if not G_RSSFEEDS then
	G_RSSFEEDS = {}
end

local function trim(s)
  return s:match'^%s*(.*%S)' or ''
end

local function seen(channel, user, message)
	--Get second word
	local person = trim(string.gsub(message, "(%S+)%s*(.+)", "%2"))
	if person == "straight" then
		say(channel, "The last time I saw straight was... Hey! I can see perfectly fine, thank you.")
	elseif person == getnick() then
		action(channel, "finds mirror")
		say(channel, "Oh, who IS that good-looking bot I see?")
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
	local adj1 = GetRandomElement(G_INSULTADJ1)
	local adj2 = GetRandomElement(G_INSULTADJ2)
	local noun = GetRandomElement(G_INSULTNOUN)
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

local function nickservget(cmd, msg)
	if cmd == "NOTICE" then
		local person = trim(msg:gsub("(%S+)%s*(%S+)%s*(%S+).*", "%1"))	--Get person (First field)
		local acc = trim(msg:gsub("(%S+)%s*(%S+)%s*(%S+).*", "%2"))		--Get second field (Should be "ACC")
		local val = trim(msg:gsub("(%S+)%s*(%S+)%s*(%S+).*", "%3"))		--Get value to see if user is registered or not
		
		say(getchannel(), "|"..person.."|"..acc.."|"..val.."|")
		if acc == "ACC" and val == "3" then
			
		end
	end
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

local function addbad(channel, user, str)
	if not isadmin(user) then
		say(channel, "Nope, not gonna do it.")
		return
	end
	for word in str:gmatch("%S+") do 
		if word ~= "addbad" then
			G_BADWORDS[word] = 1
			G_BADWORDS[word.."s"] = 1
			G_BADWORDS[word.."es"] = 1
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
			G_BIRDWORDS[word] = 1
			G_BIRDWORDS[word.."s"] = 1
			G_BIRDWORDS[word.."es"] = 1
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
			G_BADWORDS[word] = nil
			G_BADWORDS[word.."s"] = nil
			G_BADWORDS[word.."es"] = nil
			G_BIRDWORDS[word] = nil
			G_BIRDWORDS[word.."s"] = nil
			G_BIRDWORDS[word.."es"] = nil
		end
	end
end

local function updates(channel)
	say(channel, "Get your unofficial update packs right here! http://www.bit-blot.com/forum/index.php?topic=4313.0")
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
	person = string.gsub(person, "%s", "")		--Remove whitespace
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

local function addrss(channel, user, str)
	if not isadmin(user) then
		say(channel, "You don't have the privileges for this command.")
	else
		local feedurl = string.gsub(str, "%S+", "", 1)			--Remove first word
		feedurl = string.gsub(feedurl, "(%S+).*", "%1")			--Remove trailing words
		feedurl = string.gsub(feedurl, "%s", "")				--Remove whitespace
		local feedtitle,itemtitle,url = getLatestRSS(feedurl)	--Make sure this feed is valid
		if feedtitle and itemtitle and url and feedtitle:len() > 0 and itemtitle:len() > 0 and url:len() > 0 then
			G_RSSFEEDS[feedurl] = "["..feedtitle.."] "..itemtitle.." -- "..url
		else
			say(channel, "Invalid feed URL")
		end
	end
end

local function checkrss()
	for key, val in pairs(G_RSSFEEDS) do
		local feedtitle,itemtitle,url = getLatestRSS(key)
		if feedtitle and itemtitle and url and feedtitle:len() > 0 and itemtitle:len() > 0 and url:len() > 0 then
			local result = "["..feedtitle.."] "..itemtitle.." -- "..url
			if result ~= val then
				G_RSSFEEDS[key] = result
				say(getchannel(), result)	--New feed update; say so
			end
		end
	end
end
setglobal("checkrss", checkrss)

local function joinchannel(channel, user, str)
	if not isadmin(user) then
		say(channel, "You don't have the privileges for this command.")
	else
		local chan = trim(str:gsub("%S+", "", 1))	--Remove first word
		join(chan)
	end
end

local function testfunc(channel, user, str)
	raw("PRIVMSG NickServ :acc Daxar\r\n")
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
	["search"] = 	googlesearch,
	["google"] = 	googlesearch,
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
	["wp"] = 		wikisearch,
	["addrss"] = 	addrss,
	["checkrss"] = 	checkrss,
	["test"] = 		testfunc,
	["join"] =		joinchannel,
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
	["wp"] =		'searches Wikipedia for the given search query',
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
	["tell"] = 		'gives a user a message next time they join (Usage: \"!tell [nick] [message]\")',
	["addrss"] =	'adds a feed to the RSS reader (ADMIN ONLY)',
	["checkrss"] = 	'forces a check of all RSS feeds (happens automatically every 5 minutes)',
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
		
		say(channel, "Type \"!help [command]\" for an explanation of a particular command")
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