#!/bin/bash
QUIET=false
DOMAINNAME=""
while getopts "hqd:" option; do
      case $option in
      h) # display Help
         showHelp
         exit 1;;
      q) # quiet
         QUIET=true;;
      d) # Enter a name
        if [[ ! -z "$OPTARG" ]];then
            DOMAINNAME=$OPTARG
        else 
            echo "Error: Please specify a domain name after the -d parameter."
            exit 22
        fi;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done
showhelp(){
   # Display Help
   echo "Hi! Please specify options."
   echo
   echo "Syntax: fetch-domain-records.bash -d example.com [-q|h]"
   echo "options:"
   echo "-h     --help       Print this Help."
   echo "-q     --quiet       Execute quietly."
   echo
}

#get all records for a domain and populate a list
#cfcli ls -d $DOMAINNAME -f csv | tee data/$DOMAINNAME.dnsrecords.list
function fetchDomainDnsRecords(){
    # echo "Current domain: $DOMAINNAME"
    # echo "Current quiet: $QUIET" 
    # echo "Current logic: [ $QUIET = "true" ]"
    if [ $QUIET = true ]; then
        domainDnsRecords="$(cfcli ls -d $DOMAINNAME -f csv > data/$DOMAINNAME.dnsrecords.list)"
    else
        domainDnsRecords="$(cfcli ls -d $DOMAINNAME -f csv | tee data/$DOMAINNAME.dnsrecords.list)"    
    fi
}

fetchDomainDnsRecords
if [ $QUIET = false ]; then echo "$domainDnsRecords" || exit;fi

# using cloudflare-cli - install with `npm install cloudflare-cli`
# https://github.com/danielpigott/cloudflare-cli
# https://github.com/shakes80/cloudflare-cli