//
//  ONBQueueItem.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

/*
	ONBQueueItem is an abstract class whose instances represent actions to be taken
	on a connection.  ONBQueueItem instances are managed by an ONBQueue, which tells
	them when to run.  Subclasses should implement actual functionality - e.g. listing
	a directory, downloading a file, or deleting a file.

	The returned info dictionary contains the following keys:
		success		An NSNumber whose BOOL value indicates whether the item succeeded.
*/

#import <Cocoa/Cocoa.h>

@class ONBQueue;
@class ONBFTPConnection;

@interface ONBQueueItem : NSObject < NSCopying >
{
	BOOL				ONB_hidden;			// Should the item be hidden in the queue?
	ONBFTPConnection	*ONB_connection;	// Connection used to run the item
	ONBQueue			*ONB_queue;			// Queue the item is being run by
	NSDictionary		*ONB_contextInfo;	// Context info

	double				ONB_progress;
	double				ONB_speed;
	unsigned int		ONB_size;
}

// Return a retained copy of the object that has all of the pre-run properties of
// the receiver (such as remote and local filenames for a file transfer item) but
// none of the state information of a running queue item, so that the result is a
// queue item that is fresh and ready to be run.
- (id)copyWithZone:(NSZone *)zone;

// Run the queue item.  queue is the ONBQueue that owns the item, and connection is
// the remote connection one which the item should operate.  If connection is nil,
// the item should somehow attempt to create a connection on its own.
- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue;

// Cancel the queue item if it is running.  This is non-destructive, so the item can
// be run again.
- (void)cancel;

// Should the queue item be hidden in the queue or should it be displayed?
- (BOOL)hidden;
- (void)setHidden:(BOOL)hidden;

// How should the item be displayed in the queue?
- (NSString *)queueDescription;

// Any extra info that the owner of the queue item wants to attach to it
- (NSDictionary *)contextInfo;
- (void)setContextInfo:(NSDictionary *)contextInfo;

// How for through the transfer are we currently?  This is a percentage, and is nil
// if there is no way to tell or the concept doesn't make sense in this case.
- (double)progress;
- (void)setProgress:(double)progress;

// How quickly is the transfer going?  This is nil if there is no way to tell or the
// concept doesn't make sense in this case.
- (double)speed;
- (void)setSpeed:(double)speed;

// Size of the remote (downloading) or local (uploading) file - zero if unknown
- (unsigned int)size;
- (void)setSize:(unsigned int)size;

// Private methods
- (ONBFTPConnection *)ONB_connection;
- (void)ONB_setConnection:(ONBFTPConnection *)connection;
- (ONBQueue *)ONB_queue;
- (void)ONB_setQueue:(ONBQueue *)queue;
- (void)ONB_cleanUp;

@end