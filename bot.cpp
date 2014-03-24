extern "C" {
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <netdb.h>
#include <stdarg.h>
};

#include <string>
#include <sstream>
#include <set>
#include <list>
#include <cstdlib>
#include <algorithm>
#include <fstream>
using namespace std;

int conn;
char sbuf[512];

set<string> mBadWords;
set<string> mBirdWords;

string tolowercase(string s)
{
	std::transform(s.begin(), s.end(), s.begin(), ::tolower);
	return s;
}

string touppercase(string s)
{
	std::transform(s.begin(), s.end(), s.begin(), ::toupper);
	return s;
}

void inputWordList(string sFilename, set<string>& dest)
{
	ifstream infile(sFilename.c_str());
	while(!infile.fail())
	{
		string sLine;
		getline(infile, sLine);
		if(sLine.size())
			dest.insert(sLine);
	}
}

void readWords()
{
	inputWordList("badwords.txt", mBadWords);
	inputWordList("birdwords.txt", mBirdWords);
}

string replaceChar(string s, char cSearch, char cReplace)
{
	size_t pos = 0;
	while((pos = s.find(cSearch, pos)) != string::npos)
		s[pos] = cReplace;
	return s;
}

string replaceWhitespace(string s)
{
	const char* cMarkup = "!-\";:?.,()";
	for(int c = 0; c < strlen(cMarkup); c++)
		s = replaceChar(s, cMarkup[c], ' ');
	printf("Replaced %s\n", s.c_str());
	return s;
}

list<string> splitWords(string s)
{
	list<string> ret;
	istringstream iss(replaceWhitespace(s));
	do
  {
      string sub;
      iss >> sub;
      ret.push_back(tolowercase(sub));
  } while (iss);
  return ret;
}

bool isInside(string s, set<string>& vec)
{
	s = tolowercase(s);
	for(set<string>::iterator i = vec.begin(); i != vec.end(); i++)
	{
		if(s.find(*i) != string::npos)
			return true;
	}
	return false;
}

void raw(char *fmt, ...) 
{
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(sbuf, 512, fmt, ap);
    va_end(ap);
    printf("<< %s", sbuf);
    write(conn, sbuf, strlen(sbuf));
}

void say(char* channel, char* msg, ...)
{
	raw("PRIVMSG %s :%s\r\n", channel, msg);
}

int main() 
{    
    char *nick = "immabot_";
    char *channel = "#bitbottest";
    char *host = "irc.esper.net";
    char *port = "6667";
    
    char *user, *command, *where, *message, *sep, *target;
    int i, j, l, sl, o = -1, start, wordcount;
    char buf[513];
    struct addrinfo hints, *res;
    
    srand (time(NULL));
    readWords();
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    getaddrinfo(host, port, &hints, &res);
    conn = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    connect(conn, res->ai_addr, res->ai_addrlen);
    
    raw("USER %s 0 0 :%s\r\n", nick, nick);
    raw("NICK %s\r\n", nick);
    
    while ((sl = read(conn, sbuf, 512))) 
    {
        for (i = 0; i < sl; i++) 
        {
            o++;
            buf[o] = sbuf[i];
            if ((i > 0 && sbuf[i] == '\n' && sbuf[i - 1] == '\r') || o == 512) {
                buf[o + 1] = '\0';
                l = o;
                o = -1;
                
                printf(">> %s", buf);
                
                if (!strncmp(buf, "PING", 4)) 
                {
                    buf[1] = 'O';
                    raw(buf);
                } 
                else if (buf[0] == ':') 
                {
                    wordcount = 0;
                    user = command = where = message = NULL;
                    for (j = 1; j < l; j++) 
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
                            if (j == l - 1) continue;
                            start = j + 1;
                        } 
                        else if (buf[j] == ':' && wordcount == 3) 
                        {
                            if (j < l - 1) message = buf + j + 1;
                            break;
                        }
                    }
                    
                    if (wordcount < 2) continue;
                    
                    if (!strncmp(command, "001", 3) && channel != NULL) 
                    {
                        raw("JOIN %s\r\n", channel);
                    } 
                    else if (!strncmp(command, "PRIVMSG", 7) || !strncmp(command, "NOTICE", 6)) 
                    {
                        if (where == NULL || message == NULL) continue;
                        if ((sep = strchr(user, '!')) != NULL) 
                        	user[sep - user] = '\0';
                        if (where[0] == '#' || where[0] == '&' || where[0] == '+' || where[0] == '!') 
                        	target = where; else target = user;
                        printf("[from: %s] [reply-with: %s] [where: %s] [reply-to: %s] %s", user, command, where, target, message);
                        
                        if(message[0] == '!')	//bot commands
                        {
                        	if(!strncmp(&message[1], "beep", 4))	//Process different messages
                        	{
                        		say(channel, "Imma bot. beep.");
													}
													else if(!strncmp(&message[1], "ex", 2))
                        	{
                        		say(channel, "Your ex is ugly");
													}
													else if(!strncmp(&message[1], "hug", 3))
                        	{
                        		say(channel, "Setting phasors to hug.");
                        		sleep(rand() % 7 + 1);	//Pause for a random amount of time
                        		if(strlen(message) > 5)	//Hug somebody else	//TODO: See if they're here first, and disappointed if not
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
                        			raw("PRIVMSG %s :\001ACTION hugs %s a little too tightly\001\r\n", channel, sPerson.c_str());
                        		}
                        		else	//hug the person who did the command
                        			raw("PRIVMSG %s :\001ACTION hugs %s a little too tightly\001\r\n", channel, user);
													}
													else if(!strncmp(&message[1], "roll", 4) ||
																	!strncmp(&message[1], "dice", 4) ||
																	!strncmp(&message[1], "die", 3) ||
																	!strncmp(&message[1], "d6", 2))
                        	{
                        		say(channel, "Rolling a d6...");
                        		int randnum = rand() % 6 + 1;
                        		raw("PRIVMSG %s :You rolled a %d!\r\n", channel, randnum);
													}
												}
												else	//Other misc. commands
												{
													string s = tolowercase(message);
													if(s.find(tolowercase(nick)) != string::npos)	//Highlighted; respond with a "your ex" joke
													{
														string sUser = user;
														
														//Kill command by privileged user
														if(s.find("cheese curls") != string::npos && sUser.find("Daxar") == 0)	//Password for shutting off
														{
															say(channel, "Kthxbai.");
															raw("PART %s :Quit command invoked by %s\r\n", channel, user);
															return 0;	//Quit
														}
														
														//hai
														else if(s.find("hi") != string::npos ||
															  		s.find("hai") != string::npos ||
															 		  s.find("hello") != string::npos ||
															 			s.find("hey") != string::npos ||
															 			s.find("sup") != string::npos)
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
														else if(s.find("bye") != string::npos ||
															  		s.find("bai") != string::npos ||
															 		  s.find("see ya") != string::npos ||
															 			s.find("so long") != string::npos ||
															 		  s.find("night") != string::npos ||
															 		  s.find("nite") != string::npos ||
															 		  s.find("n8") != string::npos ||
															 		  s.find("later") != string::npos)
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
																	say(channel, "toodles with oodles of noodles!");
																	break;
															}
														}
														
														//Insult people for highlighting the bot randomly
														else
														{
															//Split
															printf("split\n");
															list<string> lWords = splitWords(tolowercase(s));
															lWords.remove("");
															lWords.remove(nick);
															lWords.remove("action");
														
															if(lWords.size())
															{
																int num = rand() % lWords.size();
																list<string>::iterator word = lWords.begin();
																for(int i = 0; i < num; i++)
																	word++;
																raw("PRIVMSG %s :Your ex is %s\r\n", channel, word->c_str());
															}
														}
													}
													else if(isInside(s, mBadWords))	//Dirty language
													{
														raw("PRIVMSG %s :\001ACTION slaps %s for their foul language\001\r\n", channel, user);
													}
													else if(isInside(s, mBirdWords))	//Birdy language
													{
														raw("PRIVMSG %s :\001ACTION flaps %s for their fowl language\001\r\n", channel, user);
													}
													else if(touppercase(message) == ((string)(message)) && s.length() > 5)	//All uppercase
													{
														raw("PRIVMSG %s :\001ACTION covers his ears to block out %s's yelling\001\r\n", channel, user);
													}
												}
                    }
                    else if(!strncmp(command, "JOIN", 4))	//User joined
                    {
                    	string sUser = user;
                    	size_t pos = sUser.find('!');
                    	if(pos != string::npos)
                    	{
                    		sUser.erase(pos);
											}
                      if(tolowercase(sUser) != tolowercase(nick))	//Make sure it wasn't me
                    		raw("PRIVMSG %s :Hi %s!\r\n", channel, sUser.c_str());	//Say hi
										}
                }
            }
        }
    }
    
    return 0;
}
