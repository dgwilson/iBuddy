//
//  iBuddyAppDelegate.h
//  iBuddy
//
//  Created by David Wilson on 31/08/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface iBuddyAppDelegate : NSObject <NSApplicationDelegate> 
{
	NSWindow *window;
	IBOutlet NSTextField *_textField;
	NSLevelIndicator * onScreenConnected;
	BOOL deviceConnected;
	AuthorizationRef authRef;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSLevelIndicator * onScreenConnected;


- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error;

- (void)updateScreen;
- (void)usbConnect:(NSNotification *)theNotification;
- (void)usbDisConnect:(NSNotification *)theNotification;
- (void)usbError:(NSNotification *)theNotification;


@end
