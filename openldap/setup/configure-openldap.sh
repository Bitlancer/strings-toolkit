#!/bin/bash
#
# This script configures a Bitlancer Strings OpenLDAP server already
# puppetized with Bitlancer's puppet-openldap module.
#
# RUN WITH CARE!
#
# Instructions:
#
# * Spin up a CentOS 6.x server with ius, epel, and puppetlabs repos
# * Grab this directory from git and pop in on said server
# * Run this script
# * Review information in output
# * Terminate CentOS 6.x server
# * Profit
#

# Clean up
if [ -f /tmp/strings.ldif ]; then
  rm /tmp/strings.ldif
fi

# Install packages
yum -y -q install openldap-servers apg mlocate
updatedb
echo

# Gather information
read -p "Client Name (ie: Bitlancer LLC): " client_name
read -p "Client Domain (ie: bitlancer-infra.net): " client_domain
read -p "Client LDAP Server IP (ie: 166.78.255.233): " client_ldap_server_ip
stty -echo
read -p "Client LDAP Server Root Password (ie: bob123): " client_ldap_server_root_password
stty echo
echo
echo
echo "  Name: $client_name"
echo "  Domain: $client_domain"
echo "  IP: $client_ldap_server_ip"
echo

# Sleeping
echo ">>> We will run an LDIF that might cause some damage... 5 seconds to CTRL-C!"
sleep 5
echo

# Generate password hash for LDIF
echo ">>> Generating password hash..."
echo
rootdn_password=`apg -n 1 -m 64 -a 1`
rootdn_password_hash=`slappasswd -s "$rootdn_password"`
echo "  Password: $rootdn_password"
echo

# Generate LDIF
echo ">>> Generating LDIF..."
cat strings.ldif.template | while read line; do
  while [[ "$line" =~ (\$\{[a-zA-Z_][a-zA-Z_0-9]*\}) ]]; do
    lhs=${BASH_REMATCH[1]}
    rhs="$(eval echo "\"$lhs\"")"
    line=${line//$lhs/$rhs}
  done
  echo $line >> /tmp/strings.ldif
done

# Exit
echo ">>> Setup is done"
exit 0
