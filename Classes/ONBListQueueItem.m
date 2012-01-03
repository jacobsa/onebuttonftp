//
//  ONBListQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-25.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBListQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBListQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBListQueueItem *newObject = [super copyWithZone:zone];
	[newObject setDirectory:[self directory]];
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// This class should be hidden by default
	[self setHidden:YES];
	
	ONB_completedTransfers = 0;
	
	// Set default value for directory
	[self setDirectory:@"."];
	return self;
}



- (void)dealloc
{
	[self setDirectory:nil];
	
	[super dealloc];
}



- (NSString *)directory
{
	return ONB_directory;
}



- (void)setDirectory:(NSString *)directory
{
	[ONB_directory autorelease];
	ONB_directory = [directory retain];
}



- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	[super runWithConnection:connection queue:queue];
	
	// The first thing we do is get the current path.  After that we will
	// cd to the directory to be listed, list its contents, and then
	// cd back to the directory we get here.
	[connection getCurrentDirectoryWithUserInfo:nil];
}



- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	ONB_completedTransfers++;
	
	if (ONB_completedTransfers == 1)
	{
		// Got the path before cd'ing to the directory to be listed
		ONB_previousPath = [[userInfo objectForKey:@"currentDirectory"] retain];
		[connection changeDirectory:[self directory] userInfo:nil];
	}

	else if (ONB_completedTransfers == 2)
	{
		// We've changed to the directory to be listed.  Now get the listing
		[connection getDirectoryListingWithUserInfo:nil];
	}
	
	else if (ONB_completedTransfers == 3)
	{
		// Got the directory listing
		ONB_listing = [[userInfo objectForKey:@"directoryListing"] retain];

		// Now switch back to the previous path
		[connection changeDirectory:ONB_previousPath userInfo:nil];
	}

	else if (ONB_completedTransfers == 4)
	{
		NSNumber *success = [NSNumber numberWithBool:YES];
		NSArray *directoryListing = ONB_listing;
		
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:success,
																		@"success",
																		[self directory],
																		@"directory",
																		directoryListing,
																		@"directoryListing",
																		nil];

		[[self ONB_queue] queueItemSucceededWithInfo:info];
		[self ONB_cleanUp];
	}
}



- (void)ONB_cleanUp
{
	[ONB_previousPath autorelease];
	ONB_previousPath = nil;
	
	[ONB_listing autorelease];
	ONB_listing = nil;
	
	ONB_completedTransfers = 0;
	
	[super ONB_cleanUp];
}

@end