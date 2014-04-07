#include "luafuncs.h"
#include "luainterface.h"
#include "bot.h"

#define MAX_ATTEMPT_LEN	4096	//4kB should be plenty
static string sBuf;
static bool bStop;
static string sRedir;
class HttpSimpleSocket : public minihttp::HttpSocket
{
public:
    virtual ~HttpSimpleSocket() {}

protected:
    virtual void _OnRecv(char *buf, unsigned int size)
    {
		if(IsRedirecting())
			sRedir = Hdr("location");
		
        if(!size)
            return;
			
        for(char* i = buf; i < buf+size; i++)
			sBuf.push_back(*i);
		if(sBuf.size() >= MAX_ATTEMPT_LEN || sBuf.find("</title>") != string::npos)
			//Shutdown socket; if we haven't hit it by now, we likely won't.
			bStop = true;
    }
};

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

luaFunc(join)	//channel
{
	raw("JOIN %s\r\n", lua_tostring(L,1));
}

luaFunc(getURLTitle)	//URL
{
	string sURL = lua_tostring(L,1);
	string sRet;
	bStop = false;
	sRedir.clear();
	HttpSimpleSocket *ht = new HttpSimpleSocket;

    ht->SetKeepAlive(5);
    ht->SetBufsizeIn(MAX_ATTEMPT_LEN);
	ht->Download(sURL);
	ht->SetAlwaysHandle(true);
	minihttp::SocketSet ss;
    ss.add(ht, true);
	while(ss.size() && !bStop)	//Just spin here
        ss.update();
		
	//Ok, now we have data in sBuf, parse regex
	char errbuf[512];
	TRex* pRegex = trex_compile("<title>", (const char**)&errbuf);
	if(pRegex != NULL)
	{
		const TRexChar *out_begin,*out_end;
		const TRexChar *out_temp = sBuf.c_str();
		const TRexChar *end = out_temp + strlen(out_temp);
		if(trex_search(pRegex, out_temp, &out_begin, &out_end))
		{
			string sTemp;
			for(const char* it = out_end; *it != '<' && it < end; it++)
				sTemp.push_back(*it);
			
			sRet = sTemp;
		}
		
		trex_free(pRegex);
	}
	
	sBuf.clear();
	
	luaReturnStrings(sRet.c_str(), sRedir.c_str());
}

static LuaFunctions s_functab[] =
{
	luaRegister(sleep),
	luaRegister(say),
	luaRegister(action),
	luaRegister(join),
	luaRegister(getURLTitle),
	{NULL, NULL}
};

void lua_register_enginefuncs(lua_State *L)
{	
	for(unsigned int i = 0; s_functab[i].name; ++i)
		lua_register(L, s_functab[i].name, s_functab[i].func);
}
