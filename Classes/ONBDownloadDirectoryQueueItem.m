//
//  ONBDownloadDirectoryQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-26.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBDownloadDirectoryQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBFileListing.h"
#import "ONBDownloadFileQueueItem.h"
#import "ONBQueue.h"

@implementation ONBDownloadDirectoryQueueItem

- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	// The first thing we need to do is check if the local directory exists.
	// If it doesn't exist, create it.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
	BOOL exists = [fileManager fileExistsAtPath:[self localDirectory] isDirectory:&isDirectory];
	
	if (exists && (! isDirectory))
	{
		// We've been asked to write to a normal file!
		NSNumber *success = [NSNumber numberWithBool:NO];
		NSDictionary *info = [NSDictionary dictionaryWithObject:success
														forKey:@"success"];
		[queue queueItemSucceededWithInfo:info];
		return;
	}
	
	if (! exists)
		[fileManager createDirectoryAtPath:[self localDirectory] attributes:nil];
	
	[super runWithConnection:connection queue:queue];
}

- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo
{
	ONB_completedTransfers++;
	
	if (ONB_completedTransfers == 1)
	{
		// Got the path before cd'ing to the directory to do our thing.
		ONB_previousPath = [[userInfo objectForKey:@"currentDirectory"] copy];
		
		// Now tell the connection to switch to the directory we want to transfer from
		[connection changeDirectory:[self remoteDirectory] userInfo:nil];
	}

	else if (ONB_completedTransfers == 2)
	{
		// We've changed to the directory to be transfered from.  Now get the
		// directory listing.
		[connection getDirectoryListingWithUserInfo:nil];
	}
	
	else if (ONB_completedTransfers == 3)
	{
		// Got the directory listing.
		NSArray *listing = [[userInfo objectForKey:@"directoryListing"] retain];

		// Add the appropriate queue items to the main queue and then switch
		// back to the previous path.
		NSMutableArray *queueItems = [NSMutableArray arrayWithCapacity:[listing count]];
		NSEnumerator *listingEnumerator = [listing objectEnumerator];
		ONBFileListing *currentListing;
		
		while (currentListing = [listingEnumerator nextObject])
		{
			NSString *name = [currentListing name];
			
			if ([currentListing isRegularFile])
			{
				ONBDownloadFileQueueItem *queueItem = [[ONBDownloadFileQueueItem alloc] init];
				[queueItem setLocalDirectory:[self localDirectory]];
				[queueItem setLocalFile:name];
				[queueItem setRemoteDirectory:[self remoteDirectory]];
				[queueItem setRemoteFile:name];
				[queueItem setSize:[[currentListing size] unsignedIntValue]];
				
				[queueItems addObject:queueItem];
				
				[queueItem release];
			}
			
			else if ([currentListing isDirectory])
			{
				// Ignore listings for ".." and "."
				if ([name isEqualToString:@".."] || [name isEqualToString:@"."])
					continue;
				
				ONBDownloadDirectoryQueueItem *queueItem;
				queueItem = [[ONBDownloadDirectoryQueueItem alloc] init];
				
				NSString *localPath;
				localPath = [[self localDirectory] stringByAppendingPathComponent:name];
				
				NSString *remotePath;
				remotePath = [[self remoteDirectory] stringByAppendingPathComponent:name];
				
				[queueItem setLocalDirectory:localPath];
				[queueItem setRemoteDirectory:remotePath];
				
				[queueItems addObject:queueItem];

				[queueItem release];
			}
			
			else
			{
				// Unrecognized file type.
				continue;
			}
		}
		
		[[self ONB_queue] insertObjects:queueItems inMainQueueItemsAtIndex:0];
		
		[connection changeDirectory:ONB_previousPath userInfo:nil];
	}
	
	else if (ONB_completedTransfers == 4)
	{
		NSNumber *success = [NSNumber numberWithBool:YES];
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:success,
																		@"success",
																		[self localDirectory],
																		@"localDirectory",
																		[self remoteDirectory],
																		@"remoteDirectory",
																		nil];
		[[self ONB_queue] queueItemSucceededWithInfo:info];
		[self ONB_cleanUp];
	}
}

- (NSString *)queueDescription
{
	NSString *format = NSLocalizedString(@"Download directory %@", @"");
	return [NSString stringWithFormat:format, [self remoteDirectory]];
}

@end