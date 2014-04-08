#include "bot.h"

void eightball(const char* channel)
{
	
}

void cookie(const char* channel, string user, string sCompare)
{
	
}

void ex(const char* channel, const char* message, const char* nick)
{
	
}

void hug(const char* channel, const char* message, const char* user)
{
	
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
	
}

void uptime(const char* channel)
{
	
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
	if(sCompare.find("addbad") == 0)	
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
}