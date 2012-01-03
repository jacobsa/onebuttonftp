//
//  ONBTransferFileQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-01-02.
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

@interface ONBTransferFileQueueItem : ONBQueueItem
{
	NSString		*ONB_localDirectory;
	NSString		*ONB_localFile;
	NSString		*ONB_remoteDirectory;
	NSString		*ONB_remoteFile;
	
	// The previous remote path
	NSString		*ONB_previousPath;
	
	// The previous ASCII transfer mode
	BOOL			ONB_previousASCIIMode;
	
	// Number of transfers that have completed
	unsigned int	ONB_completedTransfers;
}

// The local directory in which localFile is located - default is "."
- (NSString *)localDirectory;
- (void)setLocalDirectory:(NSString *)localDirectory;

// The name of the local file to transfer to or from - default is ""
- (NSString *)localFile;
- (void)setLocalFile:(NSString *)localFile;

// The remote directory in which remoteFile is located - default is "."
- (NSString *)remoteDirectory;
- (void)setRemoteDirectory:(NSString *)remoteDirectory;

// The name of the remote file to transfer to or from - default is ""
- (NSString *)remoteFile;
- (void)setRemoteFile:(NSString *)remoteFile;

// Private methods
- (void)ONB_startTransfer;
- (void)ONB_endTransfer;

@end