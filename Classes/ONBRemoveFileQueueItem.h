//
//  ONBRemoveFileQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-02-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBRemoveFileQueueItem is a queue item which deletes a file in the current
	working directory of the connection with which it is run.  Call setFile:
	to set the full path of the file to delete.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the delete
					succeeded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBRemoveFileQueueItem : ONBQueueItem
{
	// The path of the file to delete.
	NSString	*ONB_file;

	// The previous remote path.
	NSString		*ONB_previousPath;
	
	// Number of transfers that have completed.
	unsigned int	ONB_completedTransfers;
}

// File to delete
- (NSString *)file;
- (void)setFile:(NSString *)file;

@end