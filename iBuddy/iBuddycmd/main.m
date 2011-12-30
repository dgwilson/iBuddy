//
//  main.m
//  iBuddycmd
//
//  Created by David Wilson on 18/09/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iBuddyControl.h"

bool driverKextIsPresent ()
{
	BOOL b_kext_Present;
	
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:@"/System/Library/Extensions/iBuddy_Driver.kext"])
	{
		b_kext_Present = true;
		NSLog(@"Found - /System/Library/Extensions/iBuddy_Driver.kext");
	} else {
		b_kext_Present = false;
		NSLog(@"WARNING: Critical Support file not found - /System/Library/Extensions/iBuddy_Driver.kext");
	}
	
	if (!b_kext_Present)
	{
		NSLog(@"WARNING: Critical Support file not found : Device will not function without kext present");
		printf("WARNING: Critical Support file not found : Device will not function without kext present\n");
		printf("Run GUI application, select 'Install OS Driver' from the iBuddy menu\n");
	}

	return b_kext_Present;
}

int main (int argc, const char * argv[])
{

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	
	if (!driverKextIsPresent)
	{
		printf("WARNING: Critical Support file not found : Device will not function without kext present\n");
		printf("Run GUI application, select 'Install OS Driver' from the iBuddy menu\n");
		printf("commandline arguements will not be processed");
	} 
	else
	{
		
		NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
		
//		NSLog(@"boolArg   = %d", [args boolForKey:@"boolArg"]);
//		NSLog(@"intArg    = %ld", [args integerForKey:@"intArg"]);
//		NSLog(@"floatArg  = %f", [args floatForKey:@"floatArg"]);
//		NSLog(@"stringArg = %@", [args stringForKey:@"stringArg"]);
		
		// Arguements
		// iBuddy device specific
		
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
			

		NSString * help = [args stringForKey:@"h"];
		if (help != nil) {
			NSLog(@"yea... not sure what to do about help!");
		}
		
	//	NSString * kext = [args stringForKey:@"kext"];
	//	if (kext != nil) {
	//		if ([kext isEqualToString:@"install"]) {

//		enum iBuddyCommandCodes {
//			iBuddy_Stop = 0,
//			iBuddy_Heart_On = 1,
//			iBuddy_Heart_Off = 2,
//			iBuddy_Heart_Beat = 3,
//			iBuddy_Flap = 4,
//			iBuddy_Flap_Long =5,
//			iBuddy_Head_Light_Off = 6,
//			iBuddy_Head_Light_Red = 7,
//			iBuddy_Head_Light_Green = 8,
//			iBuddy_Head_Light_Blue = 9,
//			iBuddy_Head_Light_Cyan = 10,
//			iBuddy_Head_Light_Magenta = 11,
//			iBuddy_Head_Light_Yellow = 12,
//			iBuddy_Head_Light_White = 13,
//

//		} iBuddyCommandCodes ;


		NSString * command = [args stringForKey:@"a"];
		if (command != nil) 
		{
			iBuddyControl * iBuddyController = [[iBuddyControl alloc] init];
			if (iBuddyController)
			{
				if ([command isEqualToString:@"h1"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Heart_On]];
				}
				if ([command isEqualToString:@"f"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Flap]];
				}
				if ([command isEqualToString:@"f10"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Flap_Long]];
				}
				if ([command isEqualToString:@"b10"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Heart_Beat]];
				}
				if ([command isEqualToString:@"hlo"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Head_Light_Off]];
				}
				if ([command isEqualToString:@"hlr"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Head_Light_Red]];
				}
				if ([command isEqualToString:@"hlg"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Head_Light_Green]];
				}
				if ([command isEqualToString:@"hlb"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Head_Light_Blue]];
				}
				if ([command isEqualToString:@"hlc"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Head_Light_Cyan]];
				}
				if ([command isEqualToString:@"hlm"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Head_Light_Magenta]];
				}
				if ([command isEqualToString:@"hlw"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Head_Light_White]];
				}
				if ([command isEqualToString:@"bml"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Move_Left]];
				}
				if ([command isEqualToString:@"bmr"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Move_Right]];
				}
				if ([command isEqualToString:@"bmo"]) {
					[iBuddyController controliBuddy:[NSNumber numberWithInt:iBuddy_Move_Rotate]];
				}
				
				
			} 
			else 
			{
				NSLog(@"iBuddyController did not initialise - please check log");
			}
		}

	}
	
	[pool drain];
    return 0;
}

