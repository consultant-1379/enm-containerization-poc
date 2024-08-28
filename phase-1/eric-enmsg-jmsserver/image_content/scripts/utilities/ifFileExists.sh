#!/bin/sh

#######################################
# Action :
#   Check if the file specified by the
#   argument exists or not. The purpose
#   of this script is to be used along
#   with timeout method.
# Arguments:
#   absolute path of the file
# Returns:
#   0 if file exists
#   1 if file does not exist
#######################################

if [ -f "$1" ]; then
    exit 0
else
    exit 1
fi