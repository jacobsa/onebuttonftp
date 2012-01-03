//
//  ONBFileMonitor.h
//  OneButton File Monitor
//
//  Created by Aaron Jacobs on 2005-06-26.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Indicates that some process wrote to a file being monitored.
#define ONBFileWrittenNotification	@"ONBFileWrittenNotification"

// Indicates that a file being monitored was deleted.
// The given file will no longer be monitored.
#define ONBFileDeletedNotification	@"ONBFileDeletedNotification"

@interface ONBFileMonitor : NSObject
{
	// Used by the main thread to keep track of files being monitored
	NSMutableDictionary		*ONB_pathsForIdentifiers;
	NSMutableDictionary		*ONB_userInfoForIdentifiers;
	
	// Used by the kqueue thread to keep track of files being monitored
	NSMutableDictionary		*ONB_kqueueThreadPathsForIdentifiers;
	NSMutableDictionary		*ONB_kqueueThreadDescriptorsForIdentifiers;
	
	// Descriptors for the pipe used to communicate between threads
	int						ONB_pipeReadDescriptor;
	int						ONB_pipeWriteDescriptor;
	
	// Used to keep track of the next free identifier to assign to a file
	// under observation
	int						ONB_freeFileIdentifier;
	
	// The kqueue used to wait for events on the kqueue thread
	int						kq;
}

// Watch the file at the given path for changes and deletes.  Does nothing
// if path doesn't point to a readable file.  When an event is detected, one of the
// notifications listed at the top of this file will be posted with userInfo as the
// notification's userInfo.
- (void)monitorFileAtPath:(NSString *)path userInfo:(NSDictionary *)userInfo;

// Stop watching a file.  Does nothing if the file is not being monitored.
- (void)stopMonitoringFileAtPath:(NSString *)path;

@end