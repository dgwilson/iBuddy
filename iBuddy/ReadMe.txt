iBuddy for Mac

by David G. Wilson
http://dgwilson.wordpress.com
http://homepages.paradise.net.nz/dgwilson/

31 December 2011

iBuddy is a small USB figure in the form of an MSN messenger contact with butterfly wings. Its head can light up in 7 different colors, its heart can light up the wings can flap and its torso can twist, all the while drawing its power from the USB port.

About the Mac Project and it's components:
The iBuddy hardware device reports to be a Human Interface Device (HID) however it does not dunction correctly as a HID device connectign and disconnecting repeatedly. The mac project makes use of a codeless kext to be installed in the operating sysystem so that the operating system will ignore the device from a HID point of view. With the codeless kext installed the GUI application is able to communicate with the iBuddy to make it operate. This project also has a command line component so that the iBuddy can be operated from the command line.


iBuddy GUI
- This application is used to install the OS Driver (kext) and install the command line tool. It can also be used to make the iBuddy function, after the OS Driver is installed.


iBuddyHelper
- This application is known as a "priviledged helper". It handles the installation, or removal, of the kext behind the scenes.
- If for any reason the priviledged helper needs to be removed, then delete the following files:
		/Library/LaunchDaemons/com.davidgwilson.iBuddyHelper.plist
		/Library/PriviledgedHelperTools/com.davidgwilson.iBuddyHelper


iBuddyDriver
- This is the codeless kext that tells the OS to "leave the device alone". It's codeless, i.e. no code, unlike say a printer driver that contains actual code to send your file to the printer. This driver is also set up such that it works on 32bit and 64bit operating systems and hardware. In this case the kext has been tested on Snow Leopard 32 and 64 bit and Lion 64 bit.


iBuddyCmd
- The commandline tool is installed into /usr/local/bin as iBuddycmd. You can use this program in your batch command files or in any other way you can imagine.
- The commandline options below are the ones that have been coded... more can be added to the code for much fancier results

From terminal you can 
/usr/local/bin/iBuddycmd -a f10

and see below for other commands that can be used.

		 flap wings			-a f
		 flap wings			-a f10 (flap for 10 seconds)
		 beat heart			-a b10 (beat for 10 seconds)
		 heart on			-a h1
		 heart off			-a h0
		 body light
		 head light Off		-a hlo
		 head light Red		-a hlr
		 head light Green	-a hlg
		 head light Blue	-a hlb 
		 head light Cyan	-a hlc
		 head light Magenta	-a hlm
		 head light White	-a hlw
		 body move left		-a bml
		 body move right	-a bmr
		 body move rotate	-a bmo
 
 
Development note
- This project is set up such that compiling iBuddy will compile all of its dependant components as they are included in the GUI application. The only component that needs to be distributed form the build is the GUI application.


Known Issues
- Help is not currently functioning for iBuddycmd

