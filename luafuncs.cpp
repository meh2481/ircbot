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

string	sBuf;
bool	bStop;
string	sRedir;
string	sSearch;

#define MAX_DOWNLOAD_SIZE 1048576	//1 MB oughta be plenty
class HttpGet : public minihttp::HttpSocket
{
public:
	HttpGet() : minihttp::HttpSocket()	{bStop = false; sBuf.clear(); sRedir.clear(); sSearch.clear();};
	virtual ~HttpGet()					{};
	string getBuf()						{return sBuf;};
	int getSize()						{return sBuf.size();};
	bool isStopped()					{return bStop;};
	string getRedir()					{return sRedir;};
	void searchFor(string s)			{sSearch = s;};

protected:
	virtual void _OnRecv(void *buf, unsigned int size)
	{
		if(IsRedirecting())
			sRedir = Hdr("location");
		
		if(!size)
			return;
			
		for(char* i = (char*)buf; i < buf+size; i++)
			sBuf.push_back(*i);
		if(sBuf.size() >= MAX_DOWNLOAD_SIZE || (sSearch.size() > 1 && sBuf.find(sSearch) != string::npos))
			bStop = true;
	}
};

string HTTPGet(string sURL, string sExtra)
{
	HttpGet* ht = new HttpGet;

	ht->SetBufsizeIn(MAX_DOWNLOAD_SIZE);
	ht->Download(sURL, sExtra.c_str());
	ht->SetAlwaysHandle(true);
	minihttp::SocketSet ss;
	ss.add(ht, true);
	uint32_t startTicks = getTicks();
	while(ss.size() && !bStop && getTicks() < startTicks + 1000*10)	//Just spin here (for a maximum of 10 seconds)
		ss.update();
	return sBuf;
}

string HTTPGet(string sURL)
{
	return HTTPGet(sURL, "");
}

//http://stackoverflow.com/questions/154536/encode-decode-urls-in-c
#include <cctype>
#include <iomanip>
#include <sstream>
#include <string>
using namespace std;
string url_encode(const string &value) 
{
    ostringstream escaped;
    escaped.fill('0');
    escaped << hex;

    for (string::const_iterator i = value.begin(), n = value.end(); i != n; ++i) 
	{
        string::value_type c = (*i);

        // Keep alphanumeric and other accepted characters intact
        if (isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') 
		{
            escaped << c;
            continue;
        }

        // Any other characters are percent-encoded
        escaped << '%' << setw(2) << int((unsigned char) c);
    }
    return escaped.str();
}

#include "polarssl/sha1.h"
#include "polarssl/base64.h"
luaFunc(encode64)
{
	string sEncode = lua_tostring(L,1);
	size_t len = 0;
	const unsigned char* cEncode = (const unsigned char*) sEncode.c_str();
	base64_encode(NULL, &len, cEncode, sEncode.size());	//Grab length of our destination buffer
	unsigned char* cBuf = (unsigned char*) malloc(len) + 1;
	base64_encode(cBuf, &len, cEncode, sEncode.size());		//Do actual encode
	cBuf[len] = '\0';
	string s = (const char*)cBuf;
	free(cBuf);
	luaReturnStr(s.c_str());
}

luaFunc(hmacSHA1)
{
	string sKey = lua_tostring(L,1);
	string sInput = lua_tostring(L,2);
	unsigned char output[21];
	sha1_hmac((const unsigned char*)sKey.c_str(), sKey.size(), (const unsigned char*)sInput.c_str(), sInput.size(), output);
	output[20] = '\0';
	luaReturnStr((const char*)output);
}

luaFunc(encodeURI)
{
	string sURI = lua_tostring(L,1);
	luaReturnStr(url_encode(sURI).c_str());
}

luaFunc(wget)
{
	string sURL = lua_tostring(L,1);
	string sExtra = lua_tostring(L,2);
	string s = HTTPGet(sURL, sExtra);
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

	ht->SetBufsizeIn(MAX_DOWNLOAD_SIZE);
	ht->Download(sURL);
	ht->SetAlwaysHandle(true);
	ht->searchFor("</title>");
	minihttp::SocketSet ss;
	ss.add(ht, true);
	uint32_t startTicks = getTicks();
	while(ss.size() && !bStop && getTicks() < startTicks + 1000*5)	//Just spin here for a maximum of 5 seconds
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
	string sURL = lua_tostring(L,1);
	if(sURL.size() < 1)
		luaReturnBool(false);
	bool success = false;
	bool verbose = lua_toboolean(L, 3);
	tinyxml2::XMLDocument doc;
	tinyxml2::XMLError err = doc.Parse(HTTPGet(sURL).c_str());	//Parse this as XML document
	if(err != tinyxml2::XML_NO_ERROR)
		luaReturnNil();
	tinyxml2::XMLElement* root = doc.RootElement();
	if(root != NULL)
	{
		int cur = 0;
		int iters = 0;
		for(tinyxml2::XMLElement* entry = root->FirstChildElement("entry"); entry != NULL; entry = entry->NextSiblingElement("entry"))
		{
			iters++;
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
						
						//Handle dictionary api having fw tags in it
						tinyxml2::XMLElement* fw = dt->FirstChildElement("fw");
						if(fw != NULL)
						{
							const char* cFw = fw->GetText();
							if(cFw != NULL && strlen(cFw) > 3)
							{
								string sfw = cFw;
								while(isspace(sfw[sfw.size()-1]))
									sfw.erase(sfw.size()-1);
								while(isspace(sfw[0]))
									sfw.erase(0,1);
								toSay << " ";
								toSay << sfw;
							}
						}
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
		if(!iters)	//We got a page without an entry; see if there are spelling suggestions
		{
			const char* errtxt = "Not a real word. Spelling suggestions: ";
			ostringstream oss;
			oss << errtxt;
			for(tinyxml2::XMLElement* suggestion = root->FirstChildElement("suggestion"); suggestion != NULL; suggestion = suggestion->NextSiblingElement("suggestion"))
			{
				const char* cSug = suggestion->GetText();
				if(cSug != NULL)
				{
					oss << cSug;
					if(suggestion->NextSiblingElement("suggestion") != NULL)
						oss << ", ";
				}
			}
			if(oss.str().size() > strlen(errtxt))
			{
				raw("PRIVMSG %s :%s\r\n", lua_tostring(L,2), oss.str().c_str());
				success = true;
			}
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
	nick = "immabot";
	while(true)
	{
		lua_getglobal(L, "hasnick");
		lua_pushstring(L, nick.c_str());
		if(lua_pcall(L, 1, 1, 0) != LUA_OK)
			luaReturnNil();	//break out here if something goes terribly wrong
		int z = lua_tointeger(L, -1);
		lua_pop(L, 1);  // pop returned value 
		if(!z)
			break;
		nick = nick + "_";	//Tack underscore onto end
	}
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
	luaRegister(encodeURI),
	luaRegister(encode64),
	luaRegister(hmacSHA1),
	{NULL, NULL}
};

void lua_register_enginefuncs(lua_State *L)
{	
	for(unsigned int i = 0; s_functab[i].name; ++i)
		lua_register(L, s_functab[i].name, s_functab[i].func);
}
