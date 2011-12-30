#!/bin/sh

#  iBuddyCmdtUtility
#  iBuddy
#
#  Created by David Wilson on 2/10/11.
#  Copyright 2011 David G. Wilson. All rights reserved.

usage()
	{
	echo "Usage: $0 {-install <cmd source filename>|-remove}"
	}

echo "iBuddyCmdUtility"
echo "  all actions performed on /usr/local/bin/iBuddycmd"
echo "  input> " $0 $1 $2

export PATH=$PATH:/sbin:/usr/bin:/usr/sbin:/bin


case "$1" in

-install)

echo "iBuddycmd Install - start"
echo "installing iBuddycmd from the following location >" $2 "<"

# test for presence of /usr/local/bin - create if not there

if [ ! -d "/usr/local/bin" ]; then
	if [ ! -d "/usr/local" ]; then
		mkdir "/usr/local"
		chown root:wheel "/usr/local"
	fi
	mkdir "/usr/local/bin"
	chown root:wheel "/usr/local/bin"
	echo "iBuddycmd"
	echo "iBuddycmd - edit your .profile to add - PATH=/usr/local/bin:$PATH"
	echo "iBuddycmd - edit your .profile to add - export PATH"
	echo "iBuddycmd"
	PATH=/usr/local/bin:$PATH
	export PATH
fi

ditto -V "$2" /usr/local/bin/iBuddycmd

echo "iBuddycmd Install - complete"
;;

-remove)

echo "iBuddycmd Remove - start"

rm -R /usr/local/bin/iBuddycmd


echo "iBuddycmd remove - complete"
;;

*)
	usage
;;
esac
