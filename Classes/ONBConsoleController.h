//
//  ONBConsoleController.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-05-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ONBConsoleController : NSObject
{
	IBOutlet NSTextView		*consoleTextView;
	NSString				*ONB_windowTitle;
}

// Key-value coding support for the interface
- (NSString *)windowTitle;
- (void)setWindowTitle:(NSString *)windowTitle;

// Append the given attributed string to the console view.
- (void)appendText:(NSAttributedString *)text;

@end