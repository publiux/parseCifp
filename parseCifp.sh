#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

#Check count of command line parameters
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 cycle" >&2
  echo "eg. $0 1511"
  exit 1
fi

#Get command line parameters
cycle="$1"

#Where the CIFP data is unzipped to
datadir=./CIFP_20$cycle/

#Where to save files we create
outputdir=.

#delete any existing files
rm -f $outputdir/cifp-$cycle.db

echo "Creating the database"
#create the new sqlite database
#Create geometry and expand text
./parseCifp.pl -c$cycle $datadir

#add indexes
echo "Adding indexes"
sqlite3 $outputdir/cifp-$cycle.db < addIndexes.sql