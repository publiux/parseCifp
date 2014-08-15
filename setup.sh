#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

sudo apt-get install sqlite3
sudo apt-get install libdbi-perl
sudo apt-get install libdbd-sqlite3-perl 
