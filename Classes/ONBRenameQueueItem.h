//
//  ONBRenameQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-18.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBRenameQueueItem is a queue item which renames a remote file.  Call setFile:
	to set the name of the old file and setNewName: to set its new name.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the rename
					succeeded.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueItem.h"

@interface ONBRenameQueueItem : ONBQueueItem
{
	NSString	*ONB_file;		// The old file name
	NSString	*ONB_newName;	// The new file name
}

- (NSString *)file;
- (NSString *)newName;

- (void)setFile:(NSString *)file;
- (void)setNewName:(NSString *)newName;

@end