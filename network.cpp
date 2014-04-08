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
	//printf("<< %s", sbuf);
#ifdef _WIN32
	send(conn, sbuf, strlen(sbuf), 0);
#else
	write(conn, sbuf, strlen(sbuf));
#endif
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

