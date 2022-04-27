QUIET=false
DNSRECORD=""
EXECUTE=false # script will run "cfcli find" instead of "cfcli rm" without EXECUTE flag set
showhelp(){
    echo "Hi! Please specify options."
    echo
    echo "Syntax: add-dns-record.bash -d DNSRECORD [-q|h]"
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
            DNSRECORD=$OPTARG
        else 
            echo "Error: Please specify a DNSRECORD after the -d parameter."
            exit 22
        fi;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit 1;;
   esac
done

((j=j+1))
#echo "************** Next Record **************************"
_name=$( echo "$(echo $DNSRECORD | cut -d"," -f2)" | sed "s/TEMPLATE.TLD/$DOMAINNAME/g")
#echo "Name: $_name"
_domain=`echo "$_name" | awk -F"." '{print $(NF-1)"."$NF}'`
#echo "Domain: $_domain"
_content=$( echo "$(echo $DNSRECORD | cut -d',' -f3)" | sed "s/TEMPLATE.TLD/$DOMAINNAME/g") 
#echo "Content: $_content"
_type=$(echo $DNSRECORD | cut -d',' -f1)

case $_type in
    "A" | "AAAA" | "CNAME" | "NS" | "PTR" | "SOA" | "SOA" | "DNSKEY" | "DS" | "TXT" ) # standard addition to cloudflare
        [ "$EXECUTE" = true ] && cfcli -t "$_type" -d "$DOMAINNAME" add "$_name" "$_content" || echo "[$_domain] Proposed command: cfcli -t $_type -d $DOMAINNAME add $_name $_content"
        [[ $? -ne 0 ]] && echo "[$_domain] Error adding $_type record."  
        ;;
    "MX" ) # MX (Mail eXchange)
        #    -p  Set priority when adding a record (MX or SRV)
        [ "$EXECUTE" = true ] && cfcli -t "$_type" -p 10 -d "$DOMAINNAME" add "$_name" "$_content" || echo "[$_domain] Proposed command: cfcli -t $_type -p 10 -d $DOMAINNAME add $_name $_content"
        [[ $? -ne 0 ]] && echo "[$_domain] Error adding $_type record."
        ;;
    "SRV" ) # SRV (location of service)
        # Add an SRV record (then 3 numbers are priority, weight and port respectively)
        [ "$EXECUTE" = true ] && cfcli -t "$_type" add "$_name" "$_content" 1 1 1 "$DOMAINNAME" || echo "[$_domain] Proposed Command: cfcli -t $_type add $_name $_content 1 1 1 $DOMAINNAME"
        [[ $? -ne 0 ]] && echo "[$_domain] Error adding $_type record."
        ;;
    "ALIAS" | "CERT" | "PTR" | "NSEC" | "NSEC3" | "RRSIG" | "DHCID" | "DNAME" | "HINFO" | "HTTPS" |  "LOC" | "NAPTR" | "RP" | "TLSA" ) # 
        # Unsupported - or at least, yet to be implemented - record type
        echo "[$_domain] [SKIPPING]Unsupported record type: $j/$numberOfDNSRECORDsInTemplate: $_type,$_name,$_content"
        [[ $? -ne 0 ]] && echo "[$_domain] Error adding $_type record."
        ;;
    # Unknown record type
    \?) # Invalid option
        echo "[$_domain] Error: unknown record type: $_type"
        ;;
esac
