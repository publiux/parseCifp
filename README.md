Parse Coded Instrument Flight Procedures (CIFP) raw data from AeroNav/FAA as ARINC424 v18 into SQLite3 database

These instructions are based on using Ubuntu 1404

How to get this utility up and running:

	Enable the "universe" repository in "Software & Updates" section of System Settings and update

	Install git
		sudo apt-get install git

	Download the repository
		git clone https://github.com/jlmcgraw/parseCifp.git

	Install the following external programs
		sqlite3 	(sudo apt-get install sqlite3)

	Install the following CPAN modules
		DBI 		(sudo apt-get install libdbi-perl)
		DBD::SQLite3	(sudo apt-get install libdbd-sqlite3-perl) 

	Provide CIFP data from AeroNav (available for purchase online)
		 FAACIFP18
		 
	Requires perl version > 5.010

How to use

	Usage: ./parseCifp.pl <options> <directory>
		-v debug
		-e expand coded text (not implemented yet)
		-g create spatialite compatible geometry (not implemented yet)

	


Output is in cifp.db

This software and the data it produces come with no guarantees about accuracy or usefulness whatsoever!  Don't use it when your life may be on the line!

Thanks for trying this out!  If you have any feedback, ideas or patches please submit them to github.

-Jesse McGraw
jlmcgraw@gmail.com