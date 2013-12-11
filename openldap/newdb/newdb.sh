#!/bin/bash

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
        (echo -n "<% DOMAIN=\"${d}\"; TLD=\"${t}\"; INCREMENT=\"${i}\"; OLCROOTPW=\"$OLCROOTPW\" %>" && cat newdb.ldif.erb && echo && cat master.ldif.erb) | erb > ${d}.${t}-${s}.ldif
        ;;
    s)
        read -p "Cleartext replication password for uid=replication,ou=users,ou=ldap,dc=${d},dc=${t}: " REPLICATIONPW
       	(echo -n "<% DOMAIN=\"${d}\"; TLD=\"${t}\"; INCREMENT=\"${i}\"; OLCROOTPW=\"$OLCROOTPW\"; REPLICATIONPW=\"$REPLICATIONPW\" %>" && cat newdb.ldif.erb && echo && cat slave.ldif.erb) | erb > ${d}.${t}-${s}.ldif
        ;;
    *)
        usage
        ;;
esac
