//
//  ONBDaughterController.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-11-01.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ONBRemoteView;
@class ONBConnectionController;

@interface ONBDaughterController : NSObject
{
	NSNumber								*ONB_identifier;
	ONBConnectionController					*ONB_controller;

	// Interface values
	NSString								*ONB_windowTitle;

	// Interface objects
	IBOutlet NSArrayController				*ONB_fileListingsController;
	IBOutlet NSArrayController				*ONB_queueItemsController;
	IBOutlet ONBRemoteView					*ONB_fileListingsTableView;
	IBOutlet NSTableView					*ONB_queueTableView;
	IBOutlet NSWindow						*ONB_connectionWindow;
	IBOutlet NSWindow						*ONB_newDirectorySheet;
	IBOutlet NSWindow						*ONB_renameSheet;
	
	// For interface bindings
	NSString								*ONB_newDirectory;
	NSString								*ONB_newName;
	BOOL									ONB_transferInProgress;
	double									ONB_transferProgress;
}

// Allows the connection controller to keep track of the status of multiple windows
- (NSNumber *)identifier;
- (void)setIdentifier:(NSNumber *)identifier;

- (ONBConnectionController *)controller;
- (void)setController:(ONBConnectionController *)controller;

- (void)setFileListings:(NSArray *)listings;

// These methods are used for binding the progress bar.  The connection controller
// is responsible for running the set* methods.
- (BOOL)transferInProgress;
- (void)setTransferInProgress:(BOOL)transferInProgress;

- (double)transferProgress;
- (void)setTransferProgress:(double)transferProgress;

- (BOOL)noTransferProgress;

// User interface actions
- (IBAction)changeDirectory:(id)sender;				// Change to currently selected directory
- (IBAction)downloadFile:(id)sender;				// Download the currently selected file
- (IBAction)deleteFiles:(id)sender;					// Delete the currently selected files
- (IBAction)refresh:(id)sender;						// Refresh file listings
- (IBAction)newDirectory:(id)sender;				// Create a new directory
- (IBAction)rename:(id)sender;						// Rename the selected file
- (IBAction)editFile:(id)sender;					// Download the selected file and open for editing
- (IBAction)addToQueue:(id)sender;					// Add selected files to queue
- (IBAction)removeFromQueue:(id)sender;				// Remove the selected queue items from the queue
- (IBAction)runPauseQueue:(id)sender;				// Run or pause the queue depending on its current state


// These two methods are called by the Create and Cancel buttons of the new directory sheet
- (IBAction)createDirectory:(id)sender;
- (IBAction)dismissNewDirectory:(id)sender;

// These two methods are called by the Rename and Cancel buttons of the rename sheet
- (IBAction)doRename:(id)sender;
- (IBAction)dismissRename:(id)sender;

// Key-value coding support for the interface
- (NSString *)windowTitle;
- (void)setWindowTitle:(NSString *)windowTitle;

// Binding for the new directory sheet
- (NSString *)newDirectory;
- (void)setNewDirectory:(NSString *)newDirectory;

// Binding for the rename sheet
- (NSString *)newName;
- (void)setNewName:(NSString *)newName;

- (NSImage *)removeFromQueueImage;

- (unsigned int)remoteListingsSelected;
- (unsigned int)queueItemsSelected;
- (BOOL)canDelete;
- (BOOL)canRename;
- (BOOL)canEdit;
- (BOOL)canAddToQueue;
- (BOOL)canRemoveFromQueue;

// Create download queue items for the currently selected files and put them in the queue
// at the given index.
- (void)addSelectedItemsToQueueAtIndex:(unsigned int)index;

// Delegate methods for the window
- (void)windowWillClose:(NSNotification *)notification;

// Help the remote view out with HFS promise dragging
- (NSArray *)fileTypesForRemoteView:(ONBRemoteView *)remoteView
								rows:(NSIndexSet *)rows;

- (NSArray *)promisedFilesDroppedFromRemoteView:(ONBRemoteView *)remoteView
										destination:(NSURL *)dropDestination
										rows:(NSIndexSet *)rows;
										
// Handle double-clicks in the remote view
- (void)ONB_remoteViewDoubleClicked:(id)sender;

@end