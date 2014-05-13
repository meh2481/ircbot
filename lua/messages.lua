--Functions for handling incoming messages

local yelling = {}

--Our function that's called whenever we get a message on IRC
local function gotmessage(user, cmd, where, target, message)
	--print("[from: " .. user .. "] [reply-with: " .. cmd .. "] [where: " .. where .. "] [reply-to: " .. target .. "] ".. message)
	
	message = message:gsub("\r", "")	--Strip off \r\n
	message = message:gsub("\n", "")
	
	--Write out to our log
	if LOGFILE then
		LOGFILE:write(where..": <"..user.."> "..message.."\n")
		LOGFILE:flush()	--Go ahead and write out to the file now
	end
	
	if user == "NickServ" then
		nickservget(cmd, message)
	else
		if message:sub(1, 1) == '!' then	--Bot action preceded by '!' character
			local botaction = string.sub(message, 2)	--Get bot action
			doaction(target, botaction, user)
		end
		
		--Update last seen message
		if where == getchannel() then	--Keep PM's private
			G_LASTSEEN[string.lower(user)] = os.time()
			message = message:gsub("\001[Aa][Cc][Tt][Ii][Oo][Nn]", user) --Replace \001ACTION with username
			message = message:gsub("\001", "")	--Remove trailing \001
			G_LASTMESSAGE[string.lower(user)] = "saying \""..message.."\""
		end
		
		--Test for links
		for w in string.gmatch(message, "https?://%S+") do
			w = w:gsub("https", "http", 1)
			local title = gettitle(w)
			if title and string.len(title) > 0 then
				say(target, "["..title.."]")
			end
		end
		
		--Test for bad words & bird words
		for w in string.gmatch(message, "%S+") do
			w = w:lower():gsub("%W","")	--Convert to lowercase and remove punctuation
			if G_BADWORDS[w] then
				action(target, "slaps "..user.." for their foul language")
				break
			end
			if G_BIRDWORDS[w] then
				action(target, "pecks "..user.." for their fowl language")
				break
			end
		end
		
		--See if yelling
		local allupper = true
		for w in string.gmatch(message, "%S+") do
			local test = string.upper(w)
			if test ~= w then
				allupper = false
				break
			end
		end
		if allupper and string.len(message) > 3 then
			if yelling[user] then
				if yelling[user] > 2 then
					action(target, "covers his ears to block out "..user.."\'s yelling")
					yelling[user] = 0
				end
				yelling[user] = yelling[user] + 1
			else 
				yelling[user] = 2
			end
		else
			yelling[user] = 1
		end
	end
end
setglobal("gotmessage", gotmessage)

local function rejoin(channel)
	sleep(60*2)
	join(channel)
end

local function tellnow(channel, user)
	user = user:lower()
	if G_TOTELL[user] then
		say(channel, G_TOTELL[user])
		G_TOTELL[user] = nil	--Wipe this message from inbox
	end
end

local function joined(channel, user)
	G_LASTSEEN[string.lower(user)] = os.time()
	G_LASTMESSAGE[string.lower(user)] = "joining IRC"
	G_NICKS[string.lower(user)] = 1
	tellnow(channel, user)	--Tell the user any pending messages they have
end

local function left(channel, user)
	G_LASTSEEN[string.lower(user)] = os.time()
	G_LASTMESSAGE[string.lower(user)] = "leaving IRC"
	G_NICKS[string.lower(user)] = nil
end

local function kicked(channel, user, buf)
	local userkicked = buf:gsub("(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+).*", "%4")
	if userkicked == getnick() then
		rejoin(channel)				--If I've gotten kicked, rejoin in 2 mins
	else
		say(channel, "Trololol")	--Bask in the hilarity of another user getting kicked
		G_LASTSEEN[string.lower(user)] = os.time()
		G_LASTMESSAGE[string.lower(user)] = "being kicked from IRC"
		G_NICKS[string.lower(user)] = nil
	end
end

local function nicklist(channel, user, buf)
	buf = string.gsub(buf, ":.+:", "")
	buf = string.gsub(buf, "[@&%%%+~]", "")	--Get rid of nick op symbols and such (TODO: Save who the ops are)
	for n in string.gmatch(buf, "%S+") do 
		G_NICKS[string.lower(n)] = 1
	end
end

local function changenick(channel, user, buf)
	buf = string.gsub(buf, ":.+:", "")	--Remove all but message
	G_NICKS[string.lower(user)] = nil
	G_NICKS[string.lower(buf)] = 1
	G_LASTSEEN[string.lower(user)] = os.time()
	G_LASTSEEN[string.lower(buf)] = os.time()
	G_LASTMESSAGE[string.lower(user)] = "changing nick to "..buf 
	G_LASTMESSAGE[string.lower(buf)] = "changing nick from "..user
end

local function command(channel, cmd, user, buf)
	local actions = {
		["001"] = join,
		["JOIN"] = joined,
		["PART"] = left,
		["QUIT"] = left,
		["KICK"] = kicked,
		["353"] = nicklist,
		["404"] = rejoin,
		["433"] = newnick,
		["NICK"] = changenick,
	}
	
	local f = actions[cmd]
	if f then
		f(channel, user, buf)
	end
end
setglobal("command", command)