#!/bin/bash

# Sanity checks
if [ ! -f modified.ldif ]; then
    echo "Missing modified.ldif";
    exit 1
fi

if [ -d /var/lib/ldap-strings ]; then
    echo "Woh there cowboy!  You could blow this whole thing away.... /var/lib/ldap-strings exists!"
    exit 1
fi

# First, make sure OpenLDAP isn't running
sudo /sbin/service slapd stop

# Remove some directory contents
sudo rm -rf /etc/openldap/slapd.d/*
sudo rm -rf /var/lib/ldap/*

# Add in modified.ldif
sudo slapadd -n 0 -F /etc/openldap/slapd.d -l modified.ldif 
chown -R ldap:ldap /etc/openldap/slapd.d /var/lib/ldap

# Create /var/lib/ldap-strings
sudo mkdir /var/lib/ldap-strings
sudo chown ldap:ldap /var/lib/ldap-strings 
sudo chmod 700 /var/lib/ldap-strings

# Start slapd
sudo /sbin/service slapd start
