#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Download latest cifp from faa/aeronav
if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 <where_to_save_cifp>" >&2
  exit 1
fi

#Get command line parameters
AERONAV_ROOT_DIR="$1"

if [ ! -d $AERONAV_ROOT_DIR ]; then
    echo "$AERONAV_ROOT_DIR doesn't exist"
    exit 1
fi

#Exit if we ran this command within the last 24 hours (adjust as you see fit)
if [ -e ./lastCifpRefresh ] && [ $(date +%s -r ./lastCifpRefresh) -gt $(date +%s --date="24 hours ago") ]; then
 echo "CIFP updated within last 24 hours, exiting"
 exit
fi 

#Update the time of this file so we can check when we ran this last
touch ./lastCifpRefresh

cd $AERONAV_ROOT_DIR

#Get all of the latest charts
set +e
wget \
    --recursive \
    -l1 \
    --span-hosts \
    --domains=aeronav.faa.gov,www.faa.gov \
    --timestamping \
    --no-parent \
    -A.zip \
    -erobots=off \
    http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/download/
set -e


    
