#!/bin/bash
QUIET=false
DOMAINNAME=""
DOMAINDNSRECORDS=""
EXECUTE=false # script will run "cfcli find" instead of "cfcli rm" without EXECUTE flag set
showhelp(){
   # Display Help
    echo "Hi! Please specify options."
    echo
    echo "Usage Syntax: populate-domain-records-from-template.bash -d example.com [-q|h]"
    echo "required:"
    echo "-d example.com    specify domain name"
    echo "options:"
    echo "-h                Print this usage Help."
    echo "-q                Run quietly."
    echo "-x                Execute after (default dry-run)."
    echo
}
while getopts "hqxd:" option; do
    case $option in
      h) # display Help
         showhelp
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
if [[ $DOMAINNAME = "" ]];
then
    echo "Error: -d  must be included and followed by domainname"
    showhelp
    exit 1
fi
#get all records for a domain and populate a list
#cfcli ls -d $DOMAINNAME -f csv | tee data/$DOMAINNAME.dnsrecords.list
refreshDomainDnsRecords(){
    ./fetch-domain-dnsrecords.bash -q -d "$DOMAINNAME"
    echo "[$DOMAINNAME] dns records refresh complete."
}

populateDomainDnsRecordsFromTemplate(){
    refreshDomainDnsRecords
    # TODO: clean this mess up
    readonly existingDomainDnsRecordsFile="data/$DOMAINNAME.dnsrecords.list" #this location is hardcoded, other scripts use it too
    readonly domainDnsRecordsListTemplate="./domain-dnsrecords.list.template"
 
    [ "$EXECUTE" = true ] && echo "[$DOMAINNAME] EXECUTION INITIATED" || echo "[$DOMAINNAME] DRY RUN INITIATED" # Displaying the execution status at runtime
    
    if [[ -f $existingDomainDnsRecordsFile ]]; then # Even if empty, the file should exist after refreshing the dnsrecords above. If empty, something is wrong.
        # echo "file exists!"
        # count the existing number of records before processing
        readonly numberOfPreexistingRecords=$(wc -l < "$existingDomainDnsRecordsFile")
        if [ "$numberOfPreexistingRecords" -ne "0" ]; then # threre are existing records for domain
            echo "[$DOMAINNAME] [WARNING]:$numberOfPreexistingRecords DNS Records currently exist for $DOMAINNAME:"
            local i=0 # counter
            while IFS="" read -r dnsRecord || [ -n "$dnsRecord" ]
            do
                ((i=i+1))
                #echo "************** Next Record **************************"
                local _name=$(echo $dnsRecord | cut -d',' -f2)
                #echo "Name: $_name"
                local _domain=$DOMAINNAME
                #echo "Domain: $_domain"
                local _content=$(echo $dnsRecord | cut -d',' -f3)
                #echo "Content: $_content"
                local _type=$(echo $dnsRecord | cut -d',' -f1)
                echo "[$DOMAINNAME] $i/$numberOfPreexistingRecords: $_type,$_name,$_content"
            done < $existingDomainDnsRecordsFile
            echo "[$DOMAINNAME] ########################################################################################"
            echo "[$DOMAINNAME] [WARNING]: $numberOfPreexistingRecords DNS Records currently exist for $DOMAINNAME"
            echo "[$DOMAINNAME] [WARNING]: If you do not need the records, you can remove them:"
            echo "[$DOMAINNAME] [WARNING]: by running 'bash ./remove-all-dnsrecords-from-domain.bash -d $DOMAINNAME'"
            echo "[$DOMAINNAME] [WARNING]: for help see 'bash ./populate-domain-dnsrecords-from-template.bash -h'"
            echo "[$DOMAINNAME] [WARNING]: for more help see  'bash ./remove-all-dnsrecords-from-domain.bash -h'"
            echo "[$DOMAINNAME] [WARNING]: Beacuse the records above still exist in domain, exiting now."
            echo "[$DOMAINNAME] ########################################################################################"
            exit 1
        else # there are no existing records for the domain
            echo "[$DOMAINNAME] 0 DNS Records currently exist for $DOMAINNAME on cloudflare"
            if [[ ! -f $domainDnsRecordsListTemplate ]]; then
                echo "[$DOMAINNAME] ########################################################################################"
                echo "[$DOMAINNAME] [WARNING]: $domainDnsRecordsListTemplate does not exist."
                echo "[$DOMAINNAME] [WARNING]: for help see 'bash ./populate-domain-dnsrecords-from-template.bash -h'"
                echo "[$DOMAINNAME] [WARNING]: Beacuse the template odesn't exist there's noting to do, exiting now."
                echo "[$DOMAINNAME] ########################################################################################"
                exit 1
            fi
            readonly numberOfDnsRecordsInTemplate=$(wc -l < "$domainDnsRecordsListTemplate")  
            if [ "$numberOfDnsRecordsInTemplate" -ne "0" ]; then # threre are records in the template
                echo "[$DOMAINNAME] $numberOfDnsRecordsInTemplate DNS records are in the template to be added to $DOMAINNAME:"
                local j=0 # counter
                while IFS="" read -r dnsRecord || [ -n "$dnsRecord" ]
                do
                    ((j=j+1))
                    #echo "************** Next Record **************************"
                    [ "$EXECUTE" = true ] && ./add-dns-record.bash -x -d $dnsRecord || ./add-dns-record.bash -d $dnsRecord

                done < $domainDnsRecordsListTemplate
            else # there are no records in the template
                echo "[$DOMAINNAME] ########################################################################################"
                echo "[$DOMAINNAME] [WARNING]: $domainDnsRecordsListTemplate exists but contains $numberOfDnsRecordsInTemplate records."
                echo "[$DOMAINNAME] [WARNING]: for help see 'bash ./populate-domain-dnsrecords-from-template.bash -h'"
                echo "[$DOMAINNAME] [WARNING]: Beacuse the template doesn't contain records, there's noting to do, exiting now."
                echo "[$DOMAINNAME] ########################################################################################"
                exit 1
            fi 
        fi
    else # $existingDomainDnsRecords file does not exist
        echo "[$DOMAINNAME] Error reading $existingDomainDnsRecordsFile, file does not exist. Exiting"
        exit 1
    fi

    [ "$EXECUTE" = false ] && echo "[$DOMAINNAME] DRY RUN COMPLETE" || echo "[$DOMAINNAME] EXECUTION COMPLETE"
    [ "$EXECUTE" = false ] && echo "[$DOMAINNAME] No records were added. Review the results and add the [-x] parameter to EXECUTE, if satisfied!"
}
populateDomainDnsRecordsFromTemplate

# using cloudflare-cli - install with `npm install cloudflare-cli`
# https://github.com/danielpigott/cloudflare-cli
# https://github.com/shakes80/cloudflare-cli