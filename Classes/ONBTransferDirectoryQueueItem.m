//
//  ONBTransferDirectoryQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-26.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBTransferDirectoryQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBTransferDirectoryQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBTransferDirectoryQueueItem *newObject = [super copyWithZone:zone];
	[newObject setLocalDirectory:[self localDirectory]];
	[newObject setRemoteDirectory:[self remoteDirectory]];
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// Set default values
	[self setLocalDirectory:@"."];
	[self setRemoteDirectory:@""];

	return self;
}

- (void)dealloc
{
	[self setLocalDirectory:nil];
	[self setRemoteDirectory:nil];
	
	[super dealloc];
}

- (NSString *)localDirectory
{
	return ONB_localDirectory;
}

- (void)setLocalDirectory:(NSString *)localDirectory
{
	[ONB_localDirectory autorelease];
	ONB_localDirectory = [localDirectory copy];
}

- (NSString *)remoteDirectory
{
	return ONB_remoteDirectory;
}

- (void)setRemoteDirectory:(NSString *)remoteDirectory
{
	[ONB_remoteDirectory autorelease];
	ONB_remoteDirectory = [remoteDirectory copy];
}

- (void)ONB_cleanUp
{
	[ONB_previousPath autorelease];
	ONB_previousPath = nil;
	
	ONB_completedTransfers = 0;
	
	[super ONB_cleanUp];
}

- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	[super runWithConnection:connection queue:queue];
	
	// The first thing we do is get the current path so that we can switch back to
	// it later when everything else is done.
	[connection getCurrentDirectoryWithUserInfo:nil];
}

@end