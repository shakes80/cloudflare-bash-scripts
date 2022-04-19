# This script takes a firewall configuration xml file
# and a dnsrecord template file and injects AND replaces the existing aliases
# in the firewall configuration file

# TODO: make this script ADD the xml nodes to the config
# instead of replacing the existing nodes. Replacing meets current needs. 

# pfSense backup configuration file can be downloaded from here:
# https://firewall.sandylizardhosting.com:8888/services_acb.php
# and placed in the directory for this script
fwconfigfileoriginal="firewall.config.xml" # original
fwconfigfileworking="$fwconfigfileoriginal.working" # the temporary working copy to create
fwconfigfileoutput="$fwconfigfileoriginal.proposed" # the output, a proposed modified firewall config

# we are using the same template format and the same template for cloudflare dnsrecords
templatefile="../domain-dnsrecords.list.template"
aliasesfile="domain-dnsrecords.firewall.aliases"

# do data transformation to simplify from the template format and replace some chars 
# to comply with the format of the firewall config
sed 's/.TEMPLATE.TLD//' $templatefile |\
sed 's/.secured/_secured/'|\
sed 's/.dmz/_dmz/'|\
sed 's/.internal/_internal/'|\
grep '^[\A]'|\
awk -F',' '{ print $3 " " $2}' > $aliasesfile

# read aliases
aliaseslist=$(cat $aliasesfile)

# rewrite aliases into XML in the format for pfSense backup configuration file
aliasnodes=""
while IFS= read -r aliasline; do
    aliasname=$(echo $aliasline | cut -d ' ' -f 2-)
    aliasip=$(echo $aliasline | cut -d ' ' -f1)
    aliashost=$(echo $aliasline | cut -d ' ' -f 2- | tr _ .)
    aliasfqdn=$(echo "$aliashost.sandylizardhosting.com")
    aliasdesc=$(echo "alias for $aliasfqdn")
    aliasdetail=$(echo "IP address - $aliasip alias for $aliasfqdn")

# FIX THIS CRAP TOMORROW
    # echo [ "$aliasip" = "$aliasname" ]
    if [ "$aliasip" = "$aliasname" ];
    then
        # # debug
        # echo "alias name and alias ip ARE the same. \n \
        # aliasline is: $aliasline\n \
        # $aliasip,$aliasname"
        
        # don't add the entries that did not have a name, skip it
        continue
    else
        # # debug
        # echo "alias name and alias ip are not the same. \n \
        # aliasline is: $aliasline\n \
        # $aliasip,$aliasname"
        
        # add the node to the list of nodes
        aliasnodes=$aliasnodes"\t\t<alias>\n\t\t\t<name>$aliasname</name>\n\t\t\t<type>host</type>\n\t\t\t<address>$aliasip</address>\n\t\t\t<descr><"'![CDATA['$aliasdesc']]></descr>\n\t\t\t<detail><![CDATA['"$aliasdetail]]></detail>\n\t\t</alias>\n"
    fi
done < "$aliasesfile"

#echo "$aliasnodes"

# work on a copy, leave original alone
rm -f $fwconfigfileworking
cp  $fwconfigfileoriginal $fwconfigfileworking

# startline is the first occurance of <aliases>
startline=$(awk '/<aliases>/{print NR}' $fwconfigfileworking)
# strange parameter format for sed includes linenumber and "p"
startlinep=$startline"p"
# endline is the first occurance of </aliases>
endline=$(awk '/<\/aliases>/{print NR}' $fwconfigfileworking)
# Start writing output from first line of file to occurance of <aliases>
sed -n "1,$(echo $startlinep)" $fwconfigfileworking > $fwconfigfileoutput
# inject the nodes we created
echo "$aliasnodes" >> $fwconfigfileoutput
# from first to occurance of </aliases> to EOF
sed -n "$(echo $endline),\$p" $fwconfigfileworking >> $fwconfigfileoutput

# clean up our mess
rm $fwconfigfileworking
rm $aliasesfile

# suggest next steps
echo "Script complete. The output is located at: $(pwd)/$fwconfigfileoutput"
echo "You can fetch from home using the command below:"
echo "scp zero-mci1:$(pwd)/$fwconfigfileoutput ~/$fwconfigfileoriginal"
echo "NOTE: the filename is changed back to the original .xml from .proposed during the above transfer"
echo "and you may need to change the host."