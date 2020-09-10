#!/bin/bash

# Ideas:
# check for versions above the current running version and provide a menu option
# check for versions above the current running version and also show base version that may be needed

################################
####### SETTINGS START##########
################################

# This can be run three ways:
# ./scriptname force (this avoids the latest version check and allows you to download a specific version)
#		I saw an issue where a hotfix version was marked by PAN as "latest" so I had to create this work around.
# ./scriptname WLP (or full hostname for grep to work)
# ./scriptname (you'll be prompted for info)


subfolder="software_upgrade"
source "./paloalto-var.sh"


function TitleCaseConverter() {
    sed 's/.*/\L&/; s/[a-z]*/\u&/g' 
}

function ssi(){
	## show system info (ssi)
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<show><system><info></info></system></show>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.ssi" "$apiurl"	
	app_version=$(xmllint --xpath "string(//app-version)" "$dump/$name.ssi" | cut -c 1-4 )
	sleep 3
}

function rssi(){
	## request system software info (rssi)
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<request><system><software><info></info></software></system></request>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.rssi" "$apiurl"	
	current=$(xmllint --xpath "string(//versions/entry[current='yes']//version)" "$dump/$name.rssi")
	sleep 3
}

function rssc(){
	# request system software check (rssc)
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<request><system><software><check></check></software></system></request>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	echo
	echo "  Checking with PAN..."
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.rssc" "$apiurl"
	xmllint --xpath "//versions/entry[latest='yes']" "$dump/$name.rssc" > "$dump/$name.tmp"
	downloaded=$(xmllint --xpath "string(//downloaded)" "$dump/$name.tmp" 2>/dev/null)
	current=$(xmllint --xpath "string(//current)" "$dump/$name.tmp" 2>/dev/null)
	latestversion=$(xmllint --xpath "string(//version)" $dump/$name.tmp 2>/dev/null)
}

function error_check(){
	# look for the latest from the xml output
	checkerror=$(grep -i "error" "$dump/$name" 2>/dev/null)
	errormessage=$(xmllint --xpath "string(//*[@status])" "$dump/$name" 2>/dev/null)
	if [ "$checkerror" ] || [ "$checkfailed" ]
		then 
			errormessage=$(xmllint --xpath "string(//*[@status])" "$dump/$name")
			failmessage=$(xmllint --xpath "string(//details/line)" "$dump/$name")
			echo "  $failmessage$errormessage" 
			exit 0
	fi
}

function sji(){
	# show job id x (sji)
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<show><jobs><id>$jobid</id></jobs></show>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.sji" "$apiurl"
	sji_message=$(xmllint --xpath "string(//details/line)" "$dump/$name.sji" 2>/dev/null)
}	

function cudl(){
	# request content upgrade download latest (cudl)
	echo -ne "    $name          \033[0K\r"
	echo "  Latest Content Download First..."
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<request><content><upgrade><download><latest></latest></download></upgrade></content></request>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.cudl" "$apiurl"
	jobid=$(xmllint --xpath "string(//job)" $dump/$name.cudl)
}

function cuivl(){
	# request content upgrade install version latest (cuivl)
	echo "  Latest Content Install Now..."
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<request><content><upgrade><install><version>latest</version></install></upgrade></content></request>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.cuivl" "$apiurl"
	jobid=$(xmllint --xpath "string(//job)" "$dump/$name.cuivl")
}		

function panos_download(){
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<request><system><software><download><version>$version</version><sync-to-peer>yes</sync-to-peer></download></software></system></request>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	echo
	echo "  Downloading..."
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name.download" "$apiurl"
	jobid=$(xmllint --xpath "string(//job)" "$dump/$name.download")
}		

function panos_download_only(){
	echo "  Confirming Download Only..."
	rssi
	echo "  Downloaded : $downloaded"
	echo "  Skipping Install...            "
}

function panos_install(){
	echo "  Installing..."
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<request><system><software><install><version>$version</version></install></software></system></request>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name" "$apiurl"
	jobid=$(xmllint --xpath "string(//job)" $dump/$name)	
}

function panos_install_verified(){
	echo -ne "  Verifying Install Initiated...\033[0K\r"
	apiaction="api/?&type=op&cmd="
	apixpath=""
	apielement="<show><jobs><id>$jobid</id></jobs></show>"
	apikey="&key=$key"
	apiurl="https://$ip":"$port/$apiaction$apixpath$apielement$apikey"
	curl -sk --connect-timeout 59.01 -# --output "$dump/$name" "$apiurl"
	installstatus=$(xmllint --xpath "string(//job//status)" $dump/$name)
	installresult=$(xmllint --xpath "string(//job//result)" $dump/$name)
	sleep 15s
}

function job_progress(){
	progress="0"
		while [ $progress -lt 99 ];
			do
				sji
				echo -ne "  Job id $jobid is at $progress%\033[0K\r"
				sleep 5
				# fucking palo alto replaces the progress integer with the time it ended and the while loop doesn't like the colons, so I have to remove them...
				progress=$(xmllint --xpath "string(//progress)" "$dump/$name.sji" | sed s/://g)
		done
	job_status=""
		while [ "$status" != "FIN" ];
			do
				sji
				status=$(xmllint --xpath "string(//status)" "$dump/$name.sji")
				echo -ne "  Job id $jobid is $status...\033[0K\r"
				sleep 5
		done
	result=$(xmllint --xpath "string(//result//result)" "$dump/$name.sji")
		if [ $result == "FAIL" ]
			then
				line=$(xmllint --xpath "string(//line)" "$dump/$name.sji")
				echo "  Job $jobid has $line..."
				exit 0
		fi
}

################################
####### SETTINGS END############
################################

clear
if [ "$1" == "" ]
	then 
		read -p "  Provide the partial or full firewall hostname : " frwl
			if [ -z "$frwl" ]
				then 
					echo "  No Entry Detected, Exiting..."
					exit 0
			fi
		equipment=$(grep -i $frwl $inventory)
	else
		equipment=$(grep -i $1 $inventory)
			if  [ -z "$equipment" ];
				then 
					echo "  $name No Asset Detected in Inventory, Exiting..." 
				exit 0
			fi
fi	

clear
for i in $(echo "$equipment");
	do 
		name=$(echo $i | awk 'BEGIN{FS="_";}{print $1}')
		ip=$(echo $i | awk 'BEGIN{FS="_";}{print $2}')
		port=$(echo $i | awk 'BEGIN{FS="_";}{print $3}')
		key=$(echo $i | awk 'BEGIN{FS="_";}{print $4}')

exec -c

rm "$dump/$name."* 2>/dev/null
rm "$dump/$name" 2>/dev/null


while [ "$current" == "" ]
	do
		echo -ne "    $name          \033[0K\r"
		rssi
		if [ "$current" == "" ]
			then			
				rssc
		fi
done

echo -ne "    $name  ($current)\033[0K\r"

ssi

if [ "$app_version" -le "8226" ]
	then
		cudl
		job_progress
		cuivl
		job_progress
fi

error_check


if [ "$1" == "force" ]
	then
		echo "  Forcing Install..."
	else
		if [ "$current" == "yes" ]
			then 
			echo "  This device is already running the latest PANOS version, nothing to do.  Exiting. "
			echo
			exit 0
		fi
fi 

rssc

if [ "$version" != "$latestversion" ];
	then 
		read -n1 -p "  The latest version is $latestversion, download it?  (y/n) " latestquestion
			if [ "$latestquestion" == "y" ];
				then 
					version="$latestversion"
				else 
					echo
					read -p "  What version do you want to download? " userversion
					doesitexist=$(grep -oh "$userversion" "$dump/$name.rssc" 2>/dev/null)
					version="$userversion"
					if [ -z "$doesitexist" ]
						then 
							echo "  $userversion is not available.  Exiting..."
							exit 0
						else
							if [ "$userversion" == "$latestversion" ];
								then
									echo "  Dude, I just asked you if you wanted that version...   "
									echo "  We are noping out of here for you being a smart ass..."
									exit 0
							fi
					fi

			fi
fi

if [ "$downloaded" == "yes" ]
	then 
		echo
		read -n1 -p "  This version is already downloaded, do you want to download it again?  (y/n) : " downloadagain
fi

while [ "$downloadorinstall" == "" ] && [ "$downloadorinstall" != "d" ] && [ "$downloadorinstall" != "i" ] && [ "$installonly" != "y" ] && [ "$installonly" != "n" ];
	do
		if [ "$downloaded" == "yes" ]
			then
				echo
					read -n1 -p "  Do you want to install $version on $name? (y/n) : " installonly
			else
				echo
					read -n1 -p "  Do you want to download only -or- install $version on $name? (d/i) : " downloadorinstall		
		fi
done

if [ "$downloadorinstall" = "i" ] || [ "$installonly" == "y" ]
	then
		echo
		read -n1 -p "  Do you want to schedule a reboot of $name? (y/n) : " rebootquestion
		echo
fi

if [ "$downloadagain" == "y" ]
	then
		panos_download

		error_check
		

		job_progress
		echo "  Verifying Download...                  "
		sji
		echo "  $sji_message" | TitleCaseConverter

		error_check
		
fi

if [ "$downloadorinstall" == 'i' ]  || [ "$installonly" == "y" ]
	then
				
		panos_install

		error_check
		
		
		sji
				
		error_check
		

		panos_install_verified
		
		error_check
		

		job_progress

fi

if [ "$downloadorinstall" == "d" ] 
	then 
		panos_download_only
		exit 0
fi

if [ "$installonly" == "n" ]
	then
		echo
	else
		if [ "$rebootquestion" != "y" ];
			then 
				echo "  We are not scheduling $name for reboot, you'll have to reboot it manually "
			else
				if [ ! -e "$bounce/$rebootlist" ]
					then 
						echo "$equipment" > "$bounce/$rebootlist"
					else
						echo "$equipment" >> "$bounce/$rebootlist"
				fi
			echo 
			echo "  Current Reboots Scheduled : "
			echo
			scheduled=$(cat "$bounce/$rebootlist")
			for i in $(echo "$scheduled");
				do 
					echo "  $i" | awk 'BEGIN{FS="_";}{print $1}'
			done
			echo
		fi
fi




rm "$dump/$name."* 2>/dev/null
rm "$dump/$name" 2>/dev/null

done

