#!/bin/bash
logger -s -t "K8S_WORKAROUND" "Renaming directory /ericsson/3pp/jboss/standalone/configuration/standalone_xml_history/current"
mv /ericsson/3pp/jboss/standalone/configuration/standalone_xml_history/current /ericsson/3pp/jboss/standalone/configuration/standalone_xml_history/workaround.$$
