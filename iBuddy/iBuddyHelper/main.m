//
//  main.m
//  iBuddyHelper
//
//  Created by David Wilson on 18/09/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//
//  Credit to:
// File: ssd.c
// Abstract: Implementation of a launch-on-demand server.
// Version: 1.1



#include <launch.h>
#include <libkern/OSAtomic.h>
#include <vproc.h>
#include "shared.h"

#include <mach-o/dyld.h>
#include <spawn.h>

#pragma mark - Declarations

static bool g_is_managed = false;
static bool g_accepting_requests = true;
static dispatch_source_t g_timer_source = NULL;

/* OSAtomic*() requires signed quantities. */
static int32_t g_transaction_count = 0;


int server_check_in(void);
vproc_transaction_t server_open_transaction(void);
void server_close_transaction(vproc_transaction_t vt);
void server_send_reply(int fd, dispatch_queue_t q, CFDataRef data, vproc_transaction_t vt);
void server_handle_request(int fd, const void *buff, size_t total, vproc_transaction_t vt);
bool server_read(int fd, unsigned char *buff, size_t buff_sz, size_t *total);
void server_accept(int fd, dispatch_queue_t q);
static void server_shutdown(void *unused);


// http://qc-dev.blogspot.com/
// Even though it is tempting, I recommend against putting an additional copy of the executable into the Contents/MacOSX folder. While doing so would let you use the CFBundleCopyAuxiliaryExecutableURL API to create a URL to the helper executable, it increases the size of your bundle, which is a bigger problem than finagling the helper executable's URL on 10.5.
// Instead, I recommend appending the Contents/Library/LaunchServices/HelperTool path to the URL obtained from CFBundleCopyBundleURL(CFBundleGetMainbundle()).


#pragma mark - Main Body

int server_check_in(void)
{
	//	printf("iBuddyHelper: server_check_in\n");
	int sockfd = -1;
	
	/* If we're running under a production scenario, then we check in with
	 * launchd to get our socket file descriptors.
	 */
	launch_data_t req = launch_data_new_string(LAUNCH_KEY_CHECKIN);
	assert(req != NULL);
	
	launch_data_t resp = launch_msg(req);
	assert(resp != NULL);
	assert(launch_data_get_type(resp) == LAUNCH_DATA_DICTIONARY);
	
	launch_data_t sockets = launch_data_dict_lookup(resp, LAUNCH_JOBKEY_SOCKETS);
	assert(sockets != NULL);
	assert(launch_data_get_type(sockets) == LAUNCH_DATA_DICTIONARY);
	
	launch_data_t sarr = launch_data_dict_lookup(sockets, "com.davidgwilson.iBuddyHelper.sock");
	assert(sarr != NULL);
	assert(launch_data_get_type(sarr) == LAUNCH_DATA_ARRAY);
	
//	size_t count = launch_data_array_get_count( sarr );
	
	launch_data_t socketID = launch_data_array_get_index( sarr, 0 );
	
	sockfd = launch_data_get_fd(socketID);
	
	//	printf("iBuddyHelper: sockfd: %d\n", sockfd );
	
	return sockfd;
}

vproc_transaction_t server_open_transaction(void)
{
	/* Atomically increment our count of outstanding requests. Even though
	 * this happens serially, remember that requests themselves are handled
	 * concurrently on GCD's default priority queue. So when the requests are
	 * closed out, it can happen asynchronously with respect to this section
	 * Thus, any manipulation of the transaction counter needs to be guarded.
	 */
	if (OSAtomicIncrement32(&g_transaction_count) - 1 == 0) {
		dispatch_source_set_timer(g_timer_source, DISPATCH_TIME_FOREVER, 0llu, 0llu);
	}
	
	/* Open a new transaction. This tells Instant Off that we are "dirty" and
	 * should not be sent SIGKILL if the time comes to shut the system down.
	 * Instead, we will be sent SIGTERM.
	 */
	return vproc_transaction_begin(NULL);
}

void server_close_transaction(vproc_transaction_t vt)
{
	if (OSAtomicDecrement32(&g_transaction_count) == 0) {
		dispatch_time_t t0 = dispatch_time(DISPATCH_TIME_NOW, 20llu * NSEC_PER_SEC);
		dispatch_source_set_timer(g_timer_source, t0, 0llu, 0llu);
	}
	vproc_transaction_end(NULL, vt);
}

void server_send_reply(int fd, dispatch_queue_t q, CFDataRef data, vproc_transaction_t vt)
{
//	printf("server_send_reply...\n");
	size_t total = sizeof(struct ss_msg_s) + CFDataGetLength(data);
	
	unsigned char *buff = (unsigned char *)malloc(total);
	assert(buff != NULL);
	
	struct ss_msg_s *msg = (struct ss_msg_s *)buff;
	msg->_len = OSSwapHostToLittleInt32(total - sizeof(struct ss_msg_s));
	
	/* Coming up with a more efficient implementation is left as an exercise to
	 * the reader.
	 */
	
	(void)memcpy(msg->_bytes, CFDataGetBytePtr(data), CFDataGetLength(data));
	
	dispatch_source_t s = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, fd, 0, q);
	assert(s != NULL);
	
	__block unsigned char *track_buff = buff;
	__block size_t track_sz = total;
	dispatch_source_set_event_handler(s, ^(void) {
		ssize_t nbytes = write(fd, track_buff, track_sz);
		if (nbytes != -1) {
			track_buff += nbytes;
			track_sz -= nbytes;
			
			if (track_sz == 0) {
				dispatch_source_cancel(s);
			}
		}
	});
	
	dispatch_source_set_cancel_handler(s, ^(void) {
		/* We're officially done with this request, so close out the connection
		 * and free the resources ass_ociated with it.
		 */
		(void)close(fd);
		free(buff);
		dispatch_release(s);
		
		server_close_transaction(vt);
	});
	dispatch_resume(s);
}

void server_handle_request(int fd, const void *buff, size_t total, vproc_transaction_t vt)
{
//	printf("server_handle_request\n");
//    CFDataRef data = CFDataCreateWithBytesNoCopy(NULL, buff, total, kCFAllocatorNull);
//	assert(data != NULL);
//	
//    CFPropertyListRef plist = CFPropertyListCreateWithData(NULL, data, kCFPropertyListImmutable, NULL, NULL);
//	assert(plist != NULL);
	
    /* Handle request, create reply (of a property list type). In this case,
	 * we'll just blurt the request back to the client. But feel free to do
	 * something interesting here. Remember, this section is being run on the
	 * default-priority concurrent queue, so make sure the work for various
	 * clients can be done in parallel. If not, then you should consider
	 * creating your own serial queue.
	 */
	
	int err = 0;
	
	// input parameter is setup thus:
	// -install <pathtokext>
	// -remove
	
	// -cmdInstall <pathtoutility>
	// - cmdRemove
	
	
	// char *strtok(const char *s1, const char *s2);
	
	char *buffChar;
	buffChar = (char *)buff;
	
	const char *cmd = strtok(buffChar, " ");
	printf("iBuddyHelper cmd=%s\n", cmd);

	if (strcmp("-install", cmd) == 0)
	{
		printf("iBuddyHelper: kext INSTALL has been requested:\n");

		// lets get the shell script we're going to run
		char * const shellScript = strtok ( NULL, "\\");
		printf("iBuddyHelper: shellScript=%s\n", shellScript);
		if (strlen(shellScript) == 0)
			err = 1;
		
		// lets get the path to the kext file
		char * const driverPath = strtok ( NULL, "\\");
		printf("iBuddyHelper: driverPath=%s\n", driverPath);
		if (strlen(driverPath) == 0)
			err = 1;
		
		if (err == 0)
		{		
			printf("iBuddyHelper: execute shell script\n");
			char * const param0[] = {shellScript, "-install", driverPath, nil};
			pid_t pid0 = 0;
			(void)posix_spawn(&pid0, shellScript, NULL, NULL, param0, NULL);
			
//			int	posix_spawn(pid_t * __restrict, const char * __restrict,
//							const posix_spawn_file_actions_t *,
//							const posix_spawnattr_t * __restrict,
//							char *const __argv[ __restrict],
//							char *const __envp[ __restrict]) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
			
			// Bollocksey stuff below don't bloody work. work around to get shell script to perform the work
//			printf("iBuddyHelper: kext unload\n");
//			char app0[PATH_MAX + 1] = "/sbin/kextunload";
//			const char *param0[] = {"kextunload", "/System/Library/Extensions/iBuddy_Driver.kext", nil};
//			pid_t pid0 = 0;
//			(void)posix_spawn(&pid0, app0, NULL, NULL, (char * const *)param0, NULL);
//			sleep(2);
//			
//			printf("iBuddyHelper: copy kext\n");
//			char app1[PATH_MAX + 1] = "/usr/bin/ditto";
//			char * const _argv1[] = {"ditto", "-V", (char *)driverPath, "\"/System/Library/Extensions/iBuddy_Driver.kext\"", nil};
//			pid_t pid1 = 0;
//			(void)posix_spawn(&pid1, app1, NULL, NULL, (char * const *)_argv1, NULL);
//			sleep(2);
//			
//			printf("iBuddyHelper: chown kext\n");
//			char app3[PATH_MAX + 1] = "/usr/sbin/chown";
//			//			const char *param3[] = {"-Rv", "root:wheel", "/System/Library/Extensions/iBuddy_Driver.kext/", nil};
//			char * const param3[] = {"chown", "-Rv", "root:wheel", "\"/System/Library/Extensions/iBuddy_Driver.kext/\"", nil};
//			pid_t pid3 = 0;
//			(void)posix_spawn(&pid3, app3, NULL, NULL, (char * const *)param3, NULL);
//			sleep(2);
//
//			printf("iBuddyHelper: chmod kext\n");
//			char app2[PATH_MAX + 1] = "/bin/chmod";
//			char * const param2[] = {"chmod", "-R", "755", "\"/System/Library/Extensions/iBuddy_Driver.kext/\"", nil};
//			pid_t pid2 = 0;
//			(void)posix_spawn(&pid2, app2, NULL, NULL, (char * const *)param2, NULL);
//			sleep(2);
//			
//			printf("iBuddyHelper: kextload\n");
//			char app4[PATH_MAX + 1] = "/sbin/kextload";
//			char * const param4[] = {"kextload", "/System/Library/Extensions/iBuddy_Driver.kext", nil};
//			pid_t pid4 = 0;
//			(void)posix_spawn(&pid4, app4, NULL, NULL, (char * const *)param4, NULL);
//			sleep(2);
		}
	} 
	else if (strcmp("-remove", cmd) == 0)
	{

		printf("iBuddyHelper: kext REMOVAL has been requested:\n");
		
		// lets get the shell script we're going to run
		char * const shellScript = strtok ( NULL, " ");
		printf("iBuddyHelper: shellScript=%s\n", shellScript);
		if (strlen(shellScript) == 0)
			err = 1;
				
		if (err == 0)
		{		
			printf("iBuddyHelper: execute shell script\n");
			char * const param0[] = {shellScript, "-remove", nil};
			pid_t pid0 = 0;
			(void)posix_spawn(&pid0, shellScript, NULL, NULL, param0, NULL);
		}
		
//		printf("iBuddyHelper: kext unload\n");
//		char app0[PATH_MAX + 1] = "/sbin/kextunload";
//		const char *param0[] = {"kextunload", "/System/Library/Extensions/iBuddy_Driver.kext", nil};
//		pid_t pid0 = 0;
//		(void)posix_spawn(&pid0, app0, NULL, NULL, (char * const *)param0, NULL);
//
//		printf("iBuddyHelper: remove kext\n");
//		char app1[PATH_MAX + 1] = "/bin/rm";
//		const char *param1[] = {"rm", "-R", "/System/Library/Extensions/iBuddy_Driver.kext", nil};
//		pid_t pid1 = 0;
//		(void)posix_spawn(&pid1, app1, NULL, NULL, (char * const *)param1, NULL);
		
	} else if (strcmp("-cmdInstall", cmd) == 0)
	{
		printf("iBuddyHelper: iBuddycmd INSTALL has been requested:\n");
		
		// lets get the shell script we're going to run
		char * const shellScript = strtok ( NULL, "\\"); // the \ has been specially inserted into the command line to mark the end of the file name as the file names may have spaces in them`
		printf("iBuddyHelper: shellScript=%s\n", shellScript);
		if (strlen(shellScript) == 0)
			err = 1;
		
		// lets get the path to the kext file
		char * const driverPath = strtok ( NULL, "\\");
		printf("iBuddyHelper: driverPath=%s\n", driverPath);
		if (strlen(driverPath) == 0)
			err = 1;
		
		if (err == 0)
		{		
			printf("iBuddyHelper: execute shell script\n");
			char * const param0[] = {shellScript, "-install", driverPath, nil};
			pid_t pid0 = 0;
			(void)posix_spawn(&pid0, shellScript, NULL, NULL, param0, NULL);
		}
	} 
	else if (strcmp("-cmdRemove", cmd) == 0)
	{
		
		printf("iBuddyHelper: iBuddycmd REMOVAL has been requested:\n");
		
		// lets get the shell script we're going to run
		char * const shellScript = strtok ( NULL, " ");
		printf("iBuddyHelper: shellScript=%s\n", shellScript);
		if (strlen(shellScript) == 0)
			err = 1;
		
		if (err == 0)
		{		
			printf("iBuddyHelper: execute shell script\n");
			char * const param0[] = {shellScript, "-remove", nil};
			pid_t pid0 = 0;
			(void)posix_spawn(&pid0, shellScript, NULL, NULL, param0, NULL);
		}
				
	} else {

		printf("iBuddyHelper: no valid commands received\n");

	}
	
	
	
	/*
	 *
	 *
	 *
	 */

//	size_t space = 512;
//	unsigned char *replyMsg = (unsigned char *)malloc(space);
//	(void)memcpy(replyMsg, "Success", 7);
//	CFIndex length = OSSwapHostToLittleInt32(CFDataGetLength(replyMsg));
	
	CFDataRef replyData;
	
	if (err == 0)
	{
		// all done, no errors
		replyData = CFDataCreate(NULL, (unsigned char *)"Success", 7);
	} else
	{
		// return with error
		replyData = CFDataCreate(NULL, (unsigned char *)"Errors", 6);
	}
	
//    CFDataRef replyData = CFPropertyListCreateData(NULL, (CFPropertyListRef)plist, kCFPropertyListBinaryFormat_v1_0, 0, NULL);
//	assert(replyData != NULL);
//	
//    CFRelease(data);
//    CFRelease(plist);
	
    server_send_reply(fd, dispatch_get_current_queue(), replyData, vt);
	
	/* ss_send_reply() copies the data from replyData out, so we can safely
	 * release it here. But remember, that's an inefficient design.
	 */
	CFRelease(replyData);
}

bool server_read(int fd, unsigned char *buff, size_t buff_sz, size_t *total)
{
	//	printf("server_read...\n");
	bool result = false;
	
	struct ss_msg_s *msg = (struct ss_msg_s *)buff;
	
	unsigned char *track_buff = buff + *total;
	size_t track_sz = buff_sz - *total;
	ssize_t nbytes = read(fd, track_buff, track_sz);
	//	printf("iBuddyHelper: readbytes=%ld size of ss_msg_s=%lu total=%ld\n", nbytes, sizeof(struct ss_msg_s), *total);
	if (nbytes != -1) {
		/* We do this swap on every read(2), which is wasteful. But there is a
		 * way to avoid doing this every time and not introduce an extra
		 * parameter. See if you can find it.
		 */
		
		*total += nbytes;
		if (*total >= sizeof(struct ss_msg_s)) {
			msg->_len = OSSwapLittleToHostInt32(msg->_len);
			//			printf("iBuddyHelper: msg->_lens=%u\n", msg->_len);
			if (msg->_len == (*total - sizeof(struct ss_msg_s))) {
				result = true;
			}
		}

	}
	//	printf("server_read result=%d\n",result);
	return result;
}

void server_accept(int fd, dispatch_queue_t q)
{
	//	printf("server accept...\n");
	
	/* This variable needs to be mutable in the block. Setting __block will
	 * ensure that, when dispatch_source_set_event_handler(3) copies it to
	 * the heap, this variable will be copied to the heap as well, so it'll
	 * be safely mutable in the block.
	 */
	__block size_t total = 0;
	
	vproc_transaction_t vt = server_open_transaction();
	
	/* For large allocations like this, the VM system will lazily create
	 * the pages, so we won't get the full 10 MB (or anywhere near it) upfront.
	 * A smarter implementation would read the intended mess_age size upfront
	 * into a fixed-size buffer and then allocate the needed space right there.
	 * But if our requests are almost always going to be this small, then we
	 * avoid a potential second trap into the kernel to do the second read(2).
	 * Also, we avoid a second copy-out of the data read.
	 */
	size_t buff_sz = 10 * 1024 * 1024;
	void *buff = malloc(buff_sz);
	assert(buff != NULL);
	
	dispatch_source_t s = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, q);
	assert(s != NULL);
	
	dispatch_source_set_event_handler(s, ^(void) {
		/* You may be asking yourself, "Doesn't the fact that we're on a concurrent
		 * queue mean that multiple event handler blocks could be running
		 * simultaneously for the same source?" The answer is no. Parallelism for
		 * the global concurrent queues is at the source level, not the event
		 * handler level. So for each source, exactly one invocation of the event
		 * handler can be inflight. When scheduling on a concurrent queue, it
		 * means that that handler may be running concurrently with other sources'
		 * event handlers, but not its own.
		 */
		if (server_read(fd, buff, buff_sz, &total)) {
			struct ss_msg_s *msg = (struct ss_msg_s *)buff;
			server_handle_request(fd, msg->_bytes, msg->_len, vt);
			
			/* After handling the request (which, in this case, means that we've
			 * scheduled a source to deliver the reply), we no longer need this
			 * source. So we cancel it.
			 */
			dispatch_source_cancel(s);
		}
	});
	
	dispatch_source_set_cancel_handler(s, ^(void) {
		/* We'll close out the file descriptor after sending the reply, so in the
		 * write source's cancellation handler.
		 */
		dispatch_release(s);
		free(buff);
	});
	dispatch_resume(s);
}

static void server_shutdown(void *unused)
{
	//    log_notice("shutting down");
	printf("iBuddyHelper: main engine stopping - idle timeout.\n");
	//    log_close();
    exit(0);        /* TODO: set non-zero for SIGINT */
}

int main(int argc, const char *argv[])
{
	setlinebuf(stdout);
//	printf("iBuddyHelper:\n");
//	printf("iBuddyHelper: main engine start.\n");
	
	/* An argv[1] of "launchd" indicates that were were launched by launchd.
	 * Note that we ONLY do this check for debugging purposes. There should be no
	 * production scenario where this daemon is not being managed by launchd.
	 */
	// printf("iBuddyHelper: argv[0]=%s \n", argv[0]);
	if (argc > 0 && strcmp(argv[0], "/Library/PrivilegedHelperTools/com.davidgwilson.iBuddyHelper") == 0)
	{
		//		printf("iBuddyHelper: started by launchd  <------ g_is_managed = TRUE;\n");
		g_is_managed = TRUE;
	}
	//	if (argc > 1 && strcmp(argv[1], "launchd") == 0) {
	//	g_is_managed = true;
	//	} else {
		/* When running under a debugging environment, log mess_ages to stderr. */
	//		(void)openlog("iBuddyHelper-debug", LOG_PERROR, 0);
	//	}
	
	/* This daemon handles events serially on the main queue. The events that
	 * are synchronized on the main queue are:
	 * • New connections
	 * • The idle-exit timer
	 * • The SIGTERM handler
	 *
	 * Note that actually handling requests is done concurrently.
	 */
	dispatch_queue_t mq = dispatch_get_main_queue();
	g_timer_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, mq);
	assert(g_timer_source != NULL);
	
	/* When the idle-exit timer fires, we just call exit(2) with status 0. */
	dispatch_set_context(g_timer_source, NULL);
	dispatch_source_set_event_handler_f(g_timer_source, server_shutdown);
	
	/* We start off with our timer armed. This is for the simple reason that,
	 * upon kicking off the GCD state engine, the first thing we'll get to is
	 * a connection on our socket which will disarm the timer. Remember, handling
	 * new connections and the firing of the idle-exit timer are synchronized.
	 */
	dispatch_time_t t0 = dispatch_time(DISPATCH_TIME_NOW, 20llu * NSEC_PER_SEC);
	dispatch_source_set_timer(g_timer_source, t0, 0llu, 0llu);
	dispatch_resume(g_timer_source);
	
	/* We must ignore the default action for SIGTERM so that GCD can safely receive it
	 * and distribute it across all interested parties in the address space.
	 */
	(void)signal(SIGTERM, SIG_IGN);
	
	/* For Instant Off, we handle SIGTERM. Since SIGTERM is Instant Off's way of
	 * saying "Wind down your existing requests, and don't accept any new ones",
	 * we set a global saying to not accept new requests. This source fires
	 * synchronously with respect to the source which monitors for new connections
	 * on our socket, so things will be neatly synchronized. So unless_ it takes
	 * us 20 seconds between now and when we call dispatch_main(3), we'll be okay.
	 */
	dispatch_source_t sts = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, mq);
	assert(sts != NULL);
	
	dispatch_source_set_event_handler(sts, ^(void) {
		/* If we get SIGTERM, that means that the system is on its way out, so
		 * we need to close out our existing requests and stop accepting new
		 * ones. At this point, we know that we have at least one outstanding
		 * request. Had we been clean, we would've received SIGKILL and just
		 * exited.
		 *
		 * Note that by adopting Instant Off, you are opting into a contract
		 * where you assert that launchd is the only entity which can
		 * legitimately send you SIGTERM.
		 */
		g_accepting_requests = false;
	});
	dispatch_resume(sts);
	
	/* Now that we've set all that up, get our socket. */
	int fd = server_check_in();
	
	/* This is REQUIRED for GCD. To understand why, consider the following scenario:
	 * 0. GCD monitors the descriptor for bytes to read.
	 * 1. Bytes appear, so GCD fires off every source interested in whether there
	 *    are bytes on that socket to read.
	 * 2. 1 of N sources fires and consumes all the outstanding bytes on the
	 *    socket by calling read(2).
	 * 3. The other N - 1 sources fire and each attempt a read(2). Since all the
	 *    data has been drained, each of those read(2) calls will block.
	 *
	 * This is highly undesirable. It is important to remember that parking a
	 * queue in an unbounded blocking call will prevent any other source that
	 * fires on that queue from doing so. So whenever poss_ible, we must avoid
	 * unbounded blocking in event handlers.
	 */
	(void)fcntl(fd, F_SETFL, O_NONBLOCK);
	
	/* DISPATCH_SOURCE_TYPE_READ, in this context, means that the source will
	 * fire whenever there is a connection on the socket waiting to be accept(2)ed.
	 * I know what you're thinking after reading the above comment. "Doesn't this
	 * mean that it's safe for this socket to be blocking? The source won't fire
	 * until there is a connection to be accept(2)ed, right?"
	 *
	 * This is true, but it is important to remember that the client on the other
	 * end can cancel its attempt to connect. If the source fires after this has
	 * happened, accept(2) will block. So it is still important to set O_NONBLOCK
	 * on the socket.
	 */
	dispatch_source_t as = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, mq);
	assert(as != NULL);
	
	// http://lists.apple.com/archives/macnetworkprog/2011/Jul/msg00012.html
	
	dispatch_source_set_event_handler(as, ^(void) {

		//		printf("iBuddyHelper: dispatch_source_set_event_handler\n");
		
		struct sockaddr saddr;
		socklen_t slen = 0;
		
		int afd = accept(fd, (struct sockaddr *)&saddr, &slen);
		if (afd != -1) {
			//			printf("iBuddyHelper: dispatch_source_set_event_handler socket connection accepted\n");
			/* Again, make sure the new connection's descriptor is non-blocking. */
			(void)fcntl(fd, F_SETFL, O_NONBLOCK);
			
			/* Check to make sure that we're still accepting new requests. */
			if (g_accepting_requests) {
				//				printf("iBuddyHelper: dispatch_source_set_event_handler requests are being handled\n");
				/* We're going to handle all requests concurrently. This daemon uses an HTTP-style
				 * model, where each request comes through its own connection. Making a more
				 * efficient implementation is an exercise left to the reader.
				 */
				server_accept(afd, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
			} else {
				//				printf("iBuddyHelper: dispatch_source_set_event_handler requests are NOT being handled\n");
				/* We're no longer accepting requests. */
				(void)close(afd);
			}
		}
	});
	
	/* GCD requires that any source dealing with a file descriptor have a
	 * cancellation handler. Because GCD needs to keep the file descriptor
	 * around to monitor it, the cancellation handler is the client's signal
	 * that GCD is done with the file descriptor, and thus the client is safe
	 * to close it out. Remember, file descriptors aren't ref counted.
	 */
	dispatch_source_set_cancel_handler(as, ^(void) {
		dispatch_release(as);
		(void)close(fd);
	});
	dispatch_resume(as);
	
	//	printf("iBuddyHelper: dispatch_main\n");
	dispatch_main();
	
	//	printf("iBuddyHelper: exit(EXIT_FAILURE)\n");
	exit(EXIT_FAILURE);
}
