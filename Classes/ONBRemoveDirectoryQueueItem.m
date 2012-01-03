//
//  ONBRemoveDirectoryQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-02-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBRemoveDirectoryQueueItem.h"
#import "ONBRemoveFileQueueItem.h"
#import "ONBFileListing.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBRemoveDirectoryQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBRemoveDirectoryQueueItem *newObject = [super copyWithZone:zone];
	[newObject setDirectory:[self directory]];
	[newObject setFirstTime:[self firstTime]];
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// Set default value for file
	[self setDirectory:@""];
	[self setFirstTime:YES];
	return self;
}

- (void)dealloc
{
	[self setDirectory:nil];
	
	[super dealloc];
}

- (void)ONB_cleanUp
{
	[ONB_previousPath autorelease];
	ONB_previousPath = nil;
	
	ONB_completedTransfers = 0;
	
	[super ONB_cleanUp];
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
	
	// The first thing we want to do is get our current path so that we can return to it
	// when we're done with other stuff later.
	[connection getCurrentDirectoryWithUserInfo:nil];
}


- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{		
	ONB_completedTransfers++;
	
	if (ONB_completedTransfers == 1)
	{
		// Got the path before cd'ing to the directory to do our thing.
		ONB_previousPath = [[userInfo objectForKey:@"currentDirectory"] copy];
		
		// Now tell the connection to switch to the directory we want to delete so
		// we can see if it has any contents.
		[connection changeDirectory:[self directory] userInfo:nil];
	}

	else if (ONB_completedTransfers == 2)
	{
		// We've changed to the directory to be deleted.  Now get the
		// directory listing.
		[connection getDirectoryListingWithUserInfo:nil];
	}
	
	else if (ONB_completedTransfers == 3)
	{
		// Got the directory listing.
		NSArray *listing = [[userInfo objectForKey:@"directoryListing"] retain];

		// If there are any listings, add the appropriate queue items to the control
		// queue.
		NSMutableArray *queueItems = [NSMutableArray arrayWithCapacity:[listing count]];
		NSEnumerator *listingEnumerator = [listing objectEnumerator];
		ONBFileListing *currentListing;
		
		while (currentListing = [listingEnumerator nextObject])
		{
			// We only want to add the queue items to delete the directory contents
			// if this our first time running.  Otherwise, if there is a file in the
			// directory that we cannot delete, we will continue to loop trying to
			// delete it forever.
			if (! [self firstTime])
				break;
			
			NSString *name = [currentListing name];
			NSString *fullPath = [[self directory] stringByAppendingPathComponent:name];
			
			if ([currentListing isRegularFile])
			{
				ONBRemoveFileQueueItem *queueItem = [[ONBRemoveFileQueueItem alloc] init];
				[queueItem setFile:fullPath];

				[queueItems addObject:queueItem];

				[queueItem release];
			}
			
			else if ([currentListing isDirectory])
			{
				// Ignore listings for ".." and "."
				if ([name isEqualToString:@".."] || [name isEqualToString:@"."])
					continue;
				
				ONBRemoveDirectoryQueueItem *queueItem;
				queueItem = [[ONBRemoveDirectoryQueueItem alloc] init];
				[queueItem setDirectory:fullPath];
				
				[queueItems addObject:queueItem];
				
				[queueItem release];
			}
			
			else
			{
				// Unrecognized file type.
				continue;
			}
		}
		
		BOOL directoryEmpty = ([queueItems count]) ? NO : YES;
		
		// If the directory was not empty, we need to add a queue item to delete it
		// after it has been emptied.
		if (! directoryEmpty)
		{
			ONBRemoveDirectoryQueueItem *queueItem;
			queueItem = [[ONBRemoveDirectoryQueueItem alloc] init];
			[queueItem setDirectory:[self directory]];
			[queueItem setFirstTime:NO];
			
			[queueItems addObject:queueItem];
			
			[queueItem release];
		}
		
		[[self ONB_queue] insertObjects:queueItems inControlQueueItemsAtIndex:0];
		
		// If the directory was empty, we want to switch to its parent directory
		// and then delete it.  If not, we want to just switch back to the previous path.
		if (directoryEmpty)
		{
			NSString *parentDirectory = [[self directory] stringByDeletingLastPathComponent];
			[connection changeDirectory:parentDirectory userInfo:nil];
		}
		else
		{
			// Since the directory was not empty, we can skip the next two steps.
			ONB_completedTransfers += 2;
			
			[connection changeDirectory:ONB_previousPath userInfo:nil];
		}
	}
	
	else if (ONB_completedTransfers == 4)
	{
		// If we're here then the directory was empty on the previous step and we're
		// now in its parent directory.  So delete it.
		NSString *name = [[self directory] lastPathComponent];
		
		[connection removeDirectory:name userInfo:nil];
	}
	
	else if (ONB_completedTransfers == 5)
	{
		// We have deleted the directory, so now we should return to the previous path.
		[connection changeDirectory:ONB_previousPath userInfo:nil];
	}
	
	else if (ONB_completedTransfers == 6)
	{
			NSNumber *success = [NSNumber numberWithBool:YES];
			
			NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:success,
																			@"success",
																			nil];

			[[self ONB_queue] queueItemSucceededWithInfo:info];
			[self ONB_cleanUp];
	}
}

- (BOOL)firstTime
{
	return ONB_firstTime;
}

- (void)setFirstTime:(BOOL)firstTime
{
	ONB_firstTime = firstTime;
}

@end