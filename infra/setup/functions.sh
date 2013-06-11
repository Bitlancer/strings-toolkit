#!/bin/sh
#
# Shared functions for infra
#

# Install what we need
yum -y install words > /dev/null

#
# getServerName: generate a server name
# input: none
# output: servername
#
function getServerName {
  n=$(cat /usr/share/dict/words | wc -l)
  l=$(( ($RANDOM * 32768 + $RANDOM) % n ))
  cat /usr/share/dict/words | grep -i "^[a-z]*$" | head -$l | tail -1 | tr [A-Z] [a-z]
}

#
# novaValueByKey: gets a value from a key via file or STDIN
# input: key, [filename]
# output: value
#
function novaValueByKey {
  if [ -z "$2" ]; then
    grep "^|\ $1" $2 | sed 's/\ //g' | awk -F'|' '{ print $3 }'
  else
    grep "^|\ $1" | sed 's/\ //g' | awk -F'|' '{ print $3 }'
}

#
# installDependencies: installs dependencies
# input: none
# output: none
#
function installDependencies {
  yum -y -q install apg mlocate python-setuptools
  if [ ! -f /usr/bin/nova ]; then
    easy_install pip > /dev/null
    pip install rackspace-novaclient > /dev/null
  fi
  if [ ! -f /usr/bin/rackdns ]; then
    git clone https://github.com/kwminnick/rackspace-dns-cli > /dev/null
    cd rackspace-dns-cli
    python setup.py install > /dev/null
    cd ..
    rm -rf rackspace-dns-cli
  fi
  echo
}

