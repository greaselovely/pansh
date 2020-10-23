#!/bin/bash

# Usage: ./paloalto-script-name.sh
#     or ./paloalto-script-name.sh HQ
# The second allows you to specify by a simple phrase to 

################################
########## SETTINGS ############

subfolder="sn"
source "${HOME}/panosh/paloalto-var.sh"


function sys_info() {
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<show><system><info></info></system></show>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.sn" "$apiurl"	
	realsn=$(xmllint --xpath "string(//serial)" $dump/$name.sn)
	realname=$(xmllint --xpath "string(//devicename)" $dump/$name.sn)
	realmodel=$(xmllint --xpath "string(//model)" $dump/$name.sn)
}

function error_check(){
	# look for the latest from the xml output
	checkerror=$(grep -i "error" "$dump/$name.sn" 2>/dev/null)
	errormessage=$(xmllint --xpath "string(//*[@status])" "$dump/$name.sn" 2>/dev/null)
	if [ "$checkerror" ] || [ "$checkfailed" ]
		then 
			errormessage=$(xmllint --xpath "string(//*[@status])" "$dump/$name.sn")
			failmessage=$(xmllint --xpath "string(//details/line)" "$dump/$name.sn")
			echo "  $failmessage$errormessage" 
			echo
			exit 0
	fi
}



if [ $1 ]
	then equipment=$(grep -i $1 $inventory)
	else equipment=$(cat $inventory)
fi

> "$dump/$win"
echo -e "Hostname\t\tModel\t\tSerial" | tr '[:lower:]' '[:upper:]' >> "$dump/$win"
echo " " >> "$dump/$win"

for i in $(echo "$equipment");
	do 
		name=$(echo $i | awk 'BEGIN{FS="_";}{print $1}')
		ip=$(echo $i | awk 'BEGIN{FS="_";}{print $2}')
		port=$(echo $i | awk 'BEGIN{FS="_";}{print $3}')
		key=$(echo $i | awk 'BEGIN{FS="_";}{print $4}')
echo
echo
echo "    Attempting to access $name..." | tr '[:lower:]' '[:upper:]'

sys_info
error_check

echo -e "$realname\t\t$realmodel\t\t$realsn" | tr '[:lower:]' '[:upper:]' >> "$dump/$win"

done;

pan_sn=$(cat "$dump/$win" | column -te)
echo "$pan_sn" && echo "$pan_sn" > "$dump/pan_sn.txt"


# could use an email notification here, but for now, this is what we got.


