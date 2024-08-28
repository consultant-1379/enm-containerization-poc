OPYRIGHT Ericsson 2017
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

source "$JBOSS_HOME/bin/jbosslogger"

GREP="/bin/grep"
XMLLINT="/usr/bin/xmllint"
XSLTPROC="/usr/bin/xsltproc"
GOSSIPROUTER_XSL="$JBOSS_HOME/standalone/data/gossiprouter/gossiprouter.xsl"
STANDALONE_FILE="$JBOSS_HOME/standalone/configuration/$JBOSS_CONFIG"

update_jgoups_protocolstack()
{
    $XSLTPROC --output "$2" "$1" "$2"
    if [ $? == 0 ]
    then
        info "Successfully updated JGroups protocol stack"
    else    
        error "Failed to update JGroups protocol stack, will exit with error code 1"
        exit 1
    fi

    $XMLLINT --output "$2" --format "$2"
    if [ $? == 0 ]
    then
	info "Successfully formatted $2"
    else
	warn "Failed to format $2"
    fi
}
#Main starts here
if [ "${JGROUPS_STACK}" == "tcp-gossip" ]
then
    if $GREP "<subsystem.*urn:jboss:domain:jgroups:1.1" "$STANDALONE_FILE"
    then
        info "Updating jgroups protocol stack to tcp-gossip"
        update_jgoups_protocolstack "$GOSSIPROUTER_XSL" "$STANDALONE_FILE"
    else
        info "Jgroups subsystem does not exist, no need to update jboss configuration"
    fi
else
    info "Jgroups protocol stack is udp, no need to update jboss configuration"
fi
