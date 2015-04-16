#!/bin/sh
#
# Convert yesterday's .ozo file to MOSAIC ASCII

if [ -z $OZONE_DATA_DIR ]
then
  # OZONE_DATA_DIR is used by the Octave code to find the data
  # and must be in the environment before calling this script.
  echo OZONE_DATA_DIR is not set, unable to proceed
  exit 1
fi

# Where the Octave code is
OCTAVE_PATH=/home/senior/devel/bbb-mosaic-octave

NICE=/usr/bin/nice
OCTAVE=/usr/bin/octave

$NICE $OCTAVE --silent --path ${OCTAVE_PATH} --eval convert_yesterday

