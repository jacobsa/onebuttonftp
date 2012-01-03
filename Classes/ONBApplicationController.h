//
//  ONBApplicationController.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-10-31.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ONBBookmark.h"

@interface ONBApplicationController : NSObject
{
	// Controllers for known connections
	NSMutableArray					*ONB_connectionControllers;

	// Dummy bookmark for holding information from new connection window
	ONBBookmark						*ONB_newBookmark;
	
	// Bookmark being edited in the edit window
	ONBBookmark						*ONB_editBookmark;
	
	// For converting values to display in connection manager outline view
	NSValueTransformer				*ONB_sizeTransformer;
	
	// For keeping track of the children of connection controllers in the connection
	// manager outline view.
	unsigned int					ONB_freeIdentifier;
	NSMutableDictionary				*ONB_outlineViewChildren;
	
	NSString						*ONB_newASCIIType;
	
	IBOutlet NSWindow				*connectionManagerWindow;
	IBOutlet NSWindow				*newConnectionWindow;
	IBOutlet NSWindow				*editBookmarkWindow;
	IBOutlet NSOutlineView			*connectionsOutlineView;
	IBOutlet NSTableView			*ASCIITypesTable;
	IBOutlet NSArrayController		*ASCIITypesController;
}

// Sent by the Connect button in the New Connection window
- (IBAction)makeNewConnection:(id)sender;

// Sent by the Add Type button in the preferences window
- (IBAction)addASCIIType:(id)sender;

// Sent by the Remove Type button in the preferences window
- (IBAction)removeASCIIType:(id)sender;

// Bound to by the new type text field in the preferences window
- (NSString *)newASCIIType;
- (void)setNewASCIIType:(NSString *)newASCIIType;

// Sent by the Connect toolbar item
- (void)connectWithSelectedBookmarks:(id)sender;

// Sent by the Disconnect toolbar item
- (void)disconnectSelectedBookmarks:(id)sender;

// Sent by the Edit toolbar item
- (void)editSelectedBookmark:(id)sender;

// Sent by the Delete toolbar item
- (void)deleteSelectedConnections:(id)sender;

// Sent by the Console toolbar item
- (void)showConsoleForSelectedConnections:(id)sender;

// Key-Value Coding
- (ONBBookmark *)newBookmark;

// An array of all known connections
- (NSArray *)connectionControllers;

// The bookmark to be edited in the edit window
- (ONBBookmark *)editBookmark;
- (void)setEditBookmark:(ONBBookmark *)editBookmark;

// The connection controllers that are currently selected in the connection manager
- (NSArray *)selectedConnections;

@end