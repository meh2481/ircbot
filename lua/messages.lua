--Functions for handling incoming messages

local yelling = {}

--Our function that's called whenever we get a message on IRC
local function gotmessage(user, command, where, target, message)
	--print("[from: " .. user .. "] [reply-with: " .. command .. "] [where: " .. where .. "] [reply-to: " .. target .. "] ".. message)
	
	message = message:gsub("\r", "")	--Strip off \r\n
	message = message:gsub("\n", "")
	
	if message:sub(1, 1) == '!' then	--Bot action preceded by '!' character
		local botaction = string.sub(message, 2)	--Get bot action
		doaction(target, botaction, user)
	end
	
	--Update last seen message
	lastseen[string.lower(user)] = os.time()
	message = message:gsub("\001[Aa][Cc][Tt][Ii][Oo][Nn]", user) --Replace \001ACTION with username
	message = message:gsub("\001", "")	--Remove trailing \001
	lastmessage[string.lower(user)] = "saying \""..message.."\""
	
	--Test for links
	for w in string.gmatch(message, "https?://%S+") do
		w = w:gsub("https", "http", 1)
		local title = getURLTitle(w)
		if title and string.len(title) > 0 then
			say(target, "["..title.."]")
		end
    end
	
	--Test for bad words & bird words
	--TODO: Timer
	for w in string.gmatch(message, "%S+") do
		w = string.lower(w)
		if badwords[w] then
			action(target, "slaps "..user.." for their foul language")
		end
		if birdwords[w] then
			action(target, "pecks "..user.." for their fowl language")
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
	
	--TODO: Test for RPS battle commands,
	--TODO: hai, bai, good boy, question
	
	--TODO: Save now and then
	
end
setglobal("gotmessage", gotmessage)

local function rejoin(channel)
	sleep(60*2)
	join(channel)
end

local function joined(channel, user)
	lastseen[string.lower(user)] = os.time()
	lastmessage[string.lower(user)] = "joining IRC"
	nicks[string.lower(user)] = 1;
end

local function left(channel, user)
	lastseen[string.lower(user)] = os.time()
	lastmessage[string.lower(user)] = "leaving IRC"
	nicks[string.lower(user)] = nil
end

local function kicked(channel, user)
	say(channel, "Trololol")
	lastseen[string.lower(user)] = os.time()
	lastmessage[string.lower(user)] = "being kicked from IRC"
	nicks[string.lower(user)] = nil
end

local function nicklist(channel, user, buf)
	buf = string.gsub(buf, ":.+:", "")
	for n in string.gmatch(buf, "%S+") do 
		nicks[string.lower(n)] = 1
	end
end

local function changenick(channel, user, buf)
	buf = string.gsub(buf, ":.+:", "")	--Remove all but message
	nicks[string.lower(user)] = nil
	nicks[string.lower(buf)] = 1
	lastseen[string.lower(user)] = os.time()
	lastseen[string.lower(buf)] = os.time()
	lastmessage[string.lower(user)] = "changing nick to "..buf 
	lastmessage[string.lower(buf)] = "changing nick from "..user
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
		["NICK"] = changenick,
	}
	
	local f = actions[cmd]
	if f then
		f(channel, user, buf)
	end
end
setglobal("command", command)