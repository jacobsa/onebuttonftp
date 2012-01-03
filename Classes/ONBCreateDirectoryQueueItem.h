//
//  ONBCreateDirectoryQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-18.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBCreateDirectoryQueueItem is a queue item which creates a new directory in
	the current working directory of the connection with which it is run.  Call
	setDirectory: to set the name of the new directory.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the creation
					succeeded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBCreateDirectoryQueueItem : ONBQueueItem
{
	NSString	*ONB_directory;		// The directory to create
}

// Directory to create
- (NSString *)directory;
- (void)setDirectory:(NSString *)directory;

@end