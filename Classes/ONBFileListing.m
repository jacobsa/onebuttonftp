//
//  ONBFileListing.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-10-28.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBFileListing.h"
#include <sys/dirent.h>

// Cache icons for file types because it seems to be fairly expensive to look
// them up using NSWorkspace's iconForFileType: each time, and is very expensive
// to use NSImage's imageNamed: for every directory.
static NSImage					*ONB_directoryIcon;
static NSMutableDictionary		*ONB_fileTypeIcons;

@implementation ONBFileListing

// Set up the icons caches.
+ (void)initialize
{
	ONB_directoryIcon = [[NSImage imageNamed:@"GenericFolder"] copy];
	[ONB_directoryIcon setSize:NSMakeSize(16.0, 16.0)];
	
	ONB_fileTypeIcons = [[NSMutableDictionary alloc] initWithCapacity:30];
}

// The image returned from this method is guaranteed to be valid as long as the program
// is running, so there is no need to retain it.
+ (NSImage *)ONB_iconForFileType:(NSString *)extension
{
	NSImage *image = [ONB_fileTypeIcons objectForKey:extension];
	
	if (! image)
	{
		image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
		[image setSize:NSMakeSize(16.0, 16.0)];
		[ONB_fileTypeIcons setObject:image forKey:extension];
	}
	
	return image;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	unsigned int permissionsMode = [self permissionsMode];
	BOOL isSymbolicLink = [self isSymbolicLink];
	int type = [self type];
	
	[encoder encodeObject:[self name]];
	[encoder encodeObject:[self owner]];
	[encoder encodeObject:[self group]];
	[encoder encodeValueOfObjCType:@encode(unsigned int) at:&permissionsMode];
	[encoder encodeObject:[self lastModified]];
	[encoder encodeObject:[self size]];
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&isSymbolicLink];
	[encoder encodeObject:[self linkedFile]];
	[encoder encodeValueOfObjCType:@encode(int) at:&type];
}

- (id)initWithCoder:(NSCoder *)coder
{
	NSString *name;
	NSString *owner;
	NSString *group;
	unsigned int permissionsMode;
	NSDate *lastModified;
	NSNumber *size;
	BOOL isSymbolicLink;
	NSString *linkedFile;
	int type;
	
	name = [coder decodeObject];
	owner = [coder decodeObject];
	group = [coder decodeObject];
	[coder decodeValueOfObjCType:@encode(unsigned int) at:&permissionsMode];
	lastModified = [coder decodeObject];
	size = [coder decodeObject];
	[coder decodeValueOfObjCType:@encode(BOOL) at:&isSymbolicLink];
	linkedFile = [coder decodeObject];

	[coder decodeValueOfObjCType:@encode(int) at:&type];

	ONBFileListing *newObject = [[[self class] alloc] initWithName:name
																owner:owner
																group:group
																permissionsMode:permissionsMode
																lastModified:lastModified
																type:type
																size:size
																isSymbolicLink:isSymbolicLink
																linkedFile:linkedFile];

	[self release];
	return newObject;
}

+ (ONBFileListing *)fileListingFromCFFTPDictionary:(NSDictionary *)parsedDictionary
{
	NSString *name = [parsedDictionary objectForKey:(NSString *)kCFFTPResourceName];
	NSString *owner = [parsedDictionary objectForKey:(NSString *)kCFFTPResourceOwner];
	NSString *group = [parsedDictionary objectForKey:(NSString *)kCFFTPResourceGroup];
	unsigned int permissionsMode = [[parsedDictionary objectForKey:(NSString *)kCFFTPResourceMode] unsignedIntValue];
	NSDate *lastModified = [parsedDictionary objectForKey:(NSString *)kCFFTPResourceModDate];
	NSNumber *size = [parsedDictionary objectForKey:(NSString *)kCFFTPResourceSize];
	NSString *linkedFile = [parsedDictionary objectForKey:(NSString *)kCFFTPResourceLink];
	
	ONBFileType type = ONBUnknown;
	BOOL isSymbolicLink = NO;
	unsigned int parsedType = [[parsedDictionary objectForKey:(NSString *)kCFFTPResourceType] unsignedIntValue];
	
	switch (parsedType)
	{
		case DT_LNK:
			isSymbolicLink = YES;
			type = ONBRegularFile;
			break;
		
		case DT_DIR:
			type = ONBDirectory;
			break;
		
		case DT_REG:
			type = ONBRegularFile;
			break;
	}
	
	// If the linked file is obviously a directory, then we should mark the symlink as a directory.
	unsigned int linkedFileLength = [linkedFile length];
	if ([linkedFile isEqualToString:@"."] ||
		[linkedFile isEqualToString:@".."] ||
		(linkedFileLength && [[linkedFile substringFromIndex:linkedFileLength-1] isEqualToString:@"/"]))
		type = ONBDirectory;
	
	ONBFileListing *object = [[[self class] alloc] initWithName:name
															owner:owner
															group:group
															permissionsMode:permissionsMode
															lastModified:lastModified
															type:type
															size:size
															isSymbolicLink:isSymbolicLink
															linkedFile:linkedFile];
	return [object autorelease];
}

- (void)dealloc
{
	[ONB_name autorelease];
	[ONB_owner autorelease];
	[ONB_group autorelease];
	[ONB_lastModified autorelease];
	[ONB_size autorelease];
	[ONB_linkedFile autorelease];
	[super dealloc];
}

// Designated initializer
- (id)initWithName:(NSString *)name
				owner:(NSString *)owner
				group:(NSString *)group
				permissionsMode:(unsigned int)mode
				lastModified:(NSDate *)lastModified
				type:(ONBFileType)type
				size:(NSNumber *)size
				isSymbolicLink:(BOOL)isSymbolicLink
				linkedFile:(NSString *)linkedFile;
{
	if (! (self = [super init]))
		return nil;

	if (! name)
	{
		[self dealloc];
		return nil;
	}

	ONB_name = [name copy];
	ONB_owner = [owner copy];
	ONB_group = [group copy];
	ONB_permissionsMode = mode;
	ONB_lastModified = [lastModified copy];
	ONB_type = type;
	ONB_size = [size copy];
	ONB_isSymbolicLink = isSymbolicLink;
	ONB_linkedFile = [linkedFile copy];
	
	if ([self isDirectory])
		ONB_icon = ONB_directoryIcon;
	else
		ONB_icon = [ONBFileListing ONB_iconForFileType:[self extension]];
	
	return self;
}

- (id)init
{
	return [self initWithName:nil
						owner:nil
						group:nil
						permissionsMode:0
						lastModified:nil
						type:ONBUnknown
						size:nil
						isSymbolicLink:NO
						linkedFile:nil];
}


// If we're trying to be sent bycopy across a distributed objects link, we want to actually be
// encoded and copied rather than be sent as a proxy.
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
	if ([encoder isBycopy])
		return self;
		
	return [super replacementObjectForPortCoder:encoder];
}

- (NSString *)name
{
	return ONB_name;
}

- (NSString *)owner
{
	return ONB_owner;
}

- (NSString *)group
{
	return ONB_group;
}

- (unsigned int)permissionsMode
{
	return ONB_permissionsMode;
}

- (NSDate *)lastModified
{
	return ONB_lastModified;
}

- (NSString *)linkedFile
{
	return ONB_linkedFile;
}

- (ONBFileType)type
{
	return ONB_type;
}

- (void)setType:(ONBFileType)type
{
	ONB_type = type;
}

- (NSNumber *)size
{
	return ONB_size;
}

- (BOOL)isSymbolicLink
{
	return ONB_isSymbolicLink;
}

- (NSString *)nameWithLink
{
	if ([self isSymbolicLink])
		return [NSString stringWithFormat:@"%@ -> %@", [self name], [self linkedFile]];
	else
		return [self name];
}

- (NSString *)description
{
	return [self nameWithLink];
}

- (BOOL)isDirectory
{
	return ([self type] == ONBDirectory);
}

- (BOOL)isRegularFile
{
	return ([self type] == ONBRegularFile);
}

- (NSString *)extension
{
	if (! [self isRegularFile])
		return @"";
	
	return [[self name] pathExtension];
}

- (NSImage *)icon
{
	return ONB_icon;
}

- (NSDictionary *)nameWithLinkAndIcon
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[self nameWithLink],
														@"name",
														[self icon],
														@"icon",
														nil];
}

@end