#!/bin/bash
QUIET=false
while getopts ":hqd:" option; do
      case $option in
      h) # display Help
         showHelp
         exit 1;;
      q) # quiet
         QUIET=true;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done
#get all domains for token and populate a list
#cfcli zones -f csv | cut -d ',' -f1 > data/domains.list

function fetchDomainsList(){
    local  __resultvar=$1
    if [ $QUIET = true ]; then
        myDomainList="$(cfcli zones -f csv | cut -d ',' -f1 > data/domains.list)"
        #exit 0
    else
        local  myDomainList="$(cfcli zones -f csv | cut -d ',' -f1| tee data/domains.list)"
    fi
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myDomainList'"
    else
        echo "$myDomainList"
    fi
}

showhelp(){
   # Display Help
   echo "Hi! Please specify options."
   echo
   echo "Syntax: fetch-domains-list.bash [-q|h]"
   echo "options:"
   echo "-h     --help       Print this Help."
   echo "-q     --quiet       Execute quietly."
   echo
}

#fetchDomainsList domainList #function accessable through this method
#echo $domainList
domainList="$(fetchDomainsList)" #or function accessable through this method
if [ $QUIET = false ]; then echo "$domainList" || exit;fi
# using cloudflare-cli - install with `npm install cloudflare-cli`
# https://github.com/danielpigott/cloudflare-cli
# https://github.com/shakes80/cloudflare-cli

# cfcli - help for reference
# NAME
#     cfcli - Interact with cloudflare from the command line

# SYNOPSIS
#     cfcli [options] command [parameters]

# OPTIONS:
#     -c  --config    Path to yml file with config defaults (defaults to ~/.cfcli.yml
#     -e  --email     Email of your cloudflare account
#     -k  --token     Token for your cloudflare account
#     -u  --account   Choose one of your named cloudflare accounts from .cfcli.yml
#     -d  --domain    Domain to operate on
#     -a  --activate  Activate cloudflare after creating record (for addrecord)
#     -f  --format    Format when printing records (csv,json or table)
#     -t  --type      Type of record (for dns record functions)
#     -p  --priority  Set priority when adding a record (MX or SRV)
#     -q  --query     Comma separated filters to use when finding a record
#     -l  --ttl       Set ttl on add or edit (120 - 86400 seconds, or 1 for auto)
#     -h  --help      Display help

# COMMANDS:
#     add <name> <content>
#         Add a DNS record. Use -a to activate cf after creation
#     always-use-https on|off
#         Toggle Always Use HTTPS mode on/off
#     devmode on|off
#         Toggle development mode on/off
#     disable <name> [content]
#         Disable cloudflare caching for given record and optionally specific value
#     edit <name> <content>
#         Edit a DNS record.
#     enable <name> [content]
#         Enable cloudflare caching for given record and optionally specific value
#     find <name> [content]
#         Find a record with given name and optionally specific value
#     ls
#         List dns records for the domain
#     purge [urls]
#         Purge file at given urls (space separated) or all files if no url given
#     rm <name> [content]
#         Remove record with given name and optionally specific value
#     zone-add <name>
#         Add a zone for given name
#     zones
#         List domains in your cloudflare account


# Examples

# Add a new A record (mail) and activate cloudflare (-a)
# cfcli -a -t A add mail 8.8.8.8

# Edit a record (mail) and set the TTL
# cfcli --ttl 120 edit  mail 8.8.8.8

# Add an SRV record (then 3 numbers are priority, weight and port respectively)
# cfcli -t SRV add _sip._tcp.example.com 1 1 1 example.com

# Find all records matching the content value test.com
# cfcli find -q content:test.com

# Remove all records with the name test
# cfcli rm test

# Remove record with name test, type of A and value 1.1.1.1
# cfcli rm test -q content:1.1.1.1,type:A

# Enable cloudflare for any records that match test
# cfcli enable test

# Enable cloudflare for a record test with the value test.com
# cfcli enable test test.com

# Export domain records for test.com to csv
# cfcli -d test.com -f csv listrecords > test.csv

# Purge a given files from cache
# cfcli -d test.com purge http://test.com/script.js http://test.com/styles.css

# Enable dev mode for test.com domain
# cfcli -d test.com devmode on

# Add the zone test.com
# cfcli zone-add test.com
