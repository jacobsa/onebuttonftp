//
//  ONBQueue.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBQueue is used to manage a collection of ONBQueueItems, telling them when
	to run.  It provides an interface for telling its owner the status of executed
	and currently executing queue items.
	
	ONBQueue provides a 'main' queue section and a 'control' queue section.  The control
	items are generally run before the main ones, and are intended to be used by e.g.
	the controller level to change directories and get listings.
*/

#import <Cocoa/Cocoa.h>
#import "ONBQueueOwning.h"

typedef enum
{
	ONBDisconnected,
	ONBConnecting,
	ONBConnected
} ONBQueueConnectionStatus;

@class ONBQueueItem;
@class ONBFTPConnection;
@class ONBBookmark;

@interface ONBQueue : NSObject
{
	id < ONBQueueOwning >		ONB_owner;
	ONBBookmark					*ONB_bookmark;
	
	ONBFTPConnection			*ONB_connection;
	ONBQueueConnectionStatus	ONB_connectionStatus;
	
	NSMutableArray				*ONB_controlQueueItems;
	NSMutableArray				*ONB_mainQueueItems;
	
	BOOL						ONB_stopRunningOnFailedControl;
	BOOL						ONB_stopRunningOnFailedMain;
	
	ONBQueueItem				*ONB_currentlyRunningItem;
	BOOL						ONB_currentlyRunningItemIsControl;
	
	BOOL						ONB_continueRunningControl;
	BOOL						ONB_continueRunningMain;
}

// Designated initializer.
- (id)initWithOwner:(id < ONBQueueOwning >)owner bookmark:(ONBBookmark *)bookmark;

// The object that should receive notifications about the status of the queue.
- (id < ONBQueueOwning >)owner;

// A copy of the bookmark to which the queue should connect when running queue items.
- (ONBBookmark *)bookmark;

// If a running queue item fails in the given queue, should we stop running and reinsert
// the failed queue item or should we discard it and continue with the next?  The default
// is to discard and continue on the control queue and to stop on the main queue.
- (BOOL)stopRunningOnFailedControlQueueItem;
- (void)setStopRunningOnFailedControlQueueItem:(BOOL)stopRunningOnFailedControlQueueItem;

- (BOOL)stopRunningOnFailedMainQueueItem;
- (void)setStopRunningOnFailedMainQueueItem:(BOOL)stopRunningOnFailedMainQueueItem;


// Return an array of all not currently executing control queue items
- (NSArray *)controlQueueItems;

// Return an array of all not currently executing main queue items
- (NSArray *)mainQueueItems;


// Add new control queue items to the list at the specified place
- (void)insertObject:(id)object inControlQueueItemsAtIndex:(unsigned)index;
- (void)insertObjects:(NSArray *)objects inControlQueueItemsAtIndex:(unsigned)index;

// Remove the control queue item at the specified index
- (void)removeObjectFromControlQueueItemsAtIndex:(unsigned int)index;


// Add new main queue items to the list at the specified place
- (void)insertObject:(id)object inMainQueueItemsAtIndex:(unsigned)index;
- (void)insertObjects:(NSArray *)objects inMainQueueItemsAtIndex:(unsigned)index;

// Remove main queue items at the specified places
- (void)removeObjectFromMainQueueItemsAtIndex:(unsigned int)index;
- (void)removeObjectsFromMainQueueItemsAtIndexes:(NSIndexSet *)indexSet;


// Remove all control queue items
- (void)clearControlQueue;


// Start the queue running with the first item, and continue running after the first completes.
// If there's already an item running, just indicate that the queue should continue running
// after it completes.  This causes the queue to run both control and main queue items.
- (void)runQueue;

// Start the control queue and continue running it until it's done, but don't continue into
// the main queue (unless the queue is already running in a mode that continues into the main
// queue).
- (void)runControlQueue;

// Stop running the queue after the current item completes
- (void)pauseQueue;

// Disconnect from the server.  The currently running queue item (if any) will or will not be
// reinserted into the appropriate queue depending on the behavior defined by
// stopRunningOnFailedControlQueueItem and stopRunningOnFailedMainQueueItem.  If runQueue is
// called later, the queue will reconnect.
- (void)disconnect;

// What is the connection currently doing?
- (ONBQueueConnectionStatus)connectionStatus;

// Is the queue set to continue running main queue items after the current one finishes?
- (BOOL)willContinueRunningMainQueue;


// Status callbacks for use by running queue items
- (void)queueItemSucceededWithInfo:(NSDictionary *)info;
- (void)queueItemFailedWithError:(NSError *)error;


// The queue item that is currently running, or nil if there is none
- (ONBQueueItem *)currentlyRunningQueueItem;

// Is the currently running queue item a control item?
- (BOOL)currentlyRunningQueueItemIsControl;

@end