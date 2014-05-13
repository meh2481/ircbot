--Global variables for use by lua functions

G_DEV = "daxar"

if not G_LASTSEEN then 
	G_LASTSEEN = {}
end

if not G_LASTMESSAGE then 
	G_LASTMESSAGE = {}
end

if not G_NICKS then 
	G_NICKS = {}
end

if not G_BADWORDS then 
	G_BADWORDS = {}
end

if not G_BIRDWORDS then 
	G_BIRDWORDS = {}
end

if not G_STARTTIME then
	G_STARTTIME = os.time()
end

if not G_INSULTADJ1 then
	G_INSULTADJ1 = {}
end

if not G_INSULTADJ2 then
	G_INSULTADJ2 = {}
end

if not G_INSULTNOUN then
	G_INSULTNOUN = {}
end

if not G_TOTELL then
	G_TOTELL = {}
end

if not G_RSSFEEDS then
	G_RSSFEEDS = {}
end

if not G_ADMINS then
	G_ADMINS = {["daxar"]=true,}
end

if not LOGFILE then
	LOGFILE = assert(io.open("txt/log.txt", "a"))
end
