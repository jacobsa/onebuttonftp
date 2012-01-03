//
//  ONBDownloadFileQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-01-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBDownloadFileQueueItem.h"
#import "ONBFTPConnection.h"

@implementation ONBDownloadFileQueueItem

- (void)dealloc
{
	[ONB_downloadHandle release];
	[super dealloc];
}

- (void)connection:(ONBFTPConnection *)connection
		downloadedData:(NSData *)data
		speed:(double)speed
		percentComplete:(double)percentComplete
		userInfo:(NSDictionary *)userInfo
{
	[self setSpeed:speed];
	[self setProgress:percentComplete];
	[ONB_downloadHandle writeData:data];
}

// Create a file handle and tell the connection object to download to it.
- (void)ONB_startTransfer
{
	// Put the connection in ASCII mode if appropriate.
	id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
	if ([[preferences valueForKey:@"autoASCIIMode"] boolValue])
	{
		NSString *extension = [[[self localFile] pathExtension] lowercaseString];
		NSArray *ASCIITypes = [preferences valueForKey:@"ASCIITypes"];
		if ([ASCIITypes containsObject:extension])
			[[self ONB_connection] setUseASCIIMode:YES];
	}

	NSString *filePath = [[self localDirectory] stringByAppendingPathComponent:[self localFile]];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createFileAtPath:filePath contents:[NSData data] attributes:nil];
	
	ONB_downloadHandle = [[NSFileHandle fileHandleForWritingAtPath:filePath] retain];
	
	[[self ONB_connection] downloadFile:[self remoteFile]
									size:[self size]
									userInfo:nil];
}

- (void)ONB_endTransfer
{
	[ONB_downloadHandle release];
	ONB_downloadHandle = nil;
}

- (NSString *)queueDescription
{
	NSString *format = NSLocalizedString(@"Download %@", @"");
	return [NSString stringWithFormat:format, [self remoteFile]];
}

@end