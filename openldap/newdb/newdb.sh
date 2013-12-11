#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

usage() { echo "Usage: $0 [-s <m|s>] [-d <domain>] [-t <tld>] [-i <increment>]" 1>&2; exit 1; }

while getopts "s:d:t:i:" o; do
    case "${o}" in
        s)
            s=${OPTARG}
            ;;
        d)
            d=${OPTARG}
            ;;
        t)
            t=${OPTARG}
            ;;
        i)
            i=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${s}" ] || [ -z "${d}" ] || [ -z "${t}" ] || [ -z "${i}" ]; then
    usage
fi

read -p "Hashed olcRootPW value for dc=${d},dc=${t}: " OLCROOTPW

case "${s}" in 
    m)
        (echo -n "<% DOMAIN=\"${d}\"; TLD=\"${t}\"; INCREMENT=\"${i}\"; OLCROOTPW=\"$OLCROOTPW\" %>" && cat newdb.ldif.erb && echo && cat master.ldif.erb) | erb > ${d}.${t}.ldif
        ;;
    s)
        read -p "Cleartext replication password for uid=replication,ou=users,ou=ldap,dc=${d},dc=${t}: " REPLICATIONPW
        (echo -n "<% DOMAIN=\"${d}\"; TLD=\"${t}\"; INCREMENT=\"${i}\"; OLCROOTPW=\"$OLCROOTPW\"; REPLICATIONPW=\"$REPLICATIONPW\" %>" && cat newdb.ldif.erb && echo && cat slave.ldif.erb) | erb > ${d}.${t}.ldif
        ;;
    *)
        usage
        ;;
esac

mkdir /var/lib/ldap-strings/${d}.${t}
chown ldap:ldap /var/lib/ldap-strings/${d}.${t}
chmod 700 /var/lib/ldap-strings/${d}.${t}
ldapadd -Y EXTERNAL -H ldapi://%2fvar%2frun%2ldapi -D cn=config -f ${d}.${t}.ldif

rm ${d}.${t}.ldif
