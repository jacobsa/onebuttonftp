//
//  ONBBookmark.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-04.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBBookmark.h"

@implementation ONBBookmark

+ (void)initialize
{
	[self setKeys:[NSArray arrayWithObjects:@"user", nil]
			triggerChangeNotificationsForDependentKey:@"anonymous"];
}

- (id)init
{
	self = [super init];

	// The default is to use passive mode.
	[self setUsePassive:YES];
	
	// The default is to not use SSL at all.
	[self setSSLMode:[NSNumber numberWithUnsignedInt:ONBNoSSL]];
	
	return self;
}

- (NSString *)nickname
{
	return ONB_nickname;
}

- (NSString *)host
{
	return ONB_host;
}

- (NSNumber *)port
{
	return ONB_port;
}

- (BOOL)anonymous
{
	NSString *user = [self user];
	return ((! user) || [user isEqualToString:@""]);
}

- (NSString *)user
{
	return ONB_user;
}

- (NSString *)password
{
	return ONB_password;
}

- (NSString *)initialPath
{
	return ONB_initialPath;
}

- (BOOL)usePassive
{
	return ONB_usePassive;
}

-(NSNumber *)SSLMode
{
	return ONB_SSLMode;
}

- (BOOL)remember
{
	return ONB_remember;
}

- (void)setNickname:(NSString *)nickname
{
	[ONB_nickname autorelease];
	ONB_nickname = [nickname copy];
}

- (void)setHost:(NSString *)host
{
	[ONB_host autorelease];
	ONB_host = [host copy];
}

- (void)setPort:(NSNumber *)port
{
	[ONB_port autorelease];
	ONB_port = [port copy];
}

- (void)setUser:(NSString *)user
{
	[ONB_user autorelease];
	ONB_user = [user copy];
}

- (void)setPassword:(NSString *)password
{
	[ONB_password autorelease];
	ONB_password = [password copy];
}

- (void)setInitialPath:(NSString *)initialPath
{
	[ONB_initialPath autorelease];
	ONB_initialPath = [initialPath copy];
}

- (void)setUsePassive:(BOOL)usePassive
{
	ONB_usePassive = usePassive;
}

- (void)setSSLMode:(NSNumber *)SSLMode
{
	[ONB_SSLMode autorelease];
	ONB_SSLMode = [SSLMode copy];
}

- (void)setRemember:(BOOL)remember
{
	ONB_remember = remember;
}

- (void)dealloc
{
	[self setNickname:nil];
	[self setHost:nil];
	[self setPort:nil];
	[self setUser:nil];
	[self setPassword:nil];
	[self setInitialPath:nil];
	
	[super dealloc];
}

// Create a new bookmark with our same info
- (id)copyWithZone:(NSZone *)zone
{
	ONBBookmark *copy = [[ONBBookmark allocWithZone:zone] init];
	
	[copy setNickname:[self nickname]];
	[copy setHost:[self host]];
	[copy setPort:[self port]];
	[copy setUser:[self user]];
	[copy setPassword:[self password]];
	[copy setInitialPath:[self initialPath]];
	[copy setUsePassive:[self usePassive]];
	[copy setSSLMode:[self SSLMode]];
	[copy setRemember:[self remember]];

	return copy;
}

@end