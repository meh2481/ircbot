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
	#define _WIN32_WINNT 0x0501
	#include <winsock2.h>
	#include <ws2tcpip.h>
	#undef _WIN32_WINNT
	#define _USE_32BIT_TIME_T 1
	#include <stdio.h>
	#include <io.h>
	#include <ctime>
	#define sleep(x) Sleep(x * 1000)
#endif

#include "trex.h"
#include "minihttp.h"

#include <string>
#include <sstream>
#include <set>
#include <map>
#include <list>
#include <cstdlib>
#include <algorithm>
#include <fstream>
using namespace std;

//Global variables
extern int conn;
extern time_t starttime;
extern set<string> sBadWords;
extern set<string> sBirdWords;
extern map<string, int> mYellList;
extern set<string> sNickList;
extern set<string> sNickListLowercase;
extern map<string, time_t> mLastSeen;
extern map<string, string> mLastMessage;

//parse.cpp functions
string forceascii(const char* msg);
string tolowercase(string s);
string touppercase(string s);
void inputWordList(string sFilename, set<string>& dest);
void readWords();
void addWord(string sFilename, string sWord);
string replaceChar(string s, char cSearch, char cReplace);
string replaceWhitespace(string s);
set<string> ssplitWords(string s, bool bLowercase = true);
list<string> splitWords(string s, bool bLowercase = true);
string stripEnd(string s);
string stripRN(string s);
bool isInside(string s, set<string>& sSet);
string stripNewline(string s);

//network.cpp functions
void initNetworking();
void raw(const char *fmt, ...);
void say(const char* channel, const char* msg, ...);
void action(const char* channel, const char* msg, ...);
void shutdownNetworking();
void join(const char* channel);
void setupConnection(const char* host, const char* port, int* connection);
string getURLTitle(string sURL, string& soutURL);

//actions.cpp functions
void seen(const char* channel, const char* message);
void bai(const char* channel);
void hai(const char* channel);
void hug(const char* channel, const char* message, const char* user);
void ex(const char* channel, const char* message, const char* nick);
void cookie(const char* channel, string user, string sCompare);
void eightball(const char* channel);
void botcommand(const char* message, const char* channel, const char* user, const char* nick);
void rpschoose(const char* channel, const char* message, const char* user);

#define BAD_WORD_LIST 	"badwords.txt"
#define BIRD_WORD_LIST	"birdwords.txt"





#endif	//BOT_H