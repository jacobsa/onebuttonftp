//
//  ONBNoFirstMouse.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-11-08.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSButton ( ONBNoFirstMouse )
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
@end
