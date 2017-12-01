-- super awesome actions stuff

local function trim(s)
  return s:match'^%s*(.*%S)' or ''
end
setglobal("trim", trim)

--Helper function from http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

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

local function insult(channel, user, message)
	local insultee = string.gsub(message, "%S+%s", "", 1)
	if insultee == "insult" then
		insultee = "Thou art"
	else
		insultee = insultee.." doth be"
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

local function define(channel, user, str, verbose)
	local word = str:gsub("%S+", "", 1)	--Remove first word
	word = word:gsub("(%S+).*", "%1")	--Remove trailing words
	if G_BADWORDS[word] then
		say(channel, "you perv")
		return
	end
	--Go to dictionaryapi.com to get your own key to use here (only 1000 accesses allowed per day per key)
	local searchURL = "http://www.dictionaryapi.com/api/v1/references/collegiate/xml/"..trim(word).."?key=78452540-8d68-4323-9964-9847af6158bf"
	if verbose then
		channel = user	--User is told definition in PM if we're spitting out ALL the definitions of a word
	end
	local success = defineWord(searchURL, channel, verbose)
	if not success then
		say(channel, "Unable to find word in dictionary")
	end
end

local lastprintedactive = os.time()

local function activeusers(channel, user, str)
	local person = string.gsub(str, "%S+", "", 1)	--Remove first word
	person = string.gsub(person, "(%S+).*", "%1")	--Remove trailing words
	person = string.gsub(person, "%s", "")			--Remove whitespace
	local number = tonumber(person)
	
	if string.len(person) < 1 or number ~= nil then
		if os.time() - lastprintedactive < 10 then return end	--Don't flood channel by doing this too often
		lastprintedactive = os.time()
		local total = 0
		local toprint = 5
		if number ~= nil then
			toprint = number
		end
		for k,v in spairs(G_NUMLINES,function(t,a,b) return t[b] < t[a] end) do
			say(channel, k.." = "..v)
			--print(k,v)
			total = total + 1
			if total >= toprint then break end
		end
	else
		local nummsg = G_NUMLINES[person:lower()]
		if nummsg == nil then
			say(channel, "I haven't seen "..person.."around here.")
		else
			say(channel, person.." has written "..nummsg.." lines here.")
		end
	end
end

local function tofarenheit(str, channel)
	local degrees = trim(str:gsub("%W(%-?%d*%.?%d*)%s*\xC2?\xB0?%s*[Cc]%W", "%1", 1))	--Remove all but numbers
	local Tc = tonumber(degrees)
	if Tc == nil then return end
	local Tf = (9/5)*Tc+32
	local Tfstr = string.format("%.2f", Tf)
	local Tfe = (7/5)*Tc+16
	local Tfestr = string.format("%.2f", Tfe)
	say(channel, Tc.." °C = "..Tfstr.." °F ("..Tfestr.." °Є)")
end
setglobal("tofarenheit", tofarenheit)

local function tocelsius(str, channel)
	local degrees = trim(str:gsub("%W(%-?%d*%.?%d*)%s*\xC2?\xB0?%s*[Ff]%W", "%1", 1))	--Remove all but numbers
	local Tf = tonumber(degrees)
	if Tf == nil then return end
	local Tc = (5/9)*(Tf-32)
	local Tcstr = string.format("%.2f", Tc)
	local Tfe = (Tf * 7 - 80) / 9
	local Tfestr = string.format("%.2f", Tfe)
	say(channel, Tf.." °F = "..Tcstr.." °C ("..Tfestr.." °Є)")
end
setglobal("tocelsius", tocelsius)

local function dotime(channel, str, military)
	local offset = G_TIMES["offset"]
	local curtime = os.date("*t")
	curtime.hour = curtime.hour - offset
	local total = 0
	for k,v in pairs(G_TIMES) do
		total = total + 1
	end
	local loop = 0
	local endstr = "Time in: "
	for k,v in pairs(G_TIMES) do
		loop = loop + 1
		if k == "offset" then
			-- do nothing
		else
			local hour = curtime.hour + v
			if hour < 0 then hour = hour + 24 end
			if hour > 24 then hour = hour - 24 end
			if military == false then
				local ampm = "am"
				if hour >= 12 then ampm = "pm" end
				if hour == 0 or hour == 24 then ampm = "am" hour = 12 end
				if hour > 12 then hour = hour - 12 end
				endstr = endstr..k..": "..hour..":"..string.format("%02d",curtime.min).." "..ampm
			else
				endstr = endstr..k..": "..string.format("%02d",hour)..":"..string.format("%02d",curtime.min)
			end
			if loop < total then
				endstr = endstr.." | "
			end
		end
	end
	if total > 1 then
		say(channel, endstr)
	else
		say(channel, "No times set")
	end
end

local function convert(channel, from, to, fac, str)
	local word = str:gsub("%S+", "", 1)	--Remove first word
	word = word:gsub("(%S+).*", "%1")	--Remove trailing words
	local unit = tonumber(word)	--Remove all but numbers
	if unit == nil then return end
	local result = unit * fac
	say(channel, unit.." "..from.." = "..result.." "..to)
end

local function fromcm(channel, user, str)
	convert(channel, "cm", "in", 0.393701, str)
end
setglobal("fromcm", fromcm)

local function frominches(channel, user, str)
	convert(channel, "in", "cm", 2.54, str)
end
setglobal("frominches", frominches)

local function fromfeet(channel, user, str)
	convert(channel, "ft", "m", 0.3048, str)
end
setglobal("fromfeet", fromfeet)

local function fromm(channel, user, str)
	convert(channel, "m", "ft", 3.28084, str)
end
setglobal("fromm", fromm)

local function fromkm(channel, user, str)
	convert(channel, "km", "mi", 0.621371, str)
end
setglobal("fromkm", fromkm)

local function frommiles(channel, user, str)
	convert(channel, "mi", "km", 1.60934, str)
end
setglobal("frommiles", frommiles)

local function fromkg(channel, user, str)
	convert(channel, "kg", "lb", 2.20462, str)
end
setglobal("fromkg", fromkg)

local function fromlb(channel, user, str)
	convert(channel, "lb", "kg", 0.453592, str)
end
setglobal("fromlb", fromlb)

local function fromg(channel, user, str)
	convert(channel, "g", "oz", 0.035274, str)
end
setglobal("fromg", fromg)

local function fromoz(channel, user, str)
	convert(channel, "oz", "g", 28.3495, str)
end
setglobal("fromoz", fromoz)

local function froml(channel, user, str)
	convert(channel, "l", "gal", 0.264172, str)
end
setglobal("froml", froml)

local function fromgal(channel, user, str)
	convert(channel, "gal", "l", 3.78541, str)
end
setglobal("fromgal", fromgal)

local function cursedesc(person, percent)
	for k,v in spairs(G_CURSERS,function(t,a,b) return t[b] < t[a] end) do
		if k == person then 
			return "Biggest Foulmouth"
		end
		break
	end
	
	if percent < 1 then
		return "Junior Foulmouth"
	end
	
	if percent > 5 then
		return "Senior Foulmouth"
	end
	
	return "Intermediate Foulmouth"
end

local lastprintedfoul = os.time()

local function foulmouth(channel, user, str)
	local person = string.gsub(str, "%S+", "", 1)	--Remove first word
	person = string.gsub(person, "(%S+).*", "%1")	--Remove trailing words
	person = string.gsub(person, "%s", "")			--Remove whitespace
	local number = tonumber(person)
	
	if string.len(person) < 1 or number ~= nil then
		if os.time() - lastprintedfoul < 10 then return end	--Don't flood channel by doing this too often
		lastprintedfoul = os.time()
		--Print biggest cursers
		local total = 0
		local toprint = 5
		if number ~= nil then
			toprint = number
		end
		for k,v in spairs(G_CURSERS,function(t,a,b) return t[b] < t[a] end) do
			say(channel, k.." has cursed "..v.." times")
			total = total + 1
			if total >= toprint then break end
		end
	else
		local numcurses = G_CURSERS[person:lower()]
		if numcurses == nil then
			say(channel, person.." has a mouth like an angel. Thanks, Mom!")
		else
			local nummsgs = G_NUMLINES[person:lower()]
			local percent = ((numcurses/nummsgs) * 100)
			local percentstr = string.format("%.3f", percent)
			say(channel, person.." has cursed a total of "..numcurses.." times, earning them the title of "..cursedesc(person:lower(), percent)..". "..percentstr.. "% of their messages contain foul language.")
		end
	end
end

local function anagram(channel, user, str)
	local searchquery = string.gsub(str, "%S+%s", "", 1)		--Remove first word
	searchquery = string.gsub(searchquery, "%s", "")			--Remove whitespace
	
	--wordsmith.org has an anagram thing yaaay!
	local webpageURL = "http://wordsmith.org/anagram/anagram.cgi?anagram="..searchquery.."&t=1000&a=n"
	
	--Grab the full webpage
	local webpage = wget(webpageURL)
	
	--Search for where on the webpage anagrams are placed...
	local datastartStr = "Displaying all:"
	local substrpos = string.find(webpage, datastartStr)
	if substrpos == nil then
		say(channel, "No anagrams of "..searchquery.." exist.")
		return
	end
	
	webpage = string.sub(webpage, substrpos + string.len(datastartStr))	-- Strip off start of file
	webpage = string.sub(webpage, 1, string.find(webpage, "</div>")-1)	-- Strip off end of file
	webpage = string.gsub(webpage, "%c", "")	-- Strip out newlines
	webpage = string.gsub(webpage, "</b><br>", "")	-- Strip out first break
	webpage = string.sub(webpage, 1, string.find(webpage, "<br>", -5)-1)	-- Cut out last <br> symbol
	webpage = string.gsub(webpage, "<br>", ", ")	-- Make next newlines spaces to form a good list
	
	say(channel, "Anagrams for "..searchquery..": "..webpage)	
end

local function roll(channel, user, str)
	str = string.gsub(str, "%S+%s", "", 1)		--Remove first word
	
	local dpos = string.find(str, "d")
	if dpos == nil then
		say(channel, "Rolling a d20: "..math.random(20))
		return
	end
	
	local numdice = string.sub(str, 1, dpos-1)
	numdice = string.gsub(numdice, "%s", "")
	local dicesides = string.sub(str, dpos+1)
	dicesides = string.gsub(dicesides, "%s", "")
	
	--Error-check input
	if string.len(numdice) > 0 then
		numdice = tonumber(numdice)
	else
		numdice = 1
	end
	if string.len(dicesides) > 0 then
		dicesides = tonumber(dicesides)
	else
		dicesides = 20	-- Roll a d20 by default
	end
	
	if numdice == 0 or dicesides == 0 then return end
	
	local total = 0
	local numstr = " ("
	for i=1,numdice do
		local rolled = math.random(dicesides)
		total = total + rolled
		numstr = numstr..rolled.." "
	end
	numstr = string.sub(numstr, 1, -2)..")"
	
	if numdice < 2 then
		numstr = ""
	end
	
	say(channel, "Rolling "..numdice.."d"..dicesides..": "..total..numstr)
end

local COMPADJ1 = {
	"rare",
	"sugared",
	"precious",
	"dutiful",
	"damasked",
	"flowering",
	"gallant",
	"celestial",
	"sweet",
	"saucy",
	"sportful",
	"artful",
	"heavenly",
	"yarely",
	"tuneful",
	"courteous",
	"delicate",
	"silken",
	"brave",
	"complete",
	"vasty",
	"pleasing",
	"cheek-rosy",
	"deserving",
	"melting",
	"wholesome",
	"fruitful",
}

local COMPADJ2 = {
	"honey-tongued",
	"well-wishing",
	"berhyming",
	"fair-faced",
	"five-fingered-tied",
	"heart-inflaming",
	"not-answering",
	"spleenative",
	"softly-sprighted",
	"smooth-faced",
	"sweet-suggesting",
	"swinge-buckling",
	"tender-hearted",
	"tender-feeling",
	"thunder-darting",
	"tiger-booted",
	"lustyhooded",
	"welsh",
	"superstitious",
	"sympathizing",
	"sweet-tongued",
	"weeping-ripe",
	"well-favoured",
	"young-eyed",
	"primrose",
	"best-tempered",
	"well-graced",
}

local COMPNOUN = {
	"nymph",
        "ornament",
        "toast",
        "curiosity",
        "apple-john",
        "bilbo",
        "cuckoo-bud",
        "nose-herb",
        "gamester",
        "ouch",
        "goddess",
        "night-cap",
        "delight",
        "watercake",
        "umpire",
        "sprite",
        "song",
        "welsh cheese",
        "kissing-comfit",
        "wit-cracker",
        "hawthorn-bud",
        "valentine",
        "smilet",
        "true-penny",
        "primrose path",
        "gaudy-night",
        "pigeon-egg",
}

local function compliment(channel, user, message)
	local insultee = string.gsub(message, "%S+%s", "", 1)
	if insultee == "insult" then
		insultee = "Thou art"
	else
		insultee = insultee.." doth be"
	end
	local adj1 = COMPADJ1[math.random(#COMPADJ1)]
	local adj2 = COMPADJ2[math.random(#COMPADJ2)]
	local noun = G_INSULTNOUN[math.random(#G_INSULTNOUN)]
	local pt1 = " a "
	if string.find("aeiou", adj1:sub(1,1)) then
		pt1 = " an "	--If first adjective starts with vowel, use proper grammar
	end
	say(channel, insultee..pt1..adj1..", "..adj2.." "..noun)
end

local help

local functab = {
	["barf"] =              function(channel) say(channel, "BLEEEEEEEEEHHHHHH") end,
	["beep"] = 		function(channel) say(channel, "Imma bot. Beep.") end,
	["d6"] = 		d6,
	["coin"] = 		coin,
	["bitcoin"] = 	getbitcoin,
	["google"] = 	googlesearch,
	["8ball"] = 	eightball,
	["cookie"] = 	function(channel, user) botsnack(channel, "cookie", user) end,
	["botsnack"] = 	function(channel, user) botsnack(channel, "botsnack", user) end,
	["snack"] = 	function(channel, user) botsnack(channel, "snack", user) end,
	["ex"] = 		function(channel) insult(channel, "PAD", "PAD Thy ex") end,
	["insult"] = 	insult,
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
	["define"] = 	function(channel, user, str) define(channel, user, str, false) end,
	["dictionary"] = 	function(channel, user, str) define(channel, user, str, true) end,
	["active"] =	activeusers,
	["like"] =	function(channel) say(channel, "I don\'t know half of you half as well as I should like; and I like less than half of you half as well as you deserve.") end,
	["time"] = function(channel, user, str) dotime(channel, str, false) end,
	["timem"] = function(channel, user, str) dotime(channel, str, true) end,
	
	["cm"] = fromcm,
	["centimeters"] = fromcm,
	["in"] = frominches,
	["inches"] = frominches,
	["ft"] = fromfeet,
	["feet"] = fromfeet,
	["m"] = fromm,
	["meters"] = fromm,
	["km"] = fromkm,
	["kilometers"] = fromkm,
	["mi"] = frommiles,
	["miles"] = frommiles,
	
	["kg"] = fromkg,
	["kilograms"] = fromkg,
	["lb"] = fromlb,
	["pounds"] = fromlb,
	["g"] = fromg,
	["grams"] = fromg,
	["oz"] = fromoz,
	["ounces"] = fromoz,
	
	["l"] = froml,
	["liters"] = froml,
	["gal"] = fromgal,
	["gallons"] = fromgal,
	--["addtime"] = function(channel, user, str) addtime(channel,str) end,
	["foulmouth"] = foulmouth,
	["anagram"] = anagram,
	["roll"] = roll,
	["compliment"] = compliment,
	["mama"] = function(channel) compliment(channel, "PAD", "PAD Thy mother") end,
}

local funchelp = {
	["beep"] = 		'displays a beep message',
	["barf"] =              'does what it says on the tin',
	["d6"] = 		'rolls a 6-sided die and displays the result',
	["coin"] = 		'flips a coin and says heads or tails',
	["bitcoin"] = 	'returns the current bitcoin mining complexity',
	["search"] = 	'searches Google for the given search query and returns the first result (\"I\'m Feeling Lucky\" search)',
	["wp"] =		'searches Wikipedia for the given search query',
	["8ball"] = 	'shakes a Magic 8-ball and says the result',
	["cookie"] = 	'feeds me a cookie',
	["botsnack"] = 	'feeds me a botsnack',
	["snack"] = 	'feeds me a snack',
	["ex"] = 		'insults thy ex in a Shakespearean manner',
	["insult"] = 	'insults anyone or anything in a Shakespearean manner (Usage: \"!insult [thing]\", or just \"!insult\" for thou)',
	["compliment"] = 'compliments anyone or anything in a Shakespearean manner (Usage: \"!compliment [thing]\", or just \"!compliment\" for thou)',
	["mama"] = 'compliments thy mama in a Shakespearean manner',
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
	["define"] =	'tells you the most common meaning of a word',
	["dictionary"] =	'looks up a word in the dictionary (verbose)',
	["active"] = 	'[user|number] lists the [number] most active users, or tells how active a user is',
	["like"] =		'explains how I truly feel about you',
	["time"] =		'displays the current time in different timezones',
	["timem"] =		'displays the current time in different timezones, 24-hour format',
	["[unit]"] =	'converts between US and metric units (Example: \"!km [kilometers]\", outputs in miles)',
	["foulmouth"] = 	'[user|number] tells you how many times [user] has been slapped for their foul language, or gives the top [number] of foul mouths',
	["anagram"] = 	'[word(s)] outputs a list of anagrams for the given word or words',
	["roll"] = 		'[XdY] simulates rolling X dice with Y sides',
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
	local found = str:find("%S+")
	local act
	if found then
		local temp = str:find("%s")
		if temp then
			act = str:sub(found, temp-1)
		else
			act = str:sub(found)
		end
		if act then act = act:lower() end
	end
	if act then
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
end
setglobal("doaction", doaction)
