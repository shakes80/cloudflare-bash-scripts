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
    echo "$DOMAINNAME dns records refresh complete."
}

populateDomainDnsRecordsFromTemplate(){
    refreshDomainDnsRecords
    # TODO: clean this mess up
    readonly existingDomainDnsRecordsFile="data/$DOMAINNAME.dnsrecords.list" #this location is hardcoded, other scripts use it too
    readonly domainDnsRecordsListTemplate="./domain-dnsrecords.list.template"
 
    [ "$EXECUTE" = true ] && echo "EXECUTION INITIATED" || echo "DRY RUN INITIATED" # Displaying the execution status at runtime
    
    if [[ -f $existingDomainDnsRecordsFile ]]; then # Even if empty, the file should exist after refreshing the dnsrecords above. If empty, something is wrong.
        # echo "file exists!"
        # count the existing number of records before processing
        readonly numberOfPreexistingRecords=$(wc -l < "$existingDomainDnsRecordsFile")
        if [ "$numberOfPreexistingRecords" -ne "0" ]; then # threre are existing records for domain
            echo "[WARNING]:$numberOfPreexistingRecords DNS Records currently exist for $DOMAINNAME:"
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
                echo "$i/$numberOfPreexistingRecords: $_type,$_name,$_content"
            done < $existingDomainDnsRecordsFile
            echo "########################################################################################"
            echo "[WARNING]: $numberOfPreexistingRecords DNS Records currently exist for $DOMAINNAME"
            echo "[WARNING]: If you do not need the records, you can remove them:"
            echo "[WARNING]: by running 'bash ./remove-all-dnsrecords-from-domain.bash -d $DOMAINNAME'"
            echo "[WARNING]: for help see 'bash ./populate-domain-dnsrecords-from-template.bash -h'"
            echo "[WARNING]: for more help see  'bash ./remove-all-dnsrecords-from-domain.bash -h'"
            echo "[WARNING]: Beacuse the records above still exist in domain, exiting now."
            echo "########################################################################################"
            exit 1
        else # there are no existing records for the domain
            echo "0 DNS Records currently exist for $DOMAINNAME on cloudflare"
            if [[ ! -f $domainDnsRecordsListTemplate ]]; then
                echo "########################################################################################"
                echo "[WARNING]: $domainDnsRecordsListTemplate does not exist."
                echo "[WARNING]: for help see 'bash ./populate-domain-dnsrecords-from-template.bash -h'"
                echo "[WARNING]: Beacuse the template odesn't exist there's noting to do, exiting now."
                echo "########################################################################################"
                exit 1
            fi
            readonly numberOfDnsRecordsInTemplate=$(wc -l < "$domainDnsRecordsListTemplate")  
            if [ "$numberOfDnsRecordsInTemplate" -ne "0" ]; then # threre are records in the template
                echo "$numberOfDnsRecordsInTemplate DNS records are in the template to be added to $DOMAINNAME:"
                local j=0 # counter
                while IFS="" read -r dnsRecord || [ -n "$dnsRecord" ]
                do
                    ((j=j+1))
                    #echo "************** Next Record **************************"
                    local _name=$( echo "$(echo $dnsRecord | cut -d"," -f2)" | sed "s/TEMPLATE.TLD/$DOMAINNAME/g")
                    #echo "Name: $_name"
                    local _domain=$DOMAINNAME
                    #echo "Domain: $_domain"
                    local _content=$( echo "$(echo $dnsRecord | cut -d',' -f3)" | sed "s/TEMPLATE.TLD/$DOMAINNAME/g") 
                    #echo "Content: $_content"
                    local _type=$(echo $dnsRecord | cut -d',' -f1)
                    echo "$j/$numberOfDnsRecordsInTemplate: $_type,$_name,$_content"

                    case $_type in
                        "A" | "AAAA" | "CNAME" | "NS" | "PTR" | "SOA" | "SOA" | "DNSKEY" | "DS" | "TXT" ) # standard addition to cloudflare
                            [ "$EXECUTE" = true ] && cfcli -t "$_type" -d "$DOMAINNAME" add "$_name" "$_content" || echo "Proposed command: cfcli -t $_type -d $DOMAINNAME add $_name $_content"
                            [[ $? -ne 0 ]] && echo "Error adding $_type record."  
                            ;;
                        "MX" ) # MX (Mail eXchange)
                            #    -p  Set priority when adding a record (MX or SRV)
                            [ "$EXECUTE" = true ] && cfcli -t "$_type" -p 10 -d "$DOMAINNAME" add "$_name" "$_content" || echo "Proposed command: cfcli -t $_type -p 10 -d $DOMAINNAME add $_name $_content"
                            [[ $? -ne 0 ]] && echo "Error adding $_type record."
                            ;;
                        "SRV" ) # SRV (location of service)
                            # Add an SRV record (then 3 numbers are priority, weight and port respectively)
                            [ "$EXECUTE" = true ] && cfcli -t "$_type" add "$_name" "$_content" 1 1 1 "$DOMAINNAME" echo "cfcli -t $_type add $_name $_content 1 1 1 $DOMAINNAME"
                            [[ $? -ne 0 ]] && echo "Error adding $_type record."
                            ;;
                        "ALIAS" | "CERT" | "PTR" | "NSEC" | "NSEC3" | "RRSIG" | "DHCID" | "DNAME" | "HINFO" | "HTTPS" |  "LOC" | "NAPTR" | "RP" | "TLSA" ) # 
                            # Unsupported - or at least, yet to be implemented - record type
                            echo "[SKIPPING]Unsupported record type: $j/$numberOfDnsRecordsInTemplate: $_type,$_name,$_content"
                            [[ $? -ne 0 ]] && echo "Error adding $_type record."
                            ;;
                        # Unknown record type
                        \?) # Invalid option
                            echo "Error: unknown record type: $_type"
                            ;;
                    esac

                done < $domainDnsRecordsListTemplate
            else # there are no records in the template
                echo "########################################################################################"
                echo "[WARNING]: $domainDnsRecordsListTemplate exists but contains $numberOfDnsRecordsInTemplate records."
                echo "[WARNING]: for help see 'bash ./populate-domain-dnsrecords-from-template.bash -h'"
                echo "[WARNING]: Beacuse the template doesn't contain records, there's noting to do, exiting now."
                echo "########################################################################################"
                exit 1
            fi 
        fi
    else # $existingDomainDnsRecords file does not exist
        echo "Error reading $existingDomainDnsRecordsFile, file does not exist. Exiting"
        exit 1
    fi

    [ "$EXECUTE" = false ] && echo "DRY RUN COMPLETE" || echo "EXECUTION COMPLETE"
    [ "$EXECUTE" = false ] && echo "No records were added. Review the results and add the [-x] parameter to EXECUTE, if satisfied!"
}
populateDomainDnsRecordsFromTemplate

# using cloudflare-cli - install with `npm install cloudflare-cli`
# https://github.com/danielpigott/cloudflare-cli
# https://github.com/shakes80/cloudflare-cli