#ifndef BOT_H
#define BOT_H

#ifndef _WIN32
	extern "C" {
		#include <stdio.h>
		#include <unistd.h>
		#include <string.h>
		#include <netdb.h>
		#include <stdarg.h>
	};
#endif

#ifdef _WIN32
	#undef UNICODE
	#ifndef _WIN32_WINNT
		#define _WIN32_WINNT 0x0501
	#endif
	#include <winsock2.h>
	#include <ws2tcpip.h>
	#undef _WIN32_WINNT
	#define _USE_32BIT_TIME_T 1
	#include <stdio.h>
	#include <io.h>
	#include <ctime>
	#define sleep(x) Sleep(x * 1000)
#endif

#include "minihttp.h"
#include "luainterface.h"

#include <string>
#include <sstream>
#include <set>
#include <map>
#include <list>
#include <cstdlib>
#include <algorithm>
#include <fstream>
using namespace std;

extern int conn;
extern bool bDone;
extern const char *nick;
extern const char *channel;

//network.cpp functions
void initNetworking();
void raw(const char *fmt, ...);
void shutdownNetworking();
void setupConnection(const char* host, const char* port, int* connection);


#endif	//BOT_H