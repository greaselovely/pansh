#!/bin/bash


clear
################################
########## SETTINGS ############


subfolder="reboots"
source "${HOME}/panosh/paloalto-var.sh"


if [ $1 ]
	then
		device=$(grep -i "$1" "$inventory")
	else
		echo
		read -p "  Name of the device you want to schedule : " tempdevice
		device=$(grep -i "$tempdevice" "$inventory")
fi
	

if [ -z "$device" ]
	then
		echo
		echo "  Cannot find $1$tempdevice in inventory, exiting..."
		echo
		exit 0
fi

schedulecheck=$(grep -i "$device" "$bounce/$rebootlist")

if [ "$device" == "$schedulecheck" ]
	then
		echo
		echo "  That device appears to be scheduled already.  Exiting..."
		echo
		exit 0
fi

for i in $(echo "$device");
	do name=$(echo $i | awk 'BEGIN{FS="_";}{print $1}'| tr "[:lower:]" "[:upper:]")
done

echo
read -n1 -p "  Please confirm you want to schedule $name for reboot?  (y/n) " confirmreboot
if [ "$confirmreboot" == "y" ];
	then 
		echo
		echo "  This has been sent over for reboot overnight!"
		echo "$device" >> "$bounce/$rebootlist"
	else 
		echo
		echo "  Word.  We did NOT schedule $name for reboot."
fi

echo
echo "  Here is what is scheduled : "
echo

scheduled=$(cat "$bounce/$rebootlist")

for i in $(echo "$scheduled");
	do 
		echo "  $i" | awk 'BEGIN{FS="_";}{print $1}'
done
echo
