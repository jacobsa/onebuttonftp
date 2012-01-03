//
//  ONBSSLIdentity.m
//  OneButton Socket
//
//  Created by Aaron Jacobs on 2005-06-29.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBSSLIdentity.h"

@implementation ONBSSLIdentity

- (id)init
{
	return [self initWithIdentityRef:nil];
}

- (id)initWithIdentityRef:(SecIdentityRef)identityRef
{
	if (! (self = [super init]))
		return nil;

	ONB_identity = identityRef;
	CFRetain(ONB_identity);
	
	return self;
}

- (void)dealloc
{
	CFRelease(ONB_identity);
	[super dealloc];
}

+ (ONBSSLIdentity *)firstSSLIdentity
{
	return [self firstSSLIdentityInKeychain:nil];
}

+ (ONBSSLIdentity *)firstSSLIdentityInKeychain:(NSString *)keychainPath;
{
	// If no keychain name was specified, use the default keychain.
	SecKeychainRef keychainRef = nil;
	
	if (keychainPath)
	{
		if (SecKeychainOpen([keychainPath UTF8String], &keychainRef))
		{
			NSLog(@"Unable to open keychain");
			return nil;
		}
	}
	
	else if (SecKeychainCopyDefault(&keychainRef))
	{
			NSLog(@"Unable to get default keychain");
			return nil;
	}
	
	SecIdentitySearchRef searchRef = nil;
	if (SecIdentitySearchCreate(keychainRef, CSSM_KEYUSE_SIGN, &searchRef))
	{
		NSLog(@"Unable to create keychain search");
		CFRelease(keychainRef);
		return nil;
	}
	
	SecIdentityRef identityRef = nil;
	if (SecIdentitySearchCopyNext(searchRef, &identityRef))
	{
		NSLog(@"Unable to get next search result");
		CFRelease(keychainRef);
		CFRelease(searchRef);
		return nil;
	}
	
	ONBSSLIdentity *sslIdentity = [[[ONBSSLIdentity alloc] initWithIdentityRef:identityRef] autorelease];
	
	CFRelease(keychainRef);
	CFRelease(searchRef);
	CFRelease(identityRef);
	
	return sslIdentity;
}

- (SecIdentityRef)identityRef
{
	return ONB_identity;
}

@end