//
//  ONBUploadDirectoryQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-27.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBUploadDirectoryQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBFileListing.h"
#import "ONBUploadFileQueueItem.h"
#import "ONBQueue.h"

@implementation ONBUploadDirectoryQueueItem

- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	ONB_completedTransfers++;
	
	if (ONB_completedTransfers == 1)
	{
		// Got the path before cd'ing to the directory to do our thing.
		ONB_previousPath = [[userInfo objectForKey:@"currentDirectory"] copy];
		
		// Now tell the connection to switch to the parent of the remote directory.
		// We want to see if it already exists or not.
		NSString *parentDirectory = [[self remoteDirectory] stringByDeletingLastPathComponent];
		[connection changeDirectory:parentDirectory userInfo:nil];
	}

	else if (ONB_completedTransfers == 2)
	{
		// We've changed to the parent directory of the directory to be transferred to.
		// Get the directory listing.
		[connection getDirectoryListingWithUserInfo:nil];
	}
	
	else if (ONB_completedTransfers == 3)
	{
		// Got the directory listing for remoteDirectory's parent.  Find out if it exists or
		// not.
		NSArray *listing = [[userInfo objectForKey:@"directoryListing"] retain];

		BOOL exists = NO;
		NSEnumerator *listingEnumerator = [listing objectEnumerator];
		ONBFileListing *currentListing;
		NSString *directory = [[self remoteDirectory] lastPathComponent];
		
		while (currentListing = [listingEnumerator nextObject])
			if ([[currentListing name] isEqualToString:directory])
			{
				exists = YES;
				break;
			}
			
		if (! exists)
		{
			// Create the directory.
			[[self ONB_connection] createDirectory:directory userInfo:nil];
		}
		else
		{
			// Do something that doesn't affect anything.
			[[self ONB_connection] getCurrentDirectoryWithUserInfo:nil];
		}
	}
	
	else if (ONB_completedTransfers == 4)
	{
		// Now the remote directory exists, if it didn't before.  Get the listing
		// for the local directory so that we can add appropriate queue items.
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *localDirectory = [self localDirectory];
		NSArray *localContents = [fileManager directoryContentsAtPath:localDirectory];
		NSMutableArray *queueItems = [NSMutableArray arrayWithCapacity:[localContents count]];
		NSEnumerator *contentsEnumerator = [localContents objectEnumerator];
		NSString *name;
		
		while (name = [contentsEnumerator nextObject])
		{
			// Find out whether the file is a directory or not
			NSString *fullPath = [localDirectory stringByAppendingPathComponent:name];
			BOOL isDirectory = NO;
			[fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
			
			if (isDirectory)
			{
				ONBUploadDirectoryQueueItem *queueItem;
				queueItem = [[ONBUploadDirectoryQueueItem alloc] init];

				NSString *remoteDirectory = [self remoteDirectory];
				remoteDirectory = [remoteDirectory stringByAppendingPathComponent:name];
				
				[queueItem setLocalDirectory:fullPath];
				[queueItem setRemoteDirectory:remoteDirectory];
				
				[queueItems addObject:queueItem];
				
				[queueItem release];
			}
			else
			{
				ONBUploadFileQueueItem *queueItem = [[ONBUploadFileQueueItem alloc] init];
				
				[queueItem setLocalDirectory:localDirectory];
				[queueItem setLocalFile:name];
				[queueItem setRemoteDirectory:[self remoteDirectory]];
				[queueItem setRemoteFile:name];
				
				[queueItems addObject:queueItem];
				
				[queueItem release];
			}
		}
		
		[[self ONB_queue] insertObjects:queueItems inMainQueueItemsAtIndex:0];
		
		// Switch back to the remembered path.
		[connection changeDirectory:ONB_previousPath userInfo:nil];
	}
	
	else if (ONB_completedTransfers == 5)
	{
		ONBQueue *queue = [self ONB_queue];
		
		NSNumber *success = [NSNumber numberWithBool:YES];
		
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:success,
																		@"success",
																		[self localDirectory],
																		@"localDirectory",
																		[self remoteDirectory],
																		@"remoteDirectory",
																		nil];
		[queue queueItemSucceededWithInfo:info];
		[self ONB_cleanUp];
	}
}

- (NSString *)queueDescription
{
	NSString *format = NSLocalizedString(@"Upload directory %@", @"");
	return [NSString stringWithFormat:format, [self localDirectory]];
}

@end