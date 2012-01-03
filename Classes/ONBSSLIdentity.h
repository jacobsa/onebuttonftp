//
//  ONBSSLIdentity.h
//  OneButton Socket
//
//  Created by Aaron Jacobs on 2005-06-29.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

@interface ONBSSLIdentity : NSObject
{
	SecIdentityRef		ONB_identity;
}

// Calls firstSSLIdentityFromKeychain: with an argument of nil.
+ (ONBSSLIdentity *)firstSSLIdentity;

// Returns the first SSL identity from the given keychain (or the default
// keychain if nil is given). Returns nil if no such identity could be found.
// keychainPath should be the full POSIX path to the keychain file.
+ (ONBSSLIdentity *)firstSSLIdentityInKeychain:(NSString *)keychainPath;

// Designated initializer.
- (id)initWithIdentityRef:(SecIdentityRef)identityRef;

// The low-level identity ref underlying this identity.  It is your
// responsibility to retain this if you need it.
- (SecIdentityRef)identityRef;

@end