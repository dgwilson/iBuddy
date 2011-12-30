//
//  iBuddyAppDelegate.m
//  iBuddy
//
//  Created by David Wilson on 31/08/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import "iBuddyAppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#include <mach-o/dyld.h>
#include <spawn.h>
#include <sys/un.h>
#include <vproc.h>
#include "shared.h"
#include "common.h"

#pragma mark - Declarations

int client_connect(void);
bool client_send_command(int fd, CFDataRef sendCommand);

int launchHelper(int argc, const char *argv[]);






@implementation iBuddyAppDelegate

@synthesize window;
@synthesize onScreenConnected;

- (id)init
{
	[super init];
	
	deviceConnected = FALSE;
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbConnect:)
												 name: @"usbConnect"
											   object: nil
	 ];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbDisConnect:)
												 name: @"usbDisConnect"
											   object: nil
	 ];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbError:)
												 name: @"usbError"
											   object: nil
	 ];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbError:)
												 name: @"usbConnectIssue"
											   object: nil
	 ];	
	
	return self;
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
//	iBuddyController = [[iBuddyControl alloc] init];
//	if (iBuddyController)
//	{
//		[self iBuddyCommand:nil];
//	}

	

	
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
		NSLog(@"WARNING: Critical Support file not found : Displaying warning message to user");
		NSRunAlertPanel(@"iBuddy", 
						@"A critical support file (/System/Library/Extensions/iBuddy_Driver.kext) was not found. Please select 'Install OS Driver' from the iBuddy menu.", nil, nil, nil);
	}
	
	[self updateScreen];
}

//- (void)viewDidLoad
//{
//	NSLog(@"%@", NSStringFromSelector(_cmd));
//
//	[self updateScreen];
//}

#pragma mark - kext install/remove - helper communications

extern char **environ;

static int RunLaunchCtl(
						bool						junkStdIO, 
						const char					*command, 
						const char					*plistPath
						)
// Handles all the invocations of launchctl by doing the fork() + execve()
// for proper clean-up. Only two commands are really supported by our
// implementation; loading and unloading of a job via the plist pointed at 
// (const char *) plistPath.
{	
	int				err;
	const char *	args[5];
	pid_t			childPID;
	pid_t			waitResult;
	int				status;
	
	// Pre-conditions.
	assert(command != NULL);
	assert(plistPath != NULL);
	
    // Make sure we get sensible logging even if we never get to the waitpid.
    
    status = 0;
    
    // Set up the launchctl arguments.  We run launchctl using StartupItemContext 
	// because, in future system software, launchctl may decide on the launchd 
	// to talk to based on your Mach bootstrap namespace rather than your RUID.
    
	args[0] = "/bin/launchctl";
	args[1] = command;				// "load" or "unload"
	args[2] = "-w";
	args[3] = plistPath;			// path to plist
	args[4] = NULL;
	
    fprintf(stderr, "launchctl %s %s '%s'\n", args[1], args[2], args[3]);
	
    // Do the standard fork/exec dance.
    
	childPID = fork();
	switch (childPID) {
		case 0:
			// child
			err = 0;
            
            // If we've been told to junk the I/O for launchctl, open 
            // /dev/null and dup that down to stdin, stdout, and stderr.
            
			if (junkStdIO) {
				int		fd;
				int		err2;
				
				fd = open("/dev/null", O_RDWR);
				if (fd < 0) {
					err = errno;
				}
				if (err == 0) {
					if ( dup2(fd, STDIN_FILENO) < 0 ) {
						err = errno;
					}
				}
				if (err == 0) {
					if ( dup2(fd, STDOUT_FILENO) < 0 ) {
						err = errno;
					}
				}
				if (err == 0) {
					if ( dup2(fd, STDERR_FILENO) < 0 ) {
						err = errno;
					}
				}
				err2 = close(fd);
				if (err2 < 0) {
					err2 = 0;
				}
				if (err == 0) {
					err = err2;
				}
			}
			if (err == 0) {
				//fprintf(stderr, "execve(args[0], (char **) args, environ)\n");
				err = execve(args[0], (char **) args, environ);
			}
			if (err < 0) {
				err = errno;
			}
			_exit(EXIT_FAILURE);
			break;
		case -1:
			err = errno;
			break;
		default:
			err = 0;
			break;
	}
	
    // Only the parent gets here.  Wait for the child to complete and get its 
    // exit status.
	
	if (err == 0) {
		do {
			waitResult = waitpid(childPID, &status, 0);
		} while ( (waitResult == -1) && (errno == EINTR) );
		
		if (waitResult < 0) {
			err = errno;
		} else {
			assert(waitResult == childPID);
			
            if ( ! WIFEXITED(status) || (WEXITSTATUS(status) != 0) ) {
                err = EINVAL;
            }
		}
	}
	
    fprintf(stderr, "launchctl -> %d %ld 0x%x\n", err, (long) childPID, status);
	
	return err;
}

int client_connect( void )
{
	int socketFD = socket( AF_UNIX, SOCK_STREAM, 0 );
	assert( socketFD != -1 );
	
	struct sockaddr_un addr;
	
	addr.sun_len    = sizeof( addr );
	addr.sun_family = AF_UNIX;
	
	strcpy( addr.sun_path, kServerSocketPath );
	
	int result;
	int err;
	
	result	= connect( socketFD, (struct sockaddr *)&addr, sizeof( addr ) );
	err		= MoreUNIXErrno( result );
	CFShow( CFStringCreateWithFormat( NULL, NULL, CFSTR( "client_connect: %d" ), err ) );
	
	assert( err == 0 );
	
	return socketFD;
}

bool client_send_command(int fd, CFDataRef sendCommand)
{
	printf("client_send_command\n");
	assert(sendCommand != NULL);
	
	/* We'll be using this same buffer for receiving the reply as well. This
	 * is a very simple test client, so it will just fall on its face if the
	 * world doesn't conform to its expectations.
	 */
	size_t space = 10 * 1024 * 1024;
	unsigned char *buff = (unsigned char *)malloc(space);
	assert(buff != NULL);	
	assert(CFDataGetLength(sendCommand) <= space);
	
	/* We're going to use little endian as our wire encoding. This only matters
	 * for the first word of the data sent, which specifies the length. Everything
	 * that follows is not endian-sensitive.
	 *
	 * Note that OSSwapHostToLittleInt32() implicitly casts the input to uint32_t,
	 * despite the name indicating that it works with a signed 32-bit quantity.
	 */
	CFIndex length = OSSwapHostToLittleInt32(CFDataGetLength(sendCommand));
	
	struct ss_msg_s *msg = (struct ss_msg_s *)buff;
	msg->_len = (uint32_t)length;
	
	/* Coming up with a more efficient implementation is left as an exercise to
	 * the reader.
	 */
	(void)memcpy(msg->_bytes, CFDataGetBytePtr(sendCommand), CFDataGetLength(sendCommand));
	
	ssize_t nbytes = 0;
	unsigned char *track_buff = (unsigned char *)msg;
	size_t track_sz = sizeof(struct ss_msg_s) + CFDataGetLength(sendCommand);
	while ((nbytes = write(fd, track_buff, track_sz))) {
		if (nbytes != -1) {
			track_buff += nbytes;
			track_sz -= nbytes;
			
			if (track_sz == 0) {
				break;
			}
		} else {
			break;
		}
	}
	assert(track_sz == 0);
	//	CFRelease(sendCommand);		// just a hunch - but as this comes from the Obj-C world, the release here is not appropriate
	
	
//	printf("client_send_command ... waiting on read\n");
	track_buff = buff;
	track_sz = 10 * 1024 * 1024;
	
	size_t bytes_read = 0;
	ssize_t expected = -1;
	while ((nbytes = read(fd, track_buff, track_sz))) {
		if (nbytes != -1) {
			track_buff += nbytes;
			track_sz -= nbytes;
			bytes_read += nbytes;
			
			if (expected == -1 && bytes_read >= sizeof(struct ss_msg_s)) {
				msg->_len = OSSwapLittleToHostInt32(msg->_len);
				expected = msg->_len + sizeof(struct ss_msg_s);
			}
			/* ALWAYS run this check just in case we got the whole message
			 * in one pass.
			 */
			if (bytes_read == expected) {
				break;
			}
		} else {
			break;
		}
	}
	assert(bytes_read == expected);
	
	CFDataRef replyData = CFDataCreate(NULL, msg->_bytes, msg->_len);
	assert(replyData != NULL);

	// Boolean CFEqual(CFTypeRef cf1, CFTypeRef cf2);
	CFDataRef successRef = CFDataCreate(NULL, (unsigned char *)"Success", 7);;
	bool result = CFEqual(successRef, replyData);
	
	CFRelease(replyData);
	CFRelease(successRef);
	
	return result;
}

- (IBAction)installKext:(id)sender
{
	NSLog(@"installKext");
	NSError *error = nil;
	if (![self blessHelperWithLabel:@"com.davidgwilson.iBuddyHelper" error:&error]) {
		NSLog(@"Something went wrong with installation of Privileged Helper! %@ %ld %@", [error domain], [error code], [error userInfo]);
		NSRunAlertPanel(@"iBuddy", 
						@"Installation of Privileged Helper has not worked. See console.log for further details - maybe.", nil, nil, nil);
	} 
	else 
	{
		/* At this point, the job is available. However, this is a very
		 * simple sample, and there is no IPC infrastructure set up to
		 * make it launch-on-demand. You would normally achieve this by
		 * using a Sockets or MachServices dictionary in your launchd.plist.
		 */
		NSLog(@"Helper is available!");
		
		[self->_textField setHidden:false];
		
		// launchctl load -wF /Library/LaunchDaemons/com.davidgwilson.iBuddy.Helper
		
		char  plistDestPath[PATH_MAX] = "/Library/LaunchDaemons/com.davidgwilson.iBuddyHelper.plist";
		
		// Stop the helper tool if it's currently running.
		(void) RunLaunchCtl(FALSE, "unload", plistDestPath);

		// Use launchctl to load our job.  The plist file starts out disabled, 
		// so we pass "-w" to enable it permanently.
		int err = RunLaunchCtl(TRUE, "load", plistDestPath);
		
		NSLog(@"Launch status = %d", err);
		
		if (err == 0)
		{
			int sfd = client_connect();
			assert(sfd != -1);
			
			NSLog(@"Connection established... sending request...");

			NSString * pathForShellCommand = [[NSBundle mainBundle] pathForResource:@"iBuddyKextUtility" ofType:@"sh" inDirectory:nil];

			NSString * pathForKext = [[NSBundle mainBundle] pathForResource:@"iBuddy_Driver" ofType:@"kext" inDirectory:nil];
			NSLog(@"And the Kext is loacted at: %@", pathForKext);

			NSLog(@"Setup request to pass to helper -install");
			// <pathForShellCommand> -install <pathtokext>
			
			NSMutableString * sendString = [[NSMutableString alloc] initWithFormat:@"-install "];
			[sendString appendFormat:@"\\%@", pathForShellCommand];
			[sendString appendFormat:@"\\%@\\", pathForKext];	// filename is wrapped with quotes

			CFDataRef sendDataRef = (CFDataRef)[sendString dataUsingEncoding:NSASCIIStringEncoding];
			assert(client_send_command(sfd, sendDataRef));
			
			[sendString release];
			
			NSRunAlertPanel(@"iBuddy", 
							@"Kext installation to /System/Library/Extensions/iBuddy_Driver.kext has completed.\n\nYou can validate this by checking the output in the system.log file (run the Console program in the utilities folder).\n\nYou WILL need to disconnect and reconnect iBuddy now for it to work.", nil, nil, nil);
			
		}
	}
	
}


- (IBAction)removeKext:(id)sender
{
	NSLog(@"removeKext");
	NSError *error = nil;
	if (![self blessHelperWithLabel:@"com.davidgwilson.iBuddyHelper" error:&error]) {
		NSLog(@"Something went wrong with installation of Privileged Helper! %@ %ld %@", [error domain], [error code], [error userInfo]);
		NSRunAlertPanel(@"iBuddy", 
						@"Installation of Privileged Helper has not worked. See console.log for further details - maybe.", nil, nil, nil);
	} 
	else 
	{
		/* At this point, the job is available. However, this is a very
		 * simple sample, and there is no IPC infrastructure set up to
		 * make it launch-on-demand. You would normally achieve this by
		 * using a Sockets or MachServices dictionary in your launchd.plist.
		 */
		NSLog(@"Helper is available!");
		
		[self->_textField setHidden:false];
		
		// launchctl load -wF /Library/LaunchDaemons/com.davidgwilson.iBuddy.Helper
		
		char  plistDestPath[PATH_MAX] = "/Library/LaunchDaemons/com.davidgwilson.iBuddyHelper.plist";
		
		// Stop the helper tool if it's currently running.
		(void) RunLaunchCtl(FALSE, "unload", plistDestPath);
		
		// Use launchctl to load our job.  The plist file starts out disabled, 
		// so we pass "-w" to enable it permanently.
		int err = RunLaunchCtl(TRUE, "load", plistDestPath);
		
		NSLog(@"Launch status = %d", err);
		
		if (err == 0)
		{
			int sfd = client_connect();
			assert(sfd != -1);
			
			NSLog(@"Connection established... sending request...");
			
			NSString * pathForShellCommand = [[NSBundle mainBundle] pathForResource:@"iBuddyKextUtility" ofType:@"sh" inDirectory:nil];
			
			NSLog(@"Setup request to pass to helper -remove");
			// <pathForShellCommand> -install <pathtokext>
			
			NSMutableString * sendString = [[NSMutableString alloc] initWithFormat:@"-remove %@", pathForShellCommand];
			
			CFDataRef sendDataRef = (CFDataRef)[sendString dataUsingEncoding:NSASCIIStringEncoding];
			assert(client_send_command(sfd, sendDataRef));
			
			[sendString release];
			NSRunAlertPanel(@"iBuddy", 
							@"Kext removal from /System/Library/Extensions/iBuddy_Driver.kext has completed.\n\nYou can validate this by checking the output in the system.log file (run the Console program in the utilities folder).", nil, nil, nil);
			
		}
	}

}

- (IBAction)installCommandLineTool:(id)sender
{
	NSLog(@"installCommandLineTool");
	NSError *error = nil;
	if (![self blessHelperWithLabel:@"com.davidgwilson.iBuddyHelper" error:&error]) {
		NSLog(@"Something went wrong with installation of Privileged Helper! %@ %ld %@", [error domain], [error code], [error userInfo]);
		NSRunAlertPanel(@"iBuddy", 
						@"Installation of Privileged Helper has not worked. See console.log for further details - maybe.", nil, nil, nil);
	} 
	else 
	{
		/* At this point, the job is available. However, this is a very
		 * simple sample, and there is no IPC infrastructure set up to
		 * make it launch-on-demand. You would normally achieve this by
		 * using a Sockets or MachServices dictionary in your launchd.plist.
		 */
		NSLog(@"Helper is available!");
		
		[self->_textField setHidden:false];
		
		// launchctl load -wF /Library/LaunchDaemons/com.davidgwilson.iBuddy.Helper
		
		char  plistDestPath[PATH_MAX] = "/Library/LaunchDaemons/com.davidgwilson.iBuddyHelper.plist";
		
		// Stop the helper tool if it's currently running.
		(void) RunLaunchCtl(FALSE, "unload", plistDestPath);
		
		// Use launchctl to load our job.  The plist file starts out disabled, 
		// so we pass "-w" to enable it permanently.
		int err = RunLaunchCtl(TRUE, "load", plistDestPath);
		
		NSLog(@"Launch status = %d", err);
		
		if (err == 0)
		{
			int sfd = client_connect();
			assert(sfd != -1);
			
			NSLog(@"Connection established... sending request...");
			
			NSString * pathForShellCommand = [[NSBundle mainBundle] pathForResource:@"iBuddyCmdUtility" ofType:@"sh" inDirectory:nil];
			NSLog(@"And the iBuddyCmdUtility is loacted at: %@", pathForShellCommand);
			
			NSString * pathForCmd = [[NSBundle mainBundle] pathForResource:@"iBuddycmd" ofType:nil inDirectory:nil];
			NSLog(@"And the iBuddycmd is loacted at: %@", pathForCmd);
			
			NSLog(@"Setup request to pass to helper -cmdInstall");
			// <pathForShellCommand> -install <pathtokext>
			
			NSMutableString * sendString = [[NSMutableString alloc] initWithFormat:@"-cmdInstall "];
			[sendString appendFormat:@"\\%@", pathForShellCommand];
			[sendString appendFormat:@"\\%@\\", pathForCmd];
			
			CFDataRef sendDataRef = (CFDataRef)[sendString dataUsingEncoding:NSASCIIStringEncoding];
			assert(client_send_command(sfd, sendDataRef));
			
			[sendString release];
			
			NSRunAlertPanel(@"iBuddy", 
							@"iBuddycmd installation to /usr/local/bin has completed.\n\nYou can validate this by checking the output in the system.log file (run the Console program in the utilities folder).\n\nYou WILL need to disconnect and reconnect iBuddy now for it to work.\n\nFor the utility to work - this GUI Application must be quit.", nil, nil, nil);
			
		}
	}
	
}


- (IBAction)removeCommandLineTool:(id)sender
{
	NSLog(@"removeCommandLineTool");
	NSError *error = nil;
	if (![self blessHelperWithLabel:@"com.davidgwilson.iBuddyHelper" error:&error]) {
		NSLog(@"Something went wrong with installation of Privileged Helper! %@ %ld %@", [error domain], [error code], [error userInfo]);
		NSRunAlertPanel(@"iBuddy", 
						@"Installation of Privileged Helper has not worked. See console.log for further details - maybe.", nil, nil, nil);
	} 
	else 
	{
		/* At this point, the job is available. However, this is a very
		 * simple sample, and there is no IPC infrastructure set up to
		 * make it launch-on-demand. You would normally achieve this by
		 * using a Sockets or MachServices dictionary in your launchd.plist.
		 */
		NSLog(@"Helper is available!");
		
		[self->_textField setHidden:false];
		
		// launchctl load -wF /Library/LaunchDaemons/com.davidgwilson.iBuddy.Helper
		
		char  plistDestPath[PATH_MAX] = "/Library/LaunchDaemons/com.davidgwilson.iBuddyHelper.plist";
		
		// Stop the helper tool if it's currently running.
		(void) RunLaunchCtl(FALSE, "unload", plistDestPath);
		
		// Use launchctl to load our job.  The plist file starts out disabled, 
		// so we pass "-w" to enable it permanently.
		int err = RunLaunchCtl(TRUE, "load", plistDestPath);
		
		NSLog(@"Launch status = %d", err);
		
		if (err == 0)
		{
			int sfd = client_connect();
			assert(sfd != -1);
			
			NSLog(@"Connection established... sending request...");
			
			NSString * pathForShellCommand = [[NSBundle mainBundle] pathForResource:@"iBuddyCmdUtility" ofType:@"sh" inDirectory:nil];
			NSLog(@"And the iBuddyCmdUtility is loacted at: %@", pathForShellCommand);
			
			NSLog(@"Setup request to pass to helper -cmdRemove");
			// <pathForShellCommand> -install <pathtokext>
			
			NSMutableString * sendString = [[NSMutableString alloc] initWithFormat:@"-cmdRemove %@", pathForShellCommand];
			
			CFDataRef sendDataRef = (CFDataRef)[sendString dataUsingEncoding:NSASCIIStringEncoding];
			assert(client_send_command(sfd, sendDataRef));
			
			[sendString release];
			NSRunAlertPanel(@"iBuddy", 
							@"iBuddycmd removal from /usr/local/bin has completed.\n\nYou can validate this by checking the output in the system.log file (run the Console program in the utilities folder).", nil, nil, nil);
			
		}
	}
	
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error;
{
	BOOL result = NO;
	
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				| 
	kAuthorizationFlagInteractionAllowed	|
	kAuthorizationFlagPreAuthorize			|
	kAuthorizationFlagExtendRights;
	
	authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
	if (status != errAuthorizationSuccess) {
		NSLog(@"Failed to create AuthorizationRef, return code %i", status);
	} else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, (CFErrorRef *)error);
	}
	
	return result;
}

#pragma mark -
#pragma Screen Updates

- (void)usbConnect:(NSNotification *)theNotification
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
	deviceConnected = TRUE;
	[self updateScreen];
}
- (void)usbDisConnect:(NSNotification *)theNotification
{
	deviceConnected = FALSE;
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self updateScreen];
}
- (void)usbError:(NSNotification *)theNotification
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self updateScreen];
}

- (void)updateScreen
{	
	NSLog(@"%@", NSStringFromSelector(_cmd));
	
	if (deviceConnected)
	{	
		[onScreenConnected setFloatValue:1];
		[onScreenConnected display];
	}
	else
	{	
		[onScreenConnected setFloatValue:0];
		[onScreenConnected display];
	}
	
	return;
}

@end
