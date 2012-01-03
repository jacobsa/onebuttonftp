//
//  ONBDownloadDirectoryQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-26.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBDownloadDirectoryQueueItem is a queue item used to download a directory tree
	from a remote server to a specific local directory.  See the header for
	ONBTransferDirectoryQueueItem for a list of this class' accessor methods.  The
	directory localDirectory will be created if it does not exist.  Then the queue
	item will get the contents of remoteDirectory and add appropriate queue items
	to download them to localDirectory to the main section of the owning queue.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the operation
					succeeded.  If this is NO, none of the other keys will be
					present.
		
		localDirectory	The local directory path to which the tree was downloaded.
		
		remoteDirectory	The remote directory path from which the tree was downloaded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBTransferDirectoryQueueItem.h"

@interface ONBDownloadDirectoryQueueItem : ONBTransferDirectoryQueueItem
{
}

@end