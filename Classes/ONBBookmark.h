//
//  ONBBookmark.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-04.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	ONBNoSSL = 0,
	ONBUseExplicitSSL = 1,
	ONBUseImplicitSSL = 2
} ONBSSLMode;

@interface ONBBookmark : NSObject < NSCopying >
{
	NSString		*ONB_nickname;
	NSString		*ONB_host;
	NSNumber		*ONB_port;
	NSString		*ONB_user;
	NSString		*ONB_password;
	NSString		*ONB_initialPath;
	BOOL			ONB_usePassive;
	NSNumber		*ONB_SSLMode;
	BOOL			ONB_remember;
}

- (NSString *)nickname;
- (NSString *)host;
- (NSNumber *)port;
- (BOOL)anonymous;			// YES if user is nil or empty
- (NSString *)user;
- (NSString *)password;
- (NSString *)initialPath;
- (BOOL)usePassive;
- (NSNumber *)SSLMode;
- (BOOL)remember;

- (void)setNickname:(NSString *)nickname;
- (void)setHost:(NSString *)host;
- (void)setPort:(NSNumber *)port;
- (void)setUser:(NSString *)user;
- (void)setPassword:(NSString *)password;
- (void)setInitialPath:(NSString *)initialPath;
- (void)setUsePassive:(BOOL)usePassive;
- (void)setSSLMode:(NSNumber *)SSLMode;
- (void)setRemember:(BOOL)remember;

@end