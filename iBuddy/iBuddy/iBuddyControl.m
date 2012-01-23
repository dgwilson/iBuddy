//
//  iBuddyControl.m
//  iBuddy
//
//  Created by David G. Wilson on 05/09/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//


#import "iBuddyControl.h"
#import "iBUddyDevice.h"
#include <mach/mach.h>

//================================================================================================
//   Globals
//================================================================================================
//
static IONotificationPortRef	gNotifyPort;
static io_iterator_t			gAddedRocketIter;
static CFRunLoopRef				gRunLoop;

int						deviceCount;
NSMutableArray			*iBuddyDeviceArray;


#define iBuddyMaxPacketSize	8


@implementation iBuddyControl


- (id)init 
{
	//	NSLog(@"%@", NSStringFromSelector(_cmd));
	
	reqBuffer[0] = 0x55;
	reqBuffer[1] = 0x53;	
	reqBuffer[2] = 0x42; 
	reqBuffer[3] = 0x43;
	reqBuffer[4] = 0x00;
	reqBuffer[5] = 0x40;
	reqBuffer[6] = 0x02;
	reqBuffer[7] = 0xFF;

	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	[prefs setBool:FALSE forKey:@"debugCommands"];

	
	kern_return_t			kr;
	mach_port_t				masterPort = 0;					// requires <mach/mach.h>
	CFMutableDictionaryRef 	matchingDictionary1 = 0;		// requires <IOKit/IOKitLib.h>
	CFMutableDictionaryRef 	matchingDictionary2 = 0;		// requires <IOKit/IOKitLib.h>
	CFMutableDictionaryRef 	matchingDictionary3 = 0;		// requires <IOKit/IOKitLib.h>
	CFNumberRef				numberRef;
	CFRunLoopSourceRef      runLoopSource;

	// Device VendorID/ProductID:   0x1130/0x0002 
	int iBuddy_VendorId_num = 0x1130;
	int iBuddy_ProductId_1_num = 0x0001;			// changed from 0002 for Dennis Hah - 22Nov11 (will also need to change kext)
	int iBuddy_ProductId_2_num = 0x0002;
	int iBuddy_ProductId_3_num = 0x0006;
	
	
	deviceCount = 0;
	iBuddyDeviceArray = [[[NSMutableArray alloc] init] retain];

	// set up USB detection code
    // First create a master_port for my task
    kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (kr || !masterPort)
    {
		NSLog(@"iBuddyControl: could not create master port, err = %08x", kr);
        return NO;
    }
    
	gNotifyPort = IONotificationPortCreate(masterPort);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    
    gRunLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);
	
    matchingDictionary1 = IOServiceMatching(kIOUSBDeviceClassName);  // Interested in instances of class
																	// IOUSBDevice and its subclasses
																	// requires <IOKit/usb/IOUSBLib.h>
    matchingDictionary2 = IOServiceMatching(kIOUSBDeviceClassName);
    matchingDictionary3 = IOServiceMatching(kIOUSBDeviceClassName);
	
	// look up toll free bridge in apple documentation... 
	// discusses Core Foundation vs. Cocoa types that are interchangeable.
	
    if (matchingDictionary1)
    {
		// Create a CFNumber for the idVendor and set the value in the dictionary
		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &iBuddy_VendorId_num);
		if (!numberRef) {
			NSLog(@"iBuddyControl: could not create CFNumberRef for vendor");
		}
		CFDictionarySetValue(matchingDictionary1, CFSTR(kUSBVendorID), numberRef);
		CFRelease(numberRef);
		
		// Create a CFNumber for the idProduct and set the value in the dictionary
		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &iBuddy_ProductId_1_num);
		CFDictionarySetValue(matchingDictionary1, CFSTR(kUSBProductID), numberRef);
		CFRelease(numberRef);

		IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
											  kIOFirstMatchNotification,  // notificationType
											  matchingDictionary1,        // matching
											  DeviceAdded,				  // callback
											  NULL,						  // refCon
											  &gAddedRocketIter			  // notification
											  );    
		
		// Iterate once to get already-present devices and arm the notification    
		DeviceAdded(NULL, gAddedRocketIter);  
		
	}
	else
	{
        NSLog(@"iBuddyControl: could not create matching dictionary1");
    }

	if (matchingDictionary2)
    {
		// Create a CFNumber for the idVendor and set the value in the dictionary
		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &iBuddy_VendorId_num);
		if (!numberRef) {
			NSLog(@"iBuddyControl: could not create CFNumberRef for vendor");
		}
		CFDictionarySetValue(matchingDictionary2, CFSTR(kUSBVendorID), numberRef);
		CFRelease(numberRef);
		
		// Create a CFNumber for the idProduct and set the value in the dictionary
		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &iBuddy_ProductId_2_num);
		CFDictionarySetValue(matchingDictionary2, CFSTR(kUSBProductID), numberRef);
		CFRelease(numberRef);
		
		IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
										 kIOFirstMatchNotification,  // notificationType
										 matchingDictionary2,        // matching
										 DeviceAdded,				  // callback
										 NULL,						  // refCon
										 &gAddedRocketIter			  // notification
										 );    
		
		// Iterate once to get already-present devices and arm the notification    
		DeviceAdded(NULL, gAddedRocketIter);  
		
	}
	else
	{
        NSLog(@"iBuddyControl: could not create matching dictionary1");
    }

	if (matchingDictionary3)
    {
		// Create a CFNumber for the idVendor and set the value in the dictionary
		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &iBuddy_VendorId_num);
		if (!numberRef) {
			NSLog(@"iBuddyControl: could not create CFNumberRef for vendor");
		}
		CFDictionarySetValue(matchingDictionary3, CFSTR(kUSBVendorID), numberRef);
		CFRelease(numberRef);
		
		// Create a CFNumber for the idProduct and set the value in the dictionary
		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &iBuddy_ProductId_3_num);
		CFDictionarySetValue(matchingDictionary3, CFSTR(kUSBProductID), numberRef);
		CFRelease(numberRef);
		
		IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
										 kIOFirstMatchNotification,  // notificationType
										 matchingDictionary3,        // matching
										 DeviceAdded,				  // callback
										 NULL,						  // refCon
										 &gAddedRocketIter			  // notification
										 );    
		
		// Iterate once to get already-present devices and arm the notification    
		DeviceAdded(NULL, gAddedRocketIter);  
		
	}
	else
	{
        NSLog(@"iBuddyControl: could not create matching dictionary1");
    }

    // Now done with the master_port
    mach_port_deallocate(mach_task_self(), masterPort);
    masterPort = 0;
	
	return self;
}

//================================================================================================
//
//  DeviceAdded
//
//  This routine is the callback for our IOServiceAddMatchingNotification.  When we get called
//  we will look at all the devices that were added and we will:
//
//  1.  Create some private data to relate to each device (in this case we use the service's name
//      and the location ID of the device
//  2.  Submit an IOServiceAddInterestNotification of type kIOGeneralInterest for this device,
//      using the refCon field to store a pointer to our private data.  When we get called with
//      this interest notification, we can grab the refCon and access our private data.
//
//================================================================================================
//
void DeviceAdded(void *refCon, io_iterator_t iterator)
{
    kern_return_t			kr;
    io_service_t			usbDevice;
    IOCFPlugInInterface		**plugInInterface=NULL;
    SInt32					score;
    HRESULT					res;
    SInt32					usbVendorID;
	SInt32					usbProductID;
	
	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];

	
    while ((usbDevice = IOIteratorNext(iterator)) != 0)
    {
        io_name_t				deviceName;
        CFStringRef				deviceNameAsCFString;  
        iBuddyDevice			*privateDataRef = NULL;
		IOUSBDeviceInterface	**deviceInterface;
		
        UInt32					locationID;
		io_object_t				notification;
	
		IOUSBDevRequest			request;
		UInt8					hidDescBuf[255];

		
		deviceCount ++;
		if (debugCommands)
			NSLog(@"iBuddyControl: DeviceAdded: iBuddy Found Number %d", deviceCount);
		// NSLog(@"iBuddyControl: Device: (0x%08x) found", usbDevice);
        CFTypeRef temp1 = IORegistryEntryCreateCFProperty(usbDevice, CFSTR(kUSBVendorID), kCFAllocatorDefault, 0);
		CFNumberGetValue(temp1, kCFNumberSInt32Type, &usbVendorID);
		CFRelease(temp1);
		
		CFTypeRef temp2 = IORegistryEntryCreateCFProperty(usbDevice, CFSTR(kUSBProductID), kCFAllocatorDefault, 0);
		CFNumberGetValue(temp2, kCFNumberSInt32Type, &usbProductID);
		CFRelease(temp2);

        // Add some app-specific information about this device.
        // Create a buffer to hold the data.
        privateDataRef = [[iBuddyDevice alloc] init];
        
		[privateDataRef setusbVendorID:usbVendorID];
		[privateDataRef setusbProductID:usbProductID];
				
		NSLog(@"iBuddyControl: DeviceAdded: usbVendorID: %d(0x%d) usbProductID: %d(0x%d) : %@", usbVendorID, usbVendorID, usbProductID, usbProductID, [privateDataRef getLauncherType]);

        // Get the USB device's name.
        kr = IORegistryEntryGetName(usbDevice, deviceName);
		if (KERN_SUCCESS != kr)
        {
            deviceName[0] = '\0';
        }
        
        deviceNameAsCFString = CFStringCreateWithCString(kCFAllocatorDefault, deviceName, 
                                                         kCFStringEncodingASCII);
        
        // Dump our data to stderr just to see what it looks like.
        //CFShow(deviceNameAsCFString);
        
        // Save the device's name to our private data.        
		[privateDataRef setDeviceName:deviceNameAsCFString];
		NSLog(@"iBuddyControl: DeviceAdded: Device Name: %@", [privateDataRef deviceName]);
		
        // Now, get the locationID of this device. In order to do this, we need to create an IOUSBDeviceInterface 
        // for our device. This will create the necessary connections between our userland application and the 
        // kernel object for the USB Device.
        kr = IOCreatePlugInInterfaceForService(usbDevice, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);
        if ((kIOReturnSuccess != kr) || !plugInInterface)
        {
            NSLog(@"iBuddyControl: DeviceAdded: unable to create plugin. ret = %08x, iodev = %p", kr, plugInInterface);
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
            continue;
        }
		
        // Use the plugin interface to retrieve the device interface.
        res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                 (LPVOID) &deviceInterface);
        // Now done with the plugin interface.
        (*plugInInterface)->Release(plugInInterface);
        if (res || !deviceInterface)
        {
            NSLog(@"iBuddyControl: DeviceAdded: couldn't create a device interface %x(%08x)", (int)res, (int)res);
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
            continue;
        }

		[privateDataRef setDeviceInterface:deviceInterface];	// IOUSBDeviceInterface    **deviceInterface;
		//		NSLog(@"iBuddyControl:  [privateDataRef setDeviceInterface:deviceInterface]");
		//NSLog(@"iBuddyControl:  deviceInterface: (0x%lx)", deviceInterface);

        // Now that we have the IOUSBDeviceInterface, we can call the routines in IOUSBLib.h.
        // In this case, fetch the locationID. The locationID uniquely identifies the device
        // and will remain the same, even across reboots, so long as the bus topology doesn't change.
        
        kr = (*deviceInterface)->GetLocationID(deviceInterface, &locationID);
        if (KERN_SUCCESS != kr)
        {
            NSLog(@"iBuddyControl: DeviceAdded: GetLocationID returned kr=(0x%08x)", kr);
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
            continue;
        }
        else
        {
			[privateDataRef setLocationID:locationID];
			//NSLog(@"iBuddyControl: DeviceAdded: Location ID: (%d)", locationID);
        }
		
        
		// Get device Speed - because we can
		// iBuddy software actually doesn't need this information
		UInt8 deviceSpeed;
        kr = (*deviceInterface)->GetDeviceSpeed(deviceInterface, &deviceSpeed);
        if (KERN_SUCCESS == kr)
        {
			if (debugCommands)
			{
				if (deviceSpeed == kUSBDeviceSpeedLow)
				{
					NSLog(@"iBuddyControl: DeviceAdded: GetDeviceSpeed returned kUSBDeviceSpeedLow");
				}
				else if (deviceSpeed == kUSBDeviceSpeedFull)
				{
					NSLog(@"iBuddyControl: DeviceAdded: GetDeviceSpeed returned kUSBDeviceSpeedFull");
				}
				else if (deviceSpeed == kUSBDeviceSpeedHigh)
				{
					NSLog(@"iBuddyControl: DeviceAdded: GetDeviceSpeed returned kUSBDeviceSpeedHigh");
				}
			}
        }
		
        // Register for an interest notification of this device being removed. Use a reference to our
        // private data as the refCon which will be passed to the notification callback.
        kr = IOServiceAddInterestNotification( gNotifyPort,			// notifyPort
                                               usbDevice,			// service
                                               kIOGeneralInterest,  // interestType
                                               DeviceNotification,  // callback
                                               privateDataRef,      // refCon
                                               &notification		// notification
                                               );
		// iBuddyControl: IOServiceAddInterestNotification returned 10000003
		// http://developer.apple.com/qa/qa2001/qa1075.html
		
        if (KERN_SUCCESS != kr)
        {
            NSLog(@"iBuddyControl: DeviceAdded: IOServiceAddInterestNotification returned (%08x)", kr);
        }
        [privateDataRef setNotification:notification];
		
		// Done with this USB device; release the reference added by IOIteratorNext
		kr = IOObjectRelease(usbDevice); 
        if (KERN_SUCCESS == kr && debugCommands)
        {
			NSLog(@"iBuddyControl: DeviceAdded: success - IOObjectRelease(usbDevice)");
		}

		// Add details of the new iBuddy to the table/array of iBuddys, then send a notification/message to the main window
		// this must be loaded into the array before calling FindInterfaces
		// FindInterfaces will delete the array entry if there is an error.		
		[iBuddyDeviceArray addObject:privateDataRef];
		
		kr = FindInterfaces(deviceInterface);	// This creates & loads the iBuddyInterface and loads it into privateDataRef
		if ([privateDataRef iBuddyInterface] == nil)
		{
			NSLog(@"iBuddyControl: DeviceAdded: We have a problem. [privateDataRef iBuddyInterface] is nil, means that FindInterfaces has not been able to find the deviceInterface, recommend kext investigation at this point");
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
			[[NSNotificationCenter defaultCenter] postNotificationName: @"usbConnectIssue" object: nil];
			continue;
		}
		
        if (KERN_SUCCESS == kr)
        {			
			//NSLog(@"iBuddyControl: DeviceAdded: Reading HID Descriptor");
			request.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBStandard, kUSBInterface);
			request.bRequest = kUSBRqGetDescriptor;
			request.wValue = (kUSBReportDesc << 8);
			request.wIndex = 0;
			request.wLength = sizeof(hidDescBuf);
			request.pData = hidDescBuf;
			
			// this is going to fail if the device is not open (i.e. non exclusive access) and the program will crash --> EXC_BAD_ACCESS
			kr = (*[privateDataRef iBuddyInterface])->ControlRequest([privateDataRef iBuddyInterface], 0, &request);
			if (debugCommands)
			{
				if (KERN_SUCCESS == kr)
				{
//					NSLog(@"iBuddyControl: DeviceAdded: HIDDescriptor read succeeded");
				} else {
					NSLog(@"iBuddyControl: DeviceAdded: HIDDescriptor read failed");
				}
			}
			
			// send a connection error to the main aplication window
			NSLog(@"Issue the USB Connected Message - we're ready to rock");
			[[NSNotificationCenter defaultCenter] postNotificationName: @"usbConnect" object: nil];

		} else {
			
			// kr == kIOReturnExclusiveAccess
			NSLog(@"iBuddyControl: DeviceAdded: FAILURE - FindInterfaces(deviceInterface)");
			NSLog(@"iBuddyControl: DeviceAdded: FAILURE - Make sure software has been installed using the installer application");
			NSLog(@"iBuddyControl: DeviceAdded: FAILURE - Possibly missing KEXT file in /System/Library/Extensions");
			
			// send a connection error to the main aplication window
			[[NSNotificationCenter defaultCenter] postNotificationName: @"usbError" object: nil];
			
		}
				
		[privateDataRef release];
		CFRelease(deviceNameAsCFString);
		
    }
}

IOReturn FindInterfaces(IOUSBDeviceInterface **device)
{
    IOReturn                    kr;
    IOUSBFindInterfaceRequest   request;
    io_iterator_t               iterator;
    io_service_t                usbInterface;
    IOCFPlugInInterface         **plugInInterface = NULL;
    IOUSBInterfaceInterface     **iBuddyInterface = NULL;
    HRESULT                     result;
    SInt32                      score;
    UInt8                       interfaceClass;
    UInt8                       interfaceSubClass;
    UInt8                       interfaceNumEndpoints;
    int                         pipeRef = 0;
	iBuddyDevice					*privateDataRef;
	int							interfaceCount;
 
    CFRunLoopSourceRef          runLoopSource;

	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];
	

	if (debugCommands)
		NSLog(@"iBuddyControl: FindInterfaces: [iBuddyDeviceArray count] = %lu", [iBuddyDeviceArray count]);
	privateDataRef = [iBuddyDeviceArray objectAtIndex:[iBuddyDeviceArray count] -1 ];
		
	//Placing the constant kIOUSBFindInterfaceDontCare into the following
    //fields of the IOUSBFindInterfaceRequest structure will allow you
    //to find all the interfaces
    request.bInterfaceClass		= kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass	= kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol	= kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting	= kIOUSBFindInterfaceDontCare;
 
    //Get an iterator for the interfaces on the device
    kr = (*device)->CreateInterfaceIterator(device, &request, &iterator);
	if (KERN_SUCCESS == kr)
	{
		if (debugCommands)
			NSLog(@"iBuddyControl: FindInterfaces: success - CreateInterfaceIterator");
	}
	
	interfaceCount = 0;
    while ((usbInterface = IOIteratorNext(iterator)) != 0)
    {
		interfaceCount ++;
		if (debugCommands)
			NSLog(@"iBuddyControl: FindInterfaces:     ----> Interface count %d", interfaceCount);
		
		//Create an intermediate plug-in
        IOCreatePlugInInterfaceForService(usbInterface,
											   kIOUSBInterfaceUserClientTypeID,
											   kIOCFPlugInInterfaceID,
											   &plugInInterface, &score);
        //Release the usbInterface object after getting the plug-in
        kr = IOObjectRelease(usbInterface);
        if ((kr != kIOReturnSuccess) || !plugInInterface)
        {
            NSLog(@"iBuddyControl: FindInterfaces: Unable to create a plug-in (0x%08x)", kr);
            break;
        }
 
        //Now create the device interface for the interface
        result = (*plugInInterface)->QueryInterface(plugInInterface,
                    CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                    (LPVOID) &iBuddyInterface);
        //No longer need the intermediate plug-in
        kr = (*plugInInterface)->Release(plugInInterface);
 
        if (result || !iBuddyInterface)
        {
            NSLog(@"iBuddyControl: FindInterfaces: Couldn't create a device interface for the interface result (0x%08x)", (int)result);
            break;
        } 
		else 
		{
			//			NSLog(@"iBuddyControl: FindInterfaces: IOUSBInterfaceInterface (0x%08x)", iBuddyInterface);
			
			
			// DGW 20110905
			// Just guessing here, but I think we want the 2nd interface 
			
			if (debugCommands)
				NSLog(@"iBuddyControl: FindInterfaces: calling [privateDataRef setIBuddyInterface:iBuddyInterface]");
			[privateDataRef setIBuddyInterface:iBuddyInterface];	// IOUSBInterfaceInterface **iBuddyInterface
		}
 
        //Get interface class and subclass
        (*iBuddyInterface)->GetInterfaceClass(iBuddyInterface, &interfaceClass);
        (*iBuddyInterface)->GetInterfaceSubClass(iBuddyInterface, &interfaceSubClass);
		if (debugCommands)
			NSLog(@"iBuddyControl: FindInterfaces: Interface class %d, subclass %d", interfaceClass, interfaceSubClass);
 
        //Now open the interface. This will cause the pipes associated with
        //the endpoints in the interface descriptor to be instantiated
		
		// IOUSBInterfaceInterface - documentation
		// Before the client can transfer data to and from the interface, it must have succeeded in opening the interface. 
		// This establishes an exclusive link between the client's task and the actual interface device.
		
        kr = (*iBuddyInterface)->USBInterfaceOpen(iBuddyInterface);
//		if (debugCommands)
//			NSLog(@"iBuddyControl: FindInterfaces: USBInterfaceOpen (0x%08x) kr=(0x%08x)", iBuddyInterface, kr);
        if (kr != kIOReturnSuccess)
        {
			NSLog(@"iBuddyControl: FindInterfaces: WARNING -->");
			if (kr == kIOReturnExclusiveAccess)
			{
				NSLog(@"iBuddyControl: FindInterfaces: ");
				NSLog(@"iBuddyControl: FindInterfaces: kIOReturnExclusiveAccess (some other task has the device opened already) - Unable to open interface (%08x)", kr);
				NSLog(@"iBuddyControl: FindInterfaces: ");
				
				NSLog(@"iBuddyControl: FindInterfaces: Suggested KEXT plist vs. iBuddy mismatch issue");
				NSLog(@"iBuddyControl: FindInterfaces: PreRequisite: Check the readme document - just in case");
				NSLog(@"iBuddyControl: FindInterfaces: Diagnostic suggestions: Collect the following and mail output to developer");
				NSLog(@"iBuddyControl: FindInterfaces: Diagnostic suggestions: 1. System Profiler output saved");
				NSLog(@"iBuddyControl: FindInterfaces: Diagnostic suggestions: 2. From terminal enter 'ioreg -l -w 0 > ~/Desktop/ioreg.txt'");
				NSLog(@"iBuddyControl: FindInterfaces: Diagnostic suggestions: 3. iBuddy, vendorID, ProductID");
				NSLog(@"iBuddyControl: FindInterfaces: Diagnostic suggestions: 4. Hardware and Operating System Version information - though this will be in System Profiler");
				NSLog(@"iBuddyControl: FindInterfaces: ");
			}
			else
			{
				NSLog(@"iBuddyControl: FindInterfaces: Unable to open interface (0x%08x)", kr);
			}
			NSLog(@"iBuddyControl: FindInterfaces: WARNING --> Interface is being released, the program may no longer operate correctly");
			NSLog(@"iBuddyControl: FindInterfaces: WARNING --> Interface is being released, the program may no longer operate correctly");
			NSLog(@"iBuddyControl: FindInterfaces: WARNING --> Interface is being released, the program may no longer operate correctly");
			NSLog(@"iBuddyControl: FindInterfaces: WARNING -->");

            (void) (*iBuddyInterface)->Release(iBuddyInterface);
			
			// need to remove the iBuddy device entry from the array
			[iBuddyDeviceArray removeObjectAtIndex:[iBuddyDeviceArray count] -1 ];
			return kr;
            break;
        }
 
        //Get the number of endpoints associated with this interface
        kr = (*iBuddyInterface)->GetNumEndpoints(iBuddyInterface, &interfaceNumEndpoints);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"iBuddyControl: FindInterfaces: Unable to get number of endpoints kr=(0x%08x)", kr);
            (void) (*iBuddyInterface)->USBInterfaceClose(iBuddyInterface);
            (void) (*iBuddyInterface)->Release(iBuddyInterface);

			// need to remove the iBuddy device entry from the array
			[iBuddyDeviceArray removeObjectAtIndex:[iBuddyDeviceArray count] -1 ];
			return kr;
            break;
        }
 
		if (debugCommands)
			NSLog(@"iBuddyControl: FindInterfaces: Interface has %d endpoints", interfaceNumEndpoints);
		
        // Access each pipe in turn.
        // The pipe at index 0 is the default control pipe and should be
        // accessed using (*usbDevice)->DeviceRequest() instead
        for (pipeRef = 0; pipeRef < interfaceNumEndpoints+1; pipeRef++)
        {
            IOReturn        kr2;
            UInt8           direction;
            UInt8           number;
            UInt8           transferType;
            UInt16          maxPacketSize;
            UInt8           interval;
            char            *message;
 
            kr2 = (*iBuddyInterface)->GetPipeProperties(iBuddyInterface,
                                        pipeRef, &direction,
                                        &number, &transferType,
                                        &maxPacketSize, &interval);
			if (debugCommands)
			{
				if (kr2 != kIOReturnSuccess)
					NSLog(@"iBuddyControl: FindInterfaces: Unable to get properties of pipe %d kr2=(0x%08x)", pipeRef, kr2);
				else
				{
					NSLog(@"iBuddyControl: FindInterfaces: PipeRef %i: PipeNumber 0x%08x ", pipeRef, number);
					//printf("iBuddyControl: FindInterfaces: PipeRef %d: PipeNumber %d ", pipeRef, number);
					switch (direction) 
					{
						case kUSBOut:
							message = "out";
							break;
						case kUSBIn:
							message = "in";
							break;
						case kUSBNone:
							message = "none";
							break;
						case kUSBAnyDirn:
							message = "any";
							break;
						default:
							message = "???";
					}
					NSLog(@"iBuddyControl: FindInterfaces: --> direction %s, ", message);
					//printf("direction %s, ", message);
	 
					switch (transferType)
					{
						case kUSBControl:
							message = "control";
							break;
						case kUSBIsoc:
							message = "isoc";
							break;
						case kUSBBulk:
							message = "bulk";
							break;
						case kUSBInterrupt:
							message = "interrupt";
							break;
						case kUSBAnyType:
							message = "any";
							break;
						default:
							message = "???";
					}
					NSLog(@"iBuddyControl: FindInterfaces: --> transfer type %s, maxPacketSize %d", message, maxPacketSize);
	//                printf("transfer type %s, maxPacketSize %d\n", message, maxPacketSize);
				}
			}
        }
		
        //As with service matching notifications, to receive asynchronous
        //I/O completion notifications, you must create an event source and
        //add it to the run loop
        kr = (*iBuddyInterface)->CreateInterfaceAsyncEventSource(iBuddyInterface, &runLoopSource);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"iBuddyControl: FindInterfaces: Unable to create asynchronous event source kr=(0x%08x)", kr);
            (void) (*iBuddyInterface)->USBInterfaceClose(iBuddyInterface);
            (void) (*iBuddyInterface)->Release(iBuddyInterface);

			// need to remove the iBuddy device entry from the array
			[iBuddyDeviceArray removeObjectAtIndex:[iBuddyDeviceArray count] -1 ];
			return kr;
            break;
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
//		NSLog(@"iBuddyControl: FindInterfaces: Asynchronous event source added to run loop");
		
        //For this test, just use first interface, so exit loop
//        break;
	}
	
	if (debugCommands)
		NSLog(@"iBuddyControl: FindInterfaces: END");

    return kr;
}


//================================================================================================
//
//  DeviceNotification
//
//  This routine will get called whenever any kIOGeneralInterest notification happens.  We are
//  interested in the kIOMessageServiceIsTerminated message so that's what we look for.  Other
//  messages are defined in IOMessage.h.
//
//================================================================================================
//
void DeviceNotification( void *refCon,
                         io_service_t service,
                         natural_t messageType,
                         void *messageArgument )
{
//    kern_return_t				kr;
    iBuddyDevice					*privateDataRef = (iBuddyDevice *) refCon;
	IOUSBDeviceInterface        **iBuddyDeviceInterface = NULL;
	int							i;
	iBuddyDevice					*iBuddyDataRef;
	IOUSBDeviceInterface        **deviceInterface = NULL;
	
	//		kIOMessageServiceIsSuspended
	//		kIOMessageServiceIsResumed
	//		kIOMessageServiceIsRequestingClose
	//		kIOMessageServiceIsAttemptingOpen
	//		kIOMessageServiceWasClosed
	//		kIOMessageServiceBusyStateChange
	//		kIOMessageServicePropertyChange
	//		kIOMessageCanDevicePowerOff
	//		kIOMessageDeviceWillPowerOff
	//		kIOMessageDeviceWillNotPowerOff
	//		kIOMessageDeviceHasPoweredOn
	//		kIOMessageCanSystemPowerOff
	//		kIOMessageSystemWillPowerOff
	//		kIOMessageSystemWillNotPowerOff
	//		kIOMessageCanSystemSleep
	//		kIOMessageSystemWillSleep
	//		kIOMessageSystemWillNotSleep
	//		kIOMessageSystemHasPoweredOn
	//		kIOMessageSystemWillRestart
	//		kIOMessageSystemWillPowerOn
	
	
	switch (messageType)
	{	
		case kIOMessageServiceIsTerminated:
		{
			NSLog(@"iBuddyControl: DeviceNotification: (0x%08x) REMOVED", service);
			
			// Dump our private data to stderr just to see what it looks like.
			//NSLog(@"iBuddyControl: Device Name: %@", [privateDataRef deviceName]);
			
			// Free the data we're no longer using now that the device is going away
			//CFRelease([privateDataRef->deviceName);
			iBuddyDeviceInterface = [privateDataRef deviceInterface];
			
			if (iBuddyDeviceInterface)
			{
				(*iBuddyDeviceInterface)->Release(iBuddyDeviceInterface);
			}
			
//			kr = IOObjectRelease([privateDataRef notification]);
			IOObjectRelease([privateDataRef notification]);
			
			// iBuddy needs to be removed from iBuddyDevice array!
			NSUInteger numItems = [iBuddyDeviceArray count];
			for (i = 0; i < numItems; i++)
			{
				//iBuddyDataRef = [[USBiBuddy alloc] init];
				iBuddyDataRef = [iBuddyDeviceArray objectAtIndex: i];
				deviceInterface = [iBuddyDataRef deviceInterface];
				if (deviceInterface == iBuddyDeviceInterface) {
					NSLog(@"iBuddyControl: DeviceNotification: item at index %d remove from iBuddyDevice array", i);
					[iBuddyDeviceArray removeObjectAtIndex: i];
					deviceCount --;
					[[NSNotificationCenter defaultCenter] postNotificationName: @"usbDisConnect" object: nil];
				}
			}
			
			//[privateDataRef dealloc];
			//[privateDataRef release];
			break;
		}
		case kIOMessageServiceIsSuspended:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageServiceIsSuspended", service);
			break;
		}
		case kIOMessageServiceIsResumed:		
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageServiceIsResumed", service);
			break;
		}
		case kIOMessageServiceIsRequestingClose:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageServiceIsRequestingClose", service);
			break;
		}
		case kIOMessageServiceIsAttemptingOpen:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageServiceIsAttemptingOpen", service);
			break;
		}
		case kIOMessageServiceWasClosed:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageServiceWasClosed", service);
			break;
		}
		case kIOMessageServiceBusyStateChange:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageServiceBusyStateChange", service);
			break;
		}
		case kIOMessageServicePropertyChange:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageServicePropertyChange", service);
			break;
		}
		case kIOMessageCanDevicePowerOff:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageCanDevicePowerOff", service);
			break;
		}
		case kIOMessageDeviceWillPowerOff:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageDeviceWillPowerOff", service);
			break;
		}
		case kIOMessageDeviceWillNotPowerOff:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageDeviceWillNotPowerOff", service);
			break;
		}
		case kIOMessageDeviceHasPoweredOn:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageDeviceHasPoweredOn", service);
			break;
		}
		case kIOMessageCanSystemPowerOff:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageCanSystemPowerOff", service);
			break;
		}
		case kIOMessageSystemWillPowerOff:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageSystemWillPowerOff", service);
			break;
		}
		case kIOMessageSystemWillNotPowerOff:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageSystemWillNotPowerOff", service);
			break;
		}
		case kIOMessageCanSystemSleep:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageCanSystemSleep", service);
			break;
		}
		case kIOMessageSystemWillSleep:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageSystemWillSleep", service);
			break;
		}
		case kIOMessageSystemWillNotSleep:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageSystemWillNotSleep", service);
			break;
		}
		case kIOMessageSystemHasPoweredOn:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageSystemHasPoweredOn", service);
			break;
		}
		case kIOMessageSystemWillRestart:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageSystemWillRestart", service);
			break;
		}
		case kIOMessageSystemWillPowerOn:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) kIOMessageSystemWillPowerOn", service);
			break;
		}
		default:
		{
			NSLog(@"iBuddyControl : DeviceNotification: (0x%08x) UNKNOWN!!!!", service);
			NSLog(@"%u %u", iokit_family_msg(sub_iokit_usb, 0x0A), iokit_family_msg(sub_iokit_usb, 0x11));
			break;
		}
	}	
}

void EvaluateUSBErrorCode(IOUSBDeviceInterface **deviceInterface_param, IOUSBInterfaceInterface **iBuddyInterface_param, IOReturn kr)
{
	//	error code c/- usb.h
	//	IOUSBFamily error codes
	
	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];
	
	
	if (kr == kIOUSBUnknownPipeErr)
	{
		NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBUnknownPipeErr (0x%08x) - Pipe reference is not recognized", kr);
	} else
		if (kr == kIOUSBTooManyPipesErr)
		{
			NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBTooManyPipesErr (0x%08x) - There are too many pipes", kr);
		} else
			if (kr == kIOUSBNoAsyncPortErr)
			{
				NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBNoAsyncPortErr (0x%08x) - There is no asynchronous port", kr);
			} else
				if (kr == kIOUSBNotEnoughPipesErr)
				{
					NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBNotEnoughPipesErr (0x%08x) - There are not enough pipes in the interface", kr);
				} else
					if (kr == kIOUSBNotEnoughPowerErr)
					{
						NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBNotEnoughPowerErr (0x%08x) - There is not enough power for the selected configuration", kr);
					} else
						if (kr == kIOUSBEndpointNotFound)
						{
							NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBEndpointNotFound (0x%08x) - The endpoint has not been found", kr);
						} else
							if (kr == kIOUSBConfigNotFound)
							{
								NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBConfigNotFound (0x%08x) - The configuration has not been found", kr);
							} else
								if (kr == kIOUSBTransactionTimeout)
								{
									NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBTransactionTimeout (0x%08x) - The transaction has timed out", kr);
								} else
									if (kr == kIOUSBTransactionReturned)
									{
										NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBTransactionReturned (0x%08x) - The transaction has been returned to the caller", kr);
									} else
										if (kr == kIOUSBPipeStalled)
										{
											if (debugCommands)
											{
												NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBPipeStalled (0x%08x) - The pipe has stalled; the error needs to be cleared", kr);
											}
										} else
											if (kr == kIOUSBInterfaceNotFound)
											{
												NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBInterfaceNotFound (0x%08x) - The interface reference is not recognized", kr);
											} else
												if (kr == kIOUSBLowLatencyBufferNotPreviouslyAllocated)
												{
													NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBLowLatencyBufferNotPreviouslyAllocated (0x%08x) - Attempted to use user space low latency isochronous calls without first calling PrepareBuffer on the data buffer", kr);
												} else
													if (kr == kIOUSBLowLatencyFrameListNotPreviouslyAllocated)
													{
														NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBLowLatencyFrameListNotPreviouslyAllocated (0x%08x) - Attempted to use user space low latency isochronous calls without first calling PrepareBuffer on the frame list", kr);
													} else
														if (kr == kIOUSBHighSpeedSplitError)
														{
															NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBHighSpeedSplitError (0x%08x) - The hub received an error on a high speed bus trying to do a split transaction", kr);
														} else
															if (kr == kIOUSBSyncRequestOnWLThread)
															{
																NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOUSBSyncRequestOnWLThread (0x%08x) - A synchronous USB request was made on the work loop thread, perhaps from a callback. In this case, only asynchronous requests are permitted.", kr);
															} else
																if (kr == kIOReturnBadArgument)
																{
																	NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOReturnBadArgument (0x%08x) - There is an invalid argument.", kr);
																} else
																	if (kr == kIOReturnOverrun)
																	{
																		NSLog(@"iBuddyControl: EvaluateUSBErrorCode: kIOReturnOverrun (0x%08x) - There has been a data overrun.", kr);
																	} else
																	{
																		NSLog(@"iBuddyControl: EvaluateUSBErrorCode: Error Unknown (0x%08x)", kr);
																	}
	return;
}

void printInterpretedError(char *s, IOReturn err)
{
	// These should be defined somewhere, but I can't find them. These from Accessing hardware.
	
#if 0
	static struct{int err; char *where;} systemSources[] = {
		{0, "kernel"},
		{1, "user space library"},
		{2, "user space servers"},
		{3, "old ipc errors"},
		{4, "mach-ipc errors"},
		{7, "distributed ipc"},
		{0x3e, "user defined errors"},
		{0x3f, "(compatibility) mach-ipc errors"}
    };
#endif
	
	UInt32 system, sub, code;
    
    fprintf(stderr, "%s (0x%08X) ", s, err);
    
    system = err_get_system(err);
    sub = err_get_sub(err);
    code = err_get_code(err);
    
    if(system == err_get_system(sys_iokit))
    {
        if(sub == err_get_sub(sub_iokit_usb))
        {
            fprintf(stderr, "USB error %u(0x%X) ", code, code);
        }
        else if(sub == err_get_sub(sub_iokit_common))
        {
            fprintf(stderr, "IOKit common error %u(0x%X) ", code, code);
        }
        else
        {
            fprintf(stderr, "IOKit error %u(0x%X) from subsytem %u(0x%X) ", code, code, sub, sub);
        }
    }
    else
    {
        fprintf(stderr, "error %u(0x%X) from system %u(0x%X) - subsytem %u(0x%X) ", code, code, system, system, sub, sub);
    }
	fprintf(stderr, "\n");
}


- (BOOL)confirmDeviceConnected
{
	if (deviceCount > 0)
	{
		return YES;
	}
	
	return NO;
}

- (void)dealloc;
{
	[self ReleaseiBuddy];
	[iBuddyDevice release];
	[super dealloc];
}

#pragma mark - iBuddy device commands

- (id)sendCommandsToDevice:(UInt8)controlBits
{
	IOUSBDevRequest				devRequest;
	iBuddyDevice					*privateDataRef;
	int							iBuddyDeviceNum;
	IOUSBDeviceInterface        **deviceInterface;
	IOUSBInterfaceInterface		**iBuddyInterface;
	IOReturn                    kr;
	Boolean						debugCommands;

	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];

	
	//NSLog(@"iBuddyControl: sendCommandsToDevice");
	NSUInteger numItems = [iBuddyDeviceArray count];
	if (debugCommands)
	{
		NSLog(@"iBuddyControl: sendCommandsToDevice: iBuddys to control = %lu", numItems);
	}
	
	for (iBuddyDeviceNum = 0; iBuddyDeviceNum < numItems; iBuddyDeviceNum++)
	{
		privateDataRef = [iBuddyDeviceArray objectAtIndex: iBuddyDeviceNum];

		deviceInterface = [privateDataRef deviceInterface];
		iBuddyInterface = [privateDataRef iBuddyInterface];
		if (debugCommands)
		{
			NSLog(@"iBuddyControl: sendCommandsToDevice: iBuddyDevice index    %d", iBuddyDeviceNum);
//			NSLog(@"iBuddyControl: sendCommandsToDevice: IOUSBDeviceInterface    (0x%08x)", deviceInterface);
//			NSLog(@"iBuddyControl: sendCommandsToDevice: IOUSBInterfaceInterface (0x%08x)", iBuddyInterface);
		}
		
		if (iBuddyInterface == nil)
		{
			NSLog(@"iBuddyControl: sendCommandsToDevice: No Interface - IGNORING REQUEST");
			continue;
		}
		
		// ===========================================================================
		// iBuddy command are sent from here
		// ===========================================================================
		if (debugCommands)
		{
//			NSLog(@"iBuddyControl: iBuddyType = %@", [privateDataRef getLauncherType]);
//			NSLog(@"iBuddyControl: USBVendorID  = %d (0x%d)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
//			NSLog(@"iBuddyControl: USBProductID = %d (0x%d)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//			NSLog(@"iBuddyControl: device       = (0x%x)", [privateDataRef deviceInterface]);
			NSLog(@"iBuddyControl: controlBits  = %d", controlBits);
		}

		devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
		devRequest.bRequest = kUSBRqSetConfig; 
		devRequest.wValue = kUSBConfDesc; 
		devRequest.wIndex = 1; 
		devRequest.wLength = 8; 
		devRequest.pData = reqBuffer; 
		if (debugCommands)
		{
			NSLog(@"iBuddyControl: reqBuffer[7]=%d", reqBuffer[7]);
		}
		kr = (*deviceInterface)->DeviceRequest(deviceInterface, &devRequest);
		if (kr != kIOReturnSuccess)
		{
			if (kr == kIOReturnNoDevice)
			{
				if (debugCommands) 
					NSLog(@"iBuddyControl: IOReturn: kIOReturnNoDevice");
			} else
				if (kr == kIOReturnNotOpen)
				{
					if (debugCommands) 
						NSLog(@"iBuddyControl: IOReturn: kIOReturnNotOpen");
				} else
				{
					EvaluateUSBErrorCode(deviceInterface, iBuddyInterface, kr);
				}
		}
		
	} // for loop - number of items in iBuddyDevice array
		
	return self;
}


- (IBAction)heartLightAction:(id)sender
{
	if ([sender intValue])
		reqBuffer[7] &= 0x7F;
	else
		reqBuffer[7] |= 0x80;
	UInt8 control = 0;
	[self sendCommandsToDevice:control];
}

- (IBAction)headLightAction:(id)sender
{
	const uint8_t colorBits[8] = {0x70, 0x60, 0x50, 0x30, 0x10, 0x20, 0x40, 0x00};
	reqBuffer[7] &= 0x8F;
	reqBuffer[7] |= colorBits[[sender selectedColumn]];
	UInt8 control = 0;
	[self sendCommandsToDevice:control];
}

- (IBAction)wingsAction:(id)sender
{
	reqBuffer[7] &= 0xF3;
	if ([sender intValue])
		reqBuffer[7] |= 0x04;
	else
		reqBuffer[7] |= 0x08;
	UInt8 control = 0;
	[self sendCommandsToDevice:control];
}

- (IBAction)bodyAction:(id)sender
{
	const uint8_t bodyBits[4] = {0x01, 0x03, 0x00, 0x02};
	reqBuffer[7] &= 0xFC;
	reqBuffer[7] |= bodyBits[[sender selectedColumn]];
	UInt8 control = 0;
	[self sendCommandsToDevice:control];
}

- (void)bodyActionAuto:(NSTimer *)timer
{
	if (bodyBool)
		[bodyMatrix setState:1 atRow:0 column:3];
	else
		[bodyMatrix setState:1 atRow:0 column:0];
	[self bodyAction:bodyMatrix];
	bodyBool = !bodyBool;		// flip it
}

- (void)bodyActionRepeatEnd:(NSTimer *)timer
{
	[rotateTimer invalidate];
}

- (void)flapWingsCommand:(NSTimer *)timer
{
	flapWings = ! flapWings;
	reqBuffer[7] &= 0xF3;
	if (flapWings)
		reqBuffer[7] |= 0x04;
	else
		reqBuffer[7] |= 0x08;
	UInt8 control = 0;
	[self sendCommandsToDevice:control];
	
}

- (void)flapWingsRepeatEnd:(NSTimer *)timer
{
	[flapWingsTimer invalidate];
}

- (IBAction)flapWingsAction:(id)sender
{
	if ([sender state]) 
	{
		flapWingsTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(flapWingsCommand:) userInfo:nil repeats:YES];
	} else
	{
		[flapWingsTimer invalidate];
	}
}

- (void)beatHeartCommand:(NSTimer *)timer
{
	beatHeart = ! beatHeart;
	if (beatHeart)
		reqBuffer[7] &= 0x7F;
	else
		reqBuffer[7] |= 0x80;
	UInt8 control = 0;
	[self sendCommandsToDevice:control];
	
}

- (void)beatHeartEnd:(NSTimer *)timer
{
	[beatHeartTimer invalidate];
}

- (IBAction)beatHeartAction:(id)sender
{
	if ([sender state]) 
	{
		beatHeartTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(beatHeartCommand:) userInfo:nil repeats:YES];
	} else
	{
		[beatHeartTimer invalidate];
	}
}

- (void)DGWScheduleCancelCommand:(NSTimeInterval)duration
{
	timer = [NSTimer scheduledTimerWithTimeInterval:duration
											 target:self
										   selector:@selector(DGWAbortCommand:)
										   userInfo:nil
											repeats:NO];
	return;
}


- (id)ReleaseiBuddy
{
	iBuddyDevice					*privateDataRef = NULL;
	int							i;
	IOUSBDeviceInterface        **iBuddyDeviceInterface = NULL;
	
	NSUInteger numItems = [iBuddyDeviceArray count];	
	for (i = 0; i < numItems; i++)
	{
		privateDataRef = [iBuddyDeviceArray objectAtIndex: i];
		iBuddyDeviceInterface = [privateDataRef deviceInterface];
		(*iBuddyDeviceInterface)->USBDeviceClose(iBuddyDeviceInterface);
		(*iBuddyDeviceInterface)->Release(iBuddyDeviceInterface);
		[iBuddyDeviceArray removeObjectAtIndex: i];
	}
	
	return self;
}

#pragma mark - iBuddy device control

- (id)controliBuddy:(NSNumber*)code
{
	NSLog(@"controliBuddy = %@", code);
	
	int				controlRequest = [code intValue];
	UInt8			controls;
	Boolean			debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];
	
	controls = 0;
	
	switch(controlRequest)
	{
		case iBuddy_Stop:
		{
			controls = 0;
			[self sendCommandsToDevice:controls];
			break;
		}
		case iBuddy_Heart_On:
		{
			NSButton * onButton = [[NSButton alloc] init];
			[onButton setIntValue:1];
			[self heartLightAction:onButton];
			[onButton release];
			break;
		}
		case iBuddy_Heart_Off: 
		{
			NSButton * onButton = [[NSButton alloc] init];
			[onButton setIntValue:0];
			[self heartLightAction:onButton];
			[onButton release];
			break;
		}
		case iBuddy_Heart_Beat:
		{
			NSLog(@"iBuddy_Heart_Beat");
			beatHeartTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(beatHeartCommand:) userInfo:nil repeats:YES];
			cancelTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(beatHeartEnd:) userInfo:nil repeats:NO];
			// BOOL shouldKeepRunning = YES;        // global
			NSRunLoop *theRL = [NSRunLoop currentRunLoop];
			while ([cancelTimer isValid])
			{
				[theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
			}
			break;
		}
		case iBuddy_Flap:				// done
		{
			NSLog(@"iBuddy_Flap");
			[self flapWingsCommand:nil];
			break;
		}
		case iBuddy_Flap_Long:			// need to set 10 second timer to invalidate
		{
			NSLog(@"iBuddy_Flap_Long");
			flapWingsTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(flapWingsCommand:) userInfo:nil repeats:YES];
			cancelTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(flapWingsRepeatEnd:) userInfo:nil repeats:NO];
			NSRunLoop *theRL = [NSRunLoop currentRunLoop];
			while ([cancelTimer isValid])
			{
				[theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
			}
			break;
		}
		case iBuddy_Head_Light_Off:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:0];
			[self headLightAction:colourMatrix];
			[colourMatrix release];
			break;
		}
		case iBuddy_Head_Light_Red:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:1];
			[self headLightAction:colourMatrix];
			 [colourMatrix release];
			break;
		}
		case iBuddy_Head_Light_Green:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:2];
			[self headLightAction:colourMatrix];
			[colourMatrix release];
			break;
		}		
		case iBuddy_Head_Light_Blue:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:3];
			[self headLightAction:colourMatrix];
			[colourMatrix release];
			break;
		}		
		case iBuddy_Head_Light_Cyan:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:4];
			[self headLightAction:colourMatrix];
			[colourMatrix release];
			break;
		}		
		case iBuddy_Head_Light_Magenta:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:5];
			[self headLightAction:colourMatrix];
			[colourMatrix release];
			break;
		}		
		case iBuddy_Head_Light_Yellow:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:6];
			[self headLightAction:colourMatrix];
			[colourMatrix release];
			break;
		}		
		case iBuddy_Head_Light_White:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			NSMatrix * colourMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:8];
			[colourMatrix setState:1 atRow:0 column:7];
			[self headLightAction:colourMatrix];
			[colourMatrix release];
			break;
		}	
		case iBuddy_Move_Left:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			bodyMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:4];
			[bodyMatrix setState:1 atRow:0 column:0];
			[self bodyAction:bodyMatrix];
			[bodyMatrix release];
			break;
		}	
		case iBuddy_Move_Right:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			bodyMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:4];
			[bodyMatrix setState:1 atRow:0 column:3];
			[self bodyAction:bodyMatrix];
			[bodyMatrix release];
			break;
		}	
		case iBuddy_Move_Rotate:
		{
			NSRect fakeRect = NSMakeRect(0, 0, 20, 20);
			bodyMatrix = [[NSMatrix alloc] initWithFrame:fakeRect mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:4];
			
			rotateTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(bodyActionAuto:) userInfo:nil repeats:YES];
			cancelTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(bodyActionRepeatEnd:) userInfo:nil repeats:NO];
			NSRunLoop *theRL = [NSRunLoop currentRunLoop];
			while ([cancelTimer isValid])
			{
				[theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
			}
			break;
		}	
			
	}
	return self;
}

- (IBAction)bodyActionxx:(id)sender
{
	const uint8_t bodyBits[4] = {0x01, 0x03, 0x00, 0x02};
	reqBuffer[7] &= 0xFC;
	reqBuffer[7] |= bodyBits[[sender selectedColumn]];
	UInt8 control = 0;
	[self sendCommandsToDevice:control];
}


@end

/*
 
 The i-Buddy is controlled by sending an 8-byte output report to
 the second USB HID device.
 
 The first 7 bytes of this output report are always the same; the
 last byte controls the state of the i-Buddy.
 
 The bit configuration is as follows:
 
 +-----+-----+-----+-----+-----+-----+-----+-----+
 |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
 |     |     |     |     |     |     |     |     |
 |heart|    head color   |   wings   |  turning  |
 +-----+-----+-----+-----+-----+-----+-----+-----+
 
 bits 0-1: position of the body
 
 1 = left
 2 = right
 0 = middle, but only after right
 3 = a little to the middle, but only after right
 
 bits 2-3: position of the wings
 
 1 = wings high
 2 = wings low
 
 bits 4-6: color of the head, in terms of the RGB leds inside
 
 bits   lights   color
 ---     ---     ---
 0   000     BGR     white
 1   001     BG.     cyan
 2   010     B.R     purple
 3   011     B..     blue
 4   100     .GR     yellow
 5   101     .G.     green
 6   110     ..R     red
 7   111     ...     off
 
 bit 7: heart light
 
 0 = on
 1 = off
 
 */

// http://stackoverflow.com/questions/47981/how-do-you-set-clear-and-toggle-a-single-bit-in-c

