//
//  ONBTransferDirectoryQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-26.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBTransferFileQueueItem is a queue item class that implements the
	functionality common to the queue items for downloading and uploading
	file.  You should use a subclass of ONBTransferFileQueueItem to do an
	actual transfer.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBTransferDirectoryQueueItem : ONBQueueItem
{
	NSString		*ONB_localDirectory;
	NSString		*ONB_remoteDirectory;
	
	// The previous remote path
	NSString		*ONB_previousPath;
	
	// Number of transfers that have completed
	unsigned int	ONB_completedTransfers;
}

// The path to the local directory to be created (if it doesn't exist) or uploaded
- (NSString *)localDirectory;
- (void)setLocalDirectory:(NSString *)localDirectory;

// The path to the remote directory to be created (if it doesn't exist) or downloaded
- (NSString *)remoteDirectory;
- (void)setRemoteDirectory:(NSString *)remoteDirectory;

@end