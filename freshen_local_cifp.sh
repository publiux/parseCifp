#!/bin/bash
set -eu                 # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')    # Always put this in Bourne shell scripts

# Download latest cifp from faa/aeronav

# The script begins here
# Set some basic variables
declare -r PROGNAME=$(basename "$0")
declare -r PROGDIR=$(readlink -m "$(dirname "$0")")

# Get the number of remaining command line arguments
NUMARGS=$#

# Validate number of command line parameters
if [ "$NUMARGS" -ne 1 ] ; then
    echo "Usage: $PROGNAME <DOWNLOAD_ROOT_DIR>" >&2
    exit 1
fi

# Get command line parameters
DOWNLOAD_ROOT_DIR="$1"

# Check that our destination exists
if [ ! -d "$DOWNLOAD_ROOT_DIR" ]; then
    echo "$DOWNLOAD_ROOT_DIR doesn't exist" >&2
    exit 1
fi

# Name of file used as last refresh marker
REFRESH_MARKER="${PROGDIR}/last_faa_refresh"

# Exit if we ran this command within the last 24 hours (adjust as you see fit)
if [ -e "${REFRESH_MARKER}" ] && \
   [ "$(date +%s -r "${REFRESH_MARKER}")" -gt "$(date +%s --date="24 hours ago")" ]
    then
    echo "CIFP updated within last 24 hours, exiting"  >&2
    exit 1
fi 

# Update the time of this file so we can check when we ran this last
touch "${REFRESH_MARKER}"

# Get all of the latest charts
set +e
    wget \
        --directory-prefix="$DOWNLOAD_ROOT_DIR" \
        --recursive                             \
        -l1                                     \
        --span-hosts                            \
        --domains=aeronav.faa.gov,www.faa.gov   \
        --timestamping                          \
        --no-parent                             \
        -A.zip                                  \
        -erobots=off                            \
        http://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/download/

    echo "wget return code was $?"
set -e


    
