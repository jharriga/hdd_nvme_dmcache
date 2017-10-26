#!/bin/bash
#----------------------------------------------------------------
# TEARDOWN.sh - cleanup/teardown lvm device configuration
#
# CONFIGURATION:
#
#----------------------------------------

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# MANDATORY: set the deviceMODE and runMODE vars
deviceMODE="teardown"

# Variables
source "$myPath/vars.shinc"
# Functions
source "$myPath/Utils/functions.shinc"

# Assign LOGFILE
LOGFILE="./LOGFILEteardown"

#--------------------------------------

# Create new log file
if [ -e $LOGFILE ]; then
  rm -f $LOGFILE
fi
touch $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "$PROGNAME - Created logfile: $LOGFILE"

# TEARDOWN device configuration
updatelog "Starting: device TEARDOWN"
source "$myPath/Utils/teardownDEVICES.shinc"
updatelog "Completed: device TEARDOWN"

updatelog "$PROGNAME - END"
echo "END ${PROGNAME}**********************"
exit 0
