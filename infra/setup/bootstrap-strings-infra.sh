#!/bin/bash
#
# This script takes a Rackspace Cloud account and creates puppet infrastucture
# (the chicken) and then creates hosted Strings infrastructure (the egg).  The
# setup can then be used to create more chickens (puppet infrastructure) which
# can be used to create customer-specific eggs (customer environments).
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
read -p "OpenStack (Rackspace) Region: " OS_REGION
read -p "OpenStack (Rackspace) Base Image: " BASE_IMAGE
read -p "Environment Top Level Domain (ie: bitlancer-example.net): " TOP_LEVEL_DOMAIN
read -p "Environment Data Center (ie: dfw01): " DATA_CENTER
echo

# Generate our NOVA_BASE command
NOVACMD="nova --os-tenant-name $OS_USERNAME --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-auth-system rackspace --os-region-name $OS_REGION --os-username $OS_USERNAME --os-password $OS_API_KEY --no-cache"
DNSCMD="rackdns --os-tenant-name $OS_USERNAME --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-username $OS_USERNAME --os-password $OS_API_KEY --no-cache"

# Sleeping
echo ">>> We will run a process that might cause some damage... 5 seconds to CTRL-C!"
sleep 5
echo

# Launch Infrastructure
echo ">>> Launching Puppet Master..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/puppet-master-1.txt

echo ">>> Launching PuppetDB Server..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/puppetdb-1.txt

echo ">>> Launching PostgreSQL Server..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/postgresql-1.txt

echo ">>> Launching Dashboard Server (1/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/dashboard-1.txt

echo ">>> Launching Dashboard Server (2/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/dashboard-2.txt

echo ">>> Launching API Server (1/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/api-1.txt

echo ">>> Launching API Server (2/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/api-2.txt

echo ">>> Launching Q Manager (1/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 2 --image $BASE_IMAGE > /tmp/strings/q-1.txt

echo ">>> Launching Q Manager (2/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 2 --image $BASE_IMAGE > /tmp/strings/q-2.txt

echo ">>> Launching MySQL Server (1/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/mysql-1.txt

echo ">>> Launching MySQL Server (2/2)..."
$NOVACMD boot `getServerName`.$DATA_CENTER.$TOP_LEVEL_DOMAIN --flavor 3 --image $BASE_IMAGE > /tmp/strings/mysql-2.txt

echo ">>> Launching Dashboard Load Balancer..."
echo ">>> Launching API Load Balancer..."

echo ">>> Sleeping 3 minutes to give the APIs a break..."
sleep 180

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

echo ">>> Adding Dashboard Servers to Load Balancer..."

echo ">>> Adding API Servers to Load Balancer..."

echo ">>> Creating DNS entries..."
for SERVER in /tmp/strings/*.txt; do
  ID=`novaValueByKey id $SERVER`
  NAME=`novaValueByKey name $SERVER`
  IP_ADDRESS=`novaValueByKey ip $SERVER`
  $NOVACMD show $ID | grep ACTIVE > /dev/null
  if [ "$?" -gt 0 ]; then
    echo "Creating $NAME ($IP_ADDRESS)..."
  fi
done

# Exit
echo ">>> Infrastructure is done, see /tmp/strings directory for details"
exit 0
