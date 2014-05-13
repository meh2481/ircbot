#include "luafuncs.h"
#include "luainterface.h"
#include "bot.h"
#include "tinyxml2.h"

extern const char *nick;
extern const char *channel;

#define MAX_TITLE_ATTEMPT_LEN	4096	//4kB should be plenty
static string sBuf;
static bool bStop;
static string sRedir;
//Class for fetching just the title of a page from a URL
class HttpTitleSearch : public minihttp::HttpSocket
{
public:
    virtual ~HttpTitleSearch() {}

protected:
    virtual void _OnRecv(char *buf, unsigned int size)
    {
		if(IsRedirecting())
			sRedir = Hdr("location");
		
        if(!size)
            return;
			
        for(char* i = buf; i < buf+size; i++)
			sBuf.push_back(*i);
		if(sBuf.size() >= MAX_TITLE_ATTEMPT_LEN || sBuf.find("</title>") != string::npos)
			//Shutdown socket; if we haven't hit it by now, we likely won't.
			bStop = true;
    }
};

#define MAX_DOWNLOAD_SIZE 1048576	//1 MB oughta be plenty
class HttpGet : public minihttp::HttpSocket
{
public:
    virtual ~HttpGet() {}

protected:
    virtual void _OnRecv(char *buf, unsigned int size)
    {
		if(IsRedirecting())
			sRedir = Hdr("location");
		
        if(!size)
            return;
			
        for(char* i = buf; i < buf+size; i++)
			sBuf.push_back(*i);
		if(sBuf.size() >= MAX_DOWNLOAD_SIZE)
			bStop = true;
    }
};

string HTTPGet(string sURL)
{
	sBuf.clear();
	bStop = false;
	HttpGet *ht = new HttpGet;

    ht->SetKeepAlive(5);
    ht->SetBufsizeIn(MAX_TITLE_ATTEMPT_LEN);
	ht->Download(sURL);
	ht->SetAlwaysHandle(true);
	minihttp::SocketSet ss;
    ss.add(ht, true);
	while(ss.size() && !bStop)	//Just spin here
        ss.update();
	
	return sBuf;
}

luaFunc(sleep)	//seconds
{
	sleep(lua_tointeger(L, 1));
	luaReturnNil();
}

luaFunc(say)	//channel, msg
{
	raw("PRIVMSG %s :%s\r\n", lua_tostring(L,1), lua_tostring(L,2));
	luaReturnNil();
}

luaFunc(action)	//channel, msg
{
	raw("PRIVMSG %s :\001ACTION %s\001\r\n", lua_tostring(L,1), lua_tostring(L,2));
	luaReturnNil();
}

luaFunc(raw)
{
	raw(lua_tostring(L,1));
	luaReturnNil();
}

luaFunc(join)	//channel
{
	raw("JOIN %s\r\n", lua_tostring(L,1));
}

luaFunc(getURLTitle)	//URL
{
	sBuf.clear();
	string sURL = lua_tostring(L,1);
	string sRet;
	bStop = false;
	sRedir.clear();
	HttpTitleSearch *ht = new HttpTitleSearch;

    ht->SetKeepAlive(5);
    ht->SetBufsizeIn(MAX_TITLE_ATTEMPT_LEN);
	ht->Download(sURL);
	ht->SetAlwaysHandle(true);
	minihttp::SocketSet ss;
    ss.add(ht, true);
	while(ss.size() && !bStop)	//Just spin here
        ss.update();
		
	//Ok, now we have data in sBuf, parse for title
	size_t start = sBuf.find("<title>");
	if(start != string::npos)
	{
		size_t stop = sBuf.find('<', start+1);
		if(stop != string::npos)
			sRet = sBuf.substr(start+7, stop-(start+7));
	}
	
	luaReturn2Strings(sRet.c_str(), sRedir.c_str());
}

luaFunc(getLatestRSS)
{
	string sURL = lua_tostring(L,1);
	string sResult = HTTPGet(sURL);
	if(!sResult.size())
		luaReturnNil();
	tinyxml2::XMLDocument* doc = new tinyxml2::XMLDocument;
	tinyxml2::XMLError err = doc->Parse(sResult.c_str());	//Parse this as XML document
	if(err != tinyxml2::XML_NO_ERROR)
	{
		delete doc;
		luaReturnNil();
	}
	string feedtitle, itemtitle, url;
	tinyxml2::XMLElement* root = doc->RootElement();
	if(root != NULL)
	{
		tinyxml2::XMLElement* channel = root->FirstChildElement("channel");
		if(channel != NULL)
		{
			tinyxml2::XMLElement* ftitle = channel->FirstChildElement("title");
			const char* cTitle = ftitle->GetText();
			if(cTitle != NULL)
				feedtitle = cTitle;
			tinyxml2::XMLElement* item = channel->FirstChildElement("item");
			if(item != NULL)
			{
				tinyxml2::XMLElement* ititle = item->FirstChildElement("title");
				if(ititle != NULL)
				{
					const char* cTitle2 = ititle->GetText();
					if(cTitle2 != NULL)
						itemtitle = cTitle2;
				}
				tinyxml2::XMLElement* link = item->FirstChildElement("link");
				if(link != NULL)
				{
					const char* cLink = link->GetText();
					if(cLink != NULL)
						url = cLink;
				}
				else	//Infiniteammo.ca special case: seems to slap it all into an "enclosure" tag
				{
					tinyxml2::XMLElement* enclosure = item->FirstChildElement("enclosure");
					if(enclosure != NULL)
					{
						const char* cURL = enclosure->Attribute("url");
						if(cURL != NULL)
							url = cURL;
					}
				}
			}
		}
	}
	//Done; clear it all out
	delete doc;
	luaReturn3Strings(feedtitle.c_str(), itemtitle.c_str(), url.c_str());
}

luaFunc(getnick)
{
	luaReturnStr(nick);
}

luaFunc(getchannel)
{
	luaReturnStr(channel);
}

luaFunc(done)
{
	bDone = true;
	raw("QUIT\r\n");	//Tell the server we're done
	luaReturnNil();
}

luaFunc(reload)
{
	bShouldReload = true;
	luaReturnNil();
}

static LuaFunctions s_functab[] =
{
	luaRegister(sleep),
	luaRegister(say),
	luaRegister(action),
	luaRegister(raw),
	luaRegister(join),
	luaRegister(getURLTitle),
	luaRegister(getnick),
	luaRegister(getchannel),
	luaRegister(done),
	luaRegister(reload),
	luaRegister(getLatestRSS),
	{NULL, NULL}
};

void lua_register_enginefuncs(lua_State *L)
{	
	for(unsigned int i = 0; s_functab[i].name; ++i)
		lua_register(L, s_functab[i].name, s_functab[i].func);
}
