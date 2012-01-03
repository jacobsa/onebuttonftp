//
//  ONBUploadFileQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-01-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBUploadFileQueueItem is a queue item used to upload a file to a remote
	server from a specific local location.  See the header for ONBTransferFileQueueItem
	for a list of this class' accessor methods. The file named localFile located in the
	directory whose path is localDirectory will be uploaded to a file named
	remoteFile in remoteDirectory.  If remoteFile already exists, it will be overwritten!
	
	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the listing
					succeeded.  If this is NO, none of the other keys will be
					present.
		
		localDirectory	The local directory path from which the file was uploaded.
		
		localFile	The name of the local file that was uploaded.
		
		remoteDirectory	The remote directory path to which the file was uploaded.
		
		remoteFile	The name of the remote file that was uploaded to.
*/

#import <Cocoa/Cocoa.h>
#import "ONBTransferFileQueueItem.h"

@interface ONBUploadFileQueueItem : ONBTransferFileQueueItem
{
	NSFileHandle				*ONB_uploadHandle;
}

// Private methods
- (void)ONB_recomputeSize;

@end