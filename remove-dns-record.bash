#!/bin/bash
QUIET=false
DNSRECORD=""
EXECUTE=false # script will run "cfcli find" instead of "cfcli rm" without EXECUTE flag set
showhelp(){
    echo "Hi! Please specify options."
    echo
    echo "Syntax: remove-dns-record.bash -d dnsrecord [-q|h]"
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
            echo "Error: Please specify a dnsrecord after the -d parameter."
            exit 22
        fi;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit 1;;
   esac
done


#cfcli find -d thesandylizard.com -q name:kvm1.thesandylizard.com,content:195.179.201.227,type:A
((i=i+1))
#echo "************** Next Record **************************"
_name=$(echo $DNSRECORD | cut -d',' -f2)
#echo "Name: $_name"
_domain=`echo "$_name" | awk -F"." '{print $(NF-1)"."$NF}'`
#echo "Domain: $_domain"
_content=$(echo $DNSRECORD | cut -d',' -f3)
#echo "Content: $_content"
_type=$(echo $DNSRECORD | cut -d',' -f1)

#
# NOTICE: Please take notice to the [ "$EXECUTE" = true ] or [ "$EXECUTE" = false ]
#
[ "$EXECUTE" = true ] && echo "[$_domain] EXECUTING REMOVE: cfcli rm $_name -d $_domain -q name:$_name,type:$_type" || echo "[$_domain] DRY-RUN: Substituting find for remove: cfcli find -d $_domain -q name:$_name,type:$_type"
# script will run "cfcli find" instead of "cfcli rm" without EXECUTE flag set

#
# NOTICE: The following makes an irreversable API call using cloudflare-cli. 
# These commands will remove dns records if the EXECUTE flag is set. 
# [ "$EXECUTE" = true ] or [ "$EXECUTE" =  ] below
#
[ "$EXECUTE" = true ] && cfcli rm $_name -d $_domain -q name:$_name,type:$_type || cfcli find -f csv -d $_domain -q name:$_name,type:$_type
