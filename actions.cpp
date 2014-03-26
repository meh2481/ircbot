#include "bot.h"

void eightball(const char* channel)
{
	action(channel, "shakes the 8-ball");
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
		say(channel, "User %s was last seen %dd, %dh, %dm, %ds ago", (stripEnd(message)).c_str(), days, hours, minutes, seconds);
	}
}

void botcommand(const char* message, const char* channel, const char* user, const char* nick)
{
	string sCompare = stripEnd(tolowercase(&message[1]));
	//Process different messages
	if(sCompare == "beep")
	{
		say(channel, "Imma bot. beep.");
	}
	else if(sCompare == "ex")
	{
		ex(channel, message, nick);
	}
	else if(sCompare == "hug")
	{
		hug(channel, message, user);
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
	}
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
	}
	else if(sCompare == "seen")
	{
		seen(channel, &message[6]);
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
	//Google "I'm Feeling Lucky" search
	else if(sCompare.find("google") == 0 ||
			sCompare.find("search") == 0)
	{
		list<string> sList = splitWords(&message[1], true);
		if(sList.size())
			sList.erase(sList.begin());	//Remove first word
		
		const char* cGoogleURLStart = "https://www.google.com/search?q=";
		const char* cGoogleURLEnd = "&btnI";
		string sResult = cGoogleURLStart;
		for(list<string>::iterator i = sList.begin(); i != sList.end(); i++)
		{
			sResult += *i;
			list<string>::iterator j = i;
			if(++j != sList.end())
				sResult += '+';
		}
		sResult += cGoogleURLEnd;
		say(channel, sResult.c_str());
	}
	else if(mLastSeen.count(sCompare))	//Username; say when they were last seen
	{
		seen(channel, &message[1]);
	}
}