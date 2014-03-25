#include "bot.h"

void initNetworking()
{
#ifdef _WIN32
	WSADATA wsaData;
	int iResult;
	iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
	if (iResult != 0) {
		printf("WSAStartup failed: %d\n", iResult);
		exit(1);
	}
#endif
}

void shutdownNetworking()
{
#ifdef _WIN32
	WSACleanup();
#endif
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