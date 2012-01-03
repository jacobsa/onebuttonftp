//
//  ONBConnectionManagerCell.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-05-27.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ONBConnectionManagerCell : NSCell
{
	NSImageCell			*imageCell;
	NSTextFieldCell		*textFieldCell;
	NSFont				*largeFont;
	NSFont				*smallFont;
}

@end