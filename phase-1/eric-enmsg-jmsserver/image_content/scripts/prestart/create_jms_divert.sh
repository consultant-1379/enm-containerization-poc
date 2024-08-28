#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2016
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

# Command list
LS=/bin/ls
AWK=/bin/awk
GREP=/bin/grep
EGREP=/bin/egrep
ECHO=/bin/echo

# UTILITIES
RPM="/bin/rpm --quiet"
_XSLTPROC=/usr/bin/xsltproc

# Set default values for Global Variables
if [ -z "$JBOSS_CONFIG" ]; then
    JBOSS_CONFIG="standalone-enm.xml"
fi

if [ -z "$JBOSS_HOME" ]; then
	JBOSS_HOME="/ericsson/3pp/jboss"
fi

if [ -z "$GLOBAL_CONFIG" ]; then
	GLOBAL_CONFIG="/ericsson/tor/data/global.properties"
fi

FOLDER_XML_XSL="${JBOSS_HOME}/standalone/data/diverts"
JMS_DESTINATIONS_FILE="${FOLDER_XML_XSL}/ebs_present.xml"
LOG_TAG="ERICenmsgjmsserver_CXP9031572"
STANDALONE_FILE="${JBOSS_HOME}/standalone/configuration/$JBOSS_CONFIG"
XSLSCRIPT="$FOLDER_XML_XSL/create_divert.xsl"
XMLLINT_INDENT="    "
export XMLLINT_INDENT


#//////////////////////////////////////////////////////////////
# This function will print an info message to /var/log/messages
# Arguments:
#       $1 - Message
# Return: 0
#/////////////////////////////////////////////////////////////
info()
{
    logger -s -t ${LOG_TAG} -p user.notice "INFORMATION (): $1"
}

# main body

# Loop through all the xml files in the divert folder
for _divert_file_ in $($LS ${FOLDER_XML_XSL} | $EGREP ".xml$"); do

	_property_name_=$($ECHO $_divert_file_  | $AWK -F"." {'print $1'})
	_property_value_=$($GREP -E "^${_property_name_}=" ${GLOBAL_CONFIG}  | $AWK -F"=" '{print $2}' )
	divert_file_path=${FOLDER_XML_XSL}/${_divert_file_}

	# Check for the property in global properties file
    if [ "${_property_value_}" = "true" ]; then

		info "${_property_name_} found in ${GLOBAL_CONFIG}, setting up divert queues from ${divert_file_path}"
		if [ -f ${divert_file_path} ] && [ -f $STANDALONE_FILE ]; then
		    info "Copy JMS topics from ${divert_file_path} into $STANDALONE_FILE"
		    $_XSLTPROC --output $STANDALONE_FILE --stringparam jms_destinations_file ${divert_file_path} --stringparam jboss_config_file $STANDALONE_FILE $XSLSCRIPT $STANDALONE_FILE
		else
			info "File ${divert_file_path} or $STANDALONE_FILE not found"
		fi
	else 
		info "${_property_name_} not found in ${GLOBAL_CONFIG}, not setting up divert queue"
	fi
done
