#include "bot.h"

int conn;
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
	//gLua = &Lua;
	char sbuf[512];
	char *host = "irc.esper.net";
	char *port = "6667";
	
	char *user, *command, *where, *message, *sep, *target;
	int sl, o = -1, start, wordcount;
	char buf[513];
	
	srand (time(NULL));
	//starttime = time(NULL);
	Lua.Init();
	//readWords();
	
	initNetworking();
	
	setupConnection(host, port, &conn);	
	
	raw("USER %s 0 0 :%s\r\n", nick, nick);
	raw("NICK %s\r\n", nick);
	bool bDone = false;
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
							printf("Reloading\n");
							Lua.call("dofile", "lua/init.lua");
							raw("NAMES %s\r\n", channel);	//Ask for name list again
						}
						else
							Lua.call("gotmessage", user, command, where, target, message);
					}
					/*
						
						else	//Other misc. commands
						{
							string s = tolowercase(forceascii(message));
							set<string> words = ssplitWords(message);
							if(s.find(tolowercase(nick)) != string::npos)	//Highlighted
							{
								string sUser = user;
								string sMsg = stripRN(s);
								
								//Kill command by privileged user
								if(s.find("cheese curls") != string::npos && sUser.find("Daxar") == 0)	//Password for shutting off
								{
									raw("PART %s :Quit command invoked by %s\r\n", channel, user);
									bDone = true;	//Quit
								}
								
								//hai
								else if(words.count("hi") ||
										words.count("ohai") ||
										words.count("hai") ||
										words.count("hello") ||
										words.count("hey") ||
										words.count("sup") ||
										words.count("morning") ||
										words.count("mornin"))
								{
									hai(channel);
								}
								
								//bai
								else if(words.count("bye") ||
										words.count("bai") ||
										words.count("night") ||
										words.count("nite") ||
										words.count("n8") ||
										words.count("later"))
								{
									bai(channel);
								}
								
								//good boy
								else if(words.count("good") ||
										words.count("nice"))
								{
									action(channel, "wags tail");
								}
								
								//Bad boy
								else if(words.count("bad") ||
										words.count("down") ||
										words.count("sit"))
								{
									action(channel, "sits down and whines");
								}
								
								else if(sMsg[sMsg.size() - 1] == '?')	//Asking immabot a question
								{
									//say(channel, "Let me see...");
									eightball(channel);
								}
							}
							else if(isInside(s, sBadWords))	//Dirty language
							{
								if((!mLastSlapped.count(user)) || difftime(time(NULL), mLastSlapped[user]) >= 60.0)	//1min timeout on slapping
								{
									action(channel, "slaps %s for their foul language", user);
									mLastSlapped[user] = time(NULL);
								}
								else
									say("Daxar", "slapped difftime: %f", difftime(time(NULL), mLastSlapped[user]));
							}
							else if(isInside(s, sBirdWords))	//Birdy language
							{
								if((!mLastPecked.count(user)) || difftime(time(NULL), mLastPecked[user]) >= 60.0)	//1min timeout on pecking
								{
									action(channel, "pecks %s for their fowl language", user);
									mLastPecked[user] = time(NULL);
								}
								else
									say("Daxar", "pecked difftime: %f", difftime(time(NULL), mLastPecked[user]));
							}
							else if(touppercase(message) == ((string)(message)) && s.length() > 5)	//All uppercase
							{
								if(mYellList.count(user))
								{
									if(++mYellList[user] > 2)
									{
										action(channel, "covers his ears to block out %s's yelling", user);
										mYellList[user] = 0;
									}
								}
								else
									mYellList[user] = 1;
							}
							else if(touppercase(message) != ((string)(message)))	//Not all uppercase
							{
								mYellList[user] = 0;	//Reset yell counter
							}
							
							if(s.size())
							{
								//regex
								char errbuf[512];
								string sURL = message;
								//Extremely simple and stupid regex for URLs
								TRex* pRegex = trex_compile("https?://\\S*", (const char**)&errbuf);
								if(pRegex != NULL)
								{
									memcpy(errbuf, sURL.c_str(), sURL.length());
									const TRexChar *out_begin,*out_end;
									const TRexChar *out_temp = sURL.c_str();
									while(trex_search(pRegex, out_temp, &out_begin, &out_end))
									{
										string sTemp;
										for(const char* it = out_begin; it != out_end; it++)
										{
											if(sTemp.size() == 4 && *it == 's');	//Convert https: links to http:
											else
												sTemp.push_back(*it);
										}
										Lua.call("saytitle", channel, sTemp.c_str());
										out_temp = out_end;
									}
									
									trex_free(pRegex);
								}
								else
									printf("trex error: %s\n", errbuf);
								
							}
							
							//Check and see if rps battle
							rpschoose(channel, message, user);
						}
						
						//Mark last time seen this user
						mLastSeen[tolowercase(user)] = time(NULL);
						mLastMessage[tolowercase(user)] = "saying ";
						mLastMessage[tolowercase(user)] += message;
					}*/
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
