#!/bin/bash


################################
########## SETTINGS ############

subfolder="configs"
source "${HOME}/panosh/paloalto-var.sh"

if [ $1 ]
	then equipment=$(grep -i $1 $inventory)
	else equipment=$(cat $inventory)
fi

################################
####### SETTINGS END############

if [ ! "$(ls -A $dump)" ]
	then 
		echo "Getting configs..."
		source "${HOME}/panosh/paloalto-configs.sh" $1
fi

if [ ! -d "$dyndump" ]
	then 
		mkdir -p "$dyndump"
fi

# starts the loop in the backup directory
for f in "$dump/"*".tgz"
	do 
	echo "working on $f"
	tar -xf "$f" -C "$dump" "./running-config.xml" 2>/dev/null
	realname=$(xmllint --xpath "string(//hostname)" "$dump/running-config.xml" 2>/dev/null)
	mv "$dump/running-config.xml" "$dump/$realname.xml" 2>/dev/null
done

if [ ! "$(ls -A $dump/*.xml 2>/dev/null)" ]
	then 
		echo "We have no files!!"
		exit 0
fi

> "$dyndump/$win"

for file in "$dump/"*".xml"; 
	do 
	realname=$(xmllint --xpath "string(//hostname)" "$file")
	haenable=$(xmllint --xpath "string(//high-availability/enabled)" "$file")
	tp=$(xmllint --xpath "string(//update-schedule//threats//action)" "$file")
	av=$(xmllint --xpath "string(//update-schedule//anti-virus//action)" "$file")
	wf=$(xmllint --xpath "string(//update-schedule//wildfire//action)" "$file")
#	gp=$(xmllint --xpath "string(//update-schedule//global-protect-clientless-vpn//action)" "$file")
	tpsync=$(xmllint --xpath "string(//update-schedule//threats//recurring//sync-to-peer)" "$file")
	avsync=$(xmllint --xpath "string(//update-schedule//anti-virus//recurring//sync-to-peer)" "$file")
	wfsync=$(xmllint --xpath "string(//update-schedule//wildfire//recurring//sync-to-peer)" "$file")
	tptime=$(xmllint --xpath "string(//update-schedule//threats//recurring//at)" "$file")
	avtime=$(xmllint --xpath "string(//update-schedule//anti-virus//recurring//at)" "$file")
	wftime=$(xmllint --xpath "string(//update-schedule//wildfire//recurring//at)" "$file")
#	gptime=$(xmllint --xpath "string(//update-schedule//global-protect-clientless-vpn//recurring//at)" "$file")
#   So the XML file / PAN doesn't give us the "when" as a string in the XML, but rather a XML element header itself and so we have to strip it out of the XML.  This is the current way I am doing, and if there's a more interesting way, I'd love to learn how if you know!
	tpwhen=$(xmllint --xpath "(//threats/recurring/*)" "$file" | head -1 | sed -e 's/<//g' -e 's/>//g' -e 's/sync-to-peer//g' -e 's/yes\///g' -e 's/no\///g') 2>/dev/null
	avwhen=$(xmllint --xpath "(//anti-virus/recurring/*)" "$file" | head -1 | sed -e 's/<//g' -e 's/>//g' -e 's/sync-to-peer//g' -e 's/yes\///g' -e 's/no\///g') 2>/dev/null
	wfwhen=$(xmllint --xpath "(//wildfire/recurring/*)" "$file" | head -1 | sed -e 's/<//g' -e 's/>//g' -e 's/sync-to-peer//g' -e 's/yes\///g' -e 's/no\///g')  2>/dev/null
#	gpwhen=$(xmllint --xpath "(//global-protect-clientless-vpn/recurring/*)" "$file" | head -1 | sed -e 's/<//g' -e 's/>//g' -e 's/sync-to-peer//g' -e 's/yes\///g' -e 's/no\///g') 2>/dev/null
	
	
	if [ "$haenable" = "yes" ];
		then echo -e "$realname (HA ENABLED)" >> "$dyndump/$win"
		else echo -e "$realname" >> "$dyndump/$win"
	fi

	if [ -z "$tpsync" ];
		then echo -e "\tTP = "$tp $tpwhen $tptime >> "$dyndump/$win"
		else echo -e "\tTP = "$tp $tpwhen $tptime "sync-to-peer:" $tpsync >> "$dyndump/$win"
	fi
	if [ -z "$avsync" ];
		then echo -e "\tAV = "$av $avwhen $avtime >> "$dyndump/$win"
		else echo -e "\tAV = "$av $avwhen $avtime "sync-to-peer:" $avsync >> "$dyndump/$win"
	fi
	if [ -z "$wfsync" ];
		then echo -e "\tWF = "$wf $wfwhen $wftime >> "$dyndump/$win"
		else echo -e "\tWF = "$wf $wfwhen $wftime "sync-to-peer:" $wfsync >> "$dyndump/$win"
	fi
#	if [ -z "$gpsync" ];
#		then echo -e "\tGP = "$gp $gpwhen $gptime >> "$dyndump/$win"
#		else echo -e "\tGP = "$gp $gpwhen $gptime "sync-to-peer:" $gpsync >> "$dyndump/$win"
#	fi
	if [ "$tp" = "download-and-install" ] || [ -z "$tp" ];
		then echo
		else echo -e "\tFix $realname threats - it is set to $tp" | tr '[:lower:]' '[:upper:]' >> "$dyndump/$win"
	fi
	if [ "$av" = "download-and-install" ] || [ -z "$av" ];
		then echo
		else echo -e "\tFix $realname anti-virus - it is set to $av " | tr '[:lower:]' '[:upper:]' >> "$dyndump/$win"
	fi
	if [ "$wf" = "download-and-install" ] || [ -z "$wf" ];
		then echo
		else echo -e "\tFix $realname wildfire - it is set to $wf " | tr '[:lower:]' '[:upper:]' >> "$dyndump/$win"
	fi
	if [ "$gp" = "download-and-install" ] || [ -z "$gp" ];
		then echo
		else echo -e "Fix $realname wildfire - it is set to $gp " | tr '[:lower:]' '[:upper:]' >> "$dyndump/$win"
	fi
	
echo -e " " >> "$dyndump/$win"
	
done;


#clean up
rm "$dump/"*".xml"
cat "$dyndump/$win"



