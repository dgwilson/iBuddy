#!/bin/sh

#  iBuddyKextUtility
#  iBuddy
#
#  Created by David Wilson on 2/10/11.
#  Copyright 2011 David G. Wilson. All rights reserved.

usage()
	{
	echo "Usage: $0 {-install <kext source filename>|-remove}"
	}

echo "iBuddyKextUtility"
echo "  all actions performed on /System/Library/Extensions/iBuddy_Driver.kext"
echo "  input> " $0

export PATH=$PATH:/sbin:/usr/bin:/usr/sbin:/bin


case "$1" in

-install)

echo "iBuddy Kext Install - start"
echo "installing kext from the following location >" $2 "<"

kextunload /System/Library/Extensions/iBuddy_Driver.kext
ditto -V "$2" /System/Library/Extensions/iBuddy_Driver.kext
chown -R root:wheel /System/Library/Extensions/iBuddy_Driver.kext/
chmod -R 755 /System/Library/Extensions/iBuddy_Driver.kext/
kextload /System/Library/Extensions/iBuddy_Driver.kext/

echo "iBuddy Kext Install - complete"
;;

-remove)

echo "iBuddy Kext Remove - start"

kextunload /System/Library/Extensions/iBuddy_Driver.kext
rm -R /System/Library/Extensions/iBuddy_Driver.kext


echo "iBuddy Kext remove - complete"
;;

*)
	usage
;;
esac
