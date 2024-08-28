#!/bin/bash
##########################################################################
# COPYRIGHT Ericsson 2018
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

JAVA_SECURITY_FILE="/usr/java/default/jre/lib/security/java.security"
CIPHER=", 3DES_EDE_CBC"

#*****************************************************************************#
# This function will enable the use of 3DES_EDE_CBC cipher
# which are disabled in JAVA 8 by removing the cipher from
# jdk.tls.disabledAlgorithms property of java.security file in the VM .
#*****************************************************************************#
function enable_3DES_EDE_CBC_ciphers ()
{
 logger "Start of enable 3DES_EDE_CBC"

 if [ -f ${JAVA_SECURITY_FILE} ]; then

 #Get the line number starting with the string "jdk.tls.disabledAlgorithms="
 lineno=$(grep -n '^jdk.tls.disabledAlgorithms=' $JAVA_SECURITY_FILE | cut -d: -f 1)

 #Get the String at the line number
 str=$(awk "NR==$lineno {print;exit}" $JAVA_SECURITY_FILE)

 #Get the last Character of the String
 c=${str: -1}
 echo "$lineno"

 #iterating each line until the last character is not '\'
 while [ $c = '\' ]
 do
 ((lineno++))
 str=$(awk "NR==$lineno {print;exit}" $JAVA_SECURITY_FILE)
 c=${str: -1}
 done

 echo "Before removing the cipher"
 awk "NR==$lineno {print;exit}" $JAVA_SECURITY_FILE

 #Remove the cipher 3DES_EDE_CBC from line number
 sed -i "$lineno s/$CIPHER//g" $JAVA_SECURITY_FILE

 echo "After removing the cipher"
 awk "NR==$lineno {print;exit}" $JAVA_SECURITY_FILE
 else
 logger "file $JAVA_SECURITY_FILE not found. Exiting..."
 echo "file $JAVA_SECURITY_FILE not found. Exiting..."
 fi

 logger "End of enable 3DES_EDE_CBC"
}

#Main
enable_3DES_EDE_CBC_ciphers
