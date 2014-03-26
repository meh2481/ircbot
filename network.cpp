#include "bot.h"

void initNetworking()
{
	minihttp::InitNetwork();
}

void shutdownNetworking()
{
	minihttp::StopNetwork();
}

void raw(const char *fmt, ...) 
{
	char sbuf[512];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(sbuf, 512, fmt, ap);
	va_end(ap);
	printf("<< %s", sbuf);
#ifdef _WIN32
	send(conn, sbuf, strlen(sbuf), 0);
#else
	write(conn, sbuf, strlen(sbuf));
#endif
}

void say(const char* channel, const char* msg, ...)
{
	char sbuf[512];
	va_list ap;
	va_start(ap, msg);
	vsnprintf(sbuf, 512, msg, ap);
	va_end(ap);
	raw("PRIVMSG %s :%s\r\n", channel, sbuf);
}

void action(const char* channel, const char* msg, ...)
{
	char sbuf[512];
	va_list ap;
	va_start(ap, msg);
	vsnprintf(sbuf, 512, msg, ap);
	va_end(ap);
	raw("PRIVMSG %s :\001ACTION %s\001\r\n", channel, sbuf);
}

void join(const char* channel)
{
	raw("JOIN %s\r\n", channel);
}

void setupConnection(const char* host, const char* port, int* connection)
{
	struct addrinfo hints, *res;
	
	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	getaddrinfo(host, port, &hints, &res);
	*connection = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
	connect(*connection, res->ai_addr, res->ai_addrlen);
}


#define MAX_ATTEMPT_LEN	4096	//4kB should be plenty
string sBuf;
bool bStop;
class HttpSimpleSocket : public minihttp::HttpSocket
{
public:
    virtual ~HttpSimpleSocket() {}

protected:
    virtual void _OnRecv(char *buf, unsigned int size)
    {
        if(!size)
            return;
        //printf("===START==[Status:%d, Size:%d]======\n", GetStatusCode(), size);
        for(char* i = buf; i < buf+size; i++)
			sBuf.push_back(*i);
		if(sBuf.size() >= MAX_ATTEMPT_LEN || sBuf.find("</title>") != string::npos)
			//Shutdown socket; if we haven't hit it by now, we likely won't.
			bStop = true;
        //puts("\n===END====================");
    }
};

void getURLTitle(const char* channel, string sURL)
{
	bStop = false;
	HttpSimpleSocket *ht = new HttpSimpleSocket;

    ht->SetKeepAlive(3);
    ht->SetBufsizeIn(MAX_ATTEMPT_LEN);
	ht->Download(sURL);
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
			printf("Title: %s\n", sTemp.c_str());
			say(channel, "[%s]", sTemp.c_str());	//Say what the title is in chat
		}
		else
			printf("No title found\n");
		
		trex_free(pRegex);
	}
	else
		printf("2trex error: %s\n", errbuf);
	
	printf("buf size: %d\n", sBuf.size());
	sBuf.clear();
}