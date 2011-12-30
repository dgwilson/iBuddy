////
////  KeepMeForNow.m
////  iBuddy
////
////  Created by David Wilson on 24/09/11.
////  Copyright 2011 David G. WIlson. All rights reserved.
////
//
//#import "KeepMeForNow.h"
//
//@implementation KeepMeForNow
//
//- (void)setUp
//{
//    [super setUp];
//    
//    // Set-up code here.
//}
//
//- (void)tearDown
//{
//    // Tear-down code here.
//    
//    [super tearDown];
//}
//
//
//extern char **environ;
//
//static int RunLaunchCtl(
//						bool						junkStdIO, 
//						const char					*command, 
//						const char					*plistPath
//						)
//// Handles all the invocations of launchctl by doing the fork() + execve()
//// for proper clean-up. Only two commands are really supported by our
//// implementation; loading and unloading of a job via the plist pointed at 
//// (const char *) plistPath.
//{	
//	int				err;
//	const char *	args[5];
//	pid_t			childPID;
//	pid_t			waitResult;
//	int				status;
//	
//	// Pre-conditions.
//	assert(command != NULL);
//	assert(plistPath != NULL);
//	
//    // Make sure we get sensible logging even if we never get to the waitpid.
//    
//    status = 0;
//    
//    // Set up the launchctl arguments.  We run launchctl using StartupItemContext 
//	// because, in future system software, launchctl may decide on the launchd 
//	// to talk to based on your Mach bootstrap namespace rather than your RUID.
//    
//	args[0] = "/bin/launchctl";
//	args[1] = command;				// "load" or "unload"
//	args[2] = "-wF";
//	args[3] = plistPath;			// path to plist
//	args[4] = NULL;
//	
//    fprintf(stderr, "launchctl %s %s '%s'\n", args[1], args[2], args[3]);
//	
//    // Do the standard fork/exec dance.
//    
//	childPID = fork();
//	switch (childPID) {
//		case 0:
//			// child
//			err = 0;
//            
//            // If we've been told to junk the I/O for launchctl, open 
//            // /dev/null and dup that down to stdin, stdout, and stderr.
//            
//			if (junkStdIO) {
//				int		fd;
//				int		err2;
//				
//				fd = open("/dev/null", O_RDWR);
//				if (fd < 0) {
//					err = errno;
//				}
//				if (err == 0) {
//					if ( dup2(fd, STDIN_FILENO) < 0 ) {
//						err = errno;
//					}
//				}
//				if (err == 0) {
//					if ( dup2(fd, STDOUT_FILENO) < 0 ) {
//						err = errno;
//					}
//				}
//				if (err == 0) {
//					if ( dup2(fd, STDERR_FILENO) < 0 ) {
//						err = errno;
//					}
//				}
//				err2 = close(fd);
//				if (err2 < 0) {
//					err2 = 0;
//				}
//				if (err == 0) {
//					err = err2;
//				}
//			}
//			if (err == 0) {
//				err = execve(args[0], (char **) args, environ);
//				fprintf(stderr, "execve");
//			}
//			if (err < 0) {
//				err = errno;
//			}
//			_exit(EXIT_FAILURE);
//			break;
//		case -1:
//			err = errno;
//			break;
//		default:
//			err = 0;
//			break;
//	}
//	
//    // Only the parent gets here.  Wait for the child to complete and get its 
//    // exit status.
//	
//	if (err == 0) {
//		do {
//			waitResult = waitpid(childPID, &status, 0);
//		} while ( (waitResult == -1) && (errno == EINTR) );
//		
//		if (waitResult < 0) {
//			err = errno;
//		} else {
//			assert(waitResult == childPID);
//			
//            if ( ! WIFEXITED(status) || (WEXITSTATUS(status) != 0) ) {
//                err = EINVAL;
//            }
//		}
//	}
//	
//    fprintf(stderr, "launchctl -> %d %ld 0x%x\n", err, (long) childPID, status);
//	
//	return err;
//}
//
//- (IBAction)installKext:(id)sender
//{
//	NSError *error = nil;
//	if (![self blessHelperWithLabel:@"com.davidgwilson.iBuddy.Helper" error:&error]) {
//		NSLog(@"Something went wrong!");
//	} 
//	else 
//	{
//		/* At this point, the job is available. However, this is a very
//		 * simple sample, and there is no IPC infrastructure set up to
//		 * make it launch-on-demand. You would normally achieve this by
//		 * using a Sockets or MachServices dictionary in your launchd.plist.
//		 */
//		NSLog(@"Job is available!");
//		
//		[self->_textField setHidden:false];
//		
//		// launchctl load -wF /Library/LaunchDaemons/com.davidgwilson.iBuddy.Helper
//		
//		char		plistDestPath[PATH_MAX] = "/Library/LaunchDaemons/com.davidgwilson.iBuddy.Helper.plist";
//		// Stop the helper tool if it's currently running.
//		(void) RunLaunchCtl(false, "unload", plistDestPath);
//		
//		(void) RunLaunchCtl(false, "load", plistDestPath);
//		
//		//		NSString * pathForKext = [[NSBundle mainBundle] pathForResource:@"iBuddy_Driver" ofType:@"kext" inDirectory:nil];
//		//		//char helper[PATH_MAX + 1] = "/Library/PrivilegedHelperTools/com.davidgwilson.iBuddy.Helper";
//		//		//char helper[PATH_MAX + 1] = "/Library/LaunchDeamons/com.davidgwilson.iBuddy.Helper.plist";
//		//		char helper[PATH_MAX + 1] = "com.davidgwilson.iBuddy.Helper";
//		//		const char *_appParam1 = "-kext install";
//		//		const char *_appParam2 = [pathForKext UTF8String];
//		//		
//		//		const char *_argv[] = {
//		//			helper,
//		//			_appParam1,
//		//			_appParam2,
//		//			NULL,
//		//		};
//		//		
//		//		pid_t pid = 0;
//		//		(void)posix_spawn(&pid, helper, NULL, NULL, (char * const *)_argv, NULL);
//		
//	}
//}
//
//- (IBAction)removeKext:(id)sender
//{	
//	NSError *error = nil;
//	if (![self blessHelperWithLabel:@"com.davidgwilson.iBuddy.Helper" error:&error]) {
//		NSLog(@"Something went wrong!");
//	} 
//	else 
//	{
//		/* At this point, the job is available. However, this is a very
//		 * simple sample, and there is no IPC infrastructure set up to
//		 * make it launch-on-demand. You would normally achieve this by
//		 * using a Sockets or MachServices dictionary in your launchd.plist.
//		 */
//		NSLog(@"Job is available!");
//		
//		[self->_textField setHidden:false];
//		
//		
//		//char helper[PATH_MAX + 1] = "/Library/PrivilegedHelperTools/com.davidgwilson.iBuddy.Helper";
//		//char helper[PATH_MAX + 1] = "/Library/LaunchDeamons/com.davidgwilson.iBuddy.Helper.plist";
//		char helper[PATH_MAX + 1] = "com.davidgwilson.iBuddy.Helper";
//		const char *_appParam1 = "-kext remove";
//		
//		const char *_argv[] = {
//			helper,
//			_appParam1,
//			NULL,
//		};
//		
//		pid_t pid = 0;
//		(void)posix_spawn(&pid, helper, NULL, NULL, (char * const *)_argv, NULL);
//		
//	}
//}
//
////	NSString *pathForKext = [[NSBundle mainBundle] pathForResource:@"iBuddy_Driver" ofType:@"kext" inDirectory:nil];
////	NSLog(@"pathForKext = %@", pathForKext);
////	if ((pathForKext != nil) && ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:pathForKext]))
////	{
////		//			ditto ...bundle.../iBuddy_Driver.kext /System/Library/Extensions
////		//			chmod -R 755 /System/Library/Extensions/IOATAFamily.kext
////		//			sudo chown -R root:wheel /System/Library/Extensions/IOATAFamily.kext
////		
////		
////		const char * driverPath = [pathForKext UTF8String];
////		AuthorizationRef authorizationRef;
////		FILE *pipe = NULL;
////		OSStatus err = AuthorizationCreate(nil,
////										   kAuthorizationEmptyEnvironment,
////										   kAuthorizationFlagDefaults,
////										   &authorizationRef);
////		{
////			NSLog(@"iBuddy: kext unload - just in case");
////			char *command= "/sbin/kextunload";
////			char *args[] = {"/System/Library/Extensions/iBuddy_Driver.kext", nil};
////			err = AuthorizationExecuteWithPrivileges(authorizationRef,
////													 command,
////													 kAuthorizationFlagDefaults,
////													 args,
////													 &pipe); 
////		}
////		{
////			NSLog(@"iBuddy: copy kext");
////			char *command= "/usr/bin/ditto";
////			char *args[] = {"-V", (char *)driverPath, "/System/Library/Extensions/iBuddy_Driver.kext", nil};
////			err = AuthorizationExecuteWithPrivileges(authorizationRef,
////													 command,
////													 kAuthorizationFlagDefaults,
////													 args,
////													 &pipe); 
////		}
////		
////		{
////			NSLog(@"iBuddy: chmod kext");
////			char *command= "/bin/chmod";
////			char *args[] = {"-R", "755", "/System/Library/Extensions/iBuddy_Driver.kext", nil};
////			err = AuthorizationExecuteWithPrivileges(authorizationRef,
////													 command,
////													 kAuthorizationFlagDefaults,
////													 args,
////													 &pipe); 
////		}
////		
////		{
////			NSLog(@"iBuddy: kext load");
////			char *command= "/sbin/kextload";
////			char *args[] = {"/System/Library/Extensions/iBuddy_Driver.kext", nil};
////			err = AuthorizationExecuteWithPrivileges(authorizationRef,
////													 command,
////													 kAuthorizationFlagDefaults,
////													 args,
////													 &pipe); 
////		}
////		NSLog(@"iBuddy: kext installation complete.");
////	}	
//
//
//- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error;
//{
//	BOOL result = NO;
//	
//	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
//	AuthorizationRights authRights	= { 1, &authItem };
//	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				| 
//	kAuthorizationFlagInteractionAllowed	|
//	kAuthorizationFlagPreAuthorize			|
//	kAuthorizationFlagExtendRights;
//	
//	authRef = NULL;
//	
//	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
//	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
//	if (status != errAuthorizationSuccess) {
//		NSLog(@"Failed to create AuthorizationRef, return code %i", status);
//	} else {
//		/* This does all the work of verifying the helper tool against the application
//		 * and vice-versa. Once verification has passed, the embedded launchd.plist
//		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
//		 * executable is placed in /Library/PrivilegedHelperTools.
//		 */
//		result = SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, (CFErrorRef *)error);
//	}
//	
//	return result;
//}
//
//@end
