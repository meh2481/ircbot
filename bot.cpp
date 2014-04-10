#include "bot.h"

int conn;
bool bDone = false;
#ifdef DEBUG
	const char *nick = "immabot_";
	const char *channel = "#bitbottest";
#else
	const char *nick = "immabot";
	const char *channel = "#bitblot";
#endif

int main(int argc, char** argv) 
{
	LuaInterface Lua("lua/init.lua", argc, argv);
	char sbuf[512];
	char *host = "irc.esper.net";
	char *port = "6667";
	
	char *user, *command, *where, *message, *sep, *target;
	int sl, o = -1, start, wordcount;
	char buf[513];
	
	srand (time(NULL));
	Lua.Init();
	
	initNetworking();
	
	setupConnection(host, port, &conn);	
	
	raw("USER %s 0 0 :%s\r\n", nick, nick);
	raw("NICK %s\r\n", nick);
	#ifdef _WIN32
	while ((sl = recv(conn, sbuf, 512, 0)) && !bDone) 
	#else
	while ((sl = read(conn, sbuf, 512)) && !bDone) 
	#endif
	{
		for (int i = 0; i < sl; i++) 
		{
			o++;
			buf[o] = sbuf[i];
			if ((i > 0 && sbuf[i] == '\n' && sbuf[i - 1] == '\r') || o == 512) 
			{
				buf[o + 1] = '\0';
				int l = o;
				o = -1;
				
				//printf(">> %s", buf);
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
						
						//Check for reload
						if(!strncmp(message, "!reload", 7))
						{
							//readWords();
							//printf("Reloading\n");
							Lua.call("saveall");
							Lua.call("dofile", "lua/init.lua");
						}
						else
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
	shutdownNetworking();
	return 0;
}
