

https://devforums.apple.com/message/477239 <original>

https://devforums.apple.com/message/544612

I want to pick up on the original topic contained within this thread. A couple of weeks back ths thread was one of my start points along with WWDC 2010 Session 210.

I'm trying to build into my application a call to "priviledged helper". It's purpose will be to install a kext and/or uninstall the same kext. I wish to implement it this way so that the application can be simply installed by drag and drop. I have watched the WWDC video (session 210) and have successfully implemented the components necessary to install the helper in /Library/LaunchDaemons/<my domain / App>.plist and /Library/PriviledgedHelperTools/<my domain / App>. ... SMJobBless.

My challenge has been in trying to get the helper program to start.

Currently the client and helper program are based on the ssd example. The helper program is appearing in Activity monitor... after I trigger the call to it from my main app. I guess the helper has loaded, but it has not started. The first line of code in the helper is a printf and never appears in the system.log. If I quit (or force quit) the main app, then within 60 seconds or so the helper program runs... printf's and all before it quits as it is supposed to.

I see "man launchctl" says under the load command "All specified jobs will be loaded before any of them are allowed to start.". 
Is this what is happending to me? What does it mean?

So why doesn't my helper program actually start?

OS = 10.7.2, xcode = 4.1
Application is not sandboxed

- David

Oct  8 16:43:27 David-Wilsons-MBP SecurityAgent[442]: com.apple.ServiceManagement.blesshelper|2011-10-08 16:43:27 +1300
Oct  8 16:43:31 David-Wilsons-MBP /usr/libexec/launchdadd[445]: FAILURE: Could not submit job to launchd.
Oct  8 16:43:31 David-Wilsons-MBP /usr/libexec/launchdadd[445]: FAILURE: Job com.davidgwilson.iBuddyHelper could not be installed from /Users/dgwilson/Library/Developer/Xcode/DerivedData/iBuddy-abgsubxvhxbdyrdreaaeviycnqen/Build/Products/Debug/iBuddy.app/Contents/Library/LaunchServices/com.davidgwilson.iBuddyHelper, reason 2.
Oct  8 16:43:31 David-Wilsons-MBP iBuddy[434]: Something went wrong with installation of Privileged Helper installation!
	

/usr/local/bin/iBuddycmd


/Library/LaunchDaemons/com.davidgwilson.iBuddyHelper.plist
/Library/PriviledgedHelperTools/com.davidgwilson.iBuddyHelper

Command line options

From the terminal or other shell program...

iBuddycmd -a f10

and see below for other commands that can be used.

		// flap wings   -a f
		// flap wings	-a f10 (flap for 10 seconds)
		// beat heart	-a b10 (beat for 10 seconds)
		// heart on		-a h1
		// heart off	-a h0
		// body light
		// head light Off		-a hlo
		// head light Red		-a hlr
		// head light Green		-a hlg
		// head light Blue		-a hlb 
		// head light Cyan		-a hlc
		// head light Magenta	-a hlm
		// head light White		-a hlw
		// body move left		-a bml
		// body move right		-a bmr
		// body move rotate		-a bmo

 
