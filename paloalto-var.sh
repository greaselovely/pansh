#!/bin/bash

# Used to centralize all variables for all PAN scripts

today=$(date +%m-%d-%Y)
vendor="paloalto"
win="success.txt"
fail="error.txt"
final="$vendor$subfolder.txt"
bounce="${HOME}/$vendor/reboots"
inventory="${HOME}/panosh/$vendor-inventory.txt"

###
emailfrom="From: panosh Admin <no-reply@panosh.local>"
emailto="To: my-email-address@domain.com"
#	email addresses used in the sendmail functions for notifications
###


###
dump="${HOME}/$vendor/$subfolder/$today"
#	subfolder is configured per script
###

###
cnalist="${HOME}/scripts/cna.txt"
#	a list of URLs that mobile devices use to check if they have internet connectivity
#	or other very static websites where a phrase will be known
###	used for inet_health script

###
rebootlist="rebootlist.txt"
donotinstall="false"
downloadagain="y"
#	used for PANOS upgrade script
###
###
dyn="dynamic_updates"
dyndump="${HOME}/$vendor/$dyn/$today"
#   used for dynamic update checking
###

shopt -s nocasematch

if [ ! -d "$subfolder" ] 
	then
		subfolder=temp
fi

if [ ! -d "$dump" ]
	then
		mkdir -p "$dump"
fi

if [ ! -e "$inventory" ]
	then 
		clear
		echo
		echo "  We need to create an inventory list!"
		./paloalto-inventory.sh
fi


