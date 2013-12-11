#!/bin/bash

# Sanity checks
if [ ! -f modified.ldif ]; then
    echo "Missing modified.ldif" 1>&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -d /var/lib/ldap-strings ]; then
    echo "Woh there cowboy!  You could blow this whole thing away.... /var/lib/ldap-strings exists!" 1>&2
    exit 1
fi

# First, make sure OpenLDAP isn't running
/sbin/service slapd stop

# Remove some directory contents
rm -rf /etc/openldap/slapd.d/*
rm -rf /var/lib/ldap/*

# Add in modified.ldif
slapadd -n 0 -F /etc/openldap/slapd.d/ -l modified.ldif 
chown -R ldap:ldap /etc/openldap/slapd.d /var/lib/ldap

# Create /var/lib/ldap-strings
mkdir /var/lib/ldap-strings
chown ldap:ldap /var/lib/ldap-strings 
chmod 700 /var/lib/ldap-strings

# Start slapd
/sbin/service slapd start
