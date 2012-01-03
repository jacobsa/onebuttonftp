//
//  ONBCreateDirectoryQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-18.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBCreateDirectoryQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBCreateDirectoryQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBCreateDirectoryQueueItem *newObject = [super copyWithZone:zone];
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
	ONB_directory = [directory copy];
}

- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	[super runWithConnection:connection queue:queue];
	
	[connection createDirectory:[self directory] userInfo:nil];
}

@end