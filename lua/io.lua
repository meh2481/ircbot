--Functions for dealing with file I/O

local function readbad()
	
end
setglobal("readbad", readbad)

local function savetable(tab, filename)
	local file = io.open(filename, "w")
	if file then
		file:write(serialize_save(tab, false))
		file:close()
	end
end

local function saveall()
	savetable(birdwords, "birdwords.txt")
	savetable(badwords, "badwords.txt")
	savetable(lastseen, "lastseen.txt")
	savetable(lastmessage, "lastmessage.txt")
end
setglobal("saveall", saveall)

local function loadtable(filename)
	local file = loadfile(filename)
	if file then
		local tab = file()
		return tab
	end
	return nil
end

local function restoreall()
	birdwords = loadtable("birdwords.txt")
	badwords = loadtable("badwords.txt")
	local tmpmsg = loadtable("lastseen.txt")
	if tmpmsg then
		lastseen = tmpmsg
	end
	tmpmsg = loadtable("lastmessage.txt")
	if tmpmsg then
		lastmessage = tmpmsg
	end
	
end
setglobal("restoreall", restoreall)
