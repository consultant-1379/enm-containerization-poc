#!/bin/bash

HC_FILE="/ericsson/modelserv/MDT_complete.result"

if [ ! -f $HC_FILE ]; then
  logger "invokeMDT has not yet completed"
  echo "invokeMDT has not yet completed"
  exit 11
fi

if grep -q "success" $HC_FILE; then
  echo "MDT has completed successfully"
  exit 0
else
  echo "MDT has failed"
  exit 1
fi
