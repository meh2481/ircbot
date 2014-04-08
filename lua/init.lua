dofile("lua/globaltest.lua")
dofile("lua/actions.lua")

math.randomseed(os.time())

--Our function that's called whenever we get a message on IRC
local function gotmessage(user, command, where, target, message)
	--print("[from: " .. user .. "] [reply-with: " .. command .. "] [where: " .. where .. "] [reply-to: " .. target .. "] ".. message)
	
	message = string.sub(message, 1, -3)	--Strip off \r\n
	
	if message:sub(1, 1) == '!' then	--Bot action preceded by '!' character
		local botaction = string.sub(message, 2)	--Get bot action
		doaction(target, botaction, user)
	end

end
setglobal("gotmessage", gotmessage)