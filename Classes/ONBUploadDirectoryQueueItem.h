//
//  ONBUploadDirectoryQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-27.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBUploadDirectoryQueueItem is a queue item used to upload a directory tree
	from a local directory to a specific remote directory.  See the header for
	ONBTransferDirectoryQueueItem for a list of this class' accessor methods.  The
	directory remoteDirectory will be created if it does not exist.  Then the queue
	item will the contents of localDirectory and add appropriate queue items
	to upload them to remoteDirectory to the main section of the owning queue.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the operation
					succeeded.  If this is NO, none of the other keys will be
					present.
		
		localDirectory	The local directory path from which the tree was uploaded.
		
		remoteDirectory	The remote directory path to which the tree was uploaded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBTransferDirectoryQueueItem.h"

@interface ONBUploadDirectoryQueueItem : ONBTransferDirectoryQueueItem
{
}

@end