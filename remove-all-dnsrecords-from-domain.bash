#!/bin/bash
QUIET=false
DOMAINNAME=""
DOMAINDNSRECORDS=""
EXECUTE=false # script will run "cfcli find" instead of "cfcli rm" without EXECUTE flag set
showhelp(){
    echo "Hi! Please specify options."
    echo
    echo "Syntax: fetch-domain-records.bash -d example.com [-q|h]"
    echo "options:"
    echo "-h    Print this usage Help."
    echo "-q    Run quietly."
    echo "-x    Execute after (use AFTER default dry-run)."
    echo
}
while getopts "hqxd:" option; do
      case $option in
      h) # display Help
         showHelp
         exit 1;;
      q) # quiet
         QUIET=true;;
      x) # execute, otherwise, dry-run
         EXECUTE=true;;
      d) # Enter a name
        if [[ ! -z "$OPTARG" ]];then
            DOMAINNAME=$OPTARG
        else 
            echo "Error: Please specify a domain name after the -d parameter."
            exit 22
        fi;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit 1;;
   esac
done

# # run from cloudflare-bash-scripts
# domianListFile="data/domains.list"
# while read domain; do
#     # echo the commands out so we can run them at will.
#     #echo "./remove-all-dnsrecords-from-domain.bash -x -d $domain"
#     echo "./populate-domain-dnsrecords-from-template.bash -x -d $domain"
#     #echo $domain
#     #echo "./add-dkim-to-domain-in-zimbra-then-add-to-cloudflare.bash -d $domain "
#     #echo "ssh zero-zimbra-dmz 'sudo su - zextras -c \"/opt/zextras/libexec/zmdkimkeyutil -r -d $domain\"' > ./data/$domain.dkim.public & "

#     #echo ssh zero-zimbra-dmz 'sudo su - zextras -c "/opt/zextras/libexec/zmdkimkeyutil -r -d '$domain'"' > ./data/$domain.dkim.public
# done < $domianListFile

# ./populate-domain-dnsrecords-from-template.bash -x -d defiantdecals.com
# ./populate-domain-dnsrecords-from-template.bash -x -d dizzydelivery.com
# ./populate-domain-dnsrecords-from-template.bash -x -d meltingsaguaro.com
# ./populate-domain-dnsrecords-from-template.bash -x -d sandylizardcoffee.com
# ./populate-domain-dnsrecords-from-template.bash -x -d sandylizardholding.com
# ./populate-domain-dnsrecords-from-template.bash -x -d sandylizardhosting.com
# ./populate-domain-dnsrecords-from-template.bash -x -d sandylizardmerch.com
# ./populate-domain-dnsrecords-from-template.bash -x -d sandylizardventures.com
# ./populate-domain-dnsrecords-from-template.bash -x -d sleazydecals.com
# ./populate-domain-dnsrecords-from-template.bash -x -d thesandylizard.com
# ./populate-domain-dnsrecords-from-template.bash -x -d wonkavisionmedia.com

#get all records for a domain and populate a list
#cfcli ls -d $DOMAINNAME -f csv | tee data/$DOMAINNAME.dnsrecords.list
refreshDomainDnsRecords(){
    ./fetch-domain-dnsrecords.bash -q -d "$DOMAINNAME"
    #echo "Domain refresh complete."
}

removeAllDnsRecordsFromDomain(){
    refreshDomainDnsRecords
    domainDnsRecordsFile="data/$DOMAINNAME.dnsrecords.list"

    # iterate through $DOMAINDNSRECORDS and remove each dnsrecord
    #echo $(cat $domainDnsRecordsFile)
    i=0
    [ "$EXECUTE" = true ] && echo "[$DOMAINNAME] EXECUTION INITIATED" || echo "[$DOMAINNAME] DRY RUN INITIATED"

    while IFS="" read -r dnsRecord || [ -n "$dnsRecord" ]
    do
        #cfcli find -d thesandylizard.com -q name:kvm1.thesandylizard.com,content:195.179.201.227,type:A
        ((i=i+1))

        #echo "************** Next Record **************************"
        [ "$EXECUTE" = true ] && (./remove-dns-record.bash -x -d $dnsRecord ) || (./remove-dns-record.bash -d $dnsRecord )

    done < data/$DOMAINNAME.dnsrecords.list
    [ "$EXECUTE" = false ] && echo "[$DOMAINNAME] DRY RUN COMPLETE" || echo "[$DOMAINNAME] EXECUTION COMPLETE"
    [ "$EXECUTE" = false ] && echo "[$DOMAINNAME] No records were removed. Review the results and add the [-x] parameter to EXECUTE, if satisfied!"
}
removeAllDnsRecordsFromDomain
# using cloudflare-cli - install with `npm install cloudflare-cli`
# https://github.com/danielpigott/cloudflare-cli
# https://github.com/shakes80/cloudflare-cli