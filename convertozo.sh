#!/bin/sh
#
# Convert yesterday's .ozo file to MOSAIC ASCII

# Where the .ozo files are stored
OZONE_DATA_DIR=/home/senior/devel/ozone_test/data

# Where the Octave code is
OCTAVE_PATH=/home/senior/devel/bbb-mosaic-octave

# Where we record what happened
LOGFILE=$HOME/convertozo.log

NICE=/usr/bin/nice
OCTAVE=/usr/bin/octave

export OZONE_DATA_DIR
$NICE $OCTAVE --silent --path ${OCTAVE_PATH} --eval convert_yesterday > $LOGFILE 2>&1

