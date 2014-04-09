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
end
setglobal("restoreall", restoreall)
--[15:10:32] <fgenesis> and later just do local s = loadfile("file.txt"); if s then tab = serialize_restore(s) end