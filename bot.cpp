#include "bot.h"
#include <stdint.h>
#ifndef _WIN32
#include <time.h>
#endif

int conn;
bool bDone = false;
bool bShouldReload = false;
string nick = "immabot";
#ifdef DEBUG
const char *channel = "#bitbottest";
#else
const char *channel = "#bitblot";
#endif

uint32_t getTicks()
{
#ifdef _WIN32
	return GetTickCount();
#else
    struct timespec spec;
    clock_gettime(CLOCK_REALTIME, &spec);
    return((spec.tv_nsec / 1.0e6) + (spec.tv_sec * 1000));
#endif
}

int main(int argc, char** argv) 
{
	LuaInterface Lua("lua/init.lua", argc, argv);
	char sbuf[512];
	char *host = "irc.esper.net";
	char *port = "6667";
	bool timingOut = false;
	uint32_t curTime = getTicks();
	
	char *user, *command, *where, *message, *sep, *target;
	int sl, o = -1, start, wordcount;
	char buf[513];
	
	srand (time(NULL));
	Lua.Init();
	
	initNetworking();
	
	while(!setupConnection(host, port, &conn)) sleep(10);	//Spin here and wait for connection	
	
	raw("USER %s 0 0 :%s\r\n", nick.c_str(), nick.c_str());
	raw("NICK %s\r\n", nick.c_str());
	while(!bDone)
	{
		if(bShouldReload)
		{
			#ifdef DEBUG
			printf("Reloading\n");
			#endif
			system("git pull");
			Lua.call("saveall");
			Lua.call("dofile", "lua/init.lua");
			bShouldReload = false;
		}
		
		//Save & check RSS feeds every five minutes
		if(getTicks() > curTime + 5*60*1000)
		{
			curTime = getTicks();
			#ifdef DEBUG
			printf("Saving all...\n");
			#endif
			Lua.call("saveall");
			Lua.call("checkrss");
		}
		
		//Select loop so we can tell if we've timed out
		fd_set set;
		struct timeval timeout;
		FD_ZERO(&set);
		FD_SET(conn, &set);
		timeout.tv_sec = 60;	//1-minute timeout
		timeout.tv_usec = 0;

		//select returns 0 if timeout, 1 if input available, -1 if error.
		int canread = select(FD_SETSIZE, &set, NULL, NULL, &timeout);
		if(canread != 1)
		{
			if(timingOut)
			{
				//We've already pinged the server, and gotten nothing back. Reconnect
				#ifdef DEBUG
				printf("Reconnecting...\n");
				#endif
				close(conn);
				while(!setupConnection(host, port, &conn)) sleep(10);
				raw("USER %s 0 0 :%s\r\n", nick.c_str(), nick.c_str());
				raw("NICK %s\r\n", nick.c_str());
				continue;
			}
			raw("PING :%s\r\n", "immabotbeep");
			timingOut = true;
			continue;	//Break out here and select for input again
		}
		sl = 0;
		if(canread == 1)
		{
			#ifdef _WIN32
			sl = recv(conn, sbuf, 512, 0);
			#else
			sl = read(conn, sbuf, 512);
			#endif
			timingOut = false;	//Got stuff; we're good
			if(sl < 1)
			{
				timingOut = true;
				close(conn);
				while(!setupConnection(host, port, &conn)) sleep(10);
				raw("USER %s 0 0 :%s\r\n", nick.c_str(), nick.c_str());
				raw("NICK %s\r\n", nick.c_str());
				continue;
			}
		}
		for (int i = 0; i < sl; i++) 
		{
			o++;
			buf[o] = sbuf[i];
			if ((i > 0 && sbuf[i] == '\n' && sbuf[i - 1] == '\r') || o == 512) 
			{
				buf[o + 1] = '\0';
				int l = o;
				o = -1;
				
				#ifdef DEBUG
				printf(">> %s", buf);
				#endif
				char tempbuf[512];
				memcpy(tempbuf, buf, strlen(buf));
				
				if (!strncmp(buf, "PING", 4)) //PONG any PING we get
				{
					buf[1] = 'O';
					raw(buf);
				}
				else if (buf[0] == ':') //Message
				{
					wordcount = 0;
					user = command = where = message = NULL;
					for (int j = 1; j < l; j++) 
					{
						if (buf[j] == ' ') 
						{
							buf[j] = '\0';
							wordcount++;
							switch(wordcount) {
								case 1: user = buf + 1; break;
								case 2: command = buf + start; break;
								case 3: where = buf + start; break;
							}
							if (j == l - 1) 
								continue;
							start = j + 1;
						} 
						else if (buf[j] == ':' && wordcount == 3) 
						{
							if (j < l - 1) 
								message = buf + j + 1;
							break;
						}
					}
					
					if (wordcount < 2) 
						continue;
					
					if ((sep = strchr(user, '!')) != NULL) 
							user[sep - user] = '\0';
					
					if (!strncmp(command, "PRIVMSG", 7) || !strncmp(command, "NOTICE", 6)) //Message from IRC
					{
						if (where == NULL || message == NULL) 
							continue;
						if (where[0] == '#' || where[0] == '&' || where[0] == '+' || where[0] == '!') 
							target = where; else target = user;
						
						Lua.call("gotmessage", user, command, where, target, message);
					}
					else	//Some other kind of command
					{
						//Remove trailing chars from buffer
						for(char* k = tempbuf; ; k++)
						{
							if(*k == '\r' || *k == '\n')
							{
								*k = '\0';
								break;
							}
						}
						Lua.call("command", channel, command, user, tempbuf);
					}
				}
			}
		}
	}
	close(conn);
	shutdownNetworking();
	return 0;
}
