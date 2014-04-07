#include "bot.h"

void eightball(const char* channel)
{
	switch(rand() % 20)
	{
		case 0:
			say(channel, "It is certain");
			break;
			
		case 1:
			say(channel, "It is decidedly so");
			break;
			
		case 2:
			say(channel, "Without a doubt");
			break;
			
		case 3:
			say(channel, "Definitely");
			break;
			
		case 4:
			say(channel, "You may rely on it");
			break;
			
		case 5:
			say(channel, "As I see it, yes");
			break;
			
		case 6:
			say(channel, "Most likely");
			break;
			
		case 7:
			say(channel, "Outlook good");
			break;
			
		case 8:
			say(channel, "Yes");
			break;
			
		case 9:
			say(channel, "Signs point to yes");
			break;
			
		case 10:
			say(channel, "Reply hazy. Try again");
			break;
			
		case 11:
			say(channel, "Ask again later");
			break;
			
		case 12:
			say(channel, "I'd better not tell you now");
			break;
			
		case 13:
			say(channel, "Cannot predict now");
			break;
			
		case 14:
			say(channel, "Concentrate and ask again");
			break;
			
		case 15:
			say(channel, "Don't count on it");
			break;
			
		case 16:
			say(channel, "No");
			break;
			
		case 17:
			say(channel, "My sources say no");
			break;
			
		case 18:
			say(channel, "Outlook not so good");
			break;
			
		case 19:
			say(channel, "Very doubtful");
			break;
			
	}
}

void cookie(const char* channel, string user, string sCompare)
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

void ex(const char* channel, const char* message, const char* nick)
{
	//Insult people's exes
	//Split
	list<string> lWords = splitWords(tolowercase(&message[4]));
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

void hug(const char* channel, const char* message, const char* user)
{
	say(channel, "Setting phasors to hug.");
	sleep(rand() % 5 + 1);	//Pause for a random amount of time
	if(strlen(message) > 7)	//Hug somebody else
	{
		string sPerson = stripNewline(&message[5]);
		
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

void hai(const char* channel)
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

void bai(const char* channel)
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

void seen(const char* channel, const char* message)
{
	string sPerson = tolowercase(stripEnd(message));
	list<string> sset = splitWords(sPerson, false);
	sPerson = *sset.begin();
	if(mLastSeen.count(sPerson))
	{
		//Say last time this user was seen active
		unsigned int diff = (int)(difftime(time(NULL), mLastSeen[sPerson]));
		unsigned int seconds = diff % 60;
		unsigned int minutes = (diff / 60) % 60;
		unsigned int hours = (diff / (60*60)) % 24;
		unsigned int days = diff / (60*60*24);
		say(channel, "User %s was last seen %dd, %dh, %dm, %ds ago, %s", (stripEnd(message)).c_str(), days, hours, minutes, seconds, mLastMessage[tolowercase(sPerson)].c_str());
	}
}

void uptime(const char* channel)
{
	//Say the length of time we've been online
	unsigned int diff = (int)(difftime(time(NULL), starttime));
	unsigned int seconds = diff % 60;
	unsigned int minutes = (diff / 60) % 60;
	unsigned int hours = (diff / (60*60)) % 24;
	unsigned int days = diff / (60*60*24);
	say(channel, "Uptime: %dd, %dh, %dm, %ds", days, hours, minutes, seconds);
}

bool bWar = false;
string sRPSUser1, sRPSUser2;
string sWeapon1, sWeapon2;
time_t tRPSTimeout;
void rpswar(const char* channel, const char* message, const char* user, const char* nick)
{
	if(bWar && difftime(time(NULL),tRPSTimeout) < 5*60)	//Time out after 5 mins
	{
		say(channel, "There's already a war going on between %s and %s!", sRPSUser1.c_str(), sRPSUser2.c_str());
	}
	else
	{
		string sPerson = stripRN(message);
		list<string> sset = splitWords(sPerson, false);
		sset.pop_front();
		sPerson = sset.front();
		if(sNickList.count(sPerson))
		{
			if(user == sPerson)
			{
				say(channel, "You can't play rock paper scissors against yourself, you noodle.");
				//return;
			}
			bWar = true;
			sRPSUser2 = sPerson;
			sRPSUser1 = user;
			sWeapon1 = sWeapon2 = "";
			say(channel, "%s has challenged %s to a dual to the death! \"/msg %s [weapon]\" with weapon = \"rock\", \"paper\", or \"scissors\".", user, sPerson.c_str(), nick);
			tRPSTimeout = time(NULL);	//Start timer
			//Notify both users how to play
			say(sPerson.c_str(), "Defend yourself from %s by typing \"rock\", \"paper\", or \"scissors\"", user);
			say(user, "Attack %s by typing \"rock\", \"paper\", or \"scissors\"", sPerson.c_str());
		}
		else
		{
			say(channel, "%s isn't here!", sPerson.c_str());
		}
	}
}

void rpsVictory(string sWinner, string sWinningWeapon, string sLoser, string sLosingWeapon, const char* channel)
{
	switch(rand() % 6)
	{
		case 0:
			sleep(3);
			say(channel, "%s attacks %s with %s!", sWinner.c_str(), sLoser.c_str(), sWinningWeapon.c_str());
			sleep(1);
			say(channel, "%s defends with %s!", sLoser.c_str(), sLosingWeapon.c_str());
			sleep(2);
			say(channel, "The shield breaks! %s is slain. %s gains %d EXP!", sLoser.c_str(), sWinner.c_str(), (rand() % 20) + 1);
			break;
			
		case 1:
			sleep(3);
			say(channel, "%s steps through the bushes, when suddenly a wild %s appears!", sLoser.c_str(), sWinner.c_str());
			sleep(1);
			say(channel, "%s uses %s! It's not very effective.", sLoser.c_str(), sLosingWeapon.c_str());
			sleep(1);
			say(channel, "%s uses %s! It's super effective! %s has fainted!", sWinner.c_str(), sWinningWeapon.c_str(), sLoser.c_str());
			break;
		
		case 2:
			sleep(3);
			say(channel, "<%s> Go! %s! Use Flame Breath!", sWinner.c_str(), sWinningWeapon.c_str());
			sleep(1);
			say(channel, "<%s> Go! %s! Use Water Wave!", sLoser.c_str(), sLosingWeapon.c_str());
			sleep(2);
			say(channel, "Water isn't very good against fire. %s dies horribly.", sLoser.c_str());
			break;
			
		case 3:
			sleep(3);
			say(channel, "%s attacks %s with %s!", sLoser.c_str(), sWinner.c_str(), sLosingWeapon.c_str());
			sleep(1);
			say(channel, "%s defends with %s!", sWinner.c_str(), sWinningWeapon.c_str());
			sleep(2);
			say(channel, "The attack reflects! %s is slain. %s gains %d EXP!", sLoser.c_str(), sWinner.c_str(), (rand() % 20) + 1);
			break;
			
		case 4:
			sleep(3);
			say(channel, "%s steps through the bushes, when suddenly a wild %s appears!", sWinner.c_str(), sLoser.c_str());
			sleep(1);
			say(channel, "%s uses %s! It's not very effective.", sLoser.c_str(), sLosingWeapon.c_str());
			sleep(1);
			say(channel, "%s uses %s! It's super effective! %s has fainted!", sWinner.c_str(), sWinningWeapon.c_str(), sLoser.c_str());
			break;
		
		case 5:
			sleep(3);
			say(channel, "<%s> Go! %s! Use Flame Breath!", sLoser.c_str(), sLosingWeapon.c_str());
			sleep(1);
			say(channel, "<%s> Go! %s! Use Water Wave!", sWinner.c_str(), sWinningWeapon.c_str());
			sleep(2);
			say(channel, "Fire isn't very good against water. %s dies horribly.", sLoser.c_str());
			break;
	}
}

void rpschoose(const char* channel, const char* message, const char* user)
{
	if(!bWar) return;
	
	string sWeapon = tolowercase(stripEnd(message));
	if(sWeapon == "rock")
	{
		if(user == sRPSUser1)
			sWeapon1 = sWeapon;
		else if(user == sRPSUser2)
			sWeapon2 = sWeapon;
		else return;
		say(channel, "%s has chosen!", user);
	}
	else if(sWeapon == "paper")
	{
		if(user == sRPSUser1)
			sWeapon1 = sWeapon;
		else if(user == sRPSUser2)
			sWeapon2 = sWeapon;
		else return;
		say(channel, "%s has chosen!", user);
	}
	else if(sWeapon == "scissors")
	{
		if(user == sRPSUser1)
			sWeapon1 = sWeapon;
		else if(user == sRPSUser2)
			sWeapon2 = sWeapon;
		else return;
		say(channel, "%s has chosen!", user);
	}
	else return;
	
	//Both players have chosen
	if(sWeapon1.size() && sWeapon2.size())
	{
		bWar = false;
		//Player 2 won
		if((sWeapon1 == "rock" && sWeapon2 == "paper") ||
		   (sWeapon1 == "paper" && sWeapon2 == "scissors") ||
		   (sWeapon1 == "scissors" && sWeapon2 == "rock"))
		{
			rpsVictory(sRPSUser2, sWeapon2, sRPSUser1, sWeapon1, channel);
		}
		//Player 1 won
		else if((sWeapon1 == "rock" && sWeapon2 == "scissors") ||
				(sWeapon1 == "paper" && sWeapon2 == "rock") ||
				(sWeapon1 == "scissors" && sWeapon2 == "paper"))
		{
			rpsVictory(sRPSUser1, sWeapon1, sRPSUser2, sWeapon2, channel);
		}
		else	//Draw
		{
			say(channel, "Both %s and %s beat each other over the head with %s, but neither wins!", sRPSUser1.c_str(), sRPSUser2.c_str(), sWeapon.c_str());
		}
		
	}
}

void botcommand(const char* message, const char* channel, const char* user, const char* nick)
{
	string sCompare = stripEnd(tolowercase(&message[1]));
	//Process different messages
	/*if(sCompare == "beep")
	{
		say(channel, "Imma bot. beep.");
	}*/
	if(sCompare == "ex")
	{
		ex(channel, message, nick);
	}
	else if(sCompare == "hug")
	{
		hug(channel, message, user);
	}
	/*else if(sCompare == "roll" ||
			sCompare == "dice" ||
			sCompare == "die" ||
			sCompare == "d6")	//random number
	{
		say(channel, "Rolling a d6...");
		int randnum = rand() % 6 + 1;
		say(channel, "You rolled a %d!", randnum);
	}
	else if(sCompare == "coin" ||
			sCompare == "quarter" ||
			sCompare == "flip" ||
			sCompare == "nickel" ||
			sCompare == "dime" ||
			sCompare == "penny")
	{
		action(channel, "flips a coin into the air");
		if(rand() % 2)
			say(channel, "It's heads!");
		else
			say(channel, "It's tails!");
	}*/
	else if(sCompare == "eightball" ||
			sCompare == "eight" ||
			sCompare == "8" ||
			sCompare == "8ball" ||
			sCompare == "shake")
	{
		eightball(channel);
	}
	else if(sCompare == "cookie" ||
			sCompare == "botsnack" ||
			sCompare == "snack")	//give a bot a cookie
	{
		cookie(channel, user, sCompare);
	}
	else if(sCompare == "reload")
	{
		readWords();
		printf("Reloading\n");
		gLua->call("dofile", "lua/init.lua");
	}
	else if(sCompare == "seen")
	{
		seen(channel, &message[6]);
	}
	else if(sCompare == "join")
	{
		join(channel);	//rejoin
	}
	else if(sCompare == "uptime")
	{
		uptime(channel);
	}
	/*else if(sCompare == "bitcoin")
	{
		string sTemp;
		string sDifficulty = getURLTitle("http://bitcoindifficulty.com/", sTemp);
		say(channel, sDifficulty.c_str());
	}*/
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
	//Google "I'm Feeling Lucky" search
	else if(sCompare.find("google") == 0 ||
			sCompare.find("search") == 0)
	{
		//TODO: Broken
		list<string> sList = splitWords(&message[1], true);
		if(sList.size())
			sList.erase(sList.begin());	//Remove first word
		
		const char* cGoogleURLStart = "http://www.google.com/search?q=";
		const char* cGoogleURLEnd = "&btnI";
		string sGoogleURL = cGoogleURLStart;
		for(list<string>::iterator i = sList.begin(); i != sList.end(); i++)
		{
			sGoogleURL += *i;
			list<string>::iterator j = i;
			if(++j != sList.end())
				sGoogleURL += '+';
		}
		sGoogleURL += cGoogleURLEnd;
		string sURLResult;
		string sTitle = getURLTitle(sGoogleURL, sURLResult);
		if(sTitle.size() && sURLResult.size())
			say(channel, "[%s] - %s", sTitle.c_str(), sURLResult.c_str());
		else
			say(channel, "Unable to fetch link.");
	}
	//Rock-paper-scissors challenge
	else if(sCompare.find("rps") == 0 ||
			sCompare.find("rockpaperscissors") == 0 ||
			sCompare.find("rock") == 0 ||
			sCompare.find("paper") == 0 ||
			sCompare.find("scissors") == 0 ||
			sCompare.find("war") == 0 ||
			sCompare.find("attack") == 0 ||
			sCompare.find("challenge") == 0)
	{
		rpswar(channel, message, user, nick);
	}
	else if(mLastSeen.count(sCompare))	//Username; say when they were last seen
	{
		seen(channel, &message[1]);
	}
}