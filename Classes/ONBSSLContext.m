//
//  ONBSSLContext.m
//  OneButton Socket
//
//  Created by Aaron Jacobs on 2005-06-22.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBSSLContext.h"
#import "ONBSSLIdentity.h"

@interface ONBSSLContext ( ONBSSLContextPrivateMethods )

- (OSStatus)ONB_handleSSLReadToData:(void *)data size:(size_t *)size;
- (OSStatus)ONB_handleSSLWriteFromData:(const void *)data size:(size_t *)size;

@end

OSStatus SSLReadFunction(SSLConnectionRef connection, void *data, size_t *dataLength)
{
	return [(ONBSSLContext *)connection ONB_handleSSLReadToData:data size:dataLength];
}

OSStatus SSLWriteFunction(SSLConnectionRef connection, const void *data, size_t *dataLength)
{
	return [(ONBSSLContext *)connection ONB_handleSSLWriteFromData:data size:dataLength];
}

@implementation ONBSSLContext

-  (id)init
{
	if (! (self = [super init]))
		return nil;
	
	[self setSSLIdentity:nil];
	
	return self;
}

- (void)dealloc
{
	[self setSSLIdentity:nil];
	[super dealloc];
}

- (int)handshakeWithInputData:(NSMutableData *)inputData
					outputData:(NSMutableData *)outputData
{
	int ret;

	// If we haven't yet set up the SSL context, we should do so now.
	if (! ONB_sslContext)
	{
		if (ret = SSLNewContext((Boolean)[self sslServerMode], &ONB_sslContext))
		{
			NSLog(@"Error creating new context");
			return ret;
		}
		
		if (ret = SSLSetIOFuncs(ONB_sslContext, SSLReadFunction, SSLWriteFunction))
		{
			NSLog(@"Error setting IO Functions");
			return ret;
		}
		
		if (ret = SSLSetConnection(ONB_sslContext, self))
		{
			NSLog(@"Error setting connection");
			return ret;
		}
		
		if (ret = SSLSetEnableCertVerify(ONB_sslContext, (Boolean)[self verifySSLCertificates]))
		{
			NSLog(@"Error calling SSLSetEnableCertVerify");
			return ret;
		}
		
		SecIdentityRef identity = [[self sslIdentity] identityRef];
		if (identity || [self sslServerMode])
		{
			CFArrayRef certificates = CFArrayCreate(kCFAllocatorDefault,
													(const void **)&identity,
													identity ? 1 : 0,
													NULL);
			
			ret = SSLSetCertificate(ONB_sslContext, certificates);
			CFRelease(certificates);
			
			if (ret)
			{
				NSLog(@"Error setting certificates: %d", ret);
				return ret;
			}
			else
				NSLog(@"Set up certificates");
		}
	}
	
	ONB_inputData = inputData;
	ONB_outputData = outputData;
	ret = SSLHandshake(ONB_sslContext);
	
	if (ret == errSSLWouldBlock)
		return 0;
	
	if (! ret)
		return 1;
	
	return ret;
}

- (NSData *)encryptData:(NSData *)data inputData:(NSMutableData *)inputData
{
	if ((! data) || (! [data length]))
		return [NSData data];

	ONB_inputData = inputData;
	ONB_outputData = [NSMutableData dataWithCapacity:2*[data length]];
	unsigned int totalLength = [data length];
	unsigned int processed = 0;
	const void *buffer = [data bytes];
	
	while (processed < totalLength)
	{
		size_t written = 0;
		
		int ret;
		if (ret = SSLWrite(ONB_sslContext, buffer + processed, totalLength - processed, &written))
			return nil;

		processed += written;
	}
	
	return [NSData dataWithData:ONB_outputData];
}

- (NSData *)decryptData:(NSMutableData *)data outputData:(NSMutableData *)outputData
{
	if ((! data) || (! [data length]))
		return [NSData data];
	
	ONB_inputData = data;
	ONB_outputData = outputData;
	NSMutableData *decryptedData = [NSMutableData dataWithCapacity:[data length]];
	int ret = 0;
	
	while (! ret)
	{
		size_t read = 0;
		char buf[1024];
		
		ret = SSLRead(ONB_sslContext, buf, 1024, &read);
		if (ret && (ret != errSSLWouldBlock) && (ret != errSSLClosedGraceful))
		{
			NSLog(@"Error in SSLRead: %d", ret);
			return nil;
		}
		
		[decryptedData appendBytes:buf length:read];
	}
	
	return [NSData dataWithData:decryptedData];
}

- (BOOL)verifySSLCertificates
{
	return ONB_verifySSLCerts;
}

- (void)setVerifySSLCertificates:(BOOL)verifySSLCertificates
{
	ONB_verifySSLCerts = verifySSLCertificates;
}

- (ONBSSLIdentity *)sslIdentity
{
	return ONB_sslIdentity;
}

- (BOOL)sslServerMode
{
	return ONB_sslServerMode;
}

- (void)setSSLServerMode:(BOOL)sslServerMode
{
	ONB_sslServerMode = sslServerMode;
}

- (void)setSSLIdentity:(ONBSSLIdentity *)sslIdentity
{
	[ONB_sslIdentity autorelease];
	ONB_sslIdentity = [sslIdentity retain];
}

- (OSStatus)ONB_handleSSLWriteFromData:(const void *)data size:(size_t *)size
{
	[ONB_outputData appendBytes:data length:*size];
	return noErr;
}

- (OSStatus)ONB_handleSSLReadToData:(void *)data size:(size_t *)size
{
	size_t askedSize = *size;
	*size = MIN(askedSize, [ONB_inputData length]);
	if (! *size)
	{
		return errSSLWouldBlock;
	}
	
	NSRange byteRange = NSMakeRange(0, *size);
	[ONB_inputData getBytes:data range:byteRange];
	[ONB_inputData replaceBytesInRange:byteRange withBytes:NULL length:0];
	
	if (askedSize > *size)
		return errSSLWouldBlock;
	
	return noErr;
}

@end