//
//  ONBQueue.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBQueue.h"
#import "ONBFTPConnection.h"
#import "ONBBookmark.h"
#import "ONBQueueItem.h"

@interface ONBQueue ( ONBQueuePrivateMethods )
- (void)ONB_setCurrentlyRunningQueueItem:(ONBQueueItem *)queueItem;
- (void)ONB_setCurrentlyRunningQueueItemIsControl:(BOOL)isControl;
- (void)ONB_setConnectionStatus:(ONBQueueConnectionStatus)connectionStatus;
- (void)ONB_runQueueItem:(ONBQueueItem *)queueItem;
- (void)ONB_runNextQueueItem;
- (void)ONB_connect;
- (void)ONB_setContinueRunningControl:(BOOL)continueRunningControl;
- (void)ONB_setContinueRunningMain:(BOOL)continueRunningMain;
@end

@implementation ONBQueue

+ (void)initialize
{
	// Set up KVC dependencies
	[self setKeys:[NSArray arrayWithObjects:@"controlQueueItems", @"mainQueueItems", nil]
			triggerChangeNotificationsForDependentKey:@"queueItems"];
}

- (id)init
{
	return [self initWithOwner:nil bookmark:nil];
}

- (id)initWithOwner:(id < ONBQueueOwning >)owner bookmark:(ONBBookmark *)bookmark;
{
	if (! (self = [super init]))
		return nil;
	
	if (! bookmark)
	{
		[self dealloc];
		return nil;
	}
	
	ONB_owner = owner;
	ONB_bookmark = [bookmark retain];
	
	ONB_connection = nil;
	[self ONB_setConnectionStatus:ONBDisconnected];

	ONB_controlQueueItems = [[NSMutableArray alloc] init];
	ONB_mainQueueItems = [[NSMutableArray alloc] init];
	
	[self setStopRunningOnFailedControlQueueItem:NO];
	[self setStopRunningOnFailedMainQueueItem:YES];
	
	[self ONB_setCurrentlyRunningQueueItem:nil];
	
	[self pauseQueue];
	
	return self;
}

- (void)dealloc
{
	[self disconnect];

	[ONB_bookmark release];
	
	[ONB_controlQueueItems release];
	[ONB_mainQueueItems release];
	
	[self ONB_setCurrentlyRunningQueueItem:nil];
	
	[super dealloc];
}

- (id < ONBQueueOwning >)owner
{
	return ONB_owner;
}

- (ONBBookmark *)bookmark
{
	return [[ONB_bookmark copy] autorelease];
}

- (BOOL)stopRunningOnFailedControlQueueItem
{
	return ONB_stopRunningOnFailedControl;
}

- (void)setStopRunningOnFailedControlQueueItem:(BOOL)stopRunningOnFailedControlQueueItem
{
	ONB_stopRunningOnFailedControl = stopRunningOnFailedControlQueueItem;
}

- (BOOL)stopRunningOnFailedMainQueueItem
{
	return ONB_stopRunningOnFailedMain;
}

- (void)setStopRunningOnFailedMainQueueItem:(BOOL)stopRunningOnFailedMainQueueItem
{
	ONB_stopRunningOnFailedMain = stopRunningOnFailedMainQueueItem;
}

- (NSArray *)controlQueueItems
{
	return [[ONB_controlQueueItems copy] autorelease];
}

- (NSArray *)mainQueueItems
{
	return [[ONB_mainQueueItems copy] autorelease];
}

- (void)insertObject:(id)object inControlQueueItemsAtIndex:(unsigned)index
{
	[ONB_controlQueueItems insertObject:object atIndex:index];
}

- (void)insertObjects:(NSArray *)objects inControlQueueItemsAtIndex:(unsigned)index
{
	// Go backwards so that the items wind up in the queue in the correct order.
	NSEnumerator *objectEnumerator = [objects reverseObjectEnumerator];
	id currentObject;
	
	while (currentObject = [objectEnumerator nextObject])
		[self insertObject:currentObject inControlQueueItemsAtIndex:index];
}

- (void)removeObjectFromControlQueueItemsAtIndex:(unsigned int)index
{
	[ONB_controlQueueItems removeObjectAtIndex:index];
}

- (void)insertObject:(id)object inMainQueueItemsAtIndex:(unsigned)index
{
	[ONB_mainQueueItems insertObject:object atIndex:index];
}

- (void)insertObjects:(NSArray *)objects inMainQueueItemsAtIndex:(unsigned)index
{
	// Go backwards so that the items wind up in the queue in the correct order.
	NSEnumerator *objectEnumerator = [objects reverseObjectEnumerator];
	id currentObject;
	
	while (currentObject = [objectEnumerator nextObject])
		[self insertObject:currentObject inMainQueueItemsAtIndex:index];
}

- (void)removeObjectFromMainQueueItemsAtIndex:(unsigned int)index
{
	[ONB_mainQueueItems removeObjectAtIndex:index];
}

- (void)removeObjectsFromMainQueueItemsAtIndexes:(NSIndexSet *)indexSet
{
	// Go through the indexes in descending order so that we do not disturb the indexes
	// of later objects by removing earlier ones.
	unsigned int currentIndex = [indexSet lastIndex];
	
	while (currentIndex != NSNotFound)
	{
		[self removeObjectFromMainQueueItemsAtIndex:currentIndex];
		currentIndex = [indexSet indexLessThanIndex:currentIndex];
	}
}

- (void)clearControlQueue
{
	[self willChangeValueForKey:@"controlQueueItems"];
	[ONB_controlQueueItems removeAllObjects];
	[self didChangeValueForKey:@"controlQueueItems"];
}

- (ONBQueueConnectionStatus)connectionStatus
{
	return ONB_connectionStatus;
}

- (BOOL)willContinueRunningMainQueue
{
	return ONB_continueRunningMain;
}

- (ONBQueueItem *)currentlyRunningQueueItem
{
	return ONB_currentlyRunningItem;
}

- (BOOL)currentlyRunningQueueItemIsControl
{
	return ONB_currentlyRunningItemIsControl;
}

- (void)runQueue
{
	[self ONB_setContinueRunningControl:YES];
	[self ONB_setContinueRunningMain:YES];
	
	[self ONB_runNextQueueItem];
}

- (void)runControlQueue
{
	[self ONB_setContinueRunningControl:YES];

	[self ONB_runNextQueueItem];
}

- (void)queueItemSucceededWithInfo:(NSDictionary *)info
{
	// While the queue item was running, it was the delegate of the connection.
	[ONB_connection setDelegate:self];

	ONBQueueItem *item = [[[self currentlyRunningQueueItem] retain] autorelease];
	[self ONB_setCurrentlyRunningQueueItem:nil];
	
	[[self owner] queueItem:item succeededWithInfo:info];

	[self ONB_runNextQueueItem];
}

- (void)queueItemFailedWithError:(NSError *)error
{
	// While the queue item was running, it was the delegate of the connection.
	[ONB_connection setDelegate:self];

	ONBQueueItem *item = [[[self currentlyRunningQueueItem] retain] autorelease];
	BOOL isControl = [self currentlyRunningQueueItemIsControl];
	
	if (isControl && [self stopRunningOnFailedControlQueueItem])
	{
		[self pauseQueue];
		[self insertObject:[[item copy] autorelease] inControlQueueItemsAtIndex:0];
	}
	
	else if ((! isControl) && [self stopRunningOnFailedMainQueueItem])
	{
		[self pauseQueue];
		[self insertObject:[[item copy] autorelease] inMainQueueItemsAtIndex:0];
	}

	[self ONB_setCurrentlyRunningQueueItem:nil];
	
	[[self owner] queueItem:item failedWithError:error];

	[self ONB_runNextQueueItem];
}

- (void)pauseQueue
{
	[self ONB_setContinueRunningControl:NO];
	[self ONB_setContinueRunningMain:NO];
}

- (void)disconnect
{
	[self pauseQueue];

	ONBQueueItem *item = [[[self currentlyRunningQueueItem] retain] autorelease];
	if (item)
	{
		if ([self currentlyRunningQueueItemIsControl] && [self stopRunningOnFailedControlQueueItem])
			[self insertObject:[[item copy] autorelease] inControlQueueItemsAtIndex:0];
		
		else if ((! [self currentlyRunningQueueItemIsControl]) && [self stopRunningOnFailedMainQueueItem])
			[self insertObject:[[item copy] autorelease] inMainQueueItemsAtIndex:0];
	}

	[self ONB_setCurrentlyRunningQueueItem:nil];
	[self ONB_setConnectionStatus:ONBDisconnected];
	[ONB_connection setDelegate:nil];
	[ONB_connection release];
	ONB_connection = nil;
}

@end







@implementation ONBQueue ( ONBQueuePrivateMethods )

- (void)ONB_runQueueItem:(ONBQueueItem *)queueItem
{
	queueItem = [[queueItem copy] autorelease];
	[self ONB_setCurrentlyRunningQueueItem:queueItem];
	[queueItem runWithConnection:ONB_connection queue:self];
}

- (void)ONB_setCurrentlyRunningQueueItem:(ONBQueueItem *)queueItem
{
	[self willChangeValueForKey:@"currentlyRunningQueueItem"];
	[ONB_currentlyRunningItem autorelease];
	ONB_currentlyRunningItem = [queueItem retain];
	[self didChangeValueForKey:@"currentlyRunningQueueItem"];
}

- (void)ONB_setCurrentlyRunningQueueItemIsControl:(BOOL)isControl
{
	[self willChangeValueForKey:@"currentlyRunningQueueItemIsControl"];
	ONB_currentlyRunningItemIsControl = isControl;
	[self didChangeValueForKey:@"currentlyRunningQueueItemIsControl"];
}

- (void)ONB_setConnectionStatus:(ONBQueueConnectionStatus)connectionStatus
{
	[self willChangeValueForKey:@"connectionStatus"];
	ONB_connectionStatus = connectionStatus;
	[self didChangeValueForKey:@"connectionStatus"];
}

- (void)ONB_runNextQueueItem
{
	// Don't try to run two queue items at once.
	if ([self currentlyRunningQueueItem])
		return;
	
	// Connect first if we're not already connected.
	if ([self connectionStatus] == ONBDisconnected)
	{
		[self ONB_connect];
		return;
	}
	
	// Don't try to do anything if we are currently connecting.
	if ([self connectionStatus] != ONBConnected)
		return;
	
	ONBQueueItem *itemToRun = nil;
	BOOL isControl = NO;
	NSArray *controlItems = [self controlQueueItems];
	NSArray *mainItems = [self mainQueueItems];

	if (ONB_continueRunningControl && [controlItems count])
	{
		itemToRun = [controlItems objectAtIndex:0];
		isControl = YES;
		[self removeObjectFromControlQueueItemsAtIndex:0];
	}

	else if (ONB_continueRunningMain && [mainItems count])
	{
		itemToRun = [mainItems objectAtIndex:0];
		isControl = NO;
		[self removeObjectFromMainQueueItemsAtIndex:0];
	}
	
	if (itemToRun)
	{
		[self ONB_setCurrentlyRunningQueueItemIsControl:isControl];
		[self ONB_runQueueItem:itemToRun];
	}
	else
		[self pauseQueue];
}

- (void)ONB_connect
{
	ONBBookmark *bookmark = [self bookmark];
	NSString *user = [bookmark user];
	NSString *password = [bookmark password];
	
	if ([bookmark anonymous])
	{
		user = @"anonymous";
		password = @"onebuttonftpuser@asd.com";
	}
	
	ONB_connection = [[ONBFTPConnection alloc] initWithHost:[bookmark host]
														port:[[bookmark port] unsignedIntValue]
														username:user
														password:password
														delegate:self];

	ONBSSLMode SSLMode = [[bookmark SSLMode] intValue];
	[ONB_connection setUsePassiveMode:[bookmark usePassive]];
	[ONB_connection setUseExplicitTLS:(SSLMode == ONBUseExplicitSSL)];
	[ONB_connection setUseImplicitTLS:(SSLMode == ONBUseImplicitSSL)];
	
	[self ONB_setConnectionStatus:ONBConnecting];
	[ONB_connection connectWithUserInfo:nil];
}

- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	if ([self connectionStatus] == ONBConnecting)
	{
		[self ONB_setConnectionStatus:ONBConnected];
		[self ONB_runNextQueueItem];
		return;
	}
}

- (void)connection:(ONBFTPConnection *)connection
		failedToCompleteTaskWithUserInfo:(NSDictionary *)userInfo
		error:(NSError *)error
{
	NSLog(@"Task failed: %@", error);

	if ([self connectionStatus] == ONBConnecting)
		[self disconnect];
}

- (void)connection:(ONBFTPConnection *)connection
		sentCommunicationToServer:(NSString *)communication
{
	[[self owner] queue:self sentCommunicationToServer:communication];
}

- (void)connection:(ONBFTPConnection *)connection
		receivedCommunicationFromServer:(NSString *)communication
{
	[[self owner] queue:self receivedCommunicationFromServer:communication];
}

- (void)ONB_setContinueRunningControl:(BOOL)continueRunningControl
{
	ONB_continueRunningControl = continueRunningControl;
}

- (void)ONB_setContinueRunningMain:(BOOL)continueRunningMain
{
	[self willChangeValueForKey:@"willContinueRunningMainQueue"];
	ONB_continueRunningMain = continueRunningMain;
	[self didChangeValueForKey:@"willContinueRunningMainQueue"];
}

@end