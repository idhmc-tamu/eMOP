
#include <iostream>
#include <string>
#include <fstream>
#include <regex>
#include <iterator>
#include <array>

using namespace std;

//string all[100];



// int first word that is not ___r(i/y)nted, at, in

string allLoc[100];// global array that stores the matched regex
int totalLocCount=0;// no of ellements in array-1 

int findlocationbraces(string s)/*takes a string and finds the first word in all ocurences of braces*/
{
	std::regex words_regex("\\[[^\\s]+");// the regex formula: [ *then till a space*
    auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) { // itereates through the matches 
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
        allLoc[totalLocCount]=match_str; // adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
	return std::distance(words_begin, words_end);// returns the number of matches added to global array
	
}
int findlocationfirstword(string s)/*finds the first word ie. anything befor the first occurence of space*/
{
	 
	
	 std::regex words_regex("(.*?)\\s");// the regex formula: *anything till a space*
    auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
	std::sregex_iterator i = words_begin;
	if(i != words_end)// check if it matched anything 
	{
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 

		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
	}

	return std::distance(words_begin, words_end);// returns the number of matches added to global array


}
int findlocationbetween2stringsPRINTED(string s)//matches anything like: r(i/y)nted in/at *follwed by anything then one ore more* in||at||the *then one of* date||:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe  //
{
	
	std::regex words_regex("(([a-zA-Z]*r(i|y)nted\\s+(in|In|At|at)))\\s+(.*?)(?=((in|at)*(the)*(\\d|:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches 
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
	return std::distance(words_begin, words_end);// returns the number of matches added to global array
}
int findlocationbetween2stringsIN(string s)//between: in|IN *and one ore more* in||at||the *then one of* date||:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe  //
{
	std::regex words_regex("(in|In)\\s+(.*?)(?=((in|In|At|at)*(the)*(\\d|:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
	for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
        
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
	return std::distance(words_begin, words_end);// returns the number of matches added to global array
}

int findlocationbetween2stringsAT(string s)//between: at *and one ore more* in||at||the *then one of* date|:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe  //
{
	std::regex words_regex("(at|At)\\s+(.*?)(?=((in|In|At|at)*(the)*(\\d|:|yere\\s|year\\s|by\\s|By\\s|Year\\s|yeare\\s|MD|sold\\s|Sold\\s|signe\\s|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
        
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
	return std::distance(words_begin, words_end);// returns the number of matches added to global array
}

void findprinted_by(string s)//between: ___r(i/y)nted *followed by* by|By|by and for|by me *and one ore more* in||at||the *then one of* date |yere |year |Year|yeare|MD|sold |Sold |signe |to |at |for |in |(and are to) |printers to|and sold by|dwelling|dwellyng|Dwellynge|wythin|by the Assignes of|are to be|Reprinted|//
{
	std::regex words_regex("([a-zA-Z]*r(i|y)nted\\s+\\[*((by|By)|((by|By)\\sand\\s(for|For))|((by|By)\\sme)))\\s+(.*?)(?=((and)*(in|at)*(the)*(\\d|yere\\s|year\\s |Year\\s|yeare\\s|MD|sold\\s|Sold\\s|signe\\s|to\\s|at\\s|for\\s|in\\s|(and\\s+are\\s+to) |printers\\s+to|and\\s+sold\\s+by|dwelling|dwellyng|Dwellynge|wythin|by\\sthe\\sAssignes\\sof|are\\sto\\sbe|Reprinted|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
       
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
}





void findprinted_by2(string s) // *same as findprinted_by except after printed* !sold by *is an option. done due many different cases in data where printed by me is followed by sold and then more relavent data follows*  
{
	std::regex words_regex("([a-zA-Z]*r(i|y)nted\\s+\\[*((by|BY)|((By|by)\\sand\\s(for|For))|((by|By)\\sme)|((.*?)(?!((sold|Sold)))\\s+(By|by))))\\s+(.*?)(?=((\\d|yere\\s|year\\s |Year\\s|yeare\\s|MD|sold\\s|Sold\\s|signe\\s|to\\s|at\\s|for\\s|in\\s|and\\s+are\\s+to|printers\\s+to|and\\s+sold\\s+by|dwelling|dwellyng|Dwellynge|wythin|by\\sthe\\sAssignes\\sof|are\\sto\\sbe|Reprinted|$)))");
	
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
      
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
} 

void findBy(string s)//between: by *folowed by anything that does not include* sold by||by and for|by me *or one ore more* in||at||the *then one of* date |yere\\s|year\\s |Year\\s|yeare\\s|MD|sold\\s|Sold\\s|signe\\s|to\\s|at\\s|for\\s|in\\s|(and\\s+are\\s+to) |printers\\s+to|and\\s+sold\\s+by|dwelling|dwellyng|Dwellynge|wythin|by\\sthe\\sAssignes\\sof|are\\sto\\sbe|Reprinted
{
	std::regex words_regex("((^(by|By))|((.*?)(?!(sold|Sold))\\s+((by|By)))|((.*?)(?!(sold|Sold))\\s+((by|By)\\sand\\s(for|For))|((.*?)(?!(sold|Sold))\\s+((by|By)\\sme))|((.*?)(?!(sold))\\s+(by))))\\s+(.*?)(?=((and)*(in|at)*(the)*(\\d|yere\\s|year\\s |Year\\s|yeare\\s|MD|sold\\s|Sold\\s|signe\\s|to\\s|at\\s|for\\s|in\\s|(and\\s+are\\s+to) |printers\\s+to|and\\s+sold\\s+by|dwelling|dwellyng|Dwellynge|wythin|by\\sthe\\sAssignes\\sof|are\\sto\\sbe|Reprinted|$)))");
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
} 

void findprintedfor(string s)//between: r(i\y)nted for|by and for| *anything followed by * for * folowed spaces or a comma folloewd by one ore more* in||at||the *then one of* date|:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe
{
	std::regex words_regex("([a-zA-Z]*r(i|y)nted\\s+((for|For)|((by|By)\\sand\\s(for|For))|((.*?)\\s((for|For)))))(\\s|,)+(.*?)(?=((in|at)*(the)*(\\d|:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
        
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
}

void findfor(string s)//between:  for *folowed by spaces or comma andone ore more* in||at||the *then one of* date|:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe 
{
	std::regex words_regex("((for|For))(\\s|,)+(.*?)(?=((in|In|At|at)*(the)*(\\d|:|yere|year|by|By|Year|yeare|MD|sold|Sold|signe|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
      
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
}


void soldby(string s)//between:  sold by and in|at|\\d|:|yere|year|Year|yeare|MD|signe
{
	std::regex words_regex("((sold|Sold|soulde|Soulde))\\s+(by|By)\\s+(.*?)(?=((in|at|\\d|:|yere|year|Year|yeare|MD|signe|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
       
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
}

void sold(string s)//between sold and \\d|:|yere|year|Year|yeare|MD|signe|to\\s
{
	std::regex words_regex("(sold|Sold|soulde|Soulde|solde|Solde)\\[*\\]*\\s*(.*?)(?=((\\d|:|yere|year|Year|yeare|MD|signe|to\\s|$)))");   
	auto words_begin = 
        std::sregex_iterator(s.begin(), s.end(), words_regex);// here is where it actually searches for matching regex
    auto words_end = std::sregex_iterator();
 
    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {// itereates through the matches
        std::smatch match = *i;                                                 
        std::string match_str = match.str(); 
       
		allLoc[totalLocCount]=match_str;// adds the matches to global global array
		totalLocCount++;// increments the number of matches stored in global array
    }
}




void locationRegex( string line2 )// calls the location regex functions
{
	findlocationbraces(line2);
	findlocationbetween2stringsAT(line2);
	findlocationbetween2stringsIN(line2);
	findlocationbetween2stringsPRINTED(line2);
	

}

void printersRegex( string line2 )// calls the functions related to printers
{
	findBy(line2);
	findprinted_by2(line2);
	findprinted_by(line2);
}

void For( string line2 )// calls the functions related to for
{
	findfor(line2);
	findprintedfor(line2);

}

void Selling(string line2)// calls the functions related to sellers
{
	sold(line2);
	soldby(line2);
}


void readandwrite() // the function in which files are read and written too
{
	
	string line1;
	string line2;
	int count=0,LocCount=0,PrinterCount=0,ForCount=0,SellerCount=0;
	
	ifstream oin("CitationandImprint.txt", std::ifstream::in);// input
    ofstream complete ("complete.txt", std::ofstream::out);// complete output

	ofstream notloc ("notfoundLocation.txt", std::ofstream::out);// those that failed location regex
	ofstream notprinter ("notfoundPrinters.txt", std::ofstream::out);//those that failed printer regex
	ofstream notFor("notfoundFor.txt", std::ofstream::out);//those that failed for regex
	ofstream notseller ("notfoundSellers.txt", std::ofstream::out);//those that failed seller regex

	ofstream nothing("nothing.txt", std::ofstream::out);//those that failed everything
	ofstream everything("everything.txt", std::ofstream::out);// those that have For, printer, seller, location.

    while (!oin.eof())
	{  
		 
		std::getline(oin,line1);// reads citation id
		 if(line1!=""&&!oin.eof())
		 {
			std::getline(oin,line2);// reads imprint line
		    if(line2!="")
			{
				totalLocCount=0;
				LocCount=0;PrinterCount=0;ForCount=0;SellerCount=0;
				count++;
				cout<<"\n"<<line1;
				{
					
					
					locationRegex(line2);// regex location related opperations
					//////////////////////////////////////////writes the lines that did not have location data
					if(totalLocCount==0)
					{
						notloc<<line1<<"\n";
						notloc<<line2<<"\n\n";
					}
					else
					{
						LocCount=totalLocCount;
					}
					
					For(line2);// regex for related opperations
					//////////////////////////////////////////writes the lines that did not have for related data
					if(totalLocCount==LocCount)
					{
						notFor<<line1<<"\n";
						notFor<<line2<<"\n\n";
					}
					else
					{
						ForCount=totalLocCount-LocCount;
					}
					
					
					printersRegex(line2);// regex printers related opperations
					//////////////////////////////////////////writes the lines that did not have for printers data
					if(totalLocCount==ForCount+LocCount)
					{
						notprinter<<line1<<"\n";
						notprinter<<line2<<"\n\n";
					}
					else
					{
						PrinterCount=totalLocCount-LocCount-ForCount;
					}
					
					Selling(line2);// regex seller related opperations
					//////////////////////////////////////////writes the lines that did not have for seller data
					if(totalLocCount==ForCount+LocCount+PrinterCount)
					{
						notseller<<line1<<"\n";
						notseller<<line2<<"\n\n";
					}
					else
					{
						SellerCount= totalLocCount-LocCount-ForCount-PrinterCount;
					}
					findlocationfirstword(line2);
					////////////////////////////////////////////////////////////here the ones that have all the types of datat are written into file everything
					if(SellerCount>0&&LocCount>0&&ForCount>0&&PrinterCount>0)
					{
						everything<<"\n";
						everything<<line1<<"\n";
						everything<<line2<<"\n";
						everything<<"#$%^Location#$%^&*"<<"\n";
						for(int t=0;t<LocCount;t++)
							everything<<allLoc[t]<<"\n";
						everything<<"#$%^FOR#$%^&*"<<"\n";
						for(int t=LocCount;t<(LocCount+ForCount);t++)
							everything<<allLoc[t]<<"\n";
						everything<<"#$%^Printer#$%^&*"<<"\n";
						for(int t=(LocCount+ForCount);t<(LocCount+ForCount+PrinterCount);t++)
							everything<<allLoc[t]<<"\n";
						everything<<"#$%^Sellers#$%^&*"<<"\n";
						for(int t=(LocCount+ForCount+PrinterCount);t<(LocCount+ForCount+PrinterCount+SellerCount);t++)
							everything<<allLoc[t]<<"\n";


					}

					everything<<"#$%^firstword#$%^&*"<<"\n";
					everything<<allLoc[totalLocCount-1]<<"\n";
					//////////////////////////////////////////////every thing is written down again for compilation into one document	
					    complete<<"\n";
						complete<<line1<<"\n";
						complete<<line2<<"\n";
						complete<<"#$%^Location#$%^&*"<<"\n";
						for(int t=0;t<LocCount;t++)
							complete<<allLoc[t]<<"\n";
						complete<<"#$%^FOR#$%^&*"<<"\n";
						for(int t=LocCount;t<(LocCount+ForCount);t++)
							complete<<allLoc[t]<<"\n";
						complete<<"#$%^Printer#$%^&*"<<"\n";
						for(int t=(LocCount+ForCount);t<(LocCount+ForCount+PrinterCount);t++)
							complete<<allLoc[t]<<"\n";
						complete<<"#$%^Sellers#$%^&*"<<"\n";
						for(int t=(LocCount+ForCount+PrinterCount);t<(LocCount+ForCount+PrinterCount+SellerCount);t++)
							complete<<allLoc[t]<<"\n";
						complete<<"#$%^firstword#$%^&*"<<"\n";
					    complete<<allLoc[totalLocCount-1]<<"\n";

					

				}
	

			}
		 }

	}
		
	
}






void tester()// test any basic regex function here
{
	string line1;
	string line2;
	int count=0;
	ifstream oin("CitationandImprint.txt", std::ifstream::in);
	while (!oin.eof()&&count<100)
	{  
		 std::getline(oin,line1);
		 if(line1!=""&&!oin.eof())
		 {
			std::getline(oin,line2);
		    if(line2!="")
			{
				count++;
				cout<<"\n"<<line1<<"\n"<<line2<<"\n\n";
				if(count>0)
				{
					sold(line2);// insert function here
				}
			}
		 }
	}
}









int main()
{
    int a;
	
	readandwrite();
	//tester();
	cin>>a;
	return 0;
  
}
