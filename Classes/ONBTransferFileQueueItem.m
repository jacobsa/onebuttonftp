//
//  ONBTransferFileQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-01-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBTransferFileQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBTransferFileQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBTransferFileQueueItem *newObject = [super copyWithZone:zone];
	[newObject setLocalDirectory:[self localDirectory]];
	[newObject setLocalFile:[self localFile]];
	[newObject setRemoteDirectory:[self remoteDirectory]];
	[newObject setRemoteFile:[self remoteFile]];
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// Set default values
	[self setLocalDirectory:@"."];
	[self setLocalFile:@""];
	[self setRemoteDirectory:@"."];
	[self setRemoteFile:@""];

	return self;
}

- (void)dealloc
{
	[self setLocalDirectory:nil];
	[self setLocalFile:nil];
	[self setRemoteDirectory:nil];
	[self setRemoteFile:nil];
	
	[super dealloc];
}

- (NSString *)localDirectory
{
	return ONB_localDirectory;
}

- (void)setLocalDirectory:(NSString *)localDirectory
{
	[ONB_localDirectory autorelease];
	ONB_localDirectory = [localDirectory retain];
}

- (NSString *)localFile
{
	return ONB_localFile;
}

- (void)setLocalFile:(NSString *)localFile
{
	[ONB_localFile autorelease];
	ONB_localFile = [localFile retain];
}

- (NSString *)remoteDirectory
{
	return ONB_remoteDirectory;
}

- (void)setRemoteDirectory:(NSString *)remoteDirectory
{
	[ONB_remoteDirectory autorelease];
	ONB_remoteDirectory = [remoteDirectory retain];
}

- (NSString *)remoteFile
{
	return ONB_remoteFile;
}

- (void)setRemoteFile:(NSString *)remoteFile
{
	[ONB_remoteFile autorelease];
	ONB_remoteFile = [remoteFile retain];
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

- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	ONB_completedTransfers++;
	
	if (ONB_completedTransfers == 1)
	{
		// Got the path before cd'ing to the directory to download the file
		ONB_previousPath = [[userInfo objectForKey:@"currentDirectory"] retain];
		
		// Now tell the connection to switch to the directory we want to transfer to/from
		[connection changeDirectory:[self remoteDirectory] userInfo:nil];
	}

	else if (ONB_completedTransfers == 2)
	{
		// Record whether or not the connection is currently in binary mode.
		ONB_previousASCIIMode = [connection useASCIIMode];
		
		// We've changed to the directory to be transfered to/from.  Now start the transfer
		[self ONB_startTransfer];
	}
	
	else if (ONB_completedTransfers == 3)
	{
		// Finished the transfer
		[self ONB_endTransfer];
		
		// Reset the connection's binary transfer mode.
		[connection setUseASCIIMode:ONB_previousASCIIMode];

		// Now switch back to the previous path
		[connection changeDirectory:ONB_previousPath userInfo:nil];
	}

	else if (ONB_completedTransfers == 4)
	{
		NSNumber *success = [NSNumber numberWithBool:YES];
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:success,
																		@"success",
																		[self localDirectory],
																		@"localDirectory",
																		[self localFile],
																		@"localFile",
																		[self remoteDirectory],
																		@"remoteDirectory",
																		[self remoteFile],
																		@"remoteFile",
																		nil];
		[[self ONB_queue] queueItemSucceededWithInfo:info];
		[self ONB_cleanUp];
	}
}

- (void)connection:(ONBFTPConnection *)connection
		failedToCompleteTaskWithUserInfo:(NSDictionary *)userInfo
		error:(NSError *)error
{
	[connection setUseASCIIMode:ONB_previousASCIIMode];
	[super connection:connection failedToCompleteTaskWithUserInfo:userInfo error:error];
}

// Indicates that the object should start the transfer (e.g. by creating
// an appropriate file handle and telling the connection object to start).
// Subclasses should override this, as the default implementation just gets
// the current path.
- (void)ONB_startTransfer
{
	[[self ONB_connection] getCurrentDirectoryWithUserInfo:nil];
}

// Indicates that the transfer has completed.  If a subclass needs to do
// something, it should override this, as the default implementation does
// nothing.
- (void)ONB_endTransfer
{
}

@end