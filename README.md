Parse freely available Coded Instrument Flight Procedures (CIFP) raw data from AeroNav/FAA as ARINC424 v18 into SQLite3 database

See here for an example of the output of this utility: https://www.dropbox.com/s/htex68b9fn4mgso/cifp-1707.db.zip?dl=0

See how Instrument Procedures (including SIDs and STARs) are actually constructed!

These instructions are based on using Ubuntu 1604

How to get this utility up and running:

	Enable the "universe" repository in "Software & Updates" section of System Settings and update

	Install git
		sudo apt install git

	Download the repository
		git clone https://github.com/jlmcgraw/parseCifp.git

        Run ./setup.sh
                Installs some dependencies and sets up git hooks
		 
	Requires perl version > 5.010

How to use

	Download free CIFP data from AeroNav
	
                ./freshen_local_cifp.sh .
					or 
				visit http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/
	    
	./parseCifp.sh <path to downloaded cifp files>
            eg ./parseCifp.sh ./www.aeronav.faa.gov/Upload_313-d/cifp/cifp_201704.zip   
	
	Usage: ./parseCifp.pl <options> <directory>
		-v debug
		-e expand coded text (not implemented yet)
		-g create spatialite compatible geometry (not implemented yet)


Output is in cifp-<cycle>.db

Check out some of the sample queries in "Sample CIFP SQL queries.sql" for ideas on how to get at the data

This software and the data it produces come with no guarantees about accuracy or usefulness whatsoever!  Don't use it when your life may be on the line!

Thanks for trying this out!  If you have any feedback, ideas or patches please submit them to github.

-Jesse McGraw
jlmcgraw@gmail.com
