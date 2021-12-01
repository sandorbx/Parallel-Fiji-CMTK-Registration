## Installation instructions

### Linux(Ubuntu/Debian),

- Open the Terminal. Update the system and install CMTK from the repository, with the following commands:

	sudo apt update
	sudo apt upgrade -y
	sudo apt install cmtk -y

- If you don't have it already install Fiji from : https://fiji.sc

- Place the  Paralell_Fiji_CMTK_Registration***.ijm file in your fiji.app/plugins/macros library and you can start it from the plugins>macros menu un Fiji
or just drag and drop the script file to the fiji window and its ready to use.

### Mac

- Install CMTK, download the dmg release file from https://www.nitrc.org/frs/download.php/8217/CMTK-3.3.1-MacOSX-10.6-x86_64.dmg, double click it in finder then go to 		  your system settings>security to authorize the install

- If you don't have it already install Fiji from : https://fiji.sc

- Place the  Paralell_Fiji_CMTK_Registration***.ijm file in your fiji.app/plugins/macros library and you can start it from the plugins>macros menu un Fiji
 or just drag and drop the script file to the fiji window and its ready to use.

### Windows 10/11

- Make sure your windows 10/11 has the latest updates

- Start powershell as admin and type the following command: wsl --install

- Now you can use windows subsystem for linux by running the ubuntu terminal app, just type ubuntu in the search bar to find it, set up your username and password then 
run in the terminal :

sudo apt update
sudo apt upgrade -y
sudo apt install cmtk -y
		
- You can close the terminal and use the windows version of Fiji

-If you don't have it already install Fiji from : https://fiji.sc

-Place the Paralell_Fiji_CMTK_Registration***.ijm file in your fiji.app/plugins/macros library and you can start it from the plugins>macros menu un Fiji 
or just drag and drop the script file to the fiji window and its ready to use.

## User guide

- Very important to use the following naming convention with your image files, otherwise the script will not work : 
 images has to be named by adding a number indicating the channel in the end of the filename separated by an underscore (yourpicturename_01; yourpicturename_02 
 and so on. _01 indicates the registration channel, images belonging to the same scan must have identical names only differentiated by the channel number.

- The script has an automatic batch mode, you can register a whole database with one run, the "images to register" directory serves as a starting point from where the 
whole directory tree would be scanned recursively for images and processed.You can have several scans in one folder, in subdirectories and so on, as long as they named
appropriately they would be processed.

- You can set the number of paralell jobs in batch mode, watch out for memory consumption.

- If you check the show results box you can instantly open reformatted images in Fiji from a pop-up list.

- For detailed information on parameters and operations please visit the flybrain wiki :  http://flybrain.mrc-lmb.cam.ac.uk/dokuwiki/doku.php?id=warping_manual:start


### Special thanks to :
Kei Ito, Gregory Jefferis, Hideo Otsuna and Takashi Kawase 
