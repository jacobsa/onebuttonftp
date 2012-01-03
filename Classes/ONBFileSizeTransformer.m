//
//  ONBFileSizeTransformer.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-27.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBFileSizeTransformer.h"

@implementation ONBFileSizeTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	// We must be provided with an NSNumber object.  If we aren't return a placeholder.
	NSString *placeHolder = NSLocalizedString(@"--", @"");
	if ( (! value) || (! [value isKindOfClass:[NSNumber class]]))
		return placeHolder;
	
	// It wouldn't make any sense to have a negative file size.
	if ([value intValue] < 0)
		return placeHolder;
	
	// Constants with the size of 1 GiB, 1 MiB, and 1 KiB (though we call them their less
	// technically correct but also less nerdy names).
	const double gigabyte = 1073741824;		// 2^30
	const double megabyte = 1048576;		// 2^20
	const double kilobyte = 1024;			// 2^10
	
	// The size of the file.
	double fileSize = [value unsignedIntValue];
	
	NSString *unitString = nil;
	
	// The default unit is a byte, so we might as well make that the default scaled size.
	double scaledSize = fileSize;
	
	if (fileSize >= gigabyte)
	{
		unitString = NSLocalizedString(@"GB", @"");
		scaledSize = fileSize / gigabyte;
	}

	else if (fileSize >= megabyte)
	{
		unitString = NSLocalizedString(@"MB", @"");
		scaledSize = fileSize / megabyte;
	}
	
	else if (fileSize >= kilobyte)
	{
		unitString = NSLocalizedString(@"KB", @"");
		scaledSize = fileSize / kilobyte;
	}
	
	
	// Alright, so now if we've found a unit we should make the pretty size string and return it.
	if (unitString)
	{
		NSString *format = NSLocalizedString(@"%.1f %@", @"");
		return [NSString stringWithFormat:format, scaledSize, unitString];
	}
	
	// If we didn't find a unit string, then that means we just want to list it in bytes.  We
	// might as well use integers to make it exact.
	unsigned int exactSize = [value unsignedIntValue];
	NSString *format = NSLocalizedString(@"%u B", @"");
	return [NSString stringWithFormat:format, exactSize];
}

@end