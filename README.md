# ISAAC
## Instant Service Account Adder &amp; Configurator
### Updated main setup script to automatically rename client_* json in directory to credentials json, and also it will now ask you to enter a specific app if you have more than one!

Service Accounts are useful for those of us who wish to copy large amounts of data among/between Google Team/Shared drives. They will bypass the 750GB a day upload limit that is imposed upon all Google Drive accounts. Once this script is completed you can use any simple bash script along with the most recent version of the official RCLONE client to preform your drive to drive operations. Since you can utilize server to server transfers you will see very fast transfer speeds (I have seen over 5 GB/s so far!).

If you are trying to copy from a Shared/Team drive to a personal drive or vice versa this is not a good solution due to the fact that these service accounts can only carry up to 15GB of data each. However, when copying among Shared/Team drives since the storage never has to go to the SA's personal storage this will allow you to copy/transfer up to 75TB a day!

<b>The linux script works with WSL as well as any Linux distro, both scripts require at least v3.10 of Python already installed, configured, and added to path(if on windows the python installer has an advanced option to add to path, be sure to select it). </b>

1. Create a google group of which you are the OWNER.
2. Create an app in the Google Cloud Console at this link - https://console.cloud.google.com/
3. Once you have created an app and have it selected click the hamburger menu in the top left and select Oauth Consent Screen under the APIS and Services item in the left menu -

![image](https://user-images.githubusercontent.com/73411256/217771975-1256a77d-0e4e-4102-9912-3f07455aa9d2.png)

4. Set the app to EXTERNAL, enter your email in the required fields and click next. 
5. DO NOT CONFIGURE ANY SCOPES, instead just keep clicking next til you are finished. Once you have done this you will see a button that says PUBLISH YOUR APP in the Oauth Consent Screen section, click it to publish your app.
6. Enable each of the APIs in this image for your app - 

![image](https://user-images.githubusercontent.com/73411256/217772800-2557cf53-7842-4833-bc30-82fe49af037f.png)

7. Clone this repository in your terminal (git is obviously required and must be added to path)

8. `cd` into the cloned repo directory and run the following command, ensuring that the last browser window you have clicked on is the same window where you configured your cloud console app:

*WSL/Linux:* `"./_Linux Setup.sh"`
(If you're running the script for the first time run this command first beforehand: `chmod a+x ./_Linux Setup.sh`)

*CMD:* `".\Windows Setup.bat"`

9. Follow the on screen prompts.

10. In your Google admin panel go to groups and select bulk add and upload the csv file automatically created by the script.

That's it! You'll now have a folder with 100 jsons for each SA account that can be immediately utilized by rclone. Check out the `_ScriptExamples` directory for a script that utilizes all 100 service accounts with rclone and more. 

