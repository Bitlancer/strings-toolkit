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
read -p "OpenStack (Rackspace) Username: " os_username
stty -echo
read -p "OpenStack (Rackspace) API Key: " os_api_key
stty echo
echo
read -p "OpenStack (Rackspace) Region (ie: DFW): " os_region
read -p "Environment Top Level Domain (ie: bitlancer-example.net): " top_level_domain
echo

# Generate our NOVA and DNS commands
NOVA_RAX_AUTH=1
novacmd="nova --os-tenant-name $os_username --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-auth-system rackspace --os-region-name $os_region --os-username $os_username --os-password $os_api_key --no-cache"
dnscmd="rackdns --os-tenant-name $os_username --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-username $os_username --os-password $os_api_key --no-cache"

# Sleeping
echo ">>> We will run a process that WILL cause some damage... 10 seconds to CTRL-C!"
sleep 10

# Kill Infrastructure
echo ">>> Killing infrastructure..."
for server in /tmp/strings/*.txt; do
  id=`novaValueByKey id $server`
  name=`novaValueByKey name $server`
  echo ">>> Killing $name..."
  $novacmd delete $id
done

# Kill DNS
echo ">>> Killing DNS..."
for server in /tmp/strings/*.txt; do
  name=`novaValueByKey name $server`
  id=`$dnscmd record-list $top_level_domain | dnsIdByName $name`
  echo ">>> Killing $name..."
  $dnscmd record-delete --record_id $id $top_level_domain
done

# Kill Zone?
read -p "Do you want to kill the zone $top_level_domain, too? (y/n)" kill_zone
if [ "$kill_zone" = "y" ]; then
  $dnscmd domain-delete $top_level_domain
fi

# Remove
echo ">>> Removing /tmp/strings"
rm -rf /tmp/strings

# Exit
echo ">>> Infrastructure and DNS killed."
exit 0
