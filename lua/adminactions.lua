-- Admin-only commands

local l_f
local l_c
local l_u
local l_s

local function nickservget(cmd, msg)
	if cmd == "NOTICE" then
		local person = trim(msg:gsub("(%S+)%s*(%S+)%s*(%S+).*", "%1"))	--Get person (First field)
		local acc = trim(msg:gsub("(%S+)%s*(%S+)%s*(%S+).*", "%2"))		--Get second field (Should be "ACC")
		local val = trim(msg:gsub("(%S+)%s*(%S+)%s*(%S+).*", "%3"))		--Get value to see if user is registered or not
		
		if l_f and person == l_u and acc == "ACC" then
			if val == "3" then
				l_f(l_c, l_u, l_s, true)
			else
				l_f(l_c, l_u, l_s, false)
			end
		end
		l_f = nil
		l_c = nil
		l_u = nil
		l_s = nil
	end
end
setglobal("nickservget", nickservget)

local function testadmin_thenfunc(channel, user, str, func)
	if G_ADMINS[user:lower()] then
		say("NickServ", "acc "..user)
		l_f = func
		l_c = channel
		l_u = user
		l_s = str
	else
		func(channel, user, str, false)	--Not on our admin list
	end
end
setglobal("testadmin_thenfunc", testadmin_thenfunc)

local function err_notadmin(channel)
	say(channel, "You don't have the privileges for this command.")
end

local function quit(channel, user, str, admin)
	if admin then
		saveall()
		LOGFILE:close()
		done()
	else
		say(channel, "You wish.")
	end
end

local function reloadlater(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		reload()
	end
end

local function rmrss(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		local feedurl = string.gsub(str, "%S+", "", 1)			--Remove first word
		feedurl = string.gsub(feedurl, "(%S+).*", "%1")			--Remove trailing words
		feedurl = string.gsub(feedurl, "%s", "")				--Remove whitespace
		G_RSSFEEDS[feedurl] = nil
	end
end

local function partchannel(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		raw("PART "..channel.."\r\n");
	end
end

local function joinchannel(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		local chan = trim(str:gsub("%S+", "", 1))	--Remove first word
		join(chan)
	end
end

local function addadmin(channel, user, str, admin)
	local admintoadd = trim(str:gsub("%S+", "", 1))
	if not admin then
		err_notadmin(channel)
	else
		G_ADMINS[admintoadd:lower()] = true		--Add admin to our list
		say(channel, "Added.")
	end
end

local function rmadmin(channel, user, str, admin)
	local admintoremove = trim(str:gsub("%S+", "", 1))
	if not admin or admintoremove == G_DEV then
		err_notadmin(channel)
	else
		G_ADMINS[admintoremove:lower()] = nil	--Remove admin from list
		say(channel, "Removed.")
	end
end

local function addrss(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
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

local function addbad(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		for word in str:gmatch("%S+") do 
			if word ~= "addbad" then
				G_BADWORDS[word] = 1
				G_BADWORDS[word.."s"] = 1
				G_BADWORDS[word.."es"] = 1
			end
		end
	end
end

local function addbird(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		for word in str:gmatch("%S+") do 
			if word ~= "addbird" then
				G_BIRDWORDS[word] = 1
				G_BIRDWORDS[word.."s"] = 1
				G_BIRDWORDS[word.."es"] = 1
			end
		end
	end
end

local function removeword(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
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
end

local function sayline(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		local phrase = string.gsub(str, "%S+%s", "", 1)
		say(getchannel(), phrase)
	end
end

local function sayact(channel, user, str, admin)
	if not admin then
		err_notadmin(channel)
	else
		local phrase = string.gsub(str, "%S+%s", "", 1)
		action(getchannel(), phrase)
	end
end

local function testfunc(channel, user, str, admin)
	if admin then
		for item,val in pairs(G_ADMINS) do
			print(item,val)
		end
	end
end

local function checkrss(channel, user, str, admin)
	if admin == true or admin == nil then
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
		--checktwitter(getchannel())	--Check twitter feeds while we're at it
	end
end
setglobal("checkrss", checkrss)

local function addtime(channel, user, str, admin)
	if admin == true then
		local name = str:gsub("%S+", "", 1)	--Remove first word
		name = name:gsub("(%S+).*", "%1")	--Remove trailing words
		name = name:gsub("%s+", "")	--Remove whitespace
		local houroffset = str:gsub("%S+", "", 2) --Remove first two words
		houroffset = houroffset:gsub("%s+", "")	--Remove whitespace
		G_TIMES[name] = tonumber(houroffset)
		setglobal("G_TIMES", G_TIMES)
	end
end

local function nickname(channel, user, str, admin)
	if admin == true then
		local name = str:gsub("%S+", "", 1)	--Remove first word
		name = name:gsub("(%S+).*", "%1")	--Remove trailing words
		name = name:gsub("%s+", "")	--Remove whitespace
		raw("USER "..name.." 0 0 :"..name.."\r\n");
		raw("NICK "..name.."\r\n");
	end
end

local function checktweetybird(channel, user, str, admin)
	if admin == true then
		checktwitter()
	end
end

local adminfunctab = {
	["quit"] =		quit,
	["addbad"] =	addbad,
	["addbird"] = 	addbird,
	["rmword"] = 	removeword,
	["say"] =		sayline,
	["me"] =		sayact,
	["addrss"] = 	addrss,
	["rmrss"] =		rmrss,
	["join"] =		joinchannel,
	["part"] = 		partchannel,
	["+admin"] =	addadmin,
	["-admin"] =	rmadmin,
	["reload"] =	reloadlater,
	["test"] = 		testfunc,
	["checkrss"] = 	checkrss,
	["addtime"] = 	addtime,
	["nick"] = 		nickname,
	["checktwitter"] = checktweetybird,

}
setglobal("adminfunctab", adminfunctab)

local adminfunchelp = {
	["quit"] =		'tells me to leave',
	["addbad"] =	'adds a word to the curse word filter',
	["addbird"] = 	'adds a bird to the bird word filter',
	["rmword"] = 	'removes a word from the bad and bird word filters',
	["say"] =		'makes me say something',
	["me"] =		'makes me say something',
	["addrss"] =	'adds a feed to the RSS reader',
	["rmrss"] =		'removes a feed from the RSS reader',
	["+admin"] =	'adds an admin to the admin list',
	["-admin"] =	'removes an admin from the admin list',
	["reload"] =	'does a git pull and reloads all scripts',
	["join"] =		'makes me join a channel',
	["part"] = 		'makes me leave a channel',
	["checkrss"] = 	'forces a check of all RSS feeds (happens automatically every 5 minutes)',
	["addtime"] =	'adds the timezone to the time clock (format: !addtime [name] [UTC offset in hours])',
	["nick"] = 		'[nick] changes bot nickname to [nick]',
	["checktwitter"] = 'checks the twitterverse',
}
setglobal("adminfunchelp", adminfunchelp)
