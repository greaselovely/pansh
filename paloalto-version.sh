#!/bin/bash

clear
################################
########## SETTINGS ############

subfolder="versions"
source "${HOME}/panosh/paloalto-var.sh"

# Usage: ./paloalto-version.sh
#     or ./paloalto-version.sh HQ

if [ $1 ]
	then equipment=$(grep -i $1 $inventory)
	else equipment=$(cat $inventory)
fi

function ssi(){
	## show system info (ssi)
	hostname="$name.xml"
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<show><system><info></info></system></show>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 9.01 -# --output "$dump/$name.$FUNCNAME" "$apiurl"
	if [ ! -e "$dump/$name.$FUNCNAME" ]
		then
			echo "  Could Not Reach Firewall"
			exit 0
		else
			realversion=$(xmllint --xpath "string(//sw-version)" $dump/$name.$FUNCNAME)
			realname=$(xmllint --xpath "string(//devicename)" $dump/$name.$FUNCNAME)
	fi
	sleep 3
}


################################
####### SETTINGS END############



echo -e "Hostname\tVersion" | tr '[:lower:]' '[:upper:]' > "$dump/$win"
echo " " >> "$dump/$win"

for i in $(echo "$equipment");
	do 
		name=$(echo $i | awk 'BEGIN{FS="_";}{print $1}')
		ip=$(echo $i | awk 'BEGIN{FS="_";}{print $2}')
		port=$(echo $i | awk 'BEGIN{FS="_";}{print $3}')
		key=$(echo $i | awk 'BEGIN{FS="_";}{print $4}')
		
clear
echo
echo
echo "  Attempting to Access $name..."

ssi

if [ -z "$realname" ]
	then realversion="Failed"
fi

if [ -z "$realname" ]
	then
		echo
	else
		echo -e "$name\t$realversion" | tr '[:lower:]' '[:upper:]' >> "$dump/$win"
fi

rm "$dump/$name".* 2>/dev/null
rm "$dump/$name" 2>/dev/null

done;

if [ -z "$realname" ]
	then	
		echo "  No Asset Available"
	else
		echo 'Content-Type: text/html; charset="us-ascii" ' > "$dump/email.html"
		echo "<html>" >> "$dump/email.html"
		echo "<body>" >> "$dump/email.html"
		awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END{print "</table>"}' "$dump/$win"  >> "$dump/email.html"
		echo "</Body>" >> "$dump/email.html"
		echo "</html>" >> "$dump/email.html"
		
		(
		echo "$emailfrom"
		echo "$emailto"
		echo "MIME-Version: 1.0"
		echo "Subject: PANOS Versions" 
		echo "Content-Type: text/html" 
		cat "$dump/email.html"
		) | sendmail -t
fi

echo "  Report Sent $emailto"