#include "luafuncs.h"
#include "luainterface.h"
#include "bot.h"
#include "tinyxml2.h"

#include <algorithm>
#include <sstream>

//Thaaaanks http://www.cplusplus.com/forum/beginner/115247/#msg629035
std::string remove_letter_easy( std::string str, char c )
{
	str.erase( std::remove( str.begin(), str.end(), c ), str.end() ) ;
	return str ;
}

#define MAX_DOWNLOAD_SIZE 1048576	//1 MB oughta be plenty
class HttpGet : public minihttp::HttpSocket
{
public:
	HttpGet() 					{m_bStop = false;};
	virtual ~HttpGet()			{};
	string getBuf()				{return m_sBuf;};
	bool isStopped()			{return m_bStop;};
	string getRedir()			{return m_sRedir;};
	void searchFor(string s)	{m_sSearch = s;};

protected:
	virtual void _OnRecv(char *buf, unsigned int size)
	{
		if(IsRedirecting())
			m_sRedir = Hdr("location");
		
		if(!size)
			return;
			
		for(char* i = buf; i < buf+size; i++)
			m_sBuf.push_back(*i);
		if(m_sBuf.size() >= MAX_DOWNLOAD_SIZE || (m_sSearch.size() > 1 && m_sBuf.find(m_sSearch) != string::npos))
			m_bStop = true;
	}

	string	m_sBuf;
	bool	m_bStop;
	string	m_sRedir;
	string	m_sSearch;
};

string HTTPGet(string sURL)
{
	HttpGet* ht = new HttpGet;

	ht->SetKeepAlive(5);
	ht->SetBufsizeIn(MAX_DOWNLOAD_SIZE);
	ht->Download(sURL);
	ht->SetAlwaysHandle(true);
	minihttp::SocketSet ss;
	ss.add(ht, true);
	uint32_t startTicks = getTicks();
	while(ss.size() && !ht->isStopped() && getTicks() < startTicks + 1000*10)	//Just spin here (for a maximum of 10 seconds)
		ss.update();
	
	string sRet = ht->getBuf();
	return sRet;
}

luaFunc(wget)
{
	string sURL = lua_tostring(L,1);
	string s = HTTPGet(sURL);
	luaReturnStr(s.c_str());
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
	string sURL = lua_tostring(L,1);
	string sRet;
	HttpGet* ht = new HttpGet;

	ht->SetKeepAlive(5);
	ht->SetBufsizeIn(MAX_DOWNLOAD_SIZE);
	ht->Download(sURL);
	ht->SetAlwaysHandle(true);
	ht->searchFor("</title>");
	minihttp::SocketSet ss;
	ss.add(ht, true);
	uint32_t startTicks = getTicks();
	while(ss.size() && !ht->isStopped() && getTicks() < startTicks + 1000*5)	//Just spin here for a maximum of 5 seconds
		ss.update();
		
	string sBuf = ht->getBuf();
	//Ok, now we have data in sBuf, parse for title
	size_t start = sBuf.find("<title>");
	if(start != string::npos)
	{
		size_t stop = sBuf.find('<', start+1);
		if(stop != string::npos)
			sRet = sBuf.substr(start+7, stop-(start+7));
	}
	
	string sRedir = ht->getRedir();
	luaReturn2Strings(sRet.c_str(), sRedir.c_str());
}

luaFunc(getLatestRSS)
{
	string sURL = lua_tostring(L,1);
	string sResult = HTTPGet(sURL);
	if(!sResult.size())
		luaReturnNil();
	tinyxml2::XMLDocument doc;
	tinyxml2::XMLError err = doc.Parse(sResult.c_str());	//Parse this as XML document
	if(err != tinyxml2::XML_NO_ERROR)
		luaReturnNil();
	string feedtitle, itemtitle, url;
	tinyxml2::XMLElement* root = doc.RootElement();
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
	luaReturn3Strings(feedtitle.c_str(), itemtitle.c_str(), url.c_str());
}

luaFunc(defineWord)
{
	bool success = false;
	bool verbose = lua_toboolean(L, 3);
	tinyxml2::XMLDocument doc;
	tinyxml2::XMLError err = doc.Parse(lua_tostring(L,1));	//Parse this as XML document
	if(err != tinyxml2::XML_NO_ERROR)
		luaReturnNil();
	tinyxml2::XMLElement* root = doc.RootElement();
	if(root != NULL)
	{
		int cur = 0;
		for(tinyxml2::XMLElement* entry = root->FirstChildElement("entry"); entry != NULL; entry = entry->NextSiblingElement("entry"))
		{
			ostringstream toSay;
			if(verbose)
				toSay << ++cur << ". ";
			for(tinyxml2::XMLElement* def = entry->FirstChildElement("def"); def != NULL; def = def->NextSiblingElement("def"))
			{
				for(tinyxml2::XMLElement* dt = def->FirstChildElement("dt"); dt != NULL; dt = dt->NextSiblingElement("dt"))
				{
					const char* cDef = dt->GetText();
					if(cDef != NULL && strlen(cDef) > 3)
					{
						string s = remove_letter_easy(cDef, ':');
						while(isspace(s[s.size()-1]))
							s.erase(s.size()-1);
						while(isspace(s[0]))
							s.erase(0,1);
						toSay << s;
						if(verbose)
							toSay << "; ";
						else break;
					}
				}
			}
			if(toSay.str().size() > 3)
			{
				raw("PRIVMSG %s :%s\r\n", lua_tostring(L,2), toSay.str().c_str());
				success = true;
				if(!verbose)
					break;
			}
			if(!verbose)
				break;
		}
	}
	luaReturnBool(success);
}

luaFunc(getnick)
{
	luaReturnStr(nick.c_str());
}

luaFunc(newnick)
{
	nick = nick + "_";	//Tack underscore onto end
	raw("USER %s 0 0 :%s\r\n", nick.c_str(), nick.c_str());
	raw("NICK %s\r\n", nick.c_str());
	luaReturnNil();
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
	luaRegister(newnick),
	luaRegister(wget),
	luaRegister(defineWord),
	{NULL, NULL}
};

void lua_register_enginefuncs(lua_State *L)
{	
	for(unsigned int i = 0; s_functab[i].name; ++i)
		lua_register(L, s_functab[i].name, s_functab[i].func);
}
