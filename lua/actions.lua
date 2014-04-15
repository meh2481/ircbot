-- super awesome actions stuff

--TODO store this stuff in database on disk
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

setglobal("lastseen", lastseen)
setglobal("lastmessage", lastmessage)
setglobal("nicks", nicks)
setglobal("badwords", badwords)
setglobal("birdwords", birdwords)

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
	local upsec = os.clock()
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
	--sleep(math.random(5))
	local person = string.gsub(message, "%S+", "", 1)	--Remove first word
	person = string.gsub(person, "(%S+).*", "%1")	--Remove trailing words
	person = string.gsub(person, "%s", "")		--Remove whitespace
	if string.len(person)>0 then
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

local function quit(channel, user)
	if user == "Daxar" then
		saveall()
		done()
	else
		say(channel, "You wish.")
	end
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

local function addbad(channel, user, str)
	for word in str:gmatch("%S+") do 
		if word ~= "addbad" then
			rawget(_G, "badwords")[word] = 1
			rawget(_G, "badwords")[word.."s"] = 1
			rawget(_G, "badwords")[word.."es"] = 1
		end
	end
end

local function addbird(channel, user, str)
	for word in str:gmatch("%S+") do 
		if word ~= "addbird" then
			rawget(_G, "birdwords")[word] = 1
			rawget(_G, "birdwords")[word.."s"] = 1
			rawget(_G, "birdwords")[word.."es"] = 1
		end
	end
end

--[[local function getresult(cmd)
  local f = io.popen(cmd, 'r')
  if f then
	local s = f:read('*all')
	local rc = {f:close()}
	if rc then 
		return rc[3]
	end
  end
  return nil
end

local function heartbleed(channel, user, str)
	if channel ~= getchannel() then
		say(channel, "Please use this command on the main channel")
		return
	end
	local execline = string.gsub(str, "%S+%s", "", 1)	--Remove first word
	execline = string.gsub(execline, "(%S+).*", "%1")	--Remove trailing words
	execline = string.gsub(execline, "%s", "")			--Remove whitespace
	execline = string.gsub(execline, "https?://", "")	--Remove beginning of links
	execline = string.gsub(execline, "www%.", "")
	local safe = nil
	for test in string.gmatch(execline, "[%a%d:%.-]+") do 
		safe = test
		break
	end
	if safe and string.len(safe) > 0 then
		say(channel, "Testing "..safe.." for Heartbleed vulnerability")
		local result = getresult('Heartbleed \"'..safe..'\"')
		if result then 
			if result == 1 then
				say(channel, safe.." is at risk")
			elseif result == 2 then
				say(channel, "Unable to test "..safe)
			elseif result == 0 then
				say(channel, safe.." is safe")
			else
				print("Err: Unexpected result "..result)
			end
		else
			print("Err: Unable to test "..safe)
		end
	end
end--]]

local function removeword(channel, user, str)
	if user ~= "Daxar" or channel ~= getchannel() then
		say(channel, "Nope, not gonna do it.")
		--TODO: Log
		return
	end
	for word in str:gmatch("%S+") do 
		if word ~= "removeword" and word ~= "rmword" then
			--print("Removing "..word)
			rawget(_G, "badwords")[word] = nil
			rawget(_G, "badwords")[word.."s"] = nil
			rawget(_G, "badwords")[word.."es"] = nil
			rawget(_G, "birdwords")[word] = nil
			rawget(_G, "birdwords")[word.."s"] = nil
			rawget(_G, "birdwords")[word.."es"] = nil
			--print("word:",badwords[word])
		end
	end
end

local function doaction(channel, str, user)
	--Get command all the way until whitespace
	local act = string.sub(str, string.find(str, "%S+"))

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
		--[[["heartbleed"] = heartbleed,
		["bleed"] = 	heartbleed,
		["safe"] =		heartbleed,--]]
		--TODO: rps
	}
	
	local f = tab[act]
	if f then
		f(channel, user, str)
	end
end
setglobal("doaction", doaction)
