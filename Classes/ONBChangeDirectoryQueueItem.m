//
//  ONBChangeDirectoryQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-28.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBChangeDirectoryQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBChangeDirectoryQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBChangeDirectoryQueueItem *newObject = [super copyWithZone:zone];
	[newObject setDirectory:[self directory]];
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// This class should be hidden by default
	[self setHidden:YES];
	
	// Set default value for directory
	[self setDirectory:@""];
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
	
	[connection changeDirectory:[self directory] userInfo:nil];
}

@end