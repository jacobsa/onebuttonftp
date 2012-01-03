//
//  ONBListQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-25.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBListQueueItem is a queue item for listing the contents of a remote
	directory item.  Set which directory you want to list using setDirectory:,
	then run the queue item.
	
	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the listing
					succeeded.  If this is NO, none of the other keys will be
					present.
		
		directory	An NSString containing the directory whose contents were listed.
		
		directoryListing	An NSArray of ONBFileListings describing the contents of
							the directory.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBListQueueItem : ONBQueueItem
{
	NSString		*ONB_directory;			// Directory to list
	unsigned int	ONB_completedTransfers;	// Number of transfers that have completed
	NSString		*ONB_previousPath;		// Path when item started running
	NSArray			*ONB_listing;			// Result of the directory listing
}

// Directory whose contents should be listed
- (NSString *)directory;
- (void)setDirectory:(NSString *)directory;

@end