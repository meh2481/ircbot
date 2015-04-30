dofile("lua/globaltest.lua")
dofile("lua/globals.lua")
dofile("lua/serialize.lua")
dofile("lua/io.lua")
dofile("lua/twitter.lua")
dofile("lua/adminactions.lua")
dofile("lua/actions.lua")
dofile("lua/messages.lua")

math.randomseed(os.time())
restoreall()
--checktwitter(getchannel(), true)	--Force a twitter check to populate the list, but don't display them anywhere