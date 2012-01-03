//
//  ONBDownloadFileQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-01-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBDownloadFileQueueItem is a queue item used to download a file from a remote
	server to a specific local location.  See the header for ONBTransferFileQueueItem
	for a list of this class' accessor methods. The file named remoteFile located in the
	directory whose path is remoteDirectory will be downloaded to a file named
	localFile in localDirectory.  If localFile already exists, it will be overwritten!
	
	Note that if all possible you should call setSize to let the queue item know what
	size the remote file is.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the download
					succeeded.  If this is NO, none of the other keys will be
					present.
		
		localDirectory	The local directory path to which the file was downloaded.
		
		localFile	The name of the local file to which the file was downloaded.
		
		remoteDirectory	The remote directory path from which the file was downloaded.
		
		remoteFile	The name of the remote file that was downloaded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBTransferFileQueueItem.h"

@interface ONBDownloadFileQueueItem : ONBTransferFileQueueItem
{
	NSFileHandle			*ONB_downloadHandle;
}

@end