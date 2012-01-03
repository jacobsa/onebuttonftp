//
//  ONBRemoteView.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-02.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// The purpose of this subclass is to implement HFS promise file drags from the remote
// file listings view to the Finder.

@interface ONBRemoteView : NSTableView
{
	int			ONB_clickedRow;				// Row hit by mouse event
	int			ONB_clickedColumn;			// Column hit by mouse event
	NSIndexSet	*ONB_dragRows;				// Rows currently being dragged
	BOOL		ONB_selectOnMouseUp;		// Should the clicked row be selected in mouseUp:?
}

@end
