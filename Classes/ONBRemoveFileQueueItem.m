//
//  ONBRemoveFileQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-02-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBRemoveFileQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBRemoveFileQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBRemoveFileQueueItem *newObject = [super copyWithZone:zone];
	[newObject setFile:[self file]];
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// Set default value for file
	[self setFile:@""];
	return self;
}

- (void)dealloc
{
	[self setFile:nil];
	
	[super dealloc];
}

- (void)ONB_cleanUp
{
	[ONB_previousPath autorelease];
	ONB_previousPath = nil;
	
	ONB_completedTransfers = 0;
	
	[super ONB_cleanUp];
}

- (NSString *)file
{
	return ONB_file;
}

- (void)setFile:(NSString *)file
{
	[ONB_file autorelease];
	ONB_file = [file retain];
}

- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	[super runWithConnection:connection queue:queue];
	
	// The first thing we want to do is get our current path so that we can return to it
	// when we're done with other stuff later.
	[connection getCurrentDirectoryWithUserInfo:nil];
}

- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	ONB_completedTransfers++;
	
	if (ONB_completedTransfers == 1)
	{
		// Got the path before cd'ing to the directory to do our thing.
		ONB_previousPath = [[userInfo objectForKey:@"currentDirectory"] copy];
		
		// Now tell the connection to switch to the directory containing the file
		//  we want to delete.
		NSString *parentDirectory = [[self file] stringByDeletingLastPathComponent];
		[connection changeDirectory:parentDirectory userInfo:nil];
	}

	else if (ONB_completedTransfers == 2)
	{
		// We've changed to the directory containing the file to be deleted.  Now delete it.
		NSString *name = [[self file] lastPathComponent];
		[connection removeFile:name userInfo:nil];
	}
	
	else if (ONB_completedTransfers == 3)
	{
		// We have deleted the file, so now we should return to the previous path.
		[connection changeDirectory:ONB_previousPath userInfo:nil];
	}
	
	else if (ONB_completedTransfers == 4)
	{		
		NSNumber *success = [NSNumber numberWithBool:YES];
		
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:success,
																		@"success",
																		nil];
		[[self ONB_queue] queueItemSucceededWithInfo:info];
		[self ONB_cleanUp];
	}
}

@end