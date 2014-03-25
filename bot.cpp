#include "bot.h"

int conn;

set<string> sBadWords;
set<string> sBirdWords;
map<string, int> mYellList;
set<string> sNickList;
set<string> sNickListLowercase;
map<string, time_t> mLastSeen;

int main() 
{	
	char sbuf[512];
#ifdef DEBUG
	char *nick = "immabot_";
	char *channel = "#bitbottest";
#else
	char *nick = "immabot";
	char *channel = "#bitblot";
#endif
	char *host = "irc.esper.net";
	char *port = "6667";
	
	char *user, *command, *where, *message, *sep, *target;
	int sl, o = -1, start, wordcount;
	char buf[513];
	
	srand (time(NULL));
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
				
				printf(">> %s", buf);
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
						printf("[from: %s] [reply-with: %s] [where: %s] [reply-to: %s] %s", user, command, where, target, message);
						
						if(message[0] == '!')	//bot commands
						{
							string sCompare = stripEnd(tolowercase(&message[1]));
							printf("compare %s\n", sCompare.c_str());
							//Process different messages
							if(sCompare == "beep")	
							{
								say(channel, "Imma bot. beep.");
							}
							else if(sCompare == "hug")
							{
								say(channel, "Setting phasors to hug.");
								sleep(rand() % 5 + 1);	//Pause for a random amount of time
								if(strlen(message) > 7)	//Hug somebody else
								{
									string sPerson = &message[5];
									size_t pos = sPerson.find('\r');
									if(pos != string::npos)
										sPerson.erase(pos);
									else
									{
										pos = sPerson.find('\n');
										if(pos != string::npos)
											sPerson.erase(pos);
									}
									list<string> sset = splitWords(sPerson, false);
									sPerson = *sset.begin();
									if(sNickListLowercase.count(tolowercase(sPerson)))	//Person is here
										action(channel, "hugs %s a little too tightly", sPerson.c_str());
									else	//Disappointed
									{
										string sHalfPerson = sPerson;
										sHalfPerson.erase(sHalfPerson.size() / 2);
										action(channel, "hugs %s...", sHalfPerson.c_str());
										sleep(2);
										say(channel, "%s isn't here!", sPerson.c_str());
										sleep(1);
										action(channel, "flops onto couch and sighs dejectedly");
									}
								}
								else	//hug the person who did the command
									action(channel, "hugs %s a little too tightly", user);
							}
							else if(sCompare == "roll" ||
									sCompare == "dice" ||
									sCompare == "die" ||
									sCompare == "d6")	//random number
							{
								say(channel, "Rolling a d6...");
								int randnum = rand() % 6 + 1;
								say(channel, "You rolled a %d!", randnum);
							}
							else if(sCompare == "cookie" ||
									sCompare == "botsnack" ||
									sCompare == "snack")	//give a bot a cookie
							{
								list<string> sset = splitWords(user, false);
								string sPerson = *sset.begin();
								switch(rand() % 3)
								{
									case 0:
										action(channel, "happily grabs %s from %s and runs away to bury it", sCompare.c_str(), sPerson.c_str());
										break;
									
									case 1:
										action(channel, "grabs %s and scarfs it down hungrily", sCompare.c_str());
										break;
									
									case 2:
										action(channel, "goes om nom nom");
										break;
								}
							}
							else if(sCompare == "reload")
							{
								readWords();
							}
							else if(sCompare == "seen")
							{
								
							}
							else if(sCompare == "join")
							{
								join(channel);	//rejoin
							}
							else if(sCompare.find("addbad") == 0)	
							{
								list<string> sList = splitWords(&message[1], true);
								for(list<string>::iterator i = sList.begin(); i != sList.end(); i++)
								{
									if(i != sList.begin())
										addWord(BAD_WORD_LIST, *i);
								}
							}
							else if(sCompare.find("addbird") == 0)	
							{
								list<string> sList = splitWords(&message[1], true);
								for(list<string>::iterator i = sList.begin(); i != sList.end(); i++)
								{
									if(i != sList.begin())
										addWord(BIRD_WORD_LIST, *i);
								}
							}
							else if(mLastSeen.count(sCompare))	//Username
							{
								//Say last time they were seen active
								unsigned int diff = (int)(difftime(time(NULL), mLastSeen[sCompare]));
								unsigned int seconds = diff % 60;
								unsigned int minutes = (diff / 60) % 60;
								unsigned int hours = (diff / (60*60)) % 24;
								unsigned int days = diff / (60*60*24);
								say(channel, "User %s was last seen %dd, %dh, %dm, %ds ago", (stripEnd(&message[1])).c_str(), days, hours, minutes, seconds);
							}
						}
						else	//Other misc. commands
						{
							string s = tolowercase(forceascii(message));
							set<string> words = ssplitWords(message);
							if(s.find(tolowercase(nick)) != string::npos)	//Highlighted; respond with a "your ex" joke
							{
								string sUser = user;
								
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
									switch(rand() % 3)
									{
										case 0:
											say(channel, "ohai");
											break;
											
										case 1:
											say(channel, "Hai thar!");
											break;
											
										default:
											say(channel, "sup word diggly dog");
											break;
									}
								}
								
								//bai
								else if(words.count("bye") ||
										words.count("bai") ||
										words.count("night") ||
										words.count("nite") ||
										words.count("n8") ||
										words.count("later"))
								{
									switch(rand() % 4)
									{
										case 0:
											say(channel, "Bai!");
											break;
											
										case 1:
											say(channel, "Nite!");
											break;
											
										case 2:
											say(channel, "Bye!");
											break;
											
										default:
											say(channel, "Toodles with oodles of noodles!");
											break;
									}
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
								
								//Insult people for highlighting the bot randomly
								else
								{
									//Split
									list<string> lWords = splitWords(tolowercase(s));
									//Cut out unacceptabru words
									for(list<string>::iterator i = lWords.begin(); i != lWords.end();)
									{
										if(i->length() < 4 || *i == nick || *i == "action")
											i = lWords.erase(i);
										else
											i++;
									}
								
									if(lWords.size())
									{
										int num = rand() % lWords.size();
										list<string>::iterator word = lWords.begin();
										for(int i = 0; i < num; i++)
											word++;
										say(channel, "Your ex is %s", word->c_str());
									}
								}
							}
							else if(isInside(s, sBadWords))	//Dirty language
							{
								action(channel, "slaps %s for their foul language", user);
							}
							else if(isInside(s, sBirdWords))	//Birdy language
							{
								action(channel, "pecks %s for their fowl language", user);
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
						}
						
						//Mark last time seen this user
						mLastSeen[tolowercase(user)] = time(NULL);
					}
					else if(!strncmp(command, "JOIN", 4))	//User joined
					{
						//Split user string by hand
						string sUser = tolowercase(user);
						size_t pos = sUser.find('!');
						if(pos != string::npos)
							sUser.erase(pos);
						if(tolowercase(sUser) != tolowercase(nick))	//Make sure it wasn't me
						{
							//If left more than 60 seconds ago, or if we haven't seen them before, say hi
							if(!mLastSeen.count(sUser) || difftime(time(NULL), mLastSeen[sUser]) > 60.0)
								say(channel, "Hi %s!", sUser.c_str());	//Say hi
						}
						sNickList.insert(user);	//Add user to current user list
						sNickListLowercase.insert(sUser);
						mLastSeen[sUser] = time(NULL);
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
						join(channel);	//rejoin
					}
				}
			}
		}
	}
	shutdownNetworking();
	return 0;
}
