//
//  ONBChangeDirectoryQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-28.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBChangeDirectoryQueueItem is a queue item which changes the working
	directory of the connection with which it is run.  Call setDirectory:
	to set which directory to change to.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the change
					succeeded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBChangeDirectoryQueueItem : ONBQueueItem
{
	NSString	*ONB_directory;		// The directory to change to
}

// Directory to which we should switch
- (NSString *)directory;
- (void)setDirectory:(NSString *)directory;

@end