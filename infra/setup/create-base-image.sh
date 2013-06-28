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
read -p "OpenStack (Rackspace) Username: " os_username
stty -echo
read -p "OpenStack (Rackspace) API Key: " os_api_key
stty echo
echo
read -p "OpenStack (Rackspace) Region (ie: DFW): " os_region
read -p "OpenStack (Rackspace) Template Image (ie: da1f0392-8c64-468f-a839-a9e56caebf07): " template_image
read -p "Environment Image Version (ie: 1): " image_version
echo

# Generate our NOVA command
NOVA_RAX_AUTH=1
novacmd="nova --os-tenant-name $os_username --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-auth-system rackspace --os-region-name $os_region --os-username $os_username --os-password $os_api_key --no-cache"

# Sleeping
echo ">>> We will run a process that might cause some damage... 5 seconds to CTRL-C!"
sleep 5

# Launch Infrastructure
echo ">>> Launching Template Image..."
$novacmd boot base-image-v$image_version --flavor 2 --image $template_image > /tmp/strings/base-image.txt

echo ">>> Sleeping a few minutes to give the APIs a break..."
sleep 200

echo ">>> Checking if we're waiting on services..."
waiting=2
while [ "$waiting" -ne 0 ]; do
  waiting=2
  for server in /tmp/strings/*.txt; do
    id=`novaValueByKey id $server`
    name=`novaValueByKey name $server`
    $novacmd show $id | grep ACTIVE > /dev/null
    if [ "$?" -gt 0 ]; then
      echo ">>> Still waiting on $name... :("
      waiting=1
    fi
  done
  if [ "$waiting" -eq 2 ]; then
    waiting=0
  else
    sleep 60
  fi
done

# Get variables
id=`novaValueByKey id /tmp/strings/base-image.txt`
password=`novaValueByKey adminPass /tmp/strings/base-image.txt`
ip_address=`$novacmd show $id | novaValueByKey accessIPv4`

echo ">>> Setting up base image..."
cat commands/centos-6-x86_64.txt | while read command; do
  echo ">>> Executing: $command"
  sshpass -p $password ssh root@$ip_address "sh -c '$command'" < /dev/null
done

echo ">>> Snapshotting base image..."

echo ">>> Killing base image..."
$novacmd delete $id

# Exit
echo ">>> Infrastructure is done, see /tmp/strings directory for details"
exit 0
