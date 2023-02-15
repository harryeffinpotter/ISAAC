import os
import json

# Replace 'directory_path' with the path to the directory you want to iterate over
directory_path = './accounts'
print("\n\nPlease enter the email address for your service accounts google group.\nIf you have not created one yet you can create it here https://admin.google.com/u/1/ac/groups \nBe sure to add your admin google account email as a member of this group with Owner permissions.\n\n")
text = input("Please enter the SA group's email now:\n")
# Iterate over all files in the directory
with open(".\_NewGroupUsers.csv", "a") as a: 
    a.write("Group Email [Required],Member Email,Member Name,Member Role,Member Type\n")
    for filename in os.listdir(directory_path):
        # Get the full path of the file
        filepath = os.path.join(directory_path, filename)
        # Check if the file is a regular file (not a directory or a symlink)
        if filepath.endswith(".json"):
            # Do something with the file
            with open(filepath, 'r') as f:
                data = json.load(f)
                a.write(f"{text},{data['client_email']},Member,MEMBER,SERVICE_ACCOUNT\n")
   