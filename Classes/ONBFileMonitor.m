//
//  ONBFileMonitor.m
//  OneButton File Monitor
//
//  Created by Aaron Jacobs on 2005-06-26.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBFileMonitor.h"
#include <sys/event.h>

typedef enum
{
	ONBWatchFile,
	ONBStopWatchingFile,
	ONBQuit
} ONBKqueueThreadCommand;

typedef enum
{
	ONBFileWritten,
	ONBFileDeleted
} ONBFileChangeType;

@interface ONBFileMonitor (ONBFileMonitorPrivateMethods)
- (void)ONB_logErrorString:(NSString *)error errorCode:(int)errorCode;

- (void)ONB_writeDataToPipe:(NSData *)data;
- (NSData *)ONB_readDataFromPipe:(unsigned int)length;

- (void)ONB_sendCommandToKqueueThread:(ONBKqueueThreadCommand)command;
- (ONBKqueueThreadCommand)ONB_receiveCommandOnKqueueThread;

- (void)ONB_sendIntToKqueueThread:(int)integer;
- (int)ONB_receiveIntOnKqueueThread;

- (void)ONB_sendStringToKqueueThread:(NSString *)string;
- (NSString *)ONB_receiveStringOnKqueueThread;

- (void)ONB_kqueueThread:(id)object;
- (void)ONB_closeAllFiles;
- (int)ONB_openAndWatchFileAtPath:(NSString *)path identifier:(int)identifier;
- (void)ONB_closeAndStopWatchingFileWithIdentifier:(int)identifier;
- (void)ONB_eventForFileWithIdentifier:(int)identifier filterFlags:(unsigned int)flags;
- (void)ONB_fileChange:(NSDictionary *)changeDictionary;
@end

@implementation ONBFileMonitor

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	ONB_freeFileIdentifier = 0;
	ONB_pathsForIdentifiers = [[NSMutableDictionary alloc] init];
	ONB_userInfoForIdentifiers = [[NSMutableDictionary alloc] init];
	
	// Set up a pipe for communication and spin off the kqueue thread
	int descriptors[2];
	if (pipe(descriptors) == -1)
	{
		[self ONB_logErrorString:@"Error creating pipe" errorCode:errno];
		[self dealloc];
		return nil;
	}
	
	ONB_pipeReadDescriptor = descriptors[0];
	ONB_pipeWriteDescriptor = descriptors[1];
	[NSThread detachNewThreadSelector:@selector(ONB_kqueueThread:) toTarget:self withObject:nil];

	return self;
}

- (oneway void)release
{
	// Since NSThread retains us when we spin off another thread, we have to
	// detect when our release count is low enough and tell the thread to quit.
	if ([self retainCount] == 2)
		[self ONB_sendCommandToKqueueThread:ONBQuit];
	
	[super release];
}

- (void)dealloc
{
	[ONB_pathsForIdentifiers release];
	[ONB_userInfoForIdentifiers release];
	
	close(ONB_pipeReadDescriptor);
	close(ONB_pipeWriteDescriptor);
	
	[super dealloc];
}

- (void)ONB_kqueueThread:(id)object
{
	kq = kqueue();
	
	if (kq == -1)
	{
		[self ONB_logErrorString:@"Error setting up kqueue" errorCode:errno];
		return;
	}
	
	struct kevent pipeEvent;
	EV_SET(&pipeEvent, ONB_pipeReadDescriptor, EVFILT_READ, EV_ADD, 0, 0, NULL);
	if (kevent(kq, &pipeEvent, 1, NULL, 0, NULL) == -1)
	{
		[self ONB_logErrorString:@"Error adding pipe event" errorCode:errno];
		return;
	}

	NSAutoreleasePool *pool = nil;
	
	ONB_kqueueThreadPathsForIdentifiers = [[NSMutableDictionary alloc] init];
	ONB_kqueueThreadDescriptorsForIdentifiers = [[NSMutableDictionary alloc] init];
	
	while (1)
	{
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
		
		// Wait for something to happen.
		struct kevent event;
		if (kevent(kq, NULL, 0, &event, 1, NULL) <= 0)
		{
			[self ONB_logErrorString:@"Error getting next event" errorCode:errno];
			break;
		}
		
		if (event.filter == EVFILT_READ)
		{
			// The main thread has sent us a command.
			ONBKqueueThreadCommand command = [self ONB_receiveCommandOnKqueueThread];
			
			if (command == ONBQuit)
			{
				break;
			}
			
			if (command == ONBWatchFile)
			{
				int identifier = [self ONB_receiveIntOnKqueueThread];
				NSString *path = [self ONB_receiveStringOnKqueueThread];
				
				[self ONB_openAndWatchFileAtPath:path identifier:identifier];
			}
			
			if (command == ONBStopWatchingFile)
				[self ONB_closeAndStopWatchingFileWithIdentifier:[self ONB_receiveIntOnKqueueThread]];
		}
		
		else if (event.filter == EVFILT_VNODE)
			[self ONB_eventForFileWithIdentifier:(int)event.udata filterFlags:event.fflags];
	}
	
	[self ONB_closeAllFiles];
	
	[ONB_kqueueThreadPathsForIdentifiers release];
	[ONB_kqueueThreadDescriptorsForIdentifiers release];
	
	[pool release];
}

- (void)monitorFileAtPath:(NSString *)path userInfo:(NSDictionary *)userInfo
{
	// Don't do anything if path doesn't point to a readable file.
	NSString *fullPath = [path stringByExpandingTildeInPath];
	if (! [[NSFileManager defaultManager] isReadableFileAtPath:fullPath])
		return;
	
	int identifier = ONB_freeFileIdentifier++;
	NSNumber *identifierObject = [NSNumber numberWithInt:identifier];
	[ONB_pathsForIdentifiers setObject:path forKey:identifierObject];
	
	if (userInfo)
		[ONB_userInfoForIdentifiers setObject:userInfo forKey:identifierObject];
	
	[self ONB_sendCommandToKqueueThread:ONBWatchFile];
	[self ONB_sendIntToKqueueThread:identifier];
	[self ONB_sendStringToKqueueThread:fullPath];
}

- (void)stopMonitoringFileAtPath:(NSString *)path
{
	NSEnumerator *identifierEnumerator = [[ONB_pathsForIdentifiers allKeysForObject:path] objectEnumerator];
	NSNumber *currentIdentifier;
	
	while (currentIdentifier = [identifierEnumerator nextObject])
	{
		[self ONB_sendCommandToKqueueThread:ONBStopWatchingFile];
		[self ONB_sendIntToKqueueThread:[currentIdentifier intValue]];
		
		[ONB_userInfoForIdentifiers removeObjectForKey:currentIdentifier];
		[ONB_pathsForIdentifiers removeObjectForKey:currentIdentifier];
	}
}

- (void)ONB_sendCommandToKqueueThread:(ONBKqueueThreadCommand)command
{
	NSData *data = [NSData dataWithBytes:(const void *)&command length:sizeof(command)];
	[self ONB_writeDataToPipe:data];
}

- (ONBKqueueThreadCommand)ONB_receiveCommandOnKqueueThread
{
	ONBKqueueThreadCommand command;
	NSData *data = [self ONB_readDataFromPipe:sizeof(command)];
	[data getBytes:(void *)&command];
	
	return command;
}

- (void)ONB_sendIntToKqueueThread:(int)integer
{
	NSData *data = [NSData dataWithBytes:(const void *)&integer length:sizeof(integer)];
	[self ONB_writeDataToPipe:data];
}

- (int)ONB_receiveIntOnKqueueThread
{
	int integer;
	NSData *data = [self ONB_readDataFromPipe:sizeof(integer)];
	[data getBytes:(void *)&integer];
	
	return integer;
}

- (void)ONB_sendStringToKqueueThread:(NSString *)string
{
	const char *UTF8String = [string UTF8String];

	int length = strlen(UTF8String);
	[self ONB_sendIntToKqueueThread:length];
	
	NSData *data = [NSData dataWithBytes:(const void *)UTF8String length:length];
	[self ONB_writeDataToPipe:data];
}

- (NSString *)ONB_receiveStringOnKqueueThread
{
	int length = [self ONB_receiveIntOnKqueueThread];
	NSData *data = [self ONB_readDataFromPipe:length];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return [string autorelease];
}

- (NSData *)ONB_readDataFromPipe:(unsigned int)length
{
	NSMutableData *data = [NSMutableData dataWithLength:length];
	void *buffer = [data mutableBytes];
	ssize_t bytesRead = 0;
	
	while (bytesRead < length)
	{
		ssize_t ret = read(ONB_pipeReadDescriptor, buffer + bytesRead, length - bytesRead);
		if (ret == -1)
		{
			[self ONB_logErrorString:@"Error reading from pipe" errorCode:errno];
			return nil;
		}
		
		bytesRead += ret;
	}
	
	return data;
}

- (void)ONB_writeDataToPipe:(NSData *)data
{
	const void *buffer = [data bytes];
	size_t bytesToWrite = [data length];
	ssize_t bytesWritten = 0;
	
	while (bytesWritten < bytesToWrite)
	{
		ssize_t ret = write(ONB_pipeWriteDescriptor, buffer + bytesWritten, bytesToWrite - bytesWritten);
		if (ret == -1)
		{
			[self ONB_logErrorString:@"Error writing to pipe" errorCode:errno];
			return;
		}
		
		bytesWritten += ret;
	}
}

- (void)ONB_logErrorString:(NSString *)error errorCode:(int)errorCode
{
	NSLog(@"%@: %d", error, errorCode);
}

- (int)ONB_openAndWatchFileAtPath:(NSString *)path identifier:(int)identifier
{
	const char *UTF8Path = [path UTF8String];
	unsigned int i;
	int ret;
	
	// Try three times to open, sleeping between each, to account for the fact that
	// editors like vi and TextEdit save a file by unlinking it and then re-writing it.
	for (i=0; i<3; i++)
	{
		ret = open(UTF8Path, O_EVTONLY);
		
		if (ret != -1)
			break;
		
		usleep(100000);
	}
	
	if (ret == -1)
		return -1;
	
	struct kevent event;
	EV_SET(&event,
			ret,
			EVFILT_VNODE,
			EV_ADD | EV_CLEAR,
			NOTE_WRITE | NOTE_DELETE,
			0,
			(void *)identifier);

	if (kevent(kq, &event, 1, NULL, 0, NULL) == -1)
	{
		[self ONB_logErrorString:@"Error adding event to queue" errorCode:errno];
		return -1;
	}
	
	NSNumber *identifierObject = [NSNumber numberWithInt:identifier];
	NSNumber *descriptorObject = [NSNumber numberWithInt:ret];
	[ONB_kqueueThreadPathsForIdentifiers setObject:path forKey:identifierObject];
	[ONB_kqueueThreadDescriptorsForIdentifiers setObject:descriptorObject forKey:identifierObject];
	
	return 0;
}

- (void)ONB_eventForFileWithIdentifier:(int)identifier filterFlags:(unsigned int)flags
{
	NSNumber *identifierObject = [NSNumber numberWithInt:identifier];
	ONBFileChangeType changeType;

	if (flags & NOTE_DELETE)
	{
		NSString *path = [ONB_kqueueThreadPathsForIdentifiers objectForKey:identifierObject];
		path = [[path retain] autorelease];
		
		[self ONB_closeAndStopWatchingFileWithIdentifier:identifier];
		if ([self ONB_openAndWatchFileAtPath:path identifier:identifier] == -1)
			changeType = ONBFileDeleted;
		else
			changeType = ONBFileWritten;
	}
	else if (flags & NOTE_WRITE)
		changeType = ONBFileWritten;
	else
		return;
	
	NSNumber *changeTypeObject = [NSNumber numberWithInt:(int)changeType];
	NSDictionary *changeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:changeTypeObject,
																				@"changeType",
																				identifierObject,
																				@"identifier",
																				nil];

	[self performSelectorOnMainThread:@selector(ONB_fileChange:) withObject:changeDictionary waitUntilDone:NO];
}

- (void)ONB_closeAndStopWatchingFileWithIdentifier:(int)identifier
{
	NSNumber *identifierObject = [NSNumber numberWithInt:identifier];
	NSNumber *descriptorObject = [ONB_kqueueThreadDescriptorsForIdentifiers objectForKey:identifierObject];
	if (descriptorObject)
		close([descriptorObject intValue]);
	
	[ONB_kqueueThreadPathsForIdentifiers removeObjectForKey:identifierObject];
	[ONB_kqueueThreadDescriptorsForIdentifiers removeObjectForKey:identifierObject];
}

- (void)ONB_fileChange:(NSDictionary *)changeDictionary
{
	NSNumber *changeTypeObject = [changeDictionary objectForKey:@"changeType"];
	ONBFileChangeType changeType = (ONBFileChangeType)[changeTypeObject intValue];

	NSNumber *identifier = [changeDictionary objectForKey:@"identifier"];
	NSDictionary *userInfo = [[[ONB_userInfoForIdentifiers objectForKey:identifier] retain] autorelease];
	NSString *path = [[[ONB_pathsForIdentifiers objectForKey:identifier] retain] autorelease];
	NSString *name = nil;
		
	switch (changeType)
	{
		case ONBFileWritten:
			name = ONBFileWrittenNotification;
			break;
		
		case ONBFileDeleted:
			[self stopMonitoringFileAtPath:path];
			name = ONBFileDeletedNotification;
			break;
	}
	
	if (name)
		[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (void)ONB_closeAllFiles
{
	NSEnumerator *identifierEnumerator = [[ONB_kqueueThreadDescriptorsForIdentifiers allKeys] objectEnumerator];
	NSNumber *currentIdentifier;
	
	while (currentIdentifier = [identifierEnumerator nextObject])
		[self ONB_closeAndStopWatchingFileWithIdentifier:[currentIdentifier intValue]];
}

@end