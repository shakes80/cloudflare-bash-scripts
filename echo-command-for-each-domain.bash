#!/bin/bash
# script echos back command with $domain appended
# TODO: implement a replacement string in COMMAND for alternate placement of $domain
QUIET=false # Not Implemented
COMMAND="" # initialize COMMAND
USER="" # initialize USER
EXECUTE=false # Not Yet Implemented 
showhelp(){
    echo "Hi! Please specify options."
    echo
    echo "Syntax: echo-command-for-each-domain.bash -c command [-q|u|h]"
    echo "options:"
    echo "-h    Print this usage Help."
    echo "-q    Run quietly."
    echo "-u    Optional - USER to su as"
    echo "-x    Execute - DONT ECHO, JUST EXECUTE)."
    echo
}
fetchDomainsList(){
    ./fetch-domains-list.bash -q
}
while getopts "hquxc:" option; do
      case $option in
      h) # display Help
         showHelp
         exit 1;;
      q) # quiet
         QUIET=true;;
      u)
         USER=$OPTARG;;
      x) # execute, otherwise, dry-run
         EXECUTE=true;;
      c) # Enter a name
        if [[ ! -z "$OPTARG" ]];then
            COMMAND=$OPTARG
        else 
            echo "Error: Please specify a COMMAND after the -c parameter."
            exit 22
        fi;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit 1;;
   esac
done

fetchDomainsList

# run LOCALLY ON MACBOOK in Systems Administration/cloudflare-bash-scripts
domianListFile="data/domains.list"
while read domain; do
    if [ "$USER" = "" ]; then
        echo "$COMMAND $domain"
    else
        echo "su - $USER -c '"$COMMAND $domain"'"
    fi
done < $domianListFile
