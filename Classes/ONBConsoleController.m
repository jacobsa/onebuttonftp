//
//  ONBConsoleController.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-05-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBConsoleController.h"

@implementation ONBConsoleController

- (void)dealloc
{
	[self setWindowTitle:nil];
	[super dealloc];
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

- (void)appendText:(NSAttributedString *)text
{
	NSTextStorage *textStorage = [consoleTextView textStorage];
	
	[textStorage beginEditing];
	[textStorage appendAttributedString:text];
	[textStorage endEditing];
	
	NSRange scrollRange = NSMakeRange([textStorage length]-1, 1);
	[consoleTextView scrollRangeToVisible:scrollRange];
}

@end