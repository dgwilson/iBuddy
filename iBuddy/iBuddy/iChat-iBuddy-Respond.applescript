(*

File: iChat-iBuddy-Respond.applescript

Abstract: This script will call the iBuddy commandline program for text chats, audio chats, video chats, and file transfers when set as the event handler script for those events.
	
Version: 1.0


*)

using terms from application "iChat"
	
	on received text invitation theText from theBuddy for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlr"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end received text invitation
	
	on received audio invitation theText from theBuddy for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlr"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end received audio invitation
	
	on received video invitation theText from theBuddy for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlr"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end received video invitation
	
	on received remote screen sharing invitation from theBuddy for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlr"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end received remote screen sharing invitation
	
	on received local screen sharing invitation from theBuddy for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlr"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end received local screen sharing invitation
	
	on received file transfer invitation theFileTransfer
		do shell script "/usr/local/bin/iBuddycmd -a hlr"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end received file transfer invitation
	
	on buddy authorization requested theRequest
		do shell script "/usr/local/bin/iBuddycmd -a hlr"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end buddy authorization requested
	
	on message sent theMessage for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlo"
		do shell script "/usr/local/bin/iBuddycmd -a bmr"
	end message sent
	
	on message received theMessage from theBuddy for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlb"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end message received
	
	on chat room message received theMessage from theBuddy for theChat
		do shell script "/usr/local/bin/iBuddycmd -a hlb"
		do shell script "/usr/local/bin/iBuddycmd -a f10"
	end chat room message received
	
end using terms from
