#!/bin/bash
QUIET=false
DOMAINNAME=""
showhelp(){
    echo "Hi! Please specify options."
    echo
    echo "Syntax: add-dkim-to-domain-then-add-to-cloudflare.bash -d example.com [-h]"
    echo "options:"
    echo "-h    Print this usage Help."
    echo
}
while getopts "hd:" option; do
      case $option in
      h) # display Help
         showHelp
         exit 1;;
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

# add dkim to domain on Carbonio/Zimbra
ssh zero-carbonio-dmz 'sudo su - zimbra -c "/opt/zimbra/libexec/zmdkimkeyutil -a -d '$DOMAINNAME'"' > ./data/$DOMAINNAME.dkim.public
# query dkim for domain on Carbonio/Zimbra
ssh zero-carbonio-dmz 'sudo su - zimbra -c "/opt/zimbra/libexec/zmdkimkeyutil -q -d '$DOMAINNAME'"' > ./data/$DOMAINNAME.dkim.query

# remove dkim to domain on Carbonio/Zimbra
# ssh zero-carbonio-dmz 'sudo su - zextras -c "/opt/zextras/libexec/zmdkimkeyutil -r -d '$DOMAINNAME'"' > ./data/$DOMAINNAME.dkim.public

DKIMFILE="./data/$DOMAINNAME.dkim.query"

# example
# DKIM Selector:
# 03B1C4D0-C683-11EC-B44D-4EEFB2448DAC
SELECTORIDLINE="$(awk '/DKIM Selector\:/{ print NR; exit }' $DKIMFILE)"
DKIMSELECTOR="$(awk 'FNR>=(( '$SELECTORIDLINE' + 1 )) && FNR<=(( '$SELECTORIDLINE' + 1 ))' $DKIMFILE)"
#echo "DKIMSELECTOR: $DKIMSELECTOR"

# example
# DKIM Public signature:
# 1031E9BE-C675-11EC-B565-F1B5B1448DAC._domainkey IN      TXT     ( "v=DKIM1; k=rsa; "
#           "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyBSzIg9CS7euR8Tkvdx2jCXYfUb2b9n0iafYAgn0jRzOCuTqP5EYfg7fi8L8snE9tWEw/LT5pxMcZ7rFUvx8jWDlh2E6UgW+WHMOAep/gW579IoirmHNpCkNPn/uAMqD0v/fa9fnWCmjvZFG3fu3glnPc2XmW/kDLMQmxfNhlDAs1dl+luxx/TYfWQGGKVZ0+ZTSZQoujmB7vx"
#           "44FpnTXzF6SKoVI6RHi6u+m2hJmh9KR7OdMab42GDsjhv/TPAerHcIlqRU6PqSM1/1WW3ZXnyiC588cMYmOkQtW2PV8oWSflFU9dSz9Qjyjem8lwspbUWzM9mU1ljBVPMlytR7vQIDAQAB" )  ; ----- DKIM key 1031E9BE-C675-11EC-B565-F1B5B1448DAC for sandylizardhosting.com
SIGNATUREIDLINE="$(awk '/DKIM Public signature\:/{ print NR; exit }' $DKIMFILE)"
DKIMSIGNATURE="$( (awk 'FNR>=(( '$SIGNATUREIDLINE' + 1 )) && FNR<=(( '$SIGNATUREIDLINE' + 4 ))' $DKIMFILE) | tr -d " " | tr -d "\"\"" | tr -d "\n" | tr -d "\n" | tr -d "\t"| awk -F"[()]" '{print $2}' )"
#echo "DKIMSIGNATURE: $DKIMSIGNATURE"

# process results into the right dnsrecord format
# record should look like below
#'TXT,1031e9be-c675-11ec-b565-f1b5b1448dac._domainkey.sandylizardhosting.com,v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyBSzIg9CS7euR8Tkvdx2jCXYfUb2b9n0iafYAgn0jRzOCuTqP5EYfg7fi8L8snE9tWEw/LT5pxMcZ7rFUvx8jWDlh2E6UgW+WHMOAep/gW579IoirmHNpCkNPn/uAMqD0v/fa9fnWCmjvZFG3fu3glnPc2XmW/kDLMQmxfNhlDAs1dl+luxx/TYfWQGGKVZ0+ZTSZQoujmB7vx44FpnTXzF6SKoVI6RHi6u+m2hJmh9KR7OdMab42GDsjhv/TPAerHcIlqRU6PqSM1/1WW3ZXnyiC588cMYmOkQtW2PV8oWSflFU9dSz9Qjyjem8lwspbUWzM9mU1ljBVPMlytR7vQIDAQAB,Auto,false,3ec8b2fde78f6963bcb0b699c2731b76'
# -or-
#'TXT,03B1C4D0-C683-11EC-B44D-4EEFB2448DAC._domainkey.sandylizardhosting.com,v=DKIM1;k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy2ZPcPqfE/bSVCCdUfwSdjMjah4PnF3pdTGgUXZTPo7NSTMzLnOmaZsskFfWe2JCYf34pJyUrt2as8/DmhIu8JCLCtKsLq+b79Xd3DkpzqKa1rl4uwAKDpxcRGGiUwELs/qFSxPVX+8sdQQ3e2hsCkUrhaS+U1jBRzeuoIGvbX1tW72hGQd9x7i//RJ9OBd0ubQvCKi+QGfs0UUMcKzfnQlf9nZ3k2vjhmdOysRN6KBf0gsjwD0JYCuxHNilCru7JgtFZM6fYi/kzQPUIYvFZUBF7HDVKfwhmdXryClA0c1DyZxKTxRK4SzANgjPaVjrRUg9coo3DfCCPk28vLwHOQIDAQAB'
DNSRECORD='TXT,'$DKIMSELECTOR'._domainkey.'$DOMAINNAME','"$DKIMSIGNATURE"

# add dkim record to cloudflare
# easily add to cloudflare using

echo
echo ./add-dns-record.bash -x -d $DOMAINNAME -r "'"$DNSRECORD"'"
#./add-dns-record.bash -x -d $DOMAINNAME -r "'"$DNSRECORD"'" &
echo "# To verify the dkim signature you can run: dig -t txt $DKIMSELECTOR._domainkey.$DOMAINNAME"
