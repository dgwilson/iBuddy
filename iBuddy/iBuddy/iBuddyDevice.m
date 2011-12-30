//
//  iBuddyDevice.m
//  iBUddy
//
//  Created by David Wilson on 05/09/2011.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import "iBuddyDevice.h"


@implementation iBuddyDevice

- (id)init;
{
	[super init];
	deviceName = NULL;
	return self;
}

- (void)dealloc 
{
	[launcherType release];
	[super dealloc];
}

- (id)initWithNotify:(io_object_t)newNotification device:(IOUSBDeviceInterface **)newDeviceInterface name:(CFStringRef)newDeviceName location:(UInt32)newLocationID;
{
	[super init];
	[self setNotification:newNotification];
	[self setDeviceInterface:newDeviceInterface];
	[self setIBuddyInterface:nil];
	[self setDeviceName:newDeviceName];
	[self setLocationID:newLocationID];
	[self setusbVendorID:0];
	[self setusbProductID:0];
	[self setInterfaceNumEndpoints:0];
	[self setLauncherType:nil];
	
	return self;
}

- (io_object_t)notification;
{
	return notification;
}
- (IOUSBDeviceInterface **)deviceInterface;
{
	return deviceInterface;
}
- (IOUSBInterfaceInterface **)iBuddyInterface;
{
	return iBuddyInterface;
}
- (CFStringRef)deviceName;
{
	return deviceName;
}
- (UInt32)locationID;
{
	return locationID;
}
- (UInt8)interfaceNumEndpoints;
{
	return interfaceNumEndpoints;
}
- (SInt32)getusbVendorID;
{
	return usbVendorID;
}
- (SInt32)getusbProductID;
{
	return usbProductID;
}
- (NSString *)getLauncherType;
{
	return launcherType;
}

- (void)setNotification:(io_object_t)newNotification;
{
	notification = newNotification;
}
- (void)setDeviceInterface:(IOUSBDeviceInterface **)newDeviceInterface;
{
	deviceInterface = newDeviceInterface;
}
- (void)setIBuddyInterface:(IOUSBInterfaceInterface **)newMissileInterface;
{
	iBuddyInterface = newMissileInterface;
}
- (void)setDeviceName:(CFStringRef)newDeviceName;
{
	deviceName = newDeviceName;
}
- (void)setLocationID:(UInt32)newLocationID;
{
	locationID = newLocationID;
}

- (void)setusbVendorID:(SInt32)newusbVendorID;
{
	usbVendorID = newusbVendorID;
}
- (void)setusbProductID:(SInt32)newusbProductID;
{
	usbProductID = newusbProductID;
}
- (void)setInterfaceNumEndpoints:(UInt8)newInterfaceNumEndpoints;
{
	interfaceNumEndpoints = newInterfaceNumEndpoints;
}
- (void)setLauncherType:(NSString *)newLauncherType;
{
	[newLauncherType retain];
	[launcherType release];
	launcherType = newLauncherType;
}
@end
