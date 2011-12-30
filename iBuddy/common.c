//
//  common.c
//  ssd
//
//  Created by Eric Gorr on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "common.h"

#include <assert.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <sys/param.h>
#include <sys/un.h>
#include <netdb.h>
#include <inttypes.h>
#include <errno.h>


extern int MoreUNIXErrno(int result)
// See comment in header.
{
    int err;
    
    err = 0;
    if (result < 0) {
        err = errno;
        assert(err != 0);
    }
    return err;
}