#!/bin/bash
#
# This script takes a Rackspace Cloud account and creates a Bitlancer Strings
# base image.
#
# Instructions:
#
# * Spin up a CentOS 6.x server with ius, epel, and puppetlabs repos
# * Grab this directory from git and pop in on said server
# * Run this script
# * Terminate CentOS 6.x server
# * Profit
#

# Source in shared functions
source functions.sh

# Unlike other, less damaging scripts, we want to die if we're already running
# or there's output from another run
if [ -d /tmp/strings ]; then
  echo ">>> WARNING!  We're already running or we ran recently?"
  exit 1
else
  mkdir /tmp/strings
fi

# Install packages
installDependencies

# Gather information
read -p "OpenStack (Rackspace) Username: " OS_USERNAME
stty -echo
read -p "OpenStack (Rackspace) API Key: " OS_API_KEY
stty echo
echo
read -p "OpenStack (Rackspace) Region (ie: DFW): " OS_REGION
read -p "OpenStack (Rackspace) Template Image (ie: da1f0392-8c64-468f-a839-a9e56caebf07): " TEMPLATE_IMAGE
read -p "Environment Image Version (ie: 1): " IMAGE_VERSION
echo

# Generate our NOVA command
NOVA_RAX_AUTH=1
NOVACMD="nova --os-tenant-name $OS_USERNAME --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-auth-system rackspace --os-region-name $OS_REGION --os-username $OS_USERNAME --os-password $OS_API_KEY --no-cache"

# Sleeping
echo ">>> We will run a process that might cause some damage... 5 seconds to CTRL-C!"
sleep 5

# Launch Infrastructure
echo ">>> Launching Template Image..."
$NOVACMD boot baseImage-v$IMAGE_VERSION --flavor 2 --image $TEMPLATE_IMAGE > /tmp/strings/baseImage.txt

echo ">>> Sleeping a few minutes to give the APIs a break..."
sleep 200

echo ">>> Checking if we're waiting on services..."
WAITING=2
while [ "$WAITING" -ne 0 ]; do
  WAITING=2
  for SERVER in /tmp/strings/*.txt; do
    ID=`novaValueByKey id $SERVER`
    NAME=`novaValueByKey name $SERVER`
    $NOVACMD show $ID | grep ACTIVE > /dev/null
    if [ "$?" -gt 0 ]; then
      echo ">>> Still waiting on $NAME... :("
      WAITING=1
    fi
  done
  if [ "$WAITING" -eq 2 ]; then
    WAITING=0
  else
    sleep 60
  fi
done

# Get variables
HOST_ID=`novaValueByKey id /tmp/strings/baseImage.txt`
HOST_PASSWORD=`novaValueByKey adminPass /tmp/strings/baseImage.txt`

echo ">>> Setting up base image..."

echo ">>> Snapshotting base image..."

echo ">>> Killing base image..."
$NOVACMD delete $HOST_ID

# Exit
echo ">>> Infrastructure is done, see /tmp/strings directory for details"
exit 0
