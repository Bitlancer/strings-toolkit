#!/bin/bash

source functions.sh

for SERVER in /tmp/strings/*.txt; do
  ID=`novaValueByKey id $SERVER`
  NAME=`novaValueByKey name $SERVER`
  IP_ADDRESS=`novaValueByKey ip $SERVER`
  echo "Creating $NAME ($IP_ADDRESS)..."
done

