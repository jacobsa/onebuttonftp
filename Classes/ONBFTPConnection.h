//
//  ONBFTPConnection.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-07-05.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ONBFTPErrorDomain		@"ONBFTPErrorDomain"

@class ONBFTPConnection;

@interface NSObject ( ONBFTPConnectionDelegate )

- (void)connection:(ONBFTPConnection *)connection
		successfullyCompletedTaskWithUserInfo:(NSDictionary *)userInfo;

- (void)connection:(ONBFTPConnection *)connection
		failedToCompleteTaskWithUserInfo:(NSDictionary *)userInfo
		error:(NSError *)error;

- (void)connection:(ONBFTPConnection *)connection
		downloadedData:(NSData *)data
		speed:(double)speed
		percentComplete:(double)percentComplete
		userInfo:(NSDictionary *)userInfo;

- (NSData *)provideUploadDataForConnection:(ONBFTPConnection *)connection
									length:(unsigned int)length
									userInfo:(NSDictionary *)userInfo;

- (void)connection:(ONBFTPConnection *)connection
		uploadStatusSpeed:(double)speed
		percentComplete:(double)percentComplete
		userInfo:(NSDictionary *)userInfo;

- (void)connection:(ONBFTPConnection *)connection
		sentCommunicationToServer:(NSString *)communication;

- (void)connection:(ONBFTPConnection *)connection
		receivedCommunicationFromServer:(NSString *)communication;
@end

typedef enum
{
	ONBFTPErrorAlreadyConnected,
	ONBFTPErrorMalformedReply,
	ONBFTPErrorMalformed257Reply,
	ONBFTPErrorMalformed227Reply,
	ONBFTPErrorMalformedDirectoryListing,
	ONBFTPErrorUnexpectedReply,
	ONBFTPErrorUnhandled220Reply,
	ONBFTPErrorUnhandledAUTHReply,
	ONBFTPErrorUnhandledPBSZReply,
	ONBFTPErrorUnhandledPROTReply,
	ONBFTPErrorUnhandledUSERReply,
	ONBFTPErrorUnhandledPASSReply,
	ONBFTPErrorUnhandledPWDReply,
	ONBFTPErrorUnhandledCWDReply,
	ONBFTPErrorUnhandledDELEReply,
	ONBFTPErrorUnhandledMKDReply,
	ONBFTPErrorUnhandledRMDReply,
	ONBFTPErrorUnhandledRNFRReply,
	ONBFTPErrorUnhandledRNTOReply,
	ONBFTPErrorUnhandledPASVReply,
	ONBFTPErrorUnhandledPORTReply,
	ONBFTPErrorUnhandledLISTReply,
	ONBFTPErrorUnhandledTYPEReply,
	ONBFTPErrorUnhandledRETRReply
} ONBFTPConnectionError;

@class ONBSocket;

@interface ONBFTPConnection : NSObject
{
	BOOL					ONB_useExplicitTLS;
	BOOL					ONB_useImplicitTLS;

	NSString				*ONB_host;
	unsigned int			ONB_port;
	NSString				*ONB_username;
	NSString				*ONB_password;
	
	NSMutableString			*ONB_replyBuffer;
	ONBSocket				*ONB_controlSocket;
	int						ONB_controlState;
	
	ONBSocket				*ONB_dataSocket;

	NSData					*ONB_LISTData;
	NSMutableArray			*ONB_linksToResolve;
	NSMutableArray			*ONB_resolvedListings;
	NSString				*ONB_resolvingLinksPreviousCWD;
	
	NSString				*ONB_renameNewName;
	
	NSString				*ONB_downloadName;
	unsigned int			ONB_downloadSize;
	unsigned int			ONB_totalDownloaded;
	NSTimer					*ONB_downloadDataTimer;
	NSData					*ONB_untranslatedDownloadData;
	
	NSString				*ONB_uploadName;
	unsigned int			ONB_uploadSize;
	unsigned int			ONB_totalUploaded;
	NSTimer					*ONB_uploadTimer;
	BOOL					ONB_uploadEOF;
	unsigned int			ONB_uploadWritesInProgress;
	NSData					*ONB_untranslatedUploadData;
	
	BOOL					ONB_supportsHiddenLIST;
	
	BOOL					ONB_useASCIIMode;
	int						ONB_currentTransferType;
	
	BOOL					ONB_usePassiveMode;
	
	NSDictionary			*ONB_userInfo;
	id						ONB_delegate;
}

- (id)initWithHost:(NSString *)host
				port:(unsigned int)port
				username:(NSString *)user
				password:(NSString *)password
				delegate:(id)delegate;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)useExplicitTLS;
- (void)setUseExplicitTLS:(BOOL)useExplicitTLS;

- (BOOL)useImplicitTLS;
- (void)setUseImplicitTLS:(BOOL)useImplicitTLS;

- (NSString *)host;
- (unsigned int)port;
- (NSString *)username;
- (NSString *)password;

- (BOOL)useASCIIMode;
- (void)setUseASCIIMode:(BOOL)useASCIIMode;

- (BOOL)usePassiveMode;
- (void)setUsePassiveMode:(BOOL)usePassiveMode;


- (void)connectWithUserInfo:(NSDictionary *)userInfo;

- (void)getCurrentDirectoryWithUserInfo:(NSDictionary *)userInfo;
- (void)changeDirectory:(NSString *)newDirectory userInfo:(NSDictionary *)userInfo;
- (void)getDirectoryListingWithUserInfo:(NSDictionary *)userInfo;

- (void)downloadFile:(NSString *)filename size:(unsigned int)filesize userInfo:(NSDictionary *)userInfo;
- (void)uploadFileWithName:(NSString *)filename size:(unsigned int)filesize userInfo:(NSDictionary *)userInfo;

- (void)renameFile:(NSString *)oldName newName:(NSString *)newName userInfo:(NSDictionary *)userInfo;
- (void)removeFile:(NSString *)filename userInfo:(NSDictionary *)userInfo;

- (void)createDirectory:(NSString *)newDirectory userInfo:(NSDictionary *)userInfo;
- (void)removeDirectory:(NSString *)directory userInfo:(NSDictionary *)userInfo;

@end