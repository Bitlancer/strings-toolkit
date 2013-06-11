#!/bin/bash
#
# This script takes an out-of-box CentOS install and a Bitlancer-specific
# slapd.conf.obsolete (modified from /usr/share/openldap-servers) and generates
# an LDIF that can be used to import into cn=config.
#
# This script should only be used when Bitlancer staff make changes to the
# OpenLDAP setup process and want to use slapd.conf.obsolete instead of
# making the change directly to cn=config.  Eventually, a diff is used to
# update the OpenLDAP bootstrap scripts.
#
# Instructions:
#
# * Spin up a CentOS 6.x server with ius, epel, and puppetlabs repos
# * Grab this directory from git and pop in on said server
# * Run this script
# * Review information in conversion-output
# * Terminate CentOS 6.x server
# * Profit
#

# Install packages
yum -y -q install openldap-servers wget pdns nss-pam-ldapd puppet mlocate
updatedb

# Generate backups, or restore from backup if a new run
if [ -d /etc/openldap.bak ]; then
  rm -rf /etc/openldap
  cp -R /etc/openldap.bak /etc/openldap
else
  cp -R /etc/openldap /etc/openldap.bak
fi

if [ -d /var/lib/ldap.bak ]; then
  rm -rf /var/lib/ldap
  cp -R /var/lib/ldap.bak /var/lib/ldap
else
  cp -R /var/lib/ldap /var/lib/ldap.bak
fi

if [ -d /tmp/conversion-output ]; then
  rm -rf /tmp/conversion-output/*
else
  mkdir /tmp/conversion-output
fi

# Generate original LDIF
slapcat -n 0 > /tmp/conversion-output/original.ldif

# Remove slapd.d contents installed with the openldap-servers package
rm -rf /etc/openldap/slapd.d/*

# Grab and/or copy schema
mkdir schema
cd schema
wget -q http://www.linuxnetworks.de/pdnsldap/dnsdomain2.schema
wget -q http://openssh-lpk.googlecode.com/files/openssh-lpk_openldap.schema
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
echo ">>> Please ignore the following warning... :)"
slaptest -Q -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
slapcat -n 0 > /tmp/conversion-output/modified.ldif

# Exit
echo ">>> Conversion is done, see /tmp/conversion-output directory"
exit 0
