//
//  ONBCurrentPathQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-28.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBCurrentPathQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBCurrentPathQueueItem

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// This class should be hidden by default
	[self setHidden:YES];
	return self;
}



- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	[super runWithConnection:connection queue:queue];
	
	[connection getCurrentDirectoryWithUserInfo:nil];
}



- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	NSString *currentDirectory = [userInfo objectForKey:@"currentDirectory"];
	NSDictionary *info = [NSDictionary dictionaryWithObject:currentDirectory forKey:@"currentPath"];
	[[self ONB_queue] queueItemSucceededWithInfo:info];
}

@end