#!/bin/bash
#
# This script tears down strings infrastructure only if the proper files
# exist in /tmp/strings.  Useful during testing only, as those files tend
# to go away after the infrastructure is cleaned up.
#
# Instructions:
#
# * Spin up a CentOS 6.x server with ius, epel, and puppetlabs repos
# * Grab this directory from git and pop in on said server
# * Run this script, pray
# * Terminate CentOS 6.x server
# * Profit
#

# Source in shared functions
source functions.sh

# Unlike other, less damaging scripts, we want to die if we're already running
# or there's output from another run
if [ ! -d /tmp/strings ]; then
  echo ">>> Strings temporary directory doesn't exist, I can't help you."
  exit 1
fi

# Install packages
installDependencies

# Gather information
read -p "OpenStack (Rackspace) Username: " OS_USERNAME
stty -echo
read -p "OpenStack (Rackspace) API Key: " OS_API_KEY
stty echo
echo
read -p "OpenStack (Rackspace) Region: " OS_REGION
echo

# Generate our NOVA_BASE command
NOVACMD="nova --os-tenant-name $OS_USERNAME --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-auth-system rackspace --os-region-name $OS_REGION --os-username $OS_USERNAME --os-password $OS_API_KEY --no-cache"

# Sleeping
echo ">>> We will run a process that WILL cause some damage... 10 seconds to CTRL-C!"
sleep 10
echo

# Launch Infrastructure
echo ">>> Killing infrastructure..."
for SERVER in /tmp/strings/*.txt; do
  ID=`novaValueByKey id $SERVER`
  NAME=`novaValueByKey name $SERVER`
  echo ">>> Killing $NAME..."
  $NOVACMD delete $ID
done

# Remove
echo ">>> Removing /tmp/strings"
rm -rf /tmp/strings

# Exit
echo ">>> Infrastructure is killed."
exit 0
