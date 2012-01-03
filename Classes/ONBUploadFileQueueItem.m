//
//  ONBUploadFileQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-01-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBUploadFileQueueItem.h"
#import "ONBFTPConnection.h"

@implementation ONBUploadFileQueueItem

- (void)ONB_recomputeSize
{
	NSString *filePath = [[self localDirectory] stringByAppendingPathComponent:[self localFile]];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:filePath traverseLink:YES];
	
	if (! fileAttributes)
	{
		[self setSize:nil];
		return;
	}
	
	[self setSize:[[fileAttributes objectForKey:NSFileSize] unsignedIntValue]];
}

- (void)setLocalDirectory:(NSString *)localDirectory
{
	[super setLocalDirectory:localDirectory];
	[self ONB_recomputeSize];
}

- (void)setLocalFile:(NSString *)localFile
{
	[super setLocalFile:localFile];
	[self ONB_recomputeSize];
}

- (NSData *)provideUploadDataForConnection:(ONBFTPConnection *)connection
									length:(unsigned int)length
									userInfo:(NSDictionary *)userInfo
{
	NSData *data = [ONB_uploadHandle readDataOfLength:length];
	
	if (! [data length])
		return nil;
	
	return data;
}

- (void)connection:(ONBFTPConnection *)connection
		uploadStatusSpeed:(double)speed
		percentComplete:(double)percentComplete
		userInfo:(NSDictionary *)userInfo
{
	[self setSpeed:speed];
	[self setProgress:percentComplete];
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

	[self ONB_recomputeSize];
	NSString *filePath = [[self localDirectory] stringByAppendingPathComponent:[self localFile]];
	ONB_uploadHandle = [[NSFileHandle fileHandleForReadingAtPath:filePath] retain];
	
	[[self ONB_connection] uploadFileWithName:[self remoteFile]
											size:[self size]
											userInfo:nil];
}

- (void)ONB_endTransfer
{
	[ONB_uploadHandle release];
	ONB_uploadHandle = nil;
}

- (void)dealloc
{
	[ONB_uploadHandle release];
	[super dealloc];
}

- (NSString *)queueDescription
{
	NSString *format = NSLocalizedString(@"Upload %@", @"");
	return [NSString stringWithFormat:format, [self localFile]];
}

@end