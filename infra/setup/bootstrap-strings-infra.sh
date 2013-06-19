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
read -p "OpenStack (Rackspace) Username: " os_username
stty -echo
read -p "OpenStack (Rackspace) API Key: " os_api_key
stty echo
echo
read -p "OpenStack (Rackspace) Region (ie: DFW): " os_region
read -p "OpenStack (Rackspace) Base Image: " base_image
read -p "Environment Top Level Domain (ie: bitlancer-example.net): " top_level_domain
read -p "Environment Data Center (ie: dfw01): " data_center
echo

# Generate our NOVA and DNS commands
NOVA_RAX_AUTH=1
novacmd="nova --os-tenant-name $os_username --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-auth-system rackspace --os-region-name $os_region --os-username $os_username --os-password $os_api_key --no-cache"
dnscmd="rackdns --os-tenant-name $os_username --os-auth-url https://identity.api.rackspacecloud.com/v2.0/ --os-username $os_username --os-password $os_api_key --no-cache"

# Sleeping
echo ">>> We will run a process that might cause some damage... 5 seconds to CTRL-C!"
sleep 5

# Launch 512MB instances
echo ">>> Launching 512MB instances..."
for instance in q-1 q-2; do
  $novacmd boot `getServerName`.$data_center.$top_level_domain --flavor 2 --image $base_image > /tmp/strings/$instance.txt
done

# Launch 1024MB instances
echo ">>> Launching 1024MB instances..."
for instance in puppet-master-1 puppetdb-1 postgresql-1 dashboard-1 dashboard-2 api-1 api-2 mysql-1 mysql-2; do
  $novacmd boot `getServerName`.$data_center.$top_level_domain --flavor 3 --image $base_image > /tmp/strings/$instance.txt
done

echo ">>> Launching Dashboard Load Balancer..."
echo ">>> Launching API Load Balancer..."

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

echo ">>> Adding Dashboard Servers to Load Balancer..."

echo ">>> Adding API Servers to Load Balancer..."

echo ">>> Verifying DNS configuration..."
$dnscmd domain-show $top_level_domain > /dev/null
if [ "$?" -gt 0 ]; then
  read -p "DNS Email Address (ie: it@bitlancer.com): " dns_email
  $dnscmd domain-create $top_level_domain --email-address $dns_email > /dev/null
fi

echo ">>> Creating DNS entries..."
for server in /tmp/strings/*.txt; do
  id=`novaValueByKey id $server`
  name=`novaValueByKey name $server`
  ip_address=`$novacmd show $id | novaValueByKey accessIPv4`
  echo ">>> Creating $name ($ip_address)..."
  $dnscmd record-create --name $name --type A --data $ip_address $top_level_domain > /dev/null
done

# Exit
echo ">>> Infrastructure is done, see /tmp/strings directory for details"
exit 0
