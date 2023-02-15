#!/bin/bash -x

# ^ ^ ^ Having issues? Change "#!/bin/bash" to "#!/bin/bash -x" for an extremely verbose script output!

# Set common paths, you don't have to edit this, but you can if you need to! All of the mare required for smooth operation.
LOGDIR="./_logs"
mkdir "$LOGDIR" 2>/dev/null
SIMPLELOG="$LOGDIR/Summary.log"
touch "$SIMPLELOG" 2>/dev/null
BIGLOG="$LOGDIR/Sync.log"
touch "$BIGLOG" 2>/dev/null
CONFIGFILE="./globalConfig.sh"

# Load config file, if it can't then it has no mirrors so it exits.
if [ -f "$CONFIGFILE" ]; then
    echo "Loading config file..."
else
    echo "No config file, no mirrors loaded... exiting script."
	exit 0
fi

# Check for other running instances.
# NOTE: If you plan on running this on a crontab schedule DO NOT CHANGE IT
# However if you plan to only run it directly, lower the number in the
# double patenthesis to 2, like so -
# if (( pids > 2 ); then
pids="$(ps ax | grep "$0" | grep -v grep | wc -l)"
if (( pids > 3 )); then
echo -e "\n======\nERROR!\n======\n\n$0 is already running! Exiting script!\n"
sleep 10
exit 1
fi

echo -ne "\n\n------------------------------------------\n$(date +'%R:%S-%d/%m/%Y'): Started script!\n$(date +'%R:%S-%d/%m/%Y')..." >> "$SIMPLELOG"

#  Load config.
source "$CONFIGFILE"

########################################################
########################################################
#####                                              #####
#####  Sync from PC/Server => remote code below.   ##### 
#####                                              #####
########################################################
########################################################

# If StartingSource or StartFromLocal are not set in the config then move on to serverside sync only.
if [[ "$StartFromLocal" == "0" || -z "$StartingSource" ]]; then
	continue;
else
	# Store the mirror numbers from config into a temporary array for dribe to Mirror usage.
	mirrorsInProg=( "${MirrorNames[@]}" )
	MirrorsToGo=( "${MirrorNames[@]}" )
	for mirror in "${mirrorsInProg[@]}"
	do
		# Check config to see if StartFromLocal and StartingSource are set.
		if [[ "$StartFromLocal" == "1" && -n "$StartingSource" ]]; then
			# If CustomOauthPath is not set then it will just pick a random json then fail since we dont want to waste all SA's capacity almost instantly (15GB each for local/personal storage)
			if [[ -n "$OptionalOauthCredentials" ]]; then
				localJson="$OauthJsonPath"
			else
				localJson="./accounts/8.json"
			fi
			# Check for user cancel on server.
			echo -ne "$(date +'%R:%S-%d/%m/%Y'): Syncing from Local to shared drive first..." >> "$SIMPLELOG"
			source "$CONFIGFILE"
			if [[ "$StopSync" = true ]]; then
				echo 'Sync has been halted!'
				echo 'If this is a mistake please check the config!'
				echo 'Sync has been halted!' >> "$SIMPLELOG"
				echo 'If this is a mistake please check the config!' >> "$SIMPLELOG"
				exit
			fi
			
#################=-
##################=-
####################=-
#############################################################
##############################################################
####                                                     #####
####    Rclone sync: PC/Server => google drive           #####
####    Edit if needed.						             #####
####	                                                 #####
####    DO NOT REMOVE: 								     #####
####    --fast-list                                      #####
####    --drive-stop-on-upload-limit                     #####
####    --drive-services-account-file="$localJson"       #####
####    --driver-server-side-across-configs              #####
####    DO NOT EDIT THE PATH UNLESS YOU KNOW BASH        ##### 
####    EDIT IT IN THE CONFIG INSTEAD!                   #####
####                                                     #####
#### # # # # # # # # # # # # # # # # # # # # # # # # # # #####
####                                                     #####
####    Sync PC/Server to drive & prepare for SA clone   #####
####                                                     #####			
##############################################################
##############################################################			

rclone sync --fast-list --checkers 4 --drive-service-account-file="$localJson" --drive-server-side-across-configs --drive-upload-cutoff 1000T --error-on-no-transfer --max-transfer 500G --drive-chunk-size 256M --stats 2s --transfers 5 --order-by modtime,desc --timeout 30s --retries 1 --low-level-retries 1 --drive-stop-on-download-limit --drive-stop-on-upload-limit --drive-acknowledge-abuse --log-file="$BIGLOG" -vv "$StartingSource$SourcePath" "$MirrorNamePrefix$mirror:$DestinationPath"
			
##############################################################
##############################################################

			exitvar="$?"
			# Check exit variable, if exit variable = 0 then there were new files written.
			# If exit variable = 9 then there were NO NEW FILES, but NO ERRORS as well.
			if [[ "$exitvar" == "0" || "$exitvar" == "9" ]]; then
				syncedMirror="$mirror"
				# Mark one complete so we know local latest image data variable is correct.
				ONECOMPLETE=1
				# So now we check specifically within the successes if the success was a NEW FILE copy...
				# If it was, write a file to LOGDIR to let other drives know to copy.
				if [[ "$exitvar" -eq "0" ]]; then
					date +%s > "$LOGDIR/.lastupdated"
					date +%s > globalcachedupdate
					date +%s > serverupdated
					
					###################################################################################
					## Rclone copy last known update info, DO NOT EDIT, its only uploading ~40 bytes ##
					###################################################################################
					rclone copy --fast-list --checkers 4 --drive-service-account-file="./accounts/$COUNTER.json" --drive-server-side-across-configs --timeout 30s --retries 1 --low-level-retries 1  --drive-acknowledge-abuse --log-file="$BIGLOG" -vv "$LOGDIR/.lastupdated" "MirrorNamePrefix$mirror:/.lastupdated"
				    ###################################################################################
					## Rclone copy last known update info, DO NOT EDIT, its only uploading ~40 bytes ##
				    ###################################################################################
				fi
				# Write to logdir file date and time down to seconds, log digits number that is tied to the time so it cant be duplicated by accident...
				break;
			fi
		fi
	done
fi

# Determine which json was last # used, then go up to the next set of 5 to avoid overlap (and thus waiting for rclone to slowly error out.)
counterfromfile="$(cat ./counter)"
if [ -z "$counterfromfile" ]; then
	COUNTER=1
	echo "$COUNTER" > "./counter"
else
	case $counterfromfile in
	[1-5])
	COUNTER=6
	;;
	[6-9])
	COUNTER=10
	;;
	1[0-4])
	COUNTER=15
	;;
	1[5-9])
	COUNTER=20
	;;
	2[0-4])
	COUNTER=25
	;;
	2[5-9])
	COUNTER=30
	;;
	3[0-4])
	COUNTER=35
	;;
	3[5-9])
	COUNTER=40
	;;
	4[0-4])
	COUNTER=45
	;;
	4[5-9])
	COUNTER=50
	;;
	5[0-4])
	COUNTER=55
	;;
	5[5-9])
	COUNTER=60
	;;
	6[0-4])
	COUNTER=65
	;;
	6[5-9])
	COUNTER=70
	;;
	7[0-4])
	COUNTER=75
	;;
	7[5-9])
	COUNTER=80
	;;
	8[0-4])
	COUNTER=85
	;;
	8[5-9])
	COUNTER=90
	;;
	9[0-4])
	COUNTER=95
	;;
	9[5-9])
	COUNTER=1
	;;
	10[0-9])
	COUNTER=1
	;;
	*)
	esac
fi


#####################################################
#####################################################
#####################################################
#####                                           #####
#####  Serverside SA account sync begins here.  ##### 
#####                                           #####
#####################################################
#####################################################
#####################################################

echo "### Starting syncs from SA #$COUNTER ###" >> "$SIMPLELOG"
# Check local storage for previous date/time sshkey. If there is one store it as a variable.
if [ -f "$LOGDIR/.lastupdated" ]; then
	globalcachedupdate="$(cat "$LOGDIR/.lastupdated")"
else 
    echo "No .lastupdated found, creating now one for referencer point."
	date +%s > "$LOGDIR/.lastupdated"
fi
source "$CONFIGFILE"

# Iterate through user's mirrors.
for mirror in "${MirrorsToGo[@]}"
do
	# If Source Mirror = Destination mirror, skip over, cannot copy to itself.
	if [[ "$syncedMirror" == "$mirror" ]]; then
		continue
	fi
	SKIPNOW=0
	
	# Check to see if user changed config emergency sync stop on, if it is we stop the script safely stop between drives right here.
	source "$CONFIGFILE"
	if [[ "$StopSync" = true ]]; then
		echo 'Sync has been halted!'
		echo 'If this is a mistake please check the config!'
		echo 'Sync has been halted!' >> "$SIMPLELOG"
		echo 'If this is a mistake please check the config!' >> "$SIMPLELOG"
		exit
	fi
	# First check if there has been at least one successful drive copy (new files or not) before making this check.
	# Otherwise it would always think there was no new files.
	# Check if there are updates in comparison to local file.
	if [[ "$ONECOMPLETE" -eq "1" ]]; then
		serverupdated="$(cat $MirrorNamePrefix$mirror:.lastupdated)"
		# Now that we know the script has gone through at least once, we know if there indeed are any new updates to copy!
		# The reason why we still check every drive is new mirrors, maybe previous mirror failures, etc.
		globalcachedupdate="$(cat $LOGDIR/.lastupdated)"
		if [[ "$globalcachedupdate" == "$serverupdated" ]]; then
			echo -e "$(date +'%R:%S-%d/%m/%Y'): Mirror $mirror already updated... skipping!" >> "$SIMPLELOG"
			SKIPNOW=1
		fi
	fi

	# SERVER SIDE SYNC
	if [[ "$SKIPNOW" == "1" ]]; then
		continue
	else
		echo -ne "$(date +'%R:%S-%d/%m/%Y'): Syncing from server to mirror $mirror..." >> "$SIMPLELOG"
		while ((COUNTER < 100)); do
			echo "$COUNTER" > ./counter

#################=-
##################=-
####################=-
#############################################################
##############################################################
####                                                     #####
####    Rclone sync: PC/Server => google drive           #####
####    Edit if needed.						             #####
####	                                                 #####
####    DO NOT REMOVE: 								     #####
####    --fast-list                                      #####
####    --drive-stop-on-upload-limit                     #####
####    --drive-services-account-file="$localJson"       #####
####    --driver-server-side-across-configs              #####
####    DO NOT EDIT THE PATH UNLESS YOU KNOW BASH        ##### 
####    EDIT IT IN THE CONFIG INSTEAD!                   #####
####                                                     #####
#### # # # # # # # # # # # # # # # # # # # # # # # # # # #####
####                                                     #####
####    SA Cloning, cloning from first populated drive   #####
####    to your other remotes and bypassing 750G limit!  #####
####                                                     #####			
##############################################################
##############################################################	
rclone sync --fast-list --checkers 4 --drive-service-account-file="./accounts/$COUNTER.json" --drive-server-side-across-configs --drive-upload-cutoff 1000T --error-on-no-transfer --max-transfer 500G --drive-chunk-size 256M --stats 2s --transfers 5 --order-by modtime,desc --timeout 30s --retries 1 --low-level-retries 1 --drive-stop-on-download-limit --drive-stop-on-upload-limit --drive-acknowledge-abuse --log-file="$BIGLOG" -vv "$MirrorNamePrefix$syncedMirror:" "$MirrorNamePrefix$mirror:"
##############################################################
##############################################################			
			
			exitvar="$?"
			# Check exit variable, if exit variable = 0 then there were new files written.
			# If exit variable = 9 then there were NO NEW FILES, but NO ERRORS as well.
			if [[ "$exitvar" == "0" || "$exitvar" == "9" ]]; then
				# Mark one complete so we know local latest image data variable is correct.
				ONECOMPLETE=1
				# So now we check specifically within the successes if the success was a NEW FILE copy...
				# If it was, write a file to LOGDIR to let other drives know to copy.
				if [[ "$exitvar" -eq "0" ]]; then
					date +%s > "$LOGDIR/.lastupdated"
					date +%s > globalcachedupdate
					date +%s > serverupdated
					####################################################################################
					## Rclone copy last known update info, DO NOT EDIT, its only uploading ~40 bytes. ##
					####################################################################################
					rclone copy --fast-list --checkers 4 --drive-service-account-file="./accounts/$COUNTER.json" --drive-server-side-across-configs --timeout 30s --retries 1 --low-level-retries 1  --drive-acknowledge-abuse --log-file="$BIGLOG" -vv "$LOGDIR/.lastupdated" "$MirrorNamePrefix$mirror:.lastupdated"
				    ####################################################################################
					## Rclone copy last known update info, DO NOT EDIT, its only uploading ~40 bytes. ##
 					####################################################################################
				fi
				# Write to logdir file date and time down to seconds, log digits number that is tied to the time so it cant be duplicated by accident...
				break
			else
				((COUNTER++))
				if ((COUNTER > 100)); then
					COUNTER=1
				fi
			fi
		done
	fi
done
echo "$COUNTER" > /home/becky/counter

echo "$(date +'%R:%S-%d/%m/%Y'): All done!" >> "$SIMPLELOG"
