//
//  ONBCurrentPathQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-28.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBCurrentPathQueueItem is a queue item which retrieves the current
	working directory of the connection with which it is run.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the pausing
					succeeded.  If this is NO, none of the other keys will be
					present.

		currentPath	An NSString containing the current path on the given
					connection.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBCurrentPathQueueItem : ONBQueueItem
{
}
@end