#!/bin/bash
QUIET=false
CURRENTDOMAIN=""
DOMAINSLIST=""
fetchDomainsList(){
    ./fetch-domains-list.bash -q
}
showUsage(){
   # Display Help
   echo "Hi! Please specify options."
   echo
   echo "Syntax: fetch-domains-list.bash [-q|h]"
   echo "options:"
   echo "-h     --help       Print this Help."
   echo "-q     --quiet       Execute quietly."
   echo
}
while getopts ":hq" option; do
      case $option in
      h) # display Help
         showUsage
         exit 1;;
      q) # quiet
         QUIET=true
         shift;;
     \?) # Invalid option
         echo "Error: Invalid option"
         showUsage
         exit
   esac
done

fetchDomainDnsRecords(){
    if [ $QUIET = "true" ]; then #if QUIET supress output from subcommand
        ./fetch-domain-dnsrecords.bash -q -d $CURRENTDOMAIN    
    else
        ./fetch-domain-dnsrecords.bash -d $CURRENTDOMAIN
    fi
    #echo "Domain complete: $CURRENTDOMAIN"
}

fetchAllDomainsDnsRecords(){
    # Populate or update the domains.list
    fetchDomainsList
    
    # read domainlist
    domianListFile="data/domains.list"
    DOMAINSLIST=$(cat $domianListFile)
    
    # iterate through $DOMAINSLIST and find dnsrecords for each domain
    #echo "$DOMAINSLIST"
    for domain in $DOMAINSLIST
    do
        CURRENTDOMAIN="$domain"
        # echo "Records for: $domain"
        fetchDomainDnsRecords 
        # clean up global garbage
        CURRENTDOMAIN="" 
    done
}
fetchAllDomainsDnsRecords

# using cloudflare-cli - install with `npm install cloudflare-cli`
# https://github.com/danielpigott/cloudflare-cli
# https://github.com/shakes80/cloudflare-cli