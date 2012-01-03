//
//  ONBSSLContext.h
//  OneButton Socket
//
//  Created by Aaron Jacobs on 2005-06-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/SecureTransport.h>

@class ONBSSLIdentity;

@interface ONBSSLContext : NSObject
{
	SSLContextRef		ONB_sslContext;
	
	NSMutableData		*ONB_inputData;
	NSMutableData		*ONB_outputData;
	
	BOOL				ONB_verifySSLCerts;
	ONBSSLIdentity		*ONB_sslIdentity;
	BOOL				ONB_sslServerMode;
}

// Should certificates be verified against known root certificates?  Turn this
// off if you have self-signed or unsigned certificates.  The default is YES.
// Note that not verifying certificates removes a significant layer of security
// from SSL.  Must be set before starting a handshake.
- (BOOL)verifySSLCertificates;
- (void)setVerifySSLCertificates:(BOOL)verifySSLCertificates;

// The SSL identity that should be used in the SSL session.  This is required
// for SSL server mode.  Note that at this time it seems as if only RSA
// certificates work.  Must be set before starting a handshake.
- (ONBSSLIdentity *)sslIdentity;
- (void)setSSLIdentity:(ONBSSLIdentity *)sslIdentity;

// Should the socket operate in SSL server mode or client mode?  The default
// is client mode (NO).  If you change this to YES, you must also call
// setSSLCertificates:.  Must be set before starting a handshake.
- (BOOL)sslServerMode;
- (void)setSSLServerMode:(BOOL)sslServerMode;

// Perform a handshake.  inputData should be filled with data read from the
// socket and outputData should be empty.  When the method is done, inputData
// will contain any unused data and outputData will contain any data that needs
// to be written to the socket.  Returns 0 if it needs to be called back when
// more input data arrives and 1 if the handshake has completed.  Returns a
// negative error code on error.
- (int)handshakeWithInputData:(NSMutableData *)inputData
					outputData:(NSMutableData *)outputData;

// Encrypt data to be written to the socket. Data will be taken from inputData
// (which should contain raw bytes from the socket) if any needs to be read in
// the process of the encryption.
- (NSData *)encryptData:(NSData *)data
				inputData:(NSMutableData *)inputData;

// Decrypt data read from the socket. If not all of the data could be decrypted
// at the moment, the unused data will be left in the data object. Data will be
// added to outputData if any needs to be written in the process of the
// decryption.
- (NSData *)decryptData:(NSMutableData *)data
				outputData:(NSMutableData *)outputData;

@end