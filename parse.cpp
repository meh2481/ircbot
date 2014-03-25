#include "bot.h"

string forceascii(const char* msg)
{
	string s;
	for(int i = 0; i < strlen(msg); i++)
	{
		if(msg[i] == '\n' || msg[i] == '\r') break;	//Done
		if(msg[i] >= ' ' && msg[i] <= '~') 
			s.push_back(msg[i]);
	}
	return s;
}

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
		{
			dest.insert(tolowercase(sLine));
			//Deal with possible plural cases as well
			dest.insert(tolowercase(sLine + "s"));
			dest.insert(tolowercase(sLine + "es"));
		}
	}
	infile.close();
}

void readWords()
{
	sBadWords.clear();
	sBirdWords.clear();
	inputWordList(BAD_WORD_LIST, sBadWords);
	inputWordList(BIRD_WORD_LIST, sBirdWords);
}

void addWord(string sFilename, string sWord)
{
	ofstream ofile(sFilename.c_str(), ios_base::app);
	if(!ofile.fail())
		ofile << sWord << endl;
	ofile.close();
	
	readWords();	//Reload list
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
	return s;
}

set<string> ssplitWords(string s, bool bLowercase)
{
	set<string> ret;
	istringstream iss(replaceWhitespace(s));
	do
	{
		string sub;
		iss >> sub;
		if(!sub.size()) continue;
		if(bLowercase)
			ret.insert(tolowercase(sub));
		else
			ret.insert(sub);
	} while (iss);
  return ret;
}

list<string> splitWords(string s, bool bLowercase)
{
	list<string> ret;
	istringstream iss(replaceWhitespace(s));
	do
	{
		string sub;
		iss >> sub;
		if(!sub.size()) continue;
		if(bLowercase)
			ret.push_back(tolowercase(sub));
		else
			ret.push_back(sub);
	} while (iss);
	return ret;
}

string stripEnd(string s)
{
	size_t pos = s.find('\r');
	if(pos != string::npos)
		s.erase(pos);
	pos = s.find('\n');
	if(pos != string::npos)
		s.erase(pos);
	if(s[s.size()-1] == ' ')
		s.erase(s.size()-1);
	list<string> words = splitWords(s, false);
	return *(words.begin());
}

bool isInside(string s, set<string>& sSet)
{
	s = tolowercase(s);
	set<string> lWords = ssplitWords(s);
	for(set<string>::iterator i = lWords.begin(); i != lWords.end(); i++)
	{
		if(sSet.count(*i))
			return true;
	}
	return false;
}