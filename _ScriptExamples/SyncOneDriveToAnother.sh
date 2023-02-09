#!/bin/bash -x
DESTINATION="Team-Drive-2:"
SOURCE="Team-Drive-1:"
COUNTER="$(cat ~/counter)"
((COUNTER++))
while ((COUNTER < 99)); 
do
	echo "$COUNTER" > ~/counter
	rclone sync --fast-list --checkers 10 --drive-service-account-file=~/AutoRclone/accounts/$COUNTER.json --drive-server-side-across-configs --error-on-no-transfer --max-transfer 700G --drive-chunk-size 256M --stats 2s --transfers 15 --timeout 30s --retries 1 --low-level-retries 1 --drive-stop-on-download-limit --drive-stop-on-upload-limit --drive-acknowledge-abuse --log-file="/root/syncProgress.log" -v "$SOURCE" "$DESTINATION"
	exitvar="$?"
	if [[ "$exitvar" == "0" || "$exitvar" == "9" ]]; then
		break
	else
		echo "$COUNTER" > ~/counter
		((COUNTER++))
	fi
done
