#!/bin/bash
echo "Warning do NOT run this on your server if it is not on your local network. Unless you can  run it in a GUI on your server!"
echo "WARNING 2: THIS WILL DELETE ALL SA's CURRENTLY ON YOUR APP SINCE ITS NOT POSSIBLE TO ADD MORE THAN 100 VIA CSV!!"
echo "IF YOU HAVE OVER 100 SAs already that you plan to keep, exit now!"
rm -rf ./SetupLOG.txt >./dev/null 2>&1
touch ./SetupLOG.txt
chmod -R a+x ./*.sh
chmod -R a+x ./*.py
rm -rf ./backup >./SetupLOG.txt 2>&1
mkdir ./backup  >./SetupLOG.txt 2>&1
# REMOVE POTENTIALLY CONFLICTING FILES FROM PREVIOUS RUNS!
cp -a ./* ./backup/   >./SetupLOG.txt 2>&1
rm -rf ./emails.txt >./SetupLOG.txt 2>&1
rm -rf ./*.csv >./SetupLOG.txt 2>&1
rm -rf ./credentials/*.json  >./SetupLOG.txt 2>&1
rm -rf ./credentials/*.pickle  >./SetupLOG.txt 2>&1
rm -rf ./*.pickle  >./SetupLOG.txt 2>&1
#Install Properties-updates, I believe this was a key piece I missed last time.
echo "Installing all python prereqs, enter your password if it asks..."
sudo apt install software-properties-common -y >./SetupLOG.txt 2>&1
sudo apt update && upgrade -y >./SetupLOG.txt 2>&1
sudo apt install python3 python3-pip -y >./SetupLOG.txt 2>&1
apt install jq -y >./SetupLOG.txt 2>&1
mv ./client*.json ./credentials.json >./SetupLOG.txt 2>&1
ls ./credentials.json >./SetupLOG.txt 2>&1
if [[ "$?" != "0" ]]; then
echo -e "\n\ncredentials.json file not found! This file is required for your SA, which can be created as described at the following link @ step 3, part 1"
echo -e "https://github.com/xyou365/AutoRclone and saved as credentials.json in this folder.\n\nPlease fix this and try again!\n\n"
sleep 5
exit 0
fi
pip3 install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib

pip3 install -r requirements.txt 
clear
python3 ./gen_sa_accounts.py
projects="$(python3 ./gen_sa_accounts.py --list-projects | grep Projects | sed 's/.*(//g' | sed 's/).*//g')"
if [[ "$projects" == "1" ]]; then
	projectid="$(python3 ./gen_sa_accounts.py --list-projects | grep -v "Projects" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
elif [[ "$projects" == "0" ]]; then
	echo "No projects found... please follow the readme instructions again..."
	sleep 5
	exit 0
else
	echo "More than one project found, listing the projects below, please copy and paste in the name of the one you want to generate these accounts for!"
	python3 ./gen_sa_accounts.py --list-projects
	read projectid
fi
clear
python3 ./gen_sa_accounts.py --enable-services "$projectid"
python3 ./gen_sa_accounts.py --create-sas "$projectid"
python3 ./gen_sa_accounts.py --download-keys "$projectid"
python3 ./rename_script.py

JSO=`ls ./accounts/*.json` >./SetupLOG.txt 2>&1
rm -rf ./emails.txt  >./SetupLOG.txt 2>&1
while read  -r line
do
        jq .client_email "$line" | sed 's/^"//' | sed 's/"$//' >> emails.txt
done <<< "$JSO"

cp -a ./accounts/0.json ./accounts/100.json >./SetupLOG.txt 2>&1
cp -a ./token.pickle ./credentials/token.pickle >./SetupLOG.txt 2>&1
echo "Please enter your head SA account's email (e.g. sa@yourdomain.com)"
read saemail
echo "Now enter your Google Admin account email so we can add it as owner."
read ggowner
ggname="$(echo $ggowner | sed 's/@.*//g' )"
rm -rf ./_NewMembers.csv 2>./SetupLOG.txt
touch ./_NewMembers.csv
JSONEMAILS="$(cat ./emails.txt)"
echo "Group Email [Required],Member Email,Member Name,Member Role,Member Type" > ./_NewMembers.csv
echo "$saemail,$ggowner,$ggname,OWNER,USER" >> ./_NewMembers.csv
while read -r "line"
do
	echo "$saemail,$line,Member,MEMBER,SERVICE_ACCOUNT" >> ./_NewMembers.csv
done <<< "$JSONEMAILS"
