#!/bin/bash
mkdir ./backup  2>/dev/null
cp -a ./* ./backup/   2>/dev/null
rm -rf ./credentials/*.json  2>/dev/null
rm -rf ./credentials/*.pickle  2>/dev/null
rm -rf ./*.pickle  2>/dev/null
echo "Python 3.10 or better required."
echo "Credentials file required for your SA, which  created as described here at step 3, part 1"
echo "https://github.com/xyou365/AutoRclone and saved as credentials.json in this folder."
sleep 5
pip3 install -r requirements.txt 
python3 ./gen_sa_accounts.py
projectid="$(python3 ./gen_sa_accounts.py --list-projects | grep -v "Projects" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
python3 ./gen_sa_accounts.py --enable-services "$projectid"
python3 ./gen_sa_accounts.py --create-sas "$projectid"
python3 ./gen_sa_accounts.py --download-keys "$projectid"
python3 ./rename_script.py

JSO=`ls ./accounts/*.json`
rm -rf ./emails.txt  2>/dev/null
while read  -r line
do
        jq .client_email "$line" | sed 's/^"//' | sed 's/"$//' >> emails.txt
done <<< "$JSO"

cp -a ./accounts/0.json ./accounts/100.json
cp -a ./token.pickle ./credentials/token.pickle
echo "Please enter your head SA account's email (e.g. sa@yourdomain.com)"
read saemail
echo "Now enter the Owner account of your Google Group."
read ggowner
ggname="$(echo $ggowner | sed 's/@.*//g' )"
rm -rf ./_NewMembers.csv 2>/dev/null
touch ./_NewMembers.csv
JSONEMAILS="$(cat ./emails.txt)"
echo "Group Email [Required],Member Email,Member Name,Member Role,Member Type" > ./_NewMembers.csv
echo "$saemail,$ggowner,$ggname,OWNER,USER" >> ./_NewMembers.csv
while read -r "line"
do
	echo "$saemail,$line,Member,MEMBER,SERVICE_ACCOUNT" >> ./_NewMembers.csv
done <<< "$JSONEMAILS"
