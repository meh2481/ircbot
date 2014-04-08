#include "bot.h"

#ifdef DEBUG
	const char *nick = "immabot_";
	const char *channel = "#bitbottest";
#else
	const char *nick = "immabot";
	const char *channel = "#bitblot";
#endif

int conn;
time_t starttime;
LuaInterface* gLua;
set<string> sBadWords;
set<string> sBirdWords;
map<string, int> mYellList;
set<string> sNickList;
set<string> sNickListLowercase;
map<string, time_t> mLastSeen;
map<string, string> mLastMessage;
map<string, time_t> mLastPecked;
map<string, time_t> mLastSlapped;

int main(int argc, char** argv) 
{	
	LuaInterface Lua("lua/init.lua", argc, argv);
	gLua = &Lua;
	char sbuf[512];
	char *host = "irc.esper.net";
	char *port = "6667";
	
	char *user, *command, *where, *message, *sep, *target;
	int sl, o = -1, start, wordcount;
	char buf[513];
	
	srand (time(NULL));
	starttime = time(NULL);
	Lua.Init();
	//Lua.call("dofile", "lua/init.lua");
	readWords();
	
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
					
					if (!strncmp(command, "001", 3) && channel != NULL) //Connected message
					{
						join(channel);
					} 
					else if (!strncmp(command, "PRIVMSG", 7) || !strncmp(command, "NOTICE", 6)) //Message from IRC
					{
						if (where == NULL || message == NULL) 
							continue;
						if ((sep = strchr(user, '!')) != NULL) 
							user[sep - user] = '\0';
						if (where[0] == '#' || where[0] == '&' || where[0] == '+' || where[0] == '!') 
							target = where; else target = user;
						//printf("[from: %s] [reply-with: %s] [where: %s] [reply-to: %s] %s", user, command, where, target, message);
						Lua.call("gotmessage", user, command, where, target, message);
						
						if(message[0] == '!')	//bot commands
						{
							botcommand(message, channel, user, nick);
						}
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
					}
					else if(!strncmp(command, "JOIN", 4))	//User joined
					{
						//Split user string by hand
						string sUser = tolowercase(user);
						size_t pos = sUser.find('!');
						if(pos != string::npos)
							sUser.erase(pos);
						sNickList.insert(user);	//Add user to current user list
						sNickListLowercase.insert(sUser);
						mLastSeen[sUser] = time(NULL);
						mLastMessage[sUser] = "joining IRC";
					}
					else if(!strncmp(command, "PART", 4) ||
							!strncmp(command, "QUIT", 4))	//User left
					{
						//Split user string by hand
						string sUser = user;
						size_t pos = sUser.find('!');
						if(pos != string::npos)
							sUser.erase(pos);
						sNickList.erase(sUser);	//Remove user from current user list
						sNickListLowercase.erase(tolowercase(sUser));
						mLastSeen[tolowercase(sUser)] = time(NULL);
						mLastMessage[tolowercase(sUser)] = "leaving IRC";
					}
					else if(!strncmp(command, "KICK", 4))	//User kicked from channel
					{
						say(channel, "Trololol");	//Bask in the glory of a user being kicked
					}
					else if(!strncmp(command, "353", 3))	//List of nicks currently in channel (353 for espernet, freenode, efnet, so I'm assuming everywhere else also)
					{
						//Search for end of message to avoid overflow
						for(int i = 0; i < 512; i++)
						{
							if(tempbuf[i] == '\r' || tempbuf[i] == '\n')
							{
								tempbuf[i] = '\0';
								break;
							}
						}
						string s = &tempbuf[1];	//Skip over first ':' char
						size_t pos = s.find(':');
						if(pos != string::npos)
						{
							s.erase(0, pos+1);	//Erase beginning of string, so all we're left with is nicks
							list<string> sNicks = splitWords(s, false);	//Split into individual nicks, case sensitive
							for(list<string>::iterator i = sNicks.begin(); i != sNicks.end(); i++)
							{
								//Deal with op symbols
								string sNick = *i;
								if(sNick[0] == '~' ||
								   sNick[0] == '&' ||
								   sNick[0] == '@' ||
								   sNick[0] == '%' ||
								   sNick[0] == '+')
								{
									sNick.erase(0,1);
								}
								if(sNick.size())
								{
									sNickList.insert(sNick);
									sNickListLowercase.insert(tolowercase(sNick));
								}
							}
						}
					}
					else if(!strncmp(command, "404", 3))	//404 can't send to channel
					{
						sleep(60*2);	//Wait 2 minutes
						join(channel);	//rejoin channel
					}
				}
			}
		}
	}
	shutdownNetworking();
	return 0;
}
