//
//  ONBQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBQueueItem.h"
#import "ONBQueue.h"
#import "ONBFTPConnection.h"

@implementation ONBQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBQueueItem *newObject = [[[self class] allocWithZone:zone] init];
	
	[newObject setHidden:[self hidden]];
	[newObject setContextInfo:[self contextInfo]];
	[newObject setSize:[self size]];
	
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	[self setContextInfo:nil];
	[self setProgress:nil];
	[self setSpeed:nil];
	[self setSize:nil];
	
	return self;
}

- (void)dealloc
{
	[self ONB_cleanUp];

	[self setContextInfo:nil];
	[self setProgress:nil];
	[self setSpeed:nil];
	[self setSize:nil];
	
	[super dealloc];
}

- (NSDictionary *)contextInfo
{
	return ONB_contextInfo;
}

- (void)setContextInfo:(NSDictionary *)contextInfo
{
	[ONB_contextInfo autorelease];
	ONB_contextInfo = [contextInfo retain];
}

- (double)progress
{
	return ONB_progress;
}

- (void)setProgress:(double)progress
{
	ONB_progress = progress;
}

- (double)speed
{
	return ONB_speed;
}

- (void)setSpeed:(double)speed
{
	ONB_speed = speed;
}

- (unsigned int)size
{
	return ONB_size;
}

- (void)setSize:(unsigned int)size
{
	ONB_size = size;
}

// This should be called by subclasses before they do their thing.
- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	[self ONB_setConnection:connection];
	[self ONB_setQueue:queue];

	[connection setDelegate:self];
}

// Default implementation does nothing
- (void)cancel
{
}

- (BOOL)hidden
{
	return ONB_hidden;
}

- (void)setHidden:(BOOL)hidden
{
	ONB_hidden = hidden;
}

- (ONBFTPConnection *)ONB_connection
{
	return ONB_connection;
}

- (void)ONB_setConnection:(ONBFTPConnection *)connection
{
	ONB_connection = connection;
}

- (void)ONB_cleanUp
{
	[self cancel];
	[self ONB_setQueue:nil];
	
	[self setProgress:nil];
	[self setSpeed:nil];

	[self ONB_setConnection:nil];
}

- (ONBQueue *)ONB_queue
{
	return ONB_queue;
}

- (void)ONB_setQueue:(ONBQueue *)queue
{
	[ONB_queue autorelease];
	ONB_queue = [queue retain];
}

// Default implementation is to just display the queue item's default NSObject description
- (NSString *)queueDescription
{
	return [self description];
}

// A subclass should override the following two methods if it needs to do something more
// complicated than call a single ONBFTPConnection method.
- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	[[self ONB_queue] queueItemSucceededWithInfo:nil];
}

- (void)connection:(ONBFTPConnection *)connection
		failedToCompleteTaskWithUserInfo:(NSDictionary *)userInfo
		error:(NSError *)error
{
	[[self ONB_queue] queueItemFailedWithError:error];
}

- (void)connection:(ONBFTPConnection *)connection
		sentCommunicationToServer:(NSString *)communication
{
	[[self ONB_queue] connection:connection sentCommunicationToServer:communication];
}

- (void)connection:(ONBFTPConnection *)connection
		receivedCommunicationFromServer:(NSString *)communication
{
	[[self ONB_queue] connection:connection receivedCommunicationFromServer:communication];
}

@end