dofile("lua/actions.lua")

math.randomseed(os.time())

--From http://lua-users.org/wiki/SwitchStatement
function switch(t)
  t.case = function (self,x)
    local f=self[x] or self.default
    if f then
      if type(f)=="function" then
        f(x,self)
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return t
end

--Our function that's called whenever we get a message on IRC
function gotmessage(user, command, where, target, message)
	--print("[from: " .. user .. "] [reply-with: " .. command .. "] [where: " .. where .. "] [reply-to: " .. target .. "] ".. message)
	
	message = string.sub(message, 1, -3)	--Strip off \r\n
	
	if message:sub(1, 1) == '!' then	--Bot action preceded by '!' character
		local botaction = string.sub(message, 2)	--Get bot action
		local regexp = "%S+"	--Get command all the way until whitespace
		
		doaction(target, string.sub(botaction, string.find(botaction, regexp)))
	end

end