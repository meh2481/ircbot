--Functions for dealing with file I/O

local function savetable(tab, filename)
	local file = io.open(filename, "w")
	if file then
		file:write(serialize_save(tab, false))
		file:close()
	end
end

local function saveall()
	savetable(G_BIRDWORDS, "birdwords.txt")
	savetable(G_BADWORDS, "badwords.txt")
	savetable(G_LASTSEEN, "lastseen.txt")
	savetable(G_LASTMESSAGE, "lastmessage.txt")
	savetable(G_TOTELL, "txt/totell.txt")
	savetable(G_RSSFEEDS, "txt/rssfeeds.txt")
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
	G_BIRDWORDS = loadtable("birdwords.txt")
	G_BADWORDS = loadtable("badwords.txt")
	local tmpmsg = loadtable("lastseen.txt")
	if tmpmsg then
		G_LASTSEEN = tmpmsg
	end
	tmpmsg = loadtable("lastmessage.txt")
	if tmpmsg then
		G_LASTMESSAGE = tmpmsg
	end
	G_INSULTADJ1 = loadtable("txt/insult_adj1.txt")
	G_INSULTADJ2 = loadtable("txt/insult_adj2.txt")
	G_INSULTNOUN = loadtable("txt/insult_noun.txt")
	local ttell = loadtable("txt/totell.txt")
	if ttell then
		G_TOTELL = ttell
	end
	local rfeeds = loadtable("txt/rssfeeds.txt")
	if rfeeds then
		G_RSSFEEDS = rfeeds
	end
end
setglobal("restoreall", restoreall)
