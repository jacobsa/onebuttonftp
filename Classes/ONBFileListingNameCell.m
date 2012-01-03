//
//  ONBFileListingNameCell.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-09.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBFileListingNameCell.h"

@implementation ONBFileListingNameCell

- (void)setObjectValue:(id <NSCopying>)object
{
	if ((! object) || (! [(NSObject *)object isKindOfClass:[NSDictionary class]]))
	{
		[super setObjectValue:object];
		return;
	}
	
	NSDictionary *dictionary = (NSDictionary *)object;
	
	[self setImage:[dictionary objectForKey:@"icon"]];
	[super setObjectValue:[dictionary objectForKey:@"name"]];
}

@end