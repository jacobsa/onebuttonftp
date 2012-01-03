//
//  ONBRemoteView.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBRemoteView.h"
#import "ONBDaughterController.h"

@implementation ONBRemoteView

// Mouse click event handler.  We mostly just pass events to NSTableView's implementation,
// but unfortunately can't do that for everything because NSTableView's mouseDown: somehow
// disables the sending of mouseDragged: messages, which we need for our promise drags.
// If we don't send the event to super, mouseDragged: messages automatically get sent.
- (void)mouseDown:(NSEvent *)event
{
	// By default we don't want mouseUp: to select the row
	ONB_selectOnMouseUp = NO;

	// If there are any modifier keys held down or the click wasn't on an actual row in
	// the table, we don't care about the click.
	unsigned int modifiers = [event modifierFlags];
	ONB_clickedRow = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
	ONB_clickedColumn = [self columnAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
	
	BOOL passToSuper = NO;
	
	if (modifiers & NSShiftKeyMask ||
			modifiers & NSControlKeyMask ||
			modifiers & NSAlternateKeyMask ||
			modifiers & NSCommandKeyMask ||
			ONB_clickedRow == -1
		)
	{
		passToSuper = YES;
	}
	
	if (passToSuper)
	{
		[super mouseDown:event];
		return;
	}
	
	// If the click was on an unselected row, select it.  If it was on an already selected row,
	// hold off until mouse up in case the user is trying to drag multiple rows.
	NSIndexSet *selectedRows = [self selectedRowIndexes];
	if (! [selectedRows containsIndex:ONB_clickedRow])
	{
		NSIndexSet *rowsToSelect = [NSIndexSet indexSetWithIndex:(unsigned int)ONB_clickedRow];
		[self selectRowIndexes:rowsToSelect byExtendingSelection:NO];
	}
	else
		ONB_selectOnMouseUp = YES;
	
	// Check for a double-click
	if ([event clickCount] == 2)
		[self sendAction:[self doubleAction] to:[self target]];
}

// If mouseDown: decided that the given row should be selected now, then do so.
- (void)mouseUp:(NSEvent *)event
{
	if (ONB_selectOnMouseUp)
	{
		NSIndexSet *rowsToSelect = [NSIndexSet indexSetWithIndex:(unsigned int)[self clickedRow]];
		[self selectRowIndexes:rowsToSelect byExtendingSelection:NO];
	}
	
	[super mouseUp:event];
}

// Handle a mouse drag event by starting an HFS promise drag for the files represented by
// the currently selected rows.
- (void)mouseDragged:(NSEvent *)event
{
	NSIndexSet *selectedRows = [self selectedRowIndexes];
	
	// We don't want to drag an empty selection
	if (! [selectedRows count])
		return;
	
	NSPoint dragPosition;
	NSRect imageLocation;
	
	dragPosition = [self convertPoint:[event locationInWindow] fromView:nil];
	
	dragPosition.x -= 16;
	dragPosition.y -= 16;
	
	imageLocation.origin = dragPosition;
	imageLocation.size = NSMakeSize(32, 32);
	
	// Store the rows being dragged for later
	[ONB_dragRows release];
	ONB_dragRows = [selectedRows retain];
	
	// Find out what kind of files are being dragged, and don't do anything if there's an error
	NSArray *fileTypes = [[self dataSource] fileTypesForRemoteView:self rows:ONB_dragRows];
	
	if (! fileTypes || ! [fileTypes count])
		return;
	
	[self dragPromisedFilesOfTypes:fileTypes
						fromRect:imageLocation
						source:self
						slideBack:YES
						event:event];
}

// This gets called when the user drops the promised files on e.g. the Finder.  We have to create
// the files at the specified place and then return their names (without a path).  Note that we
// HAVE to create them before returning or the Finder will not be happy, so the controller layer
// method that we have take care of the operation creates them with size zero and then downloads
// them when it can.
- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	[[self dataSource] promisedFilesDroppedFromRemoteView:self
												destination:dropDestination
												rows:ONB_dragRows];

	// If we don't return nil here, Finder will wait for us to create the files before it starts
	// responding again, which is not good since we are merely enqueuing the files.
	return nil;
}

// Tell the dragging system what types of drag operations we support for dragging within
// our program and to other applications.
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return isLocal ? NSDragOperationPrivate : NSDragOperationCopy;
}

// Override NSTableView's default, since it might not get mouseDown events
- (int)clickedRow
{
	return ONB_clickedRow;
}

// Override NSTableView's default, since it might not get mouseDown events
- (int)clickedColumn
{
	return ONB_clickedColumn;
}

@end