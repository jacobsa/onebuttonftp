//
//  ONBRenameQueueItem.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-03-18.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBRenameQueueItem.h"
#import "ONBFTPConnection.h"
#import "ONBQueue.h"

@implementation ONBRenameQueueItem

- (id)copyWithZone:(NSZone *)zone
{
	ONBRenameQueueItem *newObject = [super copyWithZone:zone];
	[newObject setFile:[self file]];
	[newObject setNewName:[self newName]];
	return newObject;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;
	
	// This class should be hidden by default
	[self setHidden:YES];
	
	// Set default values
	[self setFile:@""];
	[self setNewName:@""];
	return self;
}

- (void)dealloc
{
	[self setFile:nil];
	[self setNewName:nil];
	
	[super dealloc];
}

- (NSString *)file
{
	return ONB_file;
}

- (void)setFile:(NSString *)file
{
	[ONB_file autorelease];
	ONB_file = [file copy];
}

- (NSString *)newName
{
	return ONB_newName;
}

- (void)setNewName:(NSString *)newName
{
	[ONB_newName autorelease];
	ONB_newName = [newName copy];
}

- (void)runWithConnection:(ONBFTPConnection *)connection queue:(ONBQueue *)queue
{
	[super runWithConnection:connection queue:queue];
	
	[connection renameFile:[self file] newName:[self newName] userInfo:nil];
}

@end