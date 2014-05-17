--Functions for dealing with file I/O

local function savetable(tab, filename)
	local file = io.open(filename, "w")
	if file then
		file:write(serialize_save(tab, false))
		file:close()
	end
end

local function saveall()
	savetable(G_BIRDWORDS, "txt/birdwords.txt")
	savetable(G_BADWORDS, "txt/badwords.txt")
	savetable(G_LASTSEEN, "txt/lastseen.txt")
	savetable(G_LASTMESSAGE, "txt/lastmessage.txt")
	savetable(G_TOTELL, "txt/totell.txt")
	savetable(G_RSSFEEDS, "txt/rssfeeds.txt")
	savetable(G_ADMINS, "txt/admins.txt")
	savetable(G_CURSERS, "txt/cursers.txt")
	savetable(G_NUMLINES, "txt/numlines.txt")
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
	G_BIRDWORDS = loadtable("txt/birdwords.txt")
	G_BADWORDS = loadtable("txt/badwords.txt")
	for key,val in pairs(G_BADWORDS) do
		if key:find(" ") then
			G_BADWORDS[key] = nil
		end
	end
	local tmpmsg = loadtable("txt/lastseen.txt")
	if tmpmsg then
		G_LASTSEEN = tmpmsg
	end
	tmpmsg = loadtable("txt/lastmessage.txt")
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
	local admins = loadtable("txt/admins.txt")
	if admins then
		G_ADMINS = admins
	end
	local cursers = loadtable("txt/cursers.txt")
	if cursers then
		G_CURSERS = cursers
	end
	local numlines = loadtable("txt/numlines.txt")
	if numlines then
		G_NUMLINES = numlines
	end
end
setglobal("restoreall", restoreall)
