//
//  ONBRemoveDirectoryQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-02-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBRemoveDirectoryQueueItem is a queue item which deletes a directory in the current
	working directory of the connection with which it is run.  If the directory has no
	contents it will be deleted immediately.  If it does have contents, appropriate queue
	items will be added to delete its contents first, and a copy of the original queue item will
	be reinserted after these items to actually remove the directory.  Call setDirectory:
	to set the full path of the directory to delete.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the delete
					succeeded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBRemoveDirectoryQueueItem : ONBQueueItem
{
	// The path of the directory to delete.
	NSString		*ONB_directory;
	
	// The previous remote path.
	NSString		*ONB_previousPath;
	
	// Number of transfers that have completed.
	unsigned int	ONB_completedTransfers;
	
	BOOL			ONB_firstTime;
}

// File to delete
- (NSString *)directory;
- (void)setDirectory:(NSString *)directory;

// Is this the first time that this queue item has been run, or is it
// the re-inserted one?
- (BOOL)firstTime;
- (void)setFirstTime:(BOOL)firstTime;

@end