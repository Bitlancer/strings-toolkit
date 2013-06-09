#!/bin/bash
#
# This script takes an out-of-box CentOS install and a Bitlancer-specific
# slapd.conf.obsolete (modified from /usr/share/openldap-servers) and generates
# an LDIF that can be used to import into cn=config.
#
# This script should only be used when Bitlancer staff make changes to the
# OpenLDAP bootstrap process and want to use slapd.conf.obsolete instead of
# making the change directly to cn=config.  Eventually, a diff is used to
# update the OpenLDAP bootstrap scripts.
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

# Remove failed/old run
if [ -d output ]; then
  rm -rf output
fi
yum -y -q remove openldap-servers
if [ -d /var/lib/ldap ]; then
  rm -rf /var/lib/ldap/*
fi

# Create output directory
mkdir output

# Install packages
yum -y -q install openldap-servers wget pdns nss-pam-ldapd puppet mlocate
updatedb

# Generate original LDIF
slapcat -n 0 > output/original.ldif

# Remove slapd.d contents installed with the openldap-servers package
rm -rf /etc/openldap/slapd.d/*

# Grab and/or copy schema
mkdir schema
cd schema
wget http://www.linuxnetworks.de/pdnsldap/dnsdomain2.schema
wget http://openssh-lpk.googlecode.com/files/openssh-lpk_openldap.schema
cp /usr/share/puppet/ext/ldap/puppet.schema puppet.schema
cp /usr/share/doc/pam_ldap-*/ldapns.schema ldapns.schema
cp /usr/share/doc/sudo-*/schema.OpenLDAP sudo.schema
cd ..
mv schema/* /etc/openldap/schema
rm -rf schema

# Copy other files into place
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/DB_CONFIG
cp slapd.conf.obsolete /etc/openldap/slapd.conf

# Begin conversion
echo "[Notice] Please ignore BDB warnings..."
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
slapcat -n 0 > output/modified.ldif

# Exit
echo "[Notice] Conversion is done, see output directory"
exit 0
