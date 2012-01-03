//
//  ONBFileListing.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-10-28.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	ONBRegularFile,
	ONBDirectory,
	ONBUnknown
} ONBFileType;

@interface ONBFileListing : NSObject < NSCoding >
{
	// Private variables
	NSString		*ONB_name;
	NSString		*ONB_owner;
	NSString		*ONB_group;
	unsigned int	ONB_permissionsMode;
	NSDate			*ONB_lastModified;
	ONBFileType		ONB_type;
	NSNumber		*ONB_size;
	BOOL			ONB_isSymbolicLink;
	NSString		*ONB_linkedFile;
	
	NSImage			*ONB_icon;
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

// Autoreleased object from a CFFTP parsed file listing dictionary
+ (ONBFileListing *)fileListingFromCFFTPDictionary:(NSDictionary *)parsedDictionary;

- (NSString *)name;
- (NSString *)owner;
- (NSString *)group;
- (unsigned int)permissionsMode;
- (NSDate *)lastModified;

// Size in bytes
- (NSNumber *)size;

// Name of file with an arrow and what it links to if it's a symlink
- (NSString *)nameWithLink;

// Is the file a symbolic link to another file?
- (BOOL)isSymbolicLink;

// File to which the link points (or nil if not a symlink)
- (NSString *)linkedFile;


- (ONBFileType)type;
- (void)setType:(ONBFileType)type;

- (NSString *)extension;
- (NSImage *)icon;

- (NSDictionary *)nameWithLinkAndIcon;


// Instead of using these methods, you could obviously just examine the type
// attribute. These are here primarily as attributes to easily bind to with
// Interface Builder.
- (BOOL)isDirectory;						// Is the file a directory?
- (BOOL)isRegularFile;						// Is the file a regular file?

@end