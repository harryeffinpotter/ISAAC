#!/bin/bash

# SA mirrors that you wish to use the SAs to clone from and to.
# It will always go IN ORDER FROM LEFT TO RIGHT. So ExampleFirstDrive will copy to the rest.
MirrorNames=( "01" "02" "03" "04" )

# What you named your rcflone drives prior to the number.
# This would look like: Group_Name-01, Group_Name-02, etc. in the config.
MirrorNamePrefix="Group_Name-"

# The following 2 settings are only configured for server to first mirror copying right now, once the mirror to mirror syncing takes over
# it just does an entire mirror copy instead of specific folders at once. This seems to be the most common use case but you can always
# add the Source and Dest paths as you wish to the rclone sync command in the server sync sectrion.
SourcePath="Downloads"
DestinationPath="/usr/LinuxServer/Downloads"


# DEPENDS ON StartingSource having a local folder path.
# Set this to 1 to enable copying from your computer/vps to a team drive FIRST, then copying from that team drive to the rest.
# NOTE 2: If you're doing a local->Remote sync it is HIGHLY RECOMMENDED you make a create a Oauth2 json for this instead of a Service Account.
# SA's are limited to 15GB each when they are dealing with Personal drive data.
StartFromLocal=0

# DEPENDS ON StartFromLocal=1 to be enabled.
# StartFromLocal=1 dependso n this.
# Set this to a local path that you wish to start the syncing from.
# Workflow will be like /usr/folder > drive-1, drive-1 > drive-2, and so on.
StartingSource=""

# Optional (RECOMMENDED FOR PC/SERVER TO DRIVE, REQUIRES STARTFROM LOCAL TO BE SET TO 1)
# E.G. if you saved the key and named it MyPersonalAccount.json and put it in the accounts folder:
# "./accounts/MyPersonalAccount.json"
# THIS WILL NOT ITERATE THROUGH THE JSONS AS YOU WOULD ONLY BE ABLE TO COPY 15GB EACH AND BURN THROUGH THEM ALL
# IF WHAT YOURE TRANSFERRING IS UNDER 15GB THEN FEEL FREE TO LEAVE IT BUT OTHERWISE GET AN OAUTH KEY IT TAKES SECONDS!
OauthJsonPath="./accounts/MYCUSTOMOAUTH.json" 

# Set to true to stop syncing.
StopSync=false
