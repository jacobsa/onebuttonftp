//
//  ONBConnectionManagerCell.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-05-27.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBConnectionManagerCell.h"

@implementation ONBConnectionManagerCell

- (id)copyWithZone:(NSZone *)zone
{
	// According to Apple's documentation about cells, the default implementation of
	// copyWithZone: only copies the pointers of instance variables, and doesn't retain
	// them.  This is trouble for us, because if one instance gets copied and then dealloc'd,
	// the text field cell and other instance variables of the copy are no longer valid.
	// So we override the default behavior to add an extra retain count to each instance
	// variable.
	[imageCell retain];
	[textFieldCell retain];
	[largeFont retain];
	[smallFont retain];
	
	return [super copyWithZone:zone];
}

- (void)dealloc
{
	[imageCell release];
	[textFieldCell release];
	[largeFont release];
	[smallFont release];
	
	[super dealloc];
}

- (id)init
{
	if (! (self = [super init]))
		return nil;

	imageCell = [[NSImageCell alloc] init];
	textFieldCell = [[NSTextFieldCell alloc] init];
	largeFont = [[NSFont boldSystemFontOfSize:14.0] retain];
	smallFont = [[NSFont systemFontOfSize:10.0] retain];
	
	return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage *image = nil;
	NSString *largeText = nil;
	NSString *smallText = nil;
	NSColor *largeTextColor = nil;
	NSColor *smallTextColor = nil;
	NSNumber *userHorizontallyCentered = nil;
	NSObject *objectValue = (NSObject *)[self objectValue];
	BOOL horizontallyCentered = NO;
	
	if ([objectValue isKindOfClass:[NSString class]])
		largeText = (NSString *)objectValue;

	else if ([objectValue isKindOfClass:[NSDictionary class]])
	{
		image = [(NSDictionary *)objectValue objectForKey:@"image"];
		largeText = [(NSDictionary *)objectValue objectForKey:@"largeText"];
		smallText = [(NSDictionary *)objectValue objectForKey:@"smallText"];
		largeTextColor = [(NSDictionary *)objectValue objectForKey:@"largeTextColor"];
		smallTextColor = [(NSDictionary *)objectValue objectForKey:@"smallTextColor"];
		userHorizontallyCentered = [(NSDictionary *)objectValue objectForKey:@"horizontallyCentered"];
	}
	
	else if ([objectValue respondsToSelector:@selector(stringValue)])
	{
		// The NSNumber cast is here just to make the compiler not complain about
		// using stringValue.
		largeText = [(NSNumber *)objectValue stringValue];
	}

	else
	{
		[super drawWithFrame:cellFrame inView:controlView];
		return;
	}

	float x = cellFrame.origin.x;
	float y = cellFrame.origin.y;
	
	float w = cellFrame.size.width;
	float h = cellFrame.size.height;
	
	NSRect imageFrame;
	NSRect largeFrame;
	NSRect smallFrame;
	
	if (smallText)
	{
		largeFrame = NSMakeRect(x, y, w, h * 14.0/24.0);
		smallFrame = NSMakeRect(x, y + h * 14.0/24.0, w, h - h * 14.0/24.0);
	}
	else
	{
		horizontallyCentered = YES;
		largeFrame = NSMakeRect(x, y + (h - h * 14.0/24.0) / 2.0, w, h * 14.0/24.0);
	}
	
	if (image)
	{
		horizontallyCentered = NO;
		float imageSize = 32.0;
		imageFrame = NSMakeRect(x, y + (h - imageSize) / 2.0, imageSize, imageSize);
		largeFrame = NSMakeRect(x + imageSize, y + (h - h * 14.0/24.0) / 2.0, w - imageSize, h * 14.0/24.0);
	}
	
	[textFieldCell setHighlighted:[self isHighlighted]];
	
	if (userHorizontallyCentered)
		horizontallyCentered = [userHorizontallyCentered boolValue];
	
	if (horizontallyCentered)
		[textFieldCell setAlignment:NSCenterTextAlignment];
	else
		[textFieldCell setAlignment:NSLeftTextAlignment];
	
	if (image)
	{
		[imageCell setObjectValue:image];
		[imageCell drawWithFrame:imageFrame inView:controlView];
	}
	
	if (largeText)
	{
		if (! largeTextColor)
			largeTextColor = [NSColor blackColor];
	
		[textFieldCell setTextColor:largeTextColor];
		[textFieldCell setFont:largeFont];
		[textFieldCell setObjectValue:largeText];
		[textFieldCell drawWithFrame:largeFrame inView:controlView];
	}
	
	if (smallText)
	{
		if (! smallTextColor)
			smallTextColor = [self isHighlighted] ? [NSColor whiteColor] : [NSColor lightGrayColor];
	
		[textFieldCell setTextColor:smallTextColor];
		[textFieldCell setFont:smallFont];
		[textFieldCell setObjectValue:smallText];
		[textFieldCell drawWithFrame:smallFrame inView:controlView];
	}
}

@end