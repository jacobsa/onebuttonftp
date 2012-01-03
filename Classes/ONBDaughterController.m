//
//  ONBDaughterController.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-11-01.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBDaughterController.h"
#import "ONBConnectionController.h"
#import "ONBFileListingNameCell.h"
#import "ONBRemoteView.h"
#import "ONBFileListing.h"
#import "ONBQueue.h"

#define ONBConnectionWindowToolbarIdentifier		@"ONBConnectionWindowToolbarIdentifier"
#define ONBAddToQueueToolbarItemIdentifier			@"ONBAddToQueueToolbarItemIdentifier"
#define ONBDeleteToolbarItemIdentifier				@"ONBDeleteToolbarItemIdentifier"
#define ONBNewDirectoryToolbarItemIdentifier		@"ONBNewDirectoryToolbarItemIdentifier"
#define ONBRefreshToolbarItemIdentifier				@"ONBRefreshToolbarItemIdentifier"
#define ONBRenameToolbarItemIdentifier				@"ONBRenameToolbarItemIdentifier"
#define ONBEditToolbarItemIdentifier				@"ONBEditToolbarItemIdentifier"

#define ONBRemoteViewNameColumnIdentifier			@"name"

// Scale an image to fit a button in the interface
NSImage *scaleImageToFitButton(NSString *imageName)
{
	// Make a copy of the image so we don't change its properties somewhere else
	NSImage *image = [[[NSImage imageNamed:imageName] copy] autorelease];

	[image setScalesWhenResized:YES];
	[image setSize:NSMakeSize(24, 24)];

	return image;
}

@implementation ONBDaughterController

+ (void)initialize
{
	// Set up KVC dependencies
	[self setKeys:[NSArray arrayWithObjects:@"remoteListingsSelected", nil]
			triggerChangeNotificationsForDependentKey:@"canDelete"];

	[self setKeys:[NSArray arrayWithObjects:@"remoteListingsSelected", nil]
			triggerChangeNotificationsForDependentKey:@"canRename"];

	[self setKeys:[NSArray arrayWithObjects:@"remoteListingsSelected", nil]
			triggerChangeNotificationsForDependentKey:@"canAddToQueue"];

	[self setKeys:[NSArray arrayWithObjects:@"queueItemsSelected", nil]
			triggerChangeNotificationsForDependentKey:@"canRemoveFromQueue"];

	[self setKeys:[NSArray arrayWithObjects:@"transferInProgress", @"transferProgress", nil]
			triggerChangeNotificationsForDependentKey:@"noTransferProgress"];
}

- (NSNumber *)identifier
{
	return ONB_identifier;
}

- (void)setIdentifier:(NSNumber *)identifier;
{
	[ONB_identifier autorelease];
	ONB_identifier = [identifier copy];
}

- (ONBConnectionController *)controller
{
	return ONB_controller;
}

- (void)setController:(ONBConnectionController *)controller
{
	// Weak reference
	ONB_controller = controller;
}

- (void)dealloc
{
	[self setNewDirectory:nil];
	[self setNewName:nil];
	
	[self setIdentifier:nil];
	
	// Remove ourself as an observer
	[self removeObserver:self forKeyPath:@"canAddToQueue"];
	[self removeObserver:self forKeyPath:@"canDelete"];
	[self removeObserver:self forKeyPath:@"canRename"];

	[super dealloc];
}

- (void)awakeFromNib
{
	NSString *title = NSLocalizedString(@"New Connection", @"");
	[self setWindowTitle:title];

	// Set up the connection window's toolbar
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:ONBConnectionWindowToolbarIdentifier];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	
	[toolbar setDelegate:self];
	[ONB_connectionWindow setToolbar:toolbar];
	
	[toolbar release];

	// Make the font size smaller in the file listings table
	NSEnumerator *columnsEnumerator = [[ONB_fileListingsTableView tableColumns] objectEnumerator];
	NSTableColumn *currentColumn;
	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	
	while (currentColumn = [columnsEnumerator nextObject])
	{
		NSCell *cell = [currentColumn dataCell];
		
		if ([[currentColumn identifier] isEqual:ONBRemoteViewNameColumnIdentifier])
		{
			[currentColumn setSortDescriptorPrototype:sortDescriptor];
		
			cell = [[[ONBFileListingNameCell alloc] init] autorelease];
			[currentColumn setDataCell:cell];
			[(NSBrowserCell *)cell setLeaf:YES];
		}
		
		NSFont *oldFont = [cell font];
		NSFont *newFont = [NSFont fontWithName:[oldFont fontName] size:11.0];

		[cell setFont:newFont];
	}
	
	[ONB_fileListingsTableView setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	// Make the font size smaller in the queue table
	columnsEnumerator = [[ONB_queueTableView tableColumns] objectEnumerator];
	
	while (currentColumn = [columnsEnumerator nextObject])
	{
		NSCell *cell = [currentColumn dataCell];
		
		NSFont *oldFont = [cell font];
		NSFont *newFont = [NSFont fontWithName:[oldFont fontName] size:11.0];

		[cell setFont:newFont];
		
		// Make it so the user cannot re-order the queue by clicking on columns
		NSSortDescriptor *noSort = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
		[currentColumn setSortDescriptorPrototype:noSort];
		[noSort release];
	}

	
	[ONB_fileListingsTableView setTarget:self];
	[ONB_fileListingsTableView setDoubleAction:@selector(ONB_remoteViewDoubleClicked:)];
	
	[ONB_fileListingsTableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	[ONB_queueTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,
																			NSFilesPromisePboardType,
																			nil]];

	// Observe ourself so that we know when to re-validate the toolbar items.
	[self addObserver:self forKeyPath:@"canAddToQueue" options:0 context:nil];
	[self addObserver:self forKeyPath:@"canDelete" options:0 context:nil];
	[self addObserver:self forKeyPath:@"canRename" options:0 context:nil];
}

- (NSString *)windowTitle
{
	return ONB_windowTitle;
}

- (void)setWindowTitle:(NSString *)windowTitle
{
	[ONB_windowTitle autorelease];
	ONB_windowTitle = [windowTitle copy];
}

- (NSString *)newDirectory
{
	return ONB_newDirectory;
}

- (NSString *)newName
{
	return ONB_newName;
}

- (NSImage *)removeFromQueueImage
{
	return scaleImageToFitButton(@"RemoveFromQueue");
}

- (unsigned int)queueItemsSelected
{
	NSArray *selectedItems = [ONB_queueItemsController selectedObjects];
	
	return [selectedItems count];
}

- (unsigned int)remoteListingsSelected
{
	NSArray *selectedListings = [ONB_fileListingsController selectedObjects];
	
	return [selectedListings count];
}

- (BOOL)canDelete
{
	return ([self remoteListingsSelected] ? YES : NO);
}

- (BOOL)canRename
{
	return ([self remoteListingsSelected] == 1);
}

- (BOOL)canEdit
{
	NSArray *selectedListings = [ONB_fileListingsController selectedObjects];
	if (! [selectedListings count])
		return NO;
	
	NSEnumerator *listingEnumerator = [selectedListings objectEnumerator];
	ONBFileListing *currentListing;
	
	while (currentListing = [listingEnumerator nextObject])
		if (! [currentListing isRegularFile])
			return NO;
	
	return YES;
}

- (BOOL)canAddToQueue
{
	return ([self remoteListingsSelected] ? YES : NO);
}

- (BOOL)canRemoveFromQueue
{
	return ([self queueItemsSelected] ? YES : NO);
}

- (void)setNewDirectory:(NSString *)newDirectory
{
	[ONB_newDirectory autorelease];
	ONB_newDirectory = [newDirectory copy];
}

- (void)setNewName:(NSString *)newName
{
	[ONB_newName autorelease];
	ONB_newName = [newName copy];
}

- (void)setFileListings:(NSArray *)listings
{
	[ONB_fileListingsController setContent:[NSMutableArray arrayWithArray:listings]];
}

- (void)ONB_remoteViewDoubleClicked:(id)sender
{
	// Don't do anything if the double-click was in empty space
	if ([sender clickedRow] == -1)
		return;
		
	// If the double-click was on a directory, switch to it
	if ([[ONB_fileListingsController valueForKeyPath:@"selection.isDirectory"] boolValue])
		[self changeDirectory:self];
	
	// If the double-click was on a file, download it
	else if ([[ONB_fileListingsController valueForKeyPath:@"selection.isRegularFile"] boolValue])
	{
		[self downloadFile:self];

		id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
		if ([[preferences valueForKey:@"startQueueImmediatelyOnFileAction"] boolValue])
			[[[self controller] queue] runQueue];
	}
}

- (IBAction)changeDirectory:(id)sender
{
	if (! ONB_fileListingsController)
		return;

	NSString *directory = [ONB_fileListingsController valueForKeyPath:@"selection.name"];
	if (! [directory isKindOfClass:[NSString class]])
	{
		NSLog(@"Error! Attempted to change directory with no directory selected!");
		return;
	}
	
	[[self controller] changeDirectoryTo:directory identifier:[self identifier]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([[notification object] isEqual:ONB_fileListingsTableView])
	{
		// The file selection has changed, so the "Delete" button
		// needs to re-evaluate whether it should be enabled.
		[self willChangeValueForKey:@"remoteListingsSelected"];
		[self didChangeValueForKey:@"remoteListingsSelected"];
	}

	if ([[notification object] isEqual:ONB_queueTableView])
	{
		// The file selection has changed, so the "Delete" button
		// needs to re-evaluate whether it should be enabled.
		[self willChangeValueForKey:@"queueItemsSelected"];
		[self didChangeValueForKey:@"queueItemsSelected"];
	}
}

// We are dishonest in this method and only actually return the first file type
// being dragged.  Why?  Because of a change in the way promise dragging apparently
// works in Tiger.  We return nil for the names of the files dropped, and in Tiger
// when we do this it will call asking for the names as many times as the number
// of file types we give to it.  So we only give it one type.
- (NSArray *)fileTypesForRemoteView:(ONBRemoteView *)remoteView
								rows:(NSIndexSet *)rows
{
	if (! ONB_fileListingsController)
		return nil;

	NSArray *listings = [ONB_fileListingsController arrangedObjects];
	unsigned int currentRow = [rows firstIndex];

	while(currentRow != NSNotFound)
	{
		ONBFileListing *fileListing = [listings objectAtIndex:currentRow];
		
		if ([fileListing isRegularFile])
			return [NSArray arrayWithObject:[fileListing extension]];

		// I'm not quite sure what the proper HFS file type to use for a directory
		// is, so this is probably wrong.
		else if ([fileListing isDirectory])
			return [NSArray arrayWithObject:NSDirectoryFileType];	

		currentRow = [rows indexGreaterThanIndex:currentRow];
	}

	return nil;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
				validateDrop:(id <NSDraggingInfo>)info
				proposedRow:(int)row
				proposedDropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pasteBoard = [info draggingPasteboard];
	
	if ([tableView isEqual:ONB_fileListingsTableView])
	{
		if (! [[pasteBoard types] containsObject:NSFilenamesPboardType])
			return NSDragOperationNone;

		// Only allow the user to drop on rows that are directories.
		if (operation == NSTableViewDropOn)
		{
			NSArray *listings = [ONB_fileListingsController arrangedObjects];
			
			// Check for an illegal row number.
			if ((row < 0) || (row >= [listings count]))
				return NSDragOperationNone;
			
			// Check to see if the given row is a directory.
			if ([[listings objectAtIndex:row] isDirectory])
				return NSDragOperationCopy;
			
			return NSDragOperationNone;
		}


		return NSDragOperationCopy;
	}
	
	if ([tableView isEqual:ONB_queueTableView])
	{
		if (operation == NSTableViewDropOn)
			return NSDragOperationNone;
		
		if ([[pasteBoard types] containsObject:NSFilesPromisePboardType])
			return NSDragOperationPrivate;
		
		if ([[pasteBoard types] containsObject:NSFilenamesPboardType])
			return NSDragOperationCopy;
			
		return NSDragOperationNone;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView
		acceptDrop:(id <NSDraggingInfo>)info
		row:(int)row
		dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pasteBoard = [info draggingPasteboard];

	if ([tableView isEqual:ONB_fileListingsTableView])
	{
		if (! [[pasteBoard types] containsObject:NSFilenamesPboardType])
		{
			NSLog(@"Attempt to drag illegal data to the file listings view!");
			return NO;
		}
		
		// If the files were dropped between rows, then the destination is the current
		// remote path.  If they were dropped on a directory, then the destination
		// is that directory.
		NSString *subdirectory = @"";
		if (operation == NSTableViewDropOn)
		{
			ONBFileListing *listing = [[ONB_fileListingsController arrangedObjects] objectAtIndex:row];
			subdirectory = [listing name];
		}

		NSArray *fileNames = [pasteBoard propertyListForType:NSFilenamesPboardType];
		[[self controller] fileNames:fileNames
							droppedOnRemoteSubdirectory:subdirectory
							identifier:[self identifier]];
		return YES;
	}
	
	if ([tableView isEqual:ONB_queueTableView])
	{
		if ([[pasteBoard types] containsObject:NSFilenamesPboardType])
		{
			NSArray *fileNames = [pasteBoard propertyListForType:NSFilenamesPboardType];
			[[self controller] fileNames:fileNames
								droppedOnQueueViewAtIndex:row
								identifier:[self identifier]];
			return YES;
		}
		
		if ([[pasteBoard types] containsObject:NSFilesPromisePboardType])
		{
			// Add queue items to download currently selected files
			[self addSelectedItemsToQueueAtIndex:row];
		
			return YES;
		}
		
		NSLog(@"Attempt to drag illegal data to the queue view!");
		return NO;
	}
	
	return NO;
}

- (void)addSelectedItemsToQueueAtIndex:(unsigned int)index
{
	if (! ONB_fileListingsController)
		return;
	
	NSArray *selectedFiles = [ONB_fileListingsController selectedObjects];	
	if (! [selectedFiles count])
		return;

	[[self controller] addRemoteListings:selectedFiles toQueueAtIndex:index identifier:[self identifier]];
}

- (NSArray *)promisedFilesDroppedFromRemoteView:(ONBRemoteView *)remoteView
										destination:(NSURL *)dropDestination
										rows:(NSIndexSet *)rows
{
	NSString *path = [dropDestination path];
	NSMutableArray *selectedListings = [NSMutableArray arrayWithCapacity:[rows count]];
	NSMutableArray *names = [NSMutableArray arrayWithCapacity:[rows count]];
	NSArray *listings = [ONB_fileListingsController arrangedObjects];
	
	unsigned int currentRow = [rows firstIndex];
	while(currentRow != NSNotFound)
	{
		ONBFileListing *fileListing = [listings objectAtIndex:currentRow];
		NSString *name = [fileListing name];
		
		if ([fileListing isRegularFile])
		{
			[selectedListings addObject:fileListing];
			[names addObject:name];
		}

		else if ([fileListing isDirectory])
		{
			// We don't want to let the user download the ".." folder, otherwise unexpected
			// stuff could happen.
			if ([name isEqualToString:@".."])
			{
				currentRow = [rows indexGreaterThanIndex:currentRow];
				continue;
			}

			[selectedListings addObject:fileListing];
			[names addObject:name];
		}
		else
			NSLog(@"Invalid file type dragged from remote view!");
		
		currentRow = [rows indexGreaterThanIndex:currentRow];
	}
	
	[[self controller] remoteListings:selectedListings
							droppedToLocalPath:path
							identifier:[self identifier]];
	
	return names;
}

- (IBAction)addToQueue:(id)sender
{
	if (! ONB_fileListingsController)
		return;
	
	NSArray *selectedFiles = [ONB_fileListingsController selectedObjects];	
	if (! [selectedFiles count])
		return;
		
	[[self controller] addRemoteListingsToEndOfQueue:selectedFiles identifier:[self identifier]];
}

- (IBAction)downloadFile:(id)sender
{
	[self addToQueue:sender];
}

- (void)deleteAlertDidEnd:(NSAlert *)alert
				returnCode:(int)returnCode
				contextInfo:(void *)contextInfo
{
	NSArray *array = (NSArray *)contextInfo;

	// If the user clicked OK, run the given queue items.
	if (returnCode == NSAlertFirstButtonReturn)
	{
		[[alert window] orderOut:self];
		
		[[self controller] deleteRemoteListings:array identifier:[self identifier]];
	}
	
	[array release];
}

- (IBAction)deleteFiles:(id)sender
{
	if (! ONB_fileListingsController)
		return;
	
	NSArray *selectedFiles = [ONB_fileListingsController selectedObjects];	
	if (! [selectedFiles count])
		return;

	// Create an alert sheet to ask the user whether they are sure they want to
	// delete the selected items, and give it the queue items as context info.
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
	[alert setMessageText:NSLocalizedString(@"Are you sure you want to delete the selected item(s)?", @"")];
	[alert setInformativeText:NSLocalizedString(@"The contents of any directories will also be deleted.", @"")];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	[alert beginSheetModalForWindow:ONB_connectionWindow
						modalDelegate:self
						didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:)
						contextInfo:[selectedFiles retain]];
}

- (IBAction)refresh:(id)sender
{
	[[self controller] refreshListingsForIdentifier:[self identifier]];
}

- (IBAction)newDirectory:(id)sender
{
	[NSApp beginSheet:ONB_newDirectorySheet
		modalForWindow:ONB_connectionWindow
		modalDelegate:self
		didEndSelector:0
		contextInfo:nil];
}

- (IBAction)dismissNewDirectory:(id)sender
{
	[NSApp endSheet:ONB_newDirectorySheet];
	[ONB_newDirectorySheet orderOut:self];
}

- (IBAction)createDirectory:(id)sender
{
	// Cause editing of new directory text box to end so that we get its value properly
	[ONB_newDirectorySheet makeFirstResponder:ONB_newDirectorySheet];

	NSString *newDirectory = [self newDirectory];

	// Close the sheet
	[self dismissNewDirectory:self];

	// Add queue items for creating the directory and refreshing the view
	[[self controller] createNewDirectory:newDirectory identifier:[self identifier]];
}

- (IBAction)dismissRename:(id)sender
{
	[NSApp endSheet:ONB_renameSheet];
	[ONB_renameSheet orderOut:self];
}

- (IBAction)doRename:(id)sender
{
	// Cause editing of new name text box to end so that we get its value properly
	[ONB_renameSheet makeFirstResponder:ONB_renameSheet];

	NSString *newName = [self newName];

	// Close the sheet
	[self dismissRename:self];
	
	NSArray *selectedListings = [ONB_fileListingsController selectedObjects];
	if ([selectedListings count] != 1)
		return;
	
	NSString *file = [[selectedListings objectAtIndex:0] name];

	[[self controller] renameFile:file to:newName identifier:[self identifier]];
}

- (IBAction)rename:(id)sender
{
	[NSApp beginSheet:ONB_renameSheet
		modalForWindow:ONB_connectionWindow
		modalDelegate:self
		didEndSelector:0
		contextInfo:nil];
}

- (IBAction)removeFromQueue:(id)sender
{
	[[self controller] removeQueueItemsAtIndexes:[ONB_queueTableView selectedRowIndexes]
										identifier:[self identifier]];
}

- (IBAction)runPauseQueue:(id)sender
{
	[[self controller] runPauseQueueForIdentifier:[self identifier]];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self controller] windowClosingForIdentifier:[self identifier]];
}

- (BOOL)transferInProgress
{
	return ONB_transferInProgress;
}

- (void)setTransferInProgress:(BOOL)transferInProgress
{
	ONB_transferInProgress = transferInProgress;
}

- (double)transferProgress
{
	return ONB_transferProgress;
}

- (void)setTransferProgress:(double)transferProgress
{
	ONB_transferProgress = transferProgress;
}

- (BOOL)noTransferProgress
{
	return [self transferInProgress] && ([self transferProgress] < 0.1);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:ONBAddToQueueToolbarItemIdentifier,
										ONBDeleteToolbarItemIdentifier,
										ONBNewDirectoryToolbarItemIdentifier,
										ONBRefreshToolbarItemIdentifier,
										ONBRenameToolbarItemIdentifier,
										ONBEditToolbarItemIdentifier,
										nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:ONBAddToQueueToolbarItemIdentifier,
										ONBDeleteToolbarItemIdentifier,
										ONBNewDirectoryToolbarItemIdentifier,
										ONBRefreshToolbarItemIdentifier,
										ONBRenameToolbarItemIdentifier,
										ONBEditToolbarItemIdentifier,
										nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
			itemForItemIdentifier:(NSString *)identifier
			willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
	
	if ([identifier isEqualToString:ONBAddToQueueToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Add to Queue", @"");
		NSString *toolTip = NSLocalizedString(@"Add the selected item(s) to the queue", @"");
		
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"AddToQueue"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(addToQueue:)];
	}
	
	else if ([identifier isEqualToString:ONBDeleteToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Delete", @"");
		NSString *toolTip = NSLocalizedString(@"Delete the currently selected item(s)", @"");
		
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"DeleteFile"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(deleteFiles:)];
	}
	
	else if ([identifier isEqualToString:ONBNewDirectoryToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"New Directory", @"");
		NSString *toolTip = NSLocalizedString(@"Create a new directory in the current remote directory", @"");
		
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"NewDirectory"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(newDirectory:)];
	}
	
	else if ([identifier isEqualToString:ONBRefreshToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Refresh", @"");
		NSString *toolTip = NSLocalizedString(@"Refresh the current remote directory", @"");
		
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"RefreshListings"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(refresh:)];
	}
	
	else if ([identifier isEqualToString:ONBRenameToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Rename", @"");
		NSString *toolTip = NSLocalizedString(@"Rename the currently selected remote file or directory", @"");
		
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"RenameFile"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(rename:)];
	}

	else if ([identifier isEqualToString:ONBEditToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Edit", @"");
		NSString *toolTip = NSLocalizedString(@"Open currently selected remote file(s) in an external editor and watch for changes", @"");
		
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"EditFile"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(editFile:)];
	}

	else
		toolbarItem = nil;
	
	return toolbarItem;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
	NSString *identifier = [item itemIdentifier];

	if ([identifier isEqualToString:ONBAddToQueueToolbarItemIdentifier])
		return [self canAddToQueue];

	else if ([identifier isEqualToString:ONBDeleteToolbarItemIdentifier])
		return [self canDelete];
	
	else if ([identifier isEqualToString:ONBRenameToolbarItemIdentifier])
		return [self canRename];

	else if ([identifier isEqualToString:ONBEditToolbarItemIdentifier])
		return [self canEdit];

	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
						ofObject:(id)object
						change:(NSDictionary *)change
						context:(void *)context
{
	if (object == self)
		[[ONB_connectionWindow toolbar] validateVisibleItems];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	SEL action = [menuItem action];

	if (action == @selector(addToQueue:))
		return [self canAddToQueue];

	if (action == @selector(deleteFiles:))
		return [self canDelete];

	if (action == @selector(rename:))
		return [self canRename];

	if (action == @selector(editFile:))
		return [self canEdit];

	return YES;
}

- (IBAction)editFile:(id)sender
{
	if (! ONB_fileListingsController)
		return;
	
	NSArray *selectedFiles = [ONB_fileListingsController selectedObjects];	
	if (! [selectedFiles count])
		return;
	
	NSEnumerator *listingEnumerator = [selectedFiles objectEnumerator];
	ONBFileListing *currentListing;
	
	while (currentListing = [listingEnumerator nextObject])
		if (! [currentListing isRegularFile])
			return;
	
	[[self controller] editFilesForRemoteListings:selectedFiles identifier:[self identifier]];
}

@end