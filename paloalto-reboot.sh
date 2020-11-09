#!/bin/bash

clear
################################
########## SETTINGS ############

subfolder="reboots"
source "${HOME}/panosh/paloalto-var.sh"
rb="$bounce/$rebootlist"

equipment=$(cat $rb | sort -r 2>/dev/null)



################################
####### SETTINGS END############

function reboot_frwl(){
	# REBOOT COMMAND!
	# VERY DANGEROUS!
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<request><restart><system></system></restart></request>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	# JUST FOR TESTING:
	#apiaction="api/?type=op&cmd=<target><show></show></target>"
	time1=$(date +%H:%M:%S)
	curl --max-time 59.11 -sk --connect-timeout 59.01 -# --output "$dump/$name-reboot.xml" "$apiurl"
	echo "$name		Start: $time1" >> "$bounce/reboots.log"
}

function validate_frwl(){
	# show system info to validate firewall upon reboot
	time2=$(date +%H:%M:%S)
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<show><system><info></info></system></show>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name-reboot-status.xml" "$apiurl"
	statuscheck=$(xmllint --xpath "string(//hostname)" $dump/$name-reboot-status.xml 2>/dev/null)
	
	if [ -z "$statuscheck" ]
		then
			version="Offline"
		else
			uptime=$(xmllint --xpath "string(//uptime)" $dump/$name-reboot-status.xml)
			version=$(xmllint --xpath "string(//sw-version)" $dump/$name-reboot-status.xml)
	fi
	
}

if [ ! -e "$bounce/reboots.tmp" ]; 
	then 
		touch "$bounce/reboots.tmp"
fi

if [ ! -e "$bounce/reboots.log" ]; 
	then 
		touch "$bounce/reboots.log"
fi

if [ -z "$equipment" ]; 
	then 
		echo "No reboots on $today!" >> "$bounce/reboots.log"
		echo "No reboots on $today!"
		exit 0
fi


echo "  $today" > "$bounce/reboots.tmp"
echo "  $today" >> "$bounce/reboots.log"
echo " " >> "$bounce/reboots.tmp"
echo "Name Version" >> "$bounce/reboots.tmp"

#########################################
########## Issue All Reboots ############

for i in $(echo "$equipment");
	do 
		name=$(echo $i | awk 'BEGIN{FS="_";}{print $1}')
		ip=$(echo $i | awk 'BEGIN{FS="_";}{print $2}')
		port=$(echo $i | awk 'BEGIN{FS="_";}{print $3}')
		key=$(echo $i | awk 'BEGIN{FS="_";}{print $4}')

reboot_frwl

done

#nap time
sleep 30m


#########################################
########## Check On Reboots #############


equipment=$(cat $rb 2>/dev/null)

if [ -z "$equipment" ]; 
	then 
		echo "Nothing In Inventory To Check" >> "$bounce/reboots.log"
		echo "Nothing In Inventory To Check"
		exit 0
fi

for i in $(echo "$equipment");
	do 
		name=$(echo $i | awk 'BEGIN{FS="_";}{print $1}')
		ip=$(echo $i | awk 'BEGIN{FS="_";}{print $2}')
		port=$(echo $i | awk 'BEGIN{FS="_";}{print $3}')
		key=$(echo $i | awk 'BEGIN{FS="_";}{print $4}')

validate_frwl

time3=$(date +%H:%M:%S)


echo "$name $version" >> "$bounce/reboots.tmp"
echo "$name		End: $time3		$version" >> "$bounce/reboots.log"

done
########## Check On Reboots #############
#########################################




#########################################
######## Email Notifications ############

echo 'Content-Type: text/html; charset="us-ascii" ' > "$bounce/reboots.html"
echo "<html>" >> "$bounce/reboots.html"
echo "<body>" >> "$bounce/reboots.html"
awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END{print "</table>"}' "$bounce/reboots.tmp"  >> "$bounce/reboots.html"
echo "</body>" >> "$bounce/reboots.html"
echo "</html>" >> "$bounce/reboots.html"

(
echo "$emailfrom"
echo "$emailto"
echo "MIME-Version: 1.0"
echo "Subject: Firewall Reboots For $today" 
echo "Content-Type: text/html" 
cat "$bounce/reboots.html"
) | /usr/sbin/sendmail -t

######## Email Notifications ############
#########################################


> "$rb"
rm -rf "$dump"
