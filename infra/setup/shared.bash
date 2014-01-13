#!/bin/bash
#
# Shared variables/functions/executions for any strings infrastructure script
#

#
# getServerName: generate a server name
# input: none
# output: servername
#
function getServerName {
  cat /usr/share/dict/words | grep -i "^[a-z]*$" | shuf -n 1 | tr [A-Z] [a-z]
}

#
# getOutputDirectory: generate an output directory
# input: none
# output: directory name
#
function getOutputDirectory {
  directory_name="/tmp/strings.$RANDOM"
  mkdir "$directory_name"
  echo "$directory_name"
}

#
# novaValueByKey: gets a value from a key via file or STDIN
# input: key, [filename]
# output: value
#
function novaValueByKey {
  if [ "$2" ]; then
    grep "^|\ $1" $2 | sed 's/\ //g' | awk -F'|' '{ print $3 }'
  else
    grep "^|\ $1" | sed 's/\ //g' | awk -F'|' '{ print $3 }'
  fi
}

#
# dnsIdByName: gets a DNS record ID by Name
# input: name
# output: value
#
function dnsIdByName {
  grep "|\ $1" | sed 's/\ //g' | awk -F'|' '{ print $2 }'
}

#
# installDependencies: installs dependencies
# input: none
# output: none
#
function installDependencies {
  yum -y -q install apg mlocate python-setuptools sshpass words python-prettytable python-httplib2 python-pip > /dev/null
  if [ ! -f /usr/bin/nova ]; then
    python-pip install rackspace-novaclient > /dev/null
    git clone -q git://github.com/openstack/python-novaclient.git > /dev/null
    cd python-novaclient
    pip install --requirement requirements.txt > /dev/null
    python setup.py install > /dev/null
    cd ..
    rm -rf python-novaclient
  fi
  if [ ! -f /usr/bin/rackdns ]; then
    git clone -q https://github.com/kwminnick/rackspace-dns-cli > /dev/null
    cd rackspace-dns-cli
    python setup.py install > /dev/null
    cd ..
    rm -rf rackspace-dns-cli
  fi
}

#
# waitOnServices: waits on services and only returns when done or timed out
# input: none
# output: none
#
function waitOnServices {
  sleep 120
  waiting=2
  fail_count=0
  while [ "$waiting" -ne 0 ]; do
    waiting=2
    fail_count=$(expr $fail_count + 1)
    for server in "$output_directory"/*.txt; do
      id=$(novaValueByKey id "$server")
      name=$(novaValueByKey name "$server")
      nova show "$id" | grep ACTIVE > /dev/null
      if [ "$?" -gt 0 ]; then
        echo ">>> Still waiting on $name... :("
        sleep 60
        waiting=1
      fi
    done
    if [ "$waiting" -eq 2 ]; then
      waiting=0
    else
      if [ "$fail_count" -gt 20 ]; then
        finishRunning
        echo ">>> Failing fast on this one, something is up..."
        echo ">>> You may want to tear down: $output_directory"
        exit 2
      fi
    fi
  done
}

#
# checkRunning: sees if a strings script is running
# input: none
# output: none
#
function checkRunning {
  if [ -f /tmp/strings.lock ]; then
    read -p "*** We're already running.  Override? (Y/n): " override
    if [ "$override" != "Y" ]; then
      exit 1
    fi
  else
    touch /tmp/strings.lock
  fi
}

#
# finishRunning: cleans up after a run
# input: none
# output: none
#
function finishRunning {
  rm /tmp/strings.lock
}
