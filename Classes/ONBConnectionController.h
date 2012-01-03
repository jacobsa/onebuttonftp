//
//  ONBConnectionController.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-04-21.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ONBQueueOwning.h"

extern NSImage *scaleImageToFitButton(NSString *imageName);

@class ONBBookmark;
@class ONBDaughterController;
@class ONBConsoleController;
@class ONBQueue;
@class ONBFileMonitor;

@interface ONBConnectionController : NSObject < ONBQueueOwning >
{
	// Controllers and properties for the currently open connection windows
	NSMutableDictionary				*ONB_windowControllers;
	NSMutableDictionary				*ONB_daughterControllers;
	NSMutableDictionary				*ONB_currentPaths;
	
	// Controllers for the console window
	NSWindowController				*ONB_consoleWindowController;
	ONBConsoleController			*ONB_consoleController;
	
	// Bookmark for the connection
	ONBBookmark						*ONB_bookmark;
	
	// The path where the server started us out when we first connected
	NSString						*ONB_firstPath;
	
	ONBQueue						*ONB_queue;
	NSNumber						*ONB_identifier;
	BOOL							ONB_selfInitiatedDisconnect;
	
	NSMutableArray					*ONB_editItems;
	ONBFileMonitor					*ONB_editItemMonitor;
}

// Designated initializer
- (id)initWithBookmark:(ONBBookmark *)bookmark;

// Look up the given controllers and/or properties
- (NSWindowController *)windowControllerWithIdentifier:(NSNumber *)identifier;
- (ONBDaughterController *)daughterControllerWithIdentifier:(NSNumber *)identifier;
- (NSString *)currentPathForWindowWithIdentifier:(NSNumber *)identifier;

- (void)setWindowController:(NSWindowController *)controller forIdentifier:(NSNumber *)identifier;
- (void)setDaughterController:(ONBDaughterController *)controller forIdentifier:(NSNumber *)identifier;
- (void)setCurrentPath:(NSString *)currentPath forWindowWithIdentifier:(NSNumber *)identifier;

- (void)destroyIdentifier:(NSNumber *)identifier;
- (NSArray *)windowControllers;
- (NSEnumerator *)daughterControllerEnumerator;

// Bookmark for the connection
- (ONBBookmark *)bookmark;

// Connect to the assigned bookmark and open a connection window
- (void)connectAndOpenWindow;

// Disconnect the queue and close all connection windows
- (void)disconnectAndCloseWindows;

// Show the console window
- (void)showConsoleWindow;

// The queue for the connection
- (ONBQueue *)queue;

// Bindings for whether or not the queue can be run or paused (whether it is empty or not)
// and which image should be used (whether it is a play button or a pause button)
- (BOOL)canRunPauseQueue;
- (NSImage *)runPauseQueueImage;

// These methods are called by instances of ONBDaughterController.
- (void)changeDirectoryTo:(NSString *)directory identifier:(NSNumber *)identifier;
- (void)getCurrentPathForIdentifier:(NSNumber *)identifier;

- (void)fileNames:(NSArray *)fileNames
		droppedOnRemoteSubdirectory:(NSString *)subdirectory
		identifier:(NSNumber *)identifier;

- (void)addLocalFiles:(NSArray *)fileNames
		toQueueAtIndex:(unsigned int)index
		remoteSubdirectory:(NSString *)subdirectory
		identifier:(NSNumber *)identifier;

- (void)fileNames:(NSArray *)fileNames
		droppedOnQueueViewAtIndex:(unsigned int)index
		identifier:(NSNumber *)identifier;

- (void)addRemoteListings:(NSArray *)listings
			toQueueAtIndex:(unsigned int)index
			localDestination:(NSString *)destination
			identifier:(NSNumber *)identifier;

- (void)addRemoteListings:(NSArray *)listings
			toQueueAtIndex:(unsigned int)index
			identifier:(NSNumber *)identifier;

- (void)addRemoteListingsToEndOfQueue:(NSArray *)listings
			identifier:(NSNumber *)identifier;

- (void)remoteListings:(NSArray *)listings
			droppedToLocalPath:(NSString *)path
			identifier:(NSNumber *)identifier;

- (void)editFilesForRemoteListings:(NSArray *)listings
						identifier:(NSNumber *)identifier;

- (void)deleteRemoteListings:(NSArray *)listings
			identifier:(NSNumber *)identifier;

- (void)windowClosingForIdentifier:(NSNumber *)identifier;

- (void)refreshListingsForIdentifier:(NSNumber *)identifier;

- (void)createNewDirectory:(NSString *)directory identifier:(NSNumber *)identifier;

- (void)renameFile:(NSString *)name to:(NSString *)newName identifier:(NSNumber *)identifier;

- (void)removeQueueItemsAtIndexes:(NSIndexSet *)indexes identifier:(NSNumber *)identifier;

- (void)runPauseQueueForIdentifier:(NSNumber *)identifier;

// Identifier used by the application controller
- (NSNumber *)identifier;
- (void)setIdentifier:(NSNumber *)identifier;

// Get an identifier for a new window controller
- (NSNumber *)ONB_freeWindowIdentifer;

// Called when we get a notification indicating that a file we are watching has been updated
- (void)fileChangeNotification:(NSNotification *)notification;

// Delete any open temporary files for editing
- (void)deleteTemporaryFiles;

@end