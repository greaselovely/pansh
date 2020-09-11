#!/bin/bash

clear
################################
########## SETTINGS ############

subfolder="configs"
source "${HOME}/panosh/paloalto-var.sh"

# Usage: ./paloalto-configs.sh
#     or ./paloalto-configs.sh HQ

if [ "$1" ]
	then equipment=$(grep -i $1 $inventory | sort)
	else equipment=$(cat $inventory | sort)
fi

################################
####### SETTINGS END############

function get_config() {
	hostname="$name"
	mkdir "$dump/$hostname"
	apiaction="api/?type=export&category=device-state"
	apixpath=""
	apielement=""
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$hostname.tgz" "$apiurl"
}

function check_hostname(){
	tar -xf "$dump/$hostname.tgz" -C "$dump/$hostname"
	namefromrun=$(xmllint --xpath "string(//hostname)" "$dump/$hostname/running-config.xml")
}

touch "$dump/$win"
> "$dump/$win"
echo -e "Hostname\t\tStatus" | tr '[:lower:]' '[:upper:]' >> "$dump/$win"
echo " " >> "$dump/$win"

# starts the loop and defines the separator and prints out what we have defined in the inventory file.
for i in $(echo "$equipment");
	do 
		name=$(echo $i | awk 'BEGIN{FS="_";}{print $1}')
		ip=$(echo $i | awk 'BEGIN{FS="_";}{print $2}')
		port=$(echo $i | awk 'BEGIN{FS="_";}{print $3}')
		key=$(echo $i | awk 'BEGIN{FS="_";}{print $4}')
		
clear
echo
echo
echo "    Attempting to Backup $name..."

get_config

check_hostname

# Check if the file was transferred
if [ -z "$namefromrun" ]
	then status="FAILED"
	else status="SUCCESS"
fi

rm -rf "$dump/$hostname"

# diff the files out to a logfile that gets emailed out
echo -e "$name\t\t$status" >> "$dump/$win"

done;

echo 'Content-Type: text/html; charset="us-ascii" ' > "$dump/email.html"
echo "<html>" >> "$dump/email.html"
echo "<body>" >> "$dump/email.html"
awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END{print "</table>"}' "$dump/$win"  >> "$dump/email.html"
echo "</body>" >> "$dump/email.html"
echo "</html>" >> "$dump/email.html"

(
echo "$emailfrom"
echo "$emailto"
echo "MIME-Version: 1.0"
echo "Subject: Firewall Backups For $today" 
echo "Content-Type: text/html" 
cat "$dump/email.html"
) | /usr/sbin/sendmail -t

