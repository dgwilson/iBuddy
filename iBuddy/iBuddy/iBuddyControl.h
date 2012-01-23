//
//  iBuddyControl.h
//  iBuddy
//
//  Created by David G. Wilson on 05/09/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>

#include <unistd.h>

//================================================================================================
//   Globals
//================================================================================================
//

@interface iBuddyControl : NSObject 
{
	
	Boolean				iBuddyConnected;
	NSTimer			  * timer;
	UInt8				reqBuffer[8];
	
	BOOL	flapWings;
	BOOL	beatHeart;
	NSTimer * flapWingsTimer;
	NSTimer * beatHeartTimer;
	NSTimer * cancelTimer;
	NSTimer * rotateTimer;
	
	bool bodyBool;
	NSMatrix * bodyMatrix;

	// flap wings	-a f10 (flap for 10 seconds)
	// beat heart	-a b10 (beat for 10 seconds)
	// heart on		-a h1
	// heart off	-a h0
	// body light
	// head light colour

	enum iBuddyCommandCodes {
		iBuddy_Stop = 0,
		iBuddy_Heart_On = 1,
		iBuddy_Heart_Off = 2,
		iBuddy_Heart_Beat = 3,
		iBuddy_Flap = 4,
		iBuddy_Flap_Long = 5,
		iBuddy_Head_Light_Off = 6,
		iBuddy_Head_Light_Red = 7,
		iBuddy_Head_Light_Green = 8,
		iBuddy_Head_Light_Blue = 9,
		iBuddy_Head_Light_Cyan = 10,
		iBuddy_Head_Light_Magenta = 11,
		iBuddy_Head_Light_Yellow = 12,
		iBuddy_Head_Light_White = 13,
		iBuddy_Move_Left = 14,
		iBuddy_Move_Right = 15,
		iBuddy_Move_Rotate = 16,
	} iBuddyCommandCodes ;
	
}

- (id)init; 

void DeviceAdded(void *refCon, io_iterator_t iterator);
IOReturn FindInterfaces(IOUSBDeviceInterface **device);
void DeviceNotification( void *refCon,
						 io_service_t service,
						 natural_t messageType,
						 void *messageArgument );
void EvaluateUSBErrorCode(IOUSBDeviceInterface **deviceInterface_param, IOUSBInterfaceInterface **missileInterface_param, IOReturn kr);
void printInterpretedError(char *s, IOReturn err);


- (BOOL)confirmDeviceConnected;
- (id)sendCommandsToDevice:(UInt8)controlBits;

- (id)ReleaseiBuddy;
- (id)controliBuddy:(NSNumber*)code;

- (void)flapWingsCommand:(NSTimer *)timer;


@end
