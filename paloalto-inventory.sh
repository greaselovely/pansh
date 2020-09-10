#!/bin/bash
#not using the central var file as it creates loops in the inventory check

subfolder="inventory"
today=$(date +%m-%d-%Y)
vendor="paloalto"
win="success.txt"
fail="error.txt"
final="$vendor$subfolder.txt"
bounce="${HOME}/$vendor/reboots"
dump="${HOME}/$vendor/$subfolder/$today"
inventory="${HOME}/panosh/$vendor-inventory.txt"
rebootlist="rebootlist.txt"
donotinstall="false"
downloadagain="y"

shopt -s nocasematch

if [ -z "$subfolder" ] 
	then
		subfolder=temp
fi

if [ ! -d "$dump" ]
	then
		mkdir -p "$dump"
fi

if [ ! -d "$bounce" ]
	then
		mkdir -p "$bounce"
fi

function sys_info() {
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<show><system><info></info></system></show>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.sn" "$apiurl"	
	realsn=$(xmllint --xpath "string(//serial)" "$dump/$name.sn")
	realname=$(xmllint --xpath "string(//devicename)" "$dump/$name.sn")
	realmodel=$(xmllint --xpath "string(//model)" "$dump/$name.sn")
}

function get_api_key() {
	apiurl="https://$ip:$port/api/?type=keygen&user=$username&password=$password"
	echo
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.key" "$apiurl"
	key=$(xmllint --xpath "string(//key)" "$dump/$name.key")
}

function error_check(){
	error=$(xmllint --xpath "string(//msg)" "$dump/$name.key" 2>/dev/null)
}

if [ "$1" == "help" ] || [ "$1" == "--h" ]|| [ "$1" == "-h" ]
	then
		echo "  $0 <hostname> <ip addr> <port> <username> [enter]"  
		echo 
		echo "  $0 FRWL-NAME-01 1.2.3.4 443 admin [enter]" 
		echo 
		echo "  You'll be prompted for the password "
		echo
		exit 0
fi

if [ "$1" ]
	then tempname="$1"
		ip="$2"
		port="$3"
		username="$4"
		if [ -z "$4" ]
			then echo && echo "  Here's How To Use Me:"
			echo
			"$0" help
			exit 0
		fi
		read -s -p " Password: " temppassword
	else 
		read -p " Name: " tempname
		read -p " IP Address: " ip
		read -p " Port Number: " port
		read -p " Username: " username
		read -s -p " Password: " temppassword
fi

name=$(tr "[:lower:]" "[:upper:]" <<< $tempname)
# one liner to urlencode the password if there are special characters
password=$(echo -n "$temppassword" | curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | cut -c 3-)
# using this to see if we already have the device name in the inventory
chkname=$(grep -i $name "$inventory" 2>/dev/null)
chkip=$(grep -i $ip "$inventory" 2>/dev/null)

if [ "$chkname" ] || [ "$chkip" ]
	then 
		echo
		echo "  Asset exists in inventory, exiting..."
		echo
		exit 0
fi

#function calls
get_api_key
error_check


if [ "$error" ]
	then
		echo
		echo "$error"
		echo " We sent : $apiurl "
		exit 0
fi

echo " "
#-=add to inventory?=-
echo & echo "  Do you want to add to the existing inventory?"
echo & read -n1 -p "  Please confirm (y/n) : " confirm

if [ "$confirm" != "y" ];
	then 
		echo "  OK.  Here's your URL key:"
		echo "  $key "
		exit
	else 
		echo "${name}_${ip}_${port}_${key}" >> "$inventory"
		echo " Checking to see if it is accessible "
			sys_info
		echo -e "  $realname\t\t$realmodel\t\t$realsn" > "$dump/$win"
		column -te "$dump/$win"
		echo
		echo
fi


