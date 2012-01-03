//
//  ONBFTPConnection.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-07-05.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBFTPConnection.h"
#import "ONBSocket.h"
#import "ONBFileListing.h"

typedef enum
{
	ONBDisconnected,
	ONBWaitingForControlSocketToConnect,
	ONBWaitingFor220,
	ONBWaitingForAUTHReply,
	ONBWaitingForPBSZReply,
	ONBWaitingForPROTReply,
	ONBWaitingForUSERReply,
	ONBWaitingForPASSReply,
	ONBWaitingForPWDReply,
	ONBWaitingForCWDReply,
	ONBWaitingForDELEReply,
	ONBWaitingForMKDReply,
	ONBWaitingForRMDReply,

	ONBWaitingForRNFRReply,
	ONBWaitingForRNTOReply,

	ONBWaitingForPASVReplyToLIST,
	ONBWaitingForDataSocketToStartToLIST,
	ONBWaitingForPORTReplyToLIST,
	ONBWaitingForLISTReply,
	ONBWaitingForLISTData,
	ONBWaitingForPWDReplyToResolveLinks,
	ONBWaitingForCWDReplyToResolveLinks,
	ONBWaitingForPASVReplyToLISTToResolveLinks,
	ONBWaitingForDataSocketToStartToLISTToResolveLinks,
	ONBWaitingForPORTReplyToLISTToResolveLinks,
	ONBWaitingForLISTReplyToResolveLinks,
	ONBWaitingForLISTDataToResolveLinks,
	ONBWaitingForCWDReplyToOriginalDirectoryToResolveLinks,
	
	ONBWaitingForTYPEReplyToRETR,
	ONBWaitingForPASVReplyToRETR,
	ONBWaitingForDataSocketToStartToRETR,
	ONBWaitingForPORTReplyToRETR,
	ONBWaitingForRETRReply,
	ONBWaitingForRETRData,
	
	ONBWaitingForTYPEReplyToSTOR,
	ONBWaitingForPASVReplyToSTOR,
	ONBWaitingForDataSocketToStartToSTOR,
	ONBWaitingForPORTReplyToSTOR,
	ONBWaitingForSTORReplyAndDataConnectionToSendUploadData,
	ONBWaitingForSTORReplyToSendUploadData,
	ONBWaitingForDataConnectionToSendUploadData,
	ONBSendingUploadData,
	ONBWaitingForSTORReply,

	ONBIdle
} ONBFTPConnectionControlState;

typedef enum
{
	ONBASCIITransferType,
	ONBImageTransferType,
	ONBUnknownTransferType
} ONBFTPConnectionTransferType;

#define ONBFIRSTDIGIT(A)		((A) / 100)

@interface ONBFTPConnection ( ONBFTPConnectionPrivateMethods )

- (void)ONB_readReply;
- (void)ONB_readLine;
- (void)ONB_constructReplyWithLine:(NSString *)line;
- (void)ONB_didReadLine:(NSString *)line;
- (void)ONB_didReadReplyWithCode:(unsigned int)code text:(NSString *)text;
- (void)ONB_sendCommand:(NSString *)command;
- (void)ONB_transferFailedWithError:(NSError *)error;
- (void)ONB_transferSucceededWithReturnInfo:(NSDictionary *)returnInfo;
- (void)ONB_setUserInfo:(NSDictionary *)userInfo;
- (void)ONB_handle220ReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleAUTHReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handlePBSZReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handlePROTReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleUSERReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handlePASSReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handlePWDReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleCWDReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleDELEReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleMKDReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleRMDReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleRNFRReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleRNTOReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handlePASVReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handlePORTReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleLISTReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleTYPEReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_finishedLISTWithData:(NSData *)listData;
- (void)ONB_handleRETRReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleSTORReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handlePWDReplyForResolvingLinksWithCode:(int)code text:(NSString *)text;
- (NSString *)ONB_parsePWDReplyWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleCWDReplyForResolvingLinksWithCode:(int)code text:(NSString *)text;
- (void)ONB_handleCWDReplyToOriginalDirectoryForResolvingLinksWithCode:(int)code text:(NSString *)text;
- (void)ONB_checkForDownloadData:(NSTimer *)timer;
- (void)ONB_handleUploadData:(NSTimer *)timer;
- (void)ONB_handleDownloadData:(NSData *)data lastTime:(BOOL)lastTime;

@end

// This function is used to translate data sent in ASCII mode from an FTP server.  It replaces
// arbitrarily long sequences of 0x0D bytes followed by an optional 0x0A byte with a single
// 0x0A byte.
//
// For example:
//		83 94 0D 0A 47			->	83 94 0A 47
//		83 94 0D 0D 0D 0D 47	->	83 94 0A 47
//		83 94 0D 0D 0D 0D 0A 47	->	83 94 0A 47
//
// networkData is the data from the server.  lastTime specifies whether there is more data
// coming or this is the last of it.  It is used to handle cases where the last byte in the
// data is 0x0D.  In this case, if there is no more data then the byte (and those 0x0D bytes
// before it) should be changed.  On the other hand, if there is more data to come then there
// may be more 0x0D bytes in the sequence and maybe a 0x0A to cap it off, and the whole sequence
// would need to be translated at once.  So if lastTime is NO, then it is possible that not all
// of networkData will be consumed by the function; some may be returned in remainingData.  The
// contents of remainingData, if any, should be prepended to the data fed to the function on
// the next call.
NSData *localASCIIModeData(NSData *networkData, NSData **remainingData, BOOL lastTime)
{
	if ((! networkData) || (! [networkData length]))
	{
		if (! lastTime)
			*remainingData = [NSData data];
		
		return [NSData data];
	}
	
	// Loop through the data and record the ranges of any sequences of 0x0D bytes followed
	// optionally by a 0x0A byte found.  Afterwards, allocate enough space for the translated
	// data and recreate the original data with the sequences condensed to single 0x0A bytes.
	
	// We will initially guess that there is such a sequence for every 20 bytes of data, and
	// allocate enough space to hold the ranges for that many sequences.  If this turns out
	// to not be enough, we will allocate more space later.
	
	unsigned int newLineSequencesLength = MAX(1, [networkData length] / 20);
	NSRange *newLineSequences = calloc(newLineSequencesLength, sizeof(NSRange));
	unsigned int newLineSequencesCount = 0;
	
	if (! newLineSequences)
	{
		[NSException raise:@"ONBMallocException" format:@"Unable to allocate memory in localASCIIModeData()"];
		return nil;
	}
	
	const char *networkDataBytes = (const char *)[networkData bytes];
	unsigned int networkDataLength = [networkData length];
	unsigned int networkDataIndex;
	unsigned int searchStatus = 0;			// Are we currently searching within a newline sequence?
	unsigned int beginningOfSequence = 0;	// At what index did the current sequence begin?
	unsigned int totalLengthOfSequences = 0;
	
	for (networkDataIndex=0; networkDataIndex<networkDataLength; networkDataIndex++)
	{
		char currentByte = networkDataBytes[networkDataIndex];
		
		if (searchStatus == 0)
		{
			// We are not currently in the middle of a sequence.  If this byte is a 0x0D, then
			// we have hit the beginning of a sequence.
			if (currentByte == 0x0D)
			{
				searchStatus = 1;
				beginningOfSequence = networkDataIndex;
			}
		}
		
		else if (searchStatus == 1)
		{
			// We are currently tracking a newline sequence.  If this byte is another 0x0D,
			// then we are still in the sequence.  Otherwise, we have found the end.
			if (currentByte != 0x0D)
			{
				// If this byte is 0x0A then we want to include it in the sequence.  If it is
				// anything else, then we don't.
				unsigned int sequenceLength = networkDataIndex - beginningOfSequence;
				
				if (currentByte == 0x0A)
					sequenceLength++;
				
				// Add the sequence to our list of sequences.  If we're out of room in the list,
				// allocate more.
				if (newLineSequencesCount == newLineSequencesLength)
				{
					// We've filled up our list.  Double its length so we have more room.
					newLineSequencesLength *= 2;
					newLineSequences = realloc(newLineSequences, newLineSequencesLength * sizeof(NSRange));
					
					if (! newLineSequences)
					{
						[NSException raise:@"ONBMallocException" format:@"Unable to allocate memory in localASCIIModeData()"];
						return nil;
					}
				}
				
				newLineSequences[newLineSequencesCount++] = NSMakeRange(beginningOfSequence, sequenceLength);
				totalLengthOfSequences += sequenceLength;
				
				// We're done with this sequence.
				searchStatus = 0;
			}
		}
	}
	
	// We now have a list of ranges of new-line characters that need to be condensed into
	// single 0x0A bytes.  We're almost ready to do so, but we must first check whether
	// the data ended while we were in the middle of a sequence of 0x0D bytes.  If so,
	// we need to save those for the next function call if this is not the last call.
	// If this *is* the last call, then we should condense that sequence as well.
	if (searchStatus == 1)
	{
		unsigned int sequenceLength = networkDataLength - beginningOfSequence;
	
		if (lastTime)
		{
			// Add the ending sequence to the list.  Be sure to first check that there
			// is enough room in the list.
			if (newLineSequencesCount == newLineSequencesLength)
			{
				// We've filled up our list.  We only need one more spot, however.
				newLineSequencesLength++;
				newLineSequences = realloc(newLineSequences, newLineSequencesLength * sizeof(NSRange));
				
				if (! newLineSequences)
				{
					[NSException raise:@"ONBMallocException" format:@"Unable to allocate memory in localASCIIModeData()"];
					return nil;
				}
			}
			
			newLineSequences[newLineSequencesCount++] = NSMakeRange(beginningOfSequence, sequenceLength);
			totalLengthOfSequences += sequenceLength;
		}
		
		else
		{
			// This is not the last call, so we want to save this ending sequence for next time.
			// Put it in remainingData and then forget about it.
			*remainingData = [NSData dataWithBytes:(networkDataBytes + beginningOfSequence) length:sequenceLength];
			networkDataLength -= sequenceLength;
		}
	}
	else if (! lastTime)
	{
		// The data didn't end with a new-line sequence, so we should make remainingData empty.
		*remainingData = [NSData data];
	}
	
	// The length of the translated data will be the length of the network data minus
	// the length of all the sequences plus one byte for each sequence (the 0x0A byte
	// into each is condensed).
	unsigned int translatedDataLength = networkDataLength - totalLengthOfSequences + newLineSequencesCount;
	NSMutableData *translatedData = [NSMutableData dataWithLength:translatedDataLength];
	char *translatedDataWritePosition = [translatedData mutableBytes];
	
	// Go through the list of sequences to condense.  Each time, copy the uncopied data up
	// to the beginning of the sequence, and then insert a 0x0A.  Finally, copy the rest
	// of the data, if any.
	unsigned int newLineSequencesIndex;
	
	for (newLineSequencesIndex=0; newLineSequencesIndex<newLineSequencesCount; newLineSequencesIndex++)
	{
		// Figure out where to start copying from.  This will either be the beginning of the
		// network data or the byte just after the last sequence condensed.
		unsigned int copyStartPosition = 0;
		
		if (newLineSequencesIndex)
		{
			NSRange lastSequence = newLineSequences[newLineSequencesIndex-1];
			copyStartPosition = lastSequence.location + lastSequence.length;
		}
		
		// Copy from copyStartPosition up to just before the beginning of this sequence.
		NSRange currentSequence =  newLineSequences[newLineSequencesIndex];
		unsigned int bytesToCopy = currentSequence.location - copyStartPosition;
		memcpy(translatedDataWritePosition, networkDataBytes + copyStartPosition, bytesToCopy);
		
		// Put in a 0x0A instead of the sequence.
		*(translatedDataWritePosition + bytesToCopy) = 0x0A;
		
		// We copied bytesToCopy bytes and then added one more.
		translatedDataWritePosition += bytesToCopy + 1;
	}
	
	// Copy the rest of the data.  If there weren't any sequences to condense, then we just get
	// all of it.
	unsigned int copyStartPosition = 0;
	
	if (newLineSequencesCount)
	{
		NSRange lastSequence = newLineSequences[newLineSequencesCount-1];
		copyStartPosition = lastSequence.location + lastSequence.length;
	}
	
	unsigned int bytesToCopy = networkDataLength - copyStartPosition;
	memcpy(translatedDataWritePosition, networkDataBytes + copyStartPosition, bytesToCopy);
	
	free(newLineSequences);
	
	return translatedData;
}

// This function is used to translate local data before sending it to an FTP server in ASCII
// mode.  It finds any 0x0A byte that is not preceeded by a 0x0D byte, and replaces it with
// a 0x0D 0x0A sequence.
//
// For example:
//		83 94 0A 0A 47				->	83 94 0D 0A 0D 0A 47
//		83 94 0D 0A 0A 47			->	83 94 0D 0A 0D 0A 47
//		83 94 0D 0A 0D 0D 0D 0A 47	->	83 94 0D 0A 0D 0D 0D 0A 47
//
// localData is the local data to be translated.  lastTime specifies whether there is more data
// coming or this is the last of it.  It is used to handle the case where the last byte in the
// data is 0x0D.  In this case, then if there is no more data then nothing needs to be done to the
// byte (since a lone 0x0D should not be changed).  On the other hand, if there is more data to
// come then it could be that the first byte of the next chunk is a 0x0A, and if the ending 0x0D
// of this chunk is not taken into consideration then we would erroneously stick an extra 0x0D
// before the 0x0A.  So if lastTime is NO, then it is possible that not all of localData will
// be consumed by the function; some may be returned in remainingData.  The contents of remainingData,
// if any, should be prepended to the data fed to the function on the next call.
NSData *networkASCIIModeData(NSData *localData, NSData **remainingData, BOOL lastTime)
{
	if ((! localData) || (! [localData length]))
	{
		if (! lastTime)
			*remainingData = [NSData data];

		return [NSData data];
	}
	
	// Loop through the data and record the positions of any bare 0x0A bytes found.
	// Afterwards, allocate enough space for the data plus the extra 0x0D bytes, and
	// recreate the data with the appropriate 0x0D bytes.
	
	// We will initially guess that 1/20th of the data is bare 0x0A bytes, and allocate
	// enough space to hold the indexes for that many positions.  If this turns out to
	// not be enough, we will allocate more space later.
	unsigned int barePositionsLength = MAX(1, [localData length] / 20);
	unsigned int *barePositions = calloc(barePositionsLength, sizeof(unsigned int));
	unsigned int barePositionsCount = 0;
	
	if (! barePositions)
	{
		[NSException raise:@"ONBMallocException" format:@"Unable to allocate memory in networkASCIIModeData()"];
		return nil;
	}
	
	const char *localDataBytes = (const char *)[localData bytes];
	unsigned int localDataLength = [localData length];
	unsigned int localDataIndex;
	
	for (localDataIndex=0; localDataIndex<localDataLength; localDataIndex++)
	{
		char currentByte = localDataBytes[localDataIndex];
		char previousByte = (localDataIndex) ? localDataBytes[localDataIndex-1] : 0x00;
		
		if ((currentByte == 0x0A) && (previousByte != 0x0D))
		{
			// We found a bare 0x0A byte.  Add its position to our list.
			
			// First, check that we haven't already filled up our list.
			if (barePositionsCount == barePositionsLength)
			{
				// We've filled up our list.  Double its length so we have more room.
				barePositionsLength *= 2;
				barePositions = realloc(barePositions, barePositionsLength * sizeof(unsigned int));
				
				if (! barePositions)
				{
					[NSException raise:@"ONBMallocException" format:@"Unable to allocate memory in networkASCIIModeData()"];
					return nil;
				}
			}
			
			barePositions[barePositionsCount++] = localDataIndex;
		}
	}
	
	// We now have a list of the positions of bare 0x0A bytes in front of which 0x0D bytes
	// need to be inserted.  We're almost ready to do so, but we must first check whether
	// the last byte of the data is 0x0D.  If it is, we need to retain it for the next
	// call to the function if this is not the last call.
	if ((localDataBytes[localDataLength-1] == 0x0D) && (! lastTime))
	{
		// The last byte is a 0x0D, so we put it in remainingData and forget about it.
		*remainingData = [NSData dataWithBytes:(localDataBytes + localDataLength - 1) length:1];
		localDataLength--;
	}
	else if (! lastTime)
		*remainingData = [NSData data];

	unsigned int translatedDataLength = localDataLength + barePositionsCount;
	NSMutableData *translatedData = [NSMutableData dataWithLength:translatedDataLength];
	char *translatedDataWritePosition = [translatedData mutableBytes];
	
	// Go through the list of bare positions.  Each time, copy the uncopied data up to (and not
	// including) the position, then insert 0x0D.  Finally copy the rest of the data.
	unsigned int barePositionsIndex;
	
	for (barePositionsIndex=0; barePositionsIndex<barePositionsCount; barePositionsIndex++)
	{
		// Figure out the last place up to which we copied.
		unsigned int lastBarePosition = (barePositionsIndex) ? barePositions[barePositionsIndex-1] : 0;
		
		// Copy from the last place we stopped up through this bare position;
		unsigned int barePosition = barePositions[barePositionsIndex];
		unsigned int bytesToCopy = barePosition - lastBarePosition;
		memcpy(translatedDataWritePosition, localDataBytes + lastBarePosition, bytesToCopy);
		
		// Insert a 0x0D.  The 0x0A at barePosition will be copied next time.
		*(translatedDataWritePosition + bytesToCopy) = 0x0D;
		
		// We copied bytesToCopy bytes and then added one more.
		translatedDataWritePosition += bytesToCopy + 1;
	}
	
	// Copy the rest of the data.  If there weren't any bare positions, then we just get all of it.
	unsigned int lastBarePosition = (barePositionsCount) ? barePositions[barePositionsCount-1] : 0;
	unsigned int bytesToCopy = localDataLength - lastBarePosition;
	memcpy(translatedDataWritePosition, localDataBytes + lastBarePosition, bytesToCopy);
	
	free(barePositions);
	
	return translatedData;
}

@implementation ONBFTPConnection

- (id)initWithHost:(NSString *)host
				port:(unsigned int)port
				username:(NSString *)user
				password:(NSString *)password
				delegate:(id)delegate
{
	if (! (self = [super init]))
		return nil;
	
	[self setUseExplicitTLS:NO];
	[self setUseImplicitTLS:NO];
	
	ONB_host = [host copy];
	ONB_port = port;
	ONB_username = [user copy];
	ONB_password = [password copy];
	
	ONB_replyBuffer = [[NSMutableString alloc] init];
	ONB_controlSocket = nil;
	ONB_controlState = ONBDisconnected;
	
	ONB_dataSocket = nil;

	ONB_LISTData = nil;
	ONB_resolvedListings = [[NSMutableArray alloc] init];
	ONB_linksToResolve = [[NSMutableArray alloc] init];
	ONB_resolvingLinksPreviousCWD = nil;
	
	ONB_supportsHiddenLIST = YES;
	
	[self setUseASCIIMode:NO];
	ONB_currentTransferType = ONBUnknownTransferType;
	
	[self setUsePassiveMode:YES];
	
	ONB_userInfo = nil;
	ONB_delegate = delegate;
	
	return self;
}

- (void)dealloc
{
	[ONB_host autorelease];
	[ONB_username autorelease];
	[ONB_password autorelease];
	
	[ONB_replyBuffer autorelease];

	[ONB_controlSocket setDelegate:nil];
	[ONB_controlSocket release];
	
	[ONB_LISTData autorelease];
	[ONB_resolvedListings autorelease];
	[ONB_linksToResolve autorelease];
	[ONB_resolvingLinksPreviousCWD autorelease];
	
	[ONB_dataSocket setDelegate:nil];
	[ONB_dataSocket release];
	
	[self ONB_setUserInfo:nil];
	
	[super dealloc];
}

- (oneway void)release
{
	// Check to see if the only things still retaining us are our own internal timers.
	unsigned int timersActive = 0;
	if (ONB_downloadDataTimer)
		timersActive++;
	
	if (ONB_uploadTimer)
		timersActive++;
	
	if ([self retainCount] <= timersActive + 1)
	{
		NSTimer *oldUploadTimer = ONB_uploadTimer;
		NSTimer *oldDownloadTimer = ONB_downloadDataTimer;
		
		ONB_uploadTimer = nil;
		ONB_downloadDataTimer = nil;
		
		[oldUploadTimer invalidate];
		[oldUploadTimer release];
		
		[oldDownloadTimer invalidate];
		[oldDownloadTimer release];
	}
	
	[super release];
}

- (id)delegate
{
	return ONB_delegate;
}

- (void)setDelegate:(id)delegate
{
	ONB_delegate = delegate;
}

- (BOOL)useExplicitTLS
{
	return ONB_useExplicitTLS;
}

- (void)setUseExplicitTLS:(BOOL)useExplicitTLS
{
	ONB_useExplicitTLS = useExplicitTLS;
}

- (BOOL)useImplicitTLS
{
	return ONB_useImplicitTLS;
}

- (void)setUseImplicitTLS:(BOOL)useImplicitTLS
{
	ONB_useImplicitTLS = useImplicitTLS;
}

- (NSString *)host
{
	return ONB_host;
}

- (unsigned int)port
{
	return ONB_port;
}

- (NSString *)username
{
	return ONB_username;
}

- (NSString *)password
{
	return ONB_password;
}

- (void)connectWithUserInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];

	// Don't try to connect twice.
	if (ONB_controlState != ONBDisconnected)
		[self ONB_transferFailedWithError:[NSError errorWithDomain:ONBFTPErrorDomain
																code:ONBFTPErrorAlreadyConnected
																userInfo:nil]];
	
	// Set up the socket, and tell it to connect.  We'll continue the FTP login
	// process when we get the delegate callback.
	ONB_controlSocket = [[ONBSocket alloc] initWithDelegate:self];
	[ONB_controlSocket connectToHost:[self host] port:[self port]];
	
	ONB_controlState = ONBWaitingForControlSocketToConnect;
}

- (void)getCurrentDirectoryWithUserInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	ONB_controlState = ONBWaitingForPWDReply;
	[self ONB_sendCommand:@"PWD"];
	[self ONB_readReply];
}

- (void)changeDirectory:(NSString *)newDirectory userInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	NSString *command = [NSString stringWithFormat:@"CWD %@", newDirectory];
	
	ONB_controlState = ONBWaitingForCWDReply;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (void)removeFile:(NSString *)filename userInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	NSString *command = [NSString stringWithFormat:@"DELE %@", filename];
	
	ONB_controlState = ONBWaitingForDELEReply;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (void)createDirectory:(NSString *)newDirectory userInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	NSString *command = [NSString stringWithFormat:@"MKD %@", newDirectory];
	
	ONB_controlState = ONBWaitingForMKDReply;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (void)removeDirectory:(NSString *)directory userInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	NSString *command = [NSString stringWithFormat:@"RMD %@", directory];
	
	ONB_controlState = ONBWaitingForRMDReply;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (void)renameFile:(NSString *)oldName newName:(NSString *)newName userInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	ONB_renameNewName = [newName copy];
	NSString *command = [NSString stringWithFormat:@"RNFR %@", oldName];
	
	ONB_controlState = ONBWaitingForRNFRReply;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (void)getDirectoryListingWithUserInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	if ([self usePassiveMode])
	{
		ONB_controlState = ONBWaitingForPASVReplyToLIST;
		[self ONB_sendCommand:@"PASV"];
		[self ONB_readReply];
	}
	else
	{
		ONB_controlState = ONBWaitingForDataSocketToStartToLIST;
		ONB_dataSocket = [[ONBSocket alloc] initWithDelegate:self];
		[ONB_dataSocket acceptConnectionsOnPort:0];
	}
}

- (void)downloadFile:(NSString *)filename size:(unsigned int)filesize userInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	ONB_totalDownloaded = 0;
	[ONB_downloadName autorelease];
	ONB_downloadName = [filename copy];
	ONB_downloadSize = filesize;
	
	// Make sure that we're currently using the appropriate transfer type.
	BOOL useASCIIMode = [self useASCIIMode];
	if ((useASCIIMode && (ONB_currentTransferType == ONBASCIITransferType)) ||
		((! useASCIIMode) && (ONB_currentTransferType == ONBImageTransferType)))
	{
		if ([self usePassiveMode])
		{
			ONB_controlState = ONBWaitingForPASVReplyToRETR;
			[self ONB_sendCommand:@"PASV"];
			[self ONB_readReply];
		}
		else
		{
			ONB_controlState = ONBWaitingForDataSocketToStartToRETR;
			ONB_dataSocket = [[ONBSocket alloc] initWithDelegate:self];
			[ONB_dataSocket acceptConnectionsOnPort:0];
		}
		return;
	}
	
	// Set the appropriate transfer type.
	NSString *command = useASCIIMode ? @"TYPE A" : @"TYPE I";
	ONB_currentTransferType = useASCIIMode ? ONBASCIITransferType : ONBImageTransferType;
	ONB_controlState = ONBWaitingForTYPEReplyToRETR;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (void)uploadFileWithName:(NSString *)filename size:(unsigned int)filesize userInfo:(NSDictionary *)userInfo
{
	[self ONB_setUserInfo:userInfo];
	
	// Reset all of the upload state information.
	[ONB_uploadTimer invalidate];
	[ONB_uploadTimer release];
	ONB_uploadTimer = nil;
	ONB_uploadEOF = NO;
	ONB_uploadWritesInProgress = 0;
	
	[ONB_uploadName autorelease];
	ONB_uploadName = [filename copy];
	ONB_uploadSize = filesize;
	ONB_totalUploaded = 0;
	
	// Make sure that we're currently using the appropriate transfer type.
	BOOL useASCIIMode = [self useASCIIMode];
	if ((useASCIIMode && (ONB_currentTransferType == ONBASCIITransferType)) ||
		((! useASCIIMode) && (ONB_currentTransferType == ONBImageTransferType)))
	{
		if ([self usePassiveMode])
		{
			ONB_controlState = ONBWaitingForPASVReplyToSTOR;
			[self ONB_sendCommand:@"PASV"];
			[self ONB_readReply];
		}
		else
		{
			ONB_controlState = ONBWaitingForDataSocketToStartToSTOR;
			ONB_dataSocket = [[ONBSocket alloc] initWithDelegate:self];
			[ONB_dataSocket acceptConnectionsOnPort:0];
		}
		return;
	}
	
	// Set the appropriate transfer type.
	NSString *command = useASCIIMode ? @"TYPE A" : @"TYPE I";
	ONB_currentTransferType = useASCIIMode ? ONBASCIITransferType : ONBImageTransferType;
	ONB_controlState = ONBWaitingForTYPEReplyToSTOR;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (BOOL)useASCIIMode
{
	return ONB_useASCIIMode;
}

- (void)setUseASCIIMode:(BOOL)useASCIIMode
{
	ONB_useASCIIMode = useASCIIMode;
}

- (BOOL)usePassiveMode
{
	return ONB_usePassiveMode;
}

- (void)setUsePassiveMode:(BOOL)usePassiveMode
{
	ONB_usePassiveMode = usePassiveMode;
}

@end








@implementation ONBFTPConnection ( ONBFTPConnectionPrivateMethods )

- (void)ONB_handle220ReplyWithCode:(int)code text:(NSString *)text
{
	if (code == 120)
	{
		// The server has sent an "expected delay" message.  Wait for it to
		// tell us it is read.
		[self ONB_readReply];
		return;
	}
	
	else if (code != 220)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandled220Reply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	if ([self useExplicitTLS])
	{
		ONB_controlState = ONBWaitingForAUTHReply;
		[self ONB_sendCommand:@"AUTH TLS"];
		[self ONB_readReply];
	}
	else
	{
		ONB_controlState = ONBWaitingForUSERReply;
		[self ONB_sendCommand:[NSString stringWithFormat:@"USER %@", [self username]]];
		[self ONB_readReply];
	}	
}

- (void)ONB_handleAUTHReplyWithCode:(int)code text:(NSString *)text
{
	if (code != 234)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledAUTHReply
												userInfo:unhandledReplyUserInfo];

		[self ONB_transferFailedWithError:error];
		return;
	}
	
	[ONB_controlSocket setSSLServerMode:NO];
	[ONB_controlSocket setVerifySSLCertificates:NO];
	[ONB_controlSocket enableSSL];
}

- (void)ONB_handlePBSZReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledPBSZReply
												userInfo:unhandledReplyUserInfo];

		[self ONB_transferFailedWithError:error];
		return;
	}
	
	ONB_controlState = ONBWaitingForPROTReply;
	[self ONB_sendCommand:@"PROT P"];
	[self ONB_readReply];
}

- (void)ONB_handlePROTReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledPROTReply
												userInfo:unhandledReplyUserInfo];

		[self ONB_transferFailedWithError:error];
		return;
	}
	
	ONB_controlState = ONBWaitingForUSERReply;
	[self ONB_sendCommand:[NSString stringWithFormat:@"USER %@", [self username]]];
	[self ONB_readReply];
}

- (void)ONB_handleUSERReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit == 2)
	{
		[self ONB_transferSucceededWithReturnInfo:nil];
		return;
	}
	else if (firstDigit == 3)
	{
		ONB_controlState = ONBWaitingForPASSReply;
		[self ONB_sendCommand:[NSString stringWithFormat:@"PASS %@", [self password]]];
		[self ONB_readReply];
		return;
	}
	
	NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
	NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																						@"replyCode",
																						text,
																						@"replyText",
																						nil];
	NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
											code:ONBFTPErrorUnhandledUSERReply
											userInfo:unhandledReplyUserInfo];
	[self ONB_transferFailedWithError:error];
}

- (void)ONB_handlePASSReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit == 2)
	{
		[self ONB_transferSucceededWithReturnInfo:nil];
		return;
	}
	
	NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
	NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																						@"replyCode",
																						text,
																						@"replyText",
																						nil];
	NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
											code:ONBFTPErrorUnhandledPASSReply
											userInfo:unhandledReplyUserInfo];
	[self ONB_transferFailedWithError:error];
}

- (void)ONB_handleLISTReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit == 1)
	{
		// The server is saying to wait for a bit.
		[self ONB_readReply];
		return;
	}
	
	else if (firstDigit == 2)
	{
		// We got a positive reply.  Now we need to wait for the actual listing data
		// to arrive on the data socket, if it has not already.
		if (ONB_LISTData)
		{
			NSData *listData = [ONB_LISTData autorelease];
			ONB_LISTData = nil;
			
			[self ONB_finishedLISTWithData:listData];
			return;
		}
		
		if (ONB_controlState == ONBWaitingForLISTReply)
			ONB_controlState = ONBWaitingForLISTData;
		else
			ONB_controlState = ONBWaitingForLISTDataToResolveLinks;
		
		return;
	}
	else if (ONB_supportsHiddenLIST)
	{
		// It might be that this server doesn't support "LIST -a".  Turn it off and try again.
		ONB_supportsHiddenLIST = NO;
		[self ONB_sendCommand:@"LIST"];
		[self ONB_readReply];
		return;
	}

	NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
	NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																						@"replyCode",
																						text,
																						@"replyText",
																						nil];
	NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
											code:ONBFTPErrorUnhandledLISTReply
											userInfo:unhandledReplyUserInfo];
	[self ONB_transferFailedWithError:error];
}

- (void)ONB_handleRETRReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit == 1)
	{
		// The server is saying to wait for a bit.
		[self ONB_readReply];
		return;
	}
	
	else if (firstDigit == 2)
	{
		// We got a positive reply.  Now we need to wait for the actual download data
		// to finish arriving on the data socket, if it hasn't already.
		if (! ONB_downloadDataTimer)
		{
			// The data connection has already closed.
			[self ONB_transferSucceededWithReturnInfo:nil];
		}
		else
			ONB_controlState = ONBWaitingForRETRData;

		return;
	}

	NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
	NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																						@"replyCode",
																						text,
																						@"replyText",
																						nil];
	NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
											code:ONBFTPErrorUnhandledRETRReply
											userInfo:unhandledReplyUserInfo];
	[self ONB_transferFailedWithError:error];
}

- (void)ONB_handleSTORReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if ((firstDigit == 1) && ((ONB_controlState == ONBWaitingForSTORReplyAndDataConnectionToSendUploadData) || 
								(ONB_controlState == ONBWaitingForSTORReplyToSendUploadData)))
	{
		if (ONB_controlState == ONBWaitingForSTORReplyAndDataConnectionToSendUploadData)
		{
			ONB_controlState = ONBWaitingForDataConnectionToSendUploadData;
			return;
		}
		
		// The server is saying to go ahead and send the data.
		ONB_controlState = ONBSendingUploadData;
		ONB_uploadTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
															target:self
															selector:@selector(ONB_handleUploadData:)
															userInfo:nil
															repeats:YES] retain];
		[self ONB_handleUploadData:nil];
		return;
	}
	
	else if ((firstDigit == 2) && (ONB_controlState == ONBWaitingForSTORReply))
	{
		[self ONB_transferSucceededWithReturnInfo:nil];
		return;
	}

	NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
	NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																						@"replyCode",
																						text,
																						@"replyText",
																						nil];
	NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
											code:ONBFTPErrorUnhandledRETRReply
											userInfo:unhandledReplyUserInfo];
	[self ONB_transferFailedWithError:error];
}

- (void)ONB_finishedLISTWithData:(NSData *)listData
{
	NSString *string = [[[NSString alloc] initWithData:listData encoding:NSASCIIStringEncoding] autorelease];
	NSMutableArray *listings = [NSMutableArray array];
	NSMutableArray *linksToResolve = [NSMutableArray array];
	ONBFileType linkType = ONBRegularFile;
	
	NSString *linkedFileName = nil;
	if ([ONB_linksToResolve count])
		linkedFileName = [[[ONB_linksToResolve objectAtIndex:0] linkedFile] lastPathComponent];
	
	NSEnumerator *lineEnumerator = [[string componentsSeparatedByString:@"\r\n"] objectEnumerator];
	NSString *line;
	while (line = [lineEnumerator nextObject])
	{
		// Ignore the empty string at the end of the listing, if any.
		if ([line isEqualToString:@""])
			continue;
		
		// Re-add the \r\n, since CFFTPCreateParsedResourceListing seems to depend on it.
		line = [line stringByAppendingString:@"\r\n"];
		
		const char *UTF8String = [line UTF8String];
		NSDictionary *parsedDictionary = nil;
		CFIndex result = CFFTPCreateParsedResourceListing(kCFAllocatorDefault,
															(const UInt8 *)UTF8String,
															strlen(UTF8String),
															(CFDictionaryRef *)&parsedDictionary);
		if (result == -1)
		{
			NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
													code:ONBFTPErrorMalformedDirectoryListing
													userInfo:[NSDictionary dictionaryWithObject:listData
																							forKey:@"listingData"]];
			[self ONB_transferFailedWithError:error];
			return;
		}
		
		// A nil dictionary will be caused by a line like "total 49" at the beginning of the listing.
		if (! parsedDictionary)
			continue;
		
		// CFFTPCreateParsedResourceListing gives you a retained dictionary.
		parsedDictionary = [parsedDictionary autorelease];
		
		ONBFileListing *listing = [ONBFileListing fileListingFromCFFTPDictionary:parsedDictionary];
		
		// Don't return listings for "." or ".."
		NSString *name = [listing name];
		if ([name isEqualToString:@"."] || [name isEqualToString:@".."])
			continue;
		
		if ([linkedFileName isEqualToString:[listing name]] && [listing isDirectory])
			linkType = ONBDirectory;
		
		// If the file listing is not a symbolic link, we are done with it.  If it is a link but
		// ONBFileListing figured out it points to a directory, we are done.  Otherwise, we need to
		// figure out if it points to a directory or to a regular file.
		if ((! [listing isSymbolicLink]) || [listing isDirectory])
		{
			[listings addObject:listing];
			continue;
		}
		
		[linksToResolve addObject:listing];
	}
	
	if ((ONB_controlState == ONBWaitingForLISTReply) || (ONB_controlState == ONBWaitingForLISTData))
	{
		// If there are no symbolic links we must type, then we are done.
		if (! [linksToResolve count])
		{
			NSDictionary *returnInfo = [NSDictionary dictionaryWithObject:listings forKey:@"directoryListing"];
			[self ONB_transferSucceededWithReturnInfo:returnInfo];
			return;
		}

		[ONB_linksToResolve addObjectsFromArray:linksToResolve];
		
		[ONB_resolvedListings removeAllObjects];
		[ONB_resolvedListings addObjectsFromArray:listings];
		
		// Get the current directory so we can switch back here when we're done resolving symlinks.
		ONB_controlState = ONBWaitingForPWDReplyToResolveLinks;
		[self ONB_sendCommand:@"PWD"];
		[self ONB_readReply];
	}
	
	else if ((ONB_controlState == ONBWaitingForLISTReplyToResolveLinks) ||
				(ONB_controlState == ONBWaitingForLISTDataToResolveLinks))
	{
		ONBFileListing *linkListing = [ONB_linksToResolve objectAtIndex:0];
		[linkListing setType:linkType];
		[ONB_resolvedListings addObject:linkListing];
		[ONB_linksToResolve removeObjectAtIndex:0];
		
		// Switch back to the original working directory so that we can complete the transfer or go on to the
		// next link to resolve.
		ONB_controlState = ONBWaitingForCWDReplyToOriginalDirectoryToResolveLinks;
		[self ONB_sendCommand:[NSString stringWithFormat:@"CWD %@", ONB_resolvingLinksPreviousCWD]];
		[self ONB_readReply];
	}
}

- (void)ONB_handleCWDReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledCWDReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	[self ONB_transferSucceededWithReturnInfo:nil];
}

- (void)ONB_handleDELEReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledDELEReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	[self ONB_transferSucceededWithReturnInfo:nil];
}

- (void)ONB_handleMKDReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledMKDReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	[self ONB_transferSucceededWithReturnInfo:nil];
}

- (void)ONB_handleRNFRReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 3)
	{
		[ONB_renameNewName release];
		ONB_renameNewName = nil;
		
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledRNFRReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	NSString *command = [NSString stringWithFormat:@"RNTO %@", ONB_renameNewName];
	[ONB_renameNewName release];
	ONB_renameNewName = nil;
	
	ONB_controlState = ONBWaitingForRNTOReply;
	[self ONB_sendCommand:command];
	[self ONB_readReply];
}

- (void)ONB_handleRNTOReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledRNTOReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	[self ONB_transferSucceededWithReturnInfo:nil];
}

- (void)ONB_handleRMDReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledRMDReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	[self ONB_transferSucceededWithReturnInfo:nil];
}

- (void)ONB_handleTYPEReplyWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		ONB_currentTransferType = ONBUnknownTransferType;
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledTYPEReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	switch (ONB_controlState)
	{
		case ONBWaitingForTYPEReplyToRETR:
			if ([self usePassiveMode])
			{
				ONB_controlState = ONBWaitingForPASVReplyToRETR;
				[self ONB_sendCommand:@"PASV"];
				[self ONB_readReply];
			}
			else
			{
				ONB_controlState = ONBWaitingForDataSocketToStartToRETR;
				ONB_dataSocket = [[ONBSocket alloc] initWithDelegate:self];
				[ONB_dataSocket acceptConnectionsOnPort:0];
			}
			break;
		
		case ONBWaitingForTYPEReplyToSTOR:
			if ([self usePassiveMode])
			{
				ONB_controlState = ONBWaitingForPASVReplyToSTOR;
				[self ONB_sendCommand:@"PASV"];
				[self ONB_readReply];
			}
			else
			{
				ONB_controlState = ONBWaitingForDataSocketToStartToSTOR;
				ONB_dataSocket = [[ONBSocket alloc] initWithDelegate:self];
				[ONB_dataSocket acceptConnectionsOnPort:0];
			}

			break;

		default:
			NSLog(@"Unhandled TYPE reply state!");
			break;
	}
}

- (void)ONB_handlePWDReplyWithCode:(int)code text:(NSString *)text
{
	NSString *pwd = [self ONB_parsePWDReplyWithCode:code text:text];
	if (! pwd)
		return;
	
	NSDictionary *returnInfo = [NSDictionary dictionaryWithObject:[NSString stringWithString:pwd]
															forKey:@"currentDirectory"];
	[self ONB_transferSucceededWithReturnInfo:returnInfo];
}

- (NSString *)ONB_parsePWDReplyWithCode:(int)code text:(NSString *)text
{
	// If the code isn't 257, we may have not actually gotten the CWD.
	if (code != 257)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledPWDReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return nil;
	}
	
	// We must scan and find the name of the current directory.  The directory name
	// should be at the beginning of the text, surrounded by quotes.  If there is a quote
	// in the directory's actual name, then it will be preceeded by another quote to escape it.
	NSScanner *scanner = [NSScanner scannerWithString:text];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	// We must have a quotation mark at the beginning of the text.
	if (! [scanner scanString:@"\"" intoString:nil])
	{
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorMalformed257Reply
												userInfo:[NSDictionary dictionaryWithObject:text
																						forKey:@"replyText"]];
		[self ONB_transferFailedWithError:error];
		return nil;
	}
	
	NSMutableString *pwd = [NSMutableString string];
	BOOL done = NO;
	BOOL error = NO;
	
	// Keep scanning until we hit an unescaped quotation mark.
	while ((! done) && (! error))
	{
		NSString *scannedString;
		if ([scanner scanUpToString:@"\"" intoString:&scannedString])
			[pwd appendString:scannedString];
		
		// Check to see if this is an escaped quotation mark.
		if ([scanner scanString:@"\"\"" intoString:nil])
			[pwd appendString:@"\""];
		else
			done = YES;
		
		// We should hit the ending quotation mark before the end of the string.
		if ([scanner isAtEnd])
			error = YES;
	}
	
	if (error)
	{
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorMalformed257Reply
												userInfo:[NSDictionary dictionaryWithObject:text
																						forKey:@"replyText"]];
		[self ONB_transferFailedWithError:error];
		return nil;
	}
	
	return [NSString stringWithString:pwd];
}

- (void)ONB_handlePWDReplyForResolvingLinksWithCode:(int)code text:(NSString *)text
{
	NSString *pwd = [self ONB_parsePWDReplyWithCode:code text:text];
	if (! pwd)
		return;
	
	[ONB_resolvingLinksPreviousCWD autorelease];
	ONB_resolvingLinksPreviousCWD = [pwd copy];
	
	NSString *parentPath = [[[ONB_linksToResolve objectAtIndex:0] linkedFile] stringByDeletingLastPathComponent];
	if ([parentPath isEqualToString:@""])
	{
		// The file is actually in the current directory.  We could optimize this in the future by
		// not actually getting the listing again.
		parentPath = pwd;
	}
	
	ONB_controlState = ONBWaitingForCWDReplyToResolveLinks;
	[self ONB_sendCommand:[NSString stringWithFormat:@"CWD %@", parentPath]];
	[self ONB_readReply];
}

- (void)ONB_handleCWDReplyToOriginalDirectoryForResolvingLinksWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledCWDReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	// If we have no more links to resolve, then we are done.
	if (! [ONB_linksToResolve count])
	{
		NSDictionary *returnInfo = [NSDictionary dictionaryWithObject:ONB_resolvedListings forKey:@"directoryListing"];
		[self ONB_transferSucceededWithReturnInfo:returnInfo];
		return;
	}
	
	// Go on to the next link to resolve.
	NSString *parentPath = [[[ONB_linksToResolve objectAtIndex:0] linkedFile] stringByDeletingLastPathComponent];
	if ([parentPath isEqualToString:@""])
	{
		// The file is actually in the current directory.  We could optimize this in the future by
		// not actually getting the listing again.
		parentPath = ONB_resolvingLinksPreviousCWD;
	}
	
	ONB_controlState = ONBWaitingForCWDReplyToResolveLinks;
	[self ONB_sendCommand:[NSString stringWithFormat:@"CWD %@", parentPath]];
	[self ONB_readReply];
}

- (void)ONB_handleCWDReplyForResolvingLinksWithCode:(int)code text:(NSString *)text
{
	unsigned int firstDigit = ONBFIRSTDIGIT(code);
	if (code == 550)
	{
		// We got a permission denied error.  We'll just have to assume that the link
		// points to a regular file, and continue on to the next link.
		ONBFileListing *linkListing = [ONB_linksToResolve objectAtIndex:0];
		[ONB_resolvedListings addObject:linkListing];
		[ONB_linksToResolve removeObjectAtIndex:0];
		
		ONB_controlState = ONBWaitingForCWDReplyToOriginalDirectoryToResolveLinks;
		[self ONB_sendCommand:[NSString stringWithFormat:@"CWD %@", ONB_resolvingLinksPreviousCWD]];
		[self ONB_readReply];
		return;
	}
	
	else if (firstDigit != 2)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledCWDReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	if ([self usePassiveMode])
	{
		ONB_controlState = ONBWaitingForPASVReplyToLISTToResolveLinks;
		[self ONB_sendCommand:@"PASV"];
		[self ONB_readReply];
	}
	else
	{
		ONB_controlState = ONBWaitingForDataSocketToStartToLISTToResolveLinks;
		ONB_dataSocket = [[ONBSocket alloc] initWithDelegate:self];
		[ONB_dataSocket acceptConnectionsOnPort:0];
	}
}

- (void)ONB_handlePASVReplyWithCode:(int)code text:(NSString *)text
{
	// The only successful code is 227.
	if (code != 227)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledPASVReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}

	// We must find the host's address and port number.  They should be within parentheses
	// like (h1,h2,h3,h4,p1,p2).
	NSScanner *scanner = [NSScanner scannerWithString:text];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	// We should be able to find the open parenthesis.
	if (! ([scanner scanUpToString:@"(" intoString:nil] &&
			[scanner scanString:@"(" intoString:nil]))
	{
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorMalformed227Reply
												userInfo:[NSDictionary dictionaryWithObject:text
																						forKey:@"replyText"]];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	// Now we should be able to scan out four numbers between 0 and 255.
	NSMutableString *hostAddress = [NSMutableString stringWithCapacity:15];
	unsigned int count;
	for(count=0; count<4; count++)
	{
		// Scan out an integer and its following comma.
		int octet;
		if (! ([scanner scanInt:&octet] &&
				[scanner scanString:@"," intoString:nil] &&
				(octet >= 0) && (octet <= 255)))
		{
			NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
													code:ONBFTPErrorMalformed227Reply
													userInfo:[NSDictionary dictionaryWithObject:text
																							forKey:@"replyText"]];
			[self ONB_transferFailedWithError:error];
			return;
		}
		
		NSString *format = (count) ? @".%d" : @"%d";
		[hostAddress appendString:[NSString stringWithFormat:format, octet]];
	}
	
	// Scan out the upper and lower halves of the 16-bit port, as well as the end parenthesis.
	int upperHalf;
	int lowerHalf;
	if (! ([scanner scanInt:&upperHalf] &&
			[scanner scanString:@"," intoString:nil] &&
			[scanner scanInt:&lowerHalf] &&
			[scanner scanString:@")" intoString:nil] &&
			(upperHalf >= 0) && (upperHalf <= 255) &&
			(lowerHalf >= 0) && (lowerHalf <= 255)))
	{
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorMalformed227Reply
												userInfo:[NSDictionary dictionaryWithObject:text
																						forKey:@"replyText"]];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	unsigned int port = (upperHalf << 8) + lowerHalf;
	NSString *command = nil;
	
	switch (ONB_controlState)
	{
		case ONBWaitingForPASVReplyToLIST:
			ONB_controlState = ONBWaitingForLISTReply;
			command = ONB_supportsHiddenLIST ? @"LIST -a" : @"LIST";
			break;
		
		case ONBWaitingForPASVReplyToLISTToResolveLinks:
			ONB_controlState = ONBWaitingForLISTReplyToResolveLinks;
			command = ONB_supportsHiddenLIST ? @"LIST -a" : @"LIST";
			break;
		
		case ONBWaitingForPASVReplyToRETR:
			ONB_controlState = ONBWaitingForRETRReply;
			command = [NSString stringWithFormat:@"RETR %@", ONB_downloadName];
			ONB_downloadDataTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
																		target:self
																		selector:@selector(ONB_checkForDownloadData:)
																		userInfo:nil
																		repeats:YES] retain];
			break;
		
		case ONBWaitingForPASVReplyToSTOR:
			ONB_controlState = ONBWaitingForSTORReplyToSendUploadData;
			command = [NSString stringWithFormat:@"STOR %@", ONB_uploadName];
			break;
		
		default:
			NSLog(@"Unrecognized PASV reply state!");
	}
	
	if (command)
	{
		[self ONB_sendCommand:command];
		[self ONB_readReply];
	}
	
	ONB_dataSocket = [[ONBSocket alloc] initWithDelegate:self];
	[ONB_dataSocket connectToHost:hostAddress port:port];
}

- (void)ONB_handlePORTReplyWithCode:(int)code text:(NSString *)text
{
	// The only successful code is 200.
	if (code != 200)
	{
		NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
		NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																							@"replyCode",
																							text,
																							@"replyText",
																							nil];
		NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
												code:ONBFTPErrorUnhandledPORTReply
												userInfo:unhandledReplyUserInfo];
		[self ONB_transferFailedWithError:error];
		return;
	}
	
	NSString *command = nil;
	switch (ONB_controlState)
	{
		case ONBWaitingForPORTReplyToLIST:
		case ONBWaitingForPORTReplyToLISTToResolveLinks:
			if (ONB_controlState == ONBWaitingForPORTReplyToLIST)
				ONB_controlState = ONBWaitingForLISTReply;
			else
				ONB_controlState = ONBWaitingForLISTReplyToResolveLinks;
			
			command = ONB_supportsHiddenLIST ? @"LIST -a" : @"LIST";
			break;
		
		case ONBWaitingForPORTReplyToRETR:
			ONB_controlState = ONBWaitingForRETRReply;
			command = [NSString stringWithFormat:@"RETR %@", ONB_downloadName];
			ONB_downloadDataTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
																		target:self
																		selector:@selector(ONB_checkForDownloadData:)
																		userInfo:nil
																		repeats:YES] retain];
			break;

		case ONBWaitingForPORTReplyToSTOR:
			ONB_controlState = ONBWaitingForSTORReplyAndDataConnectionToSendUploadData;
			command = [NSString stringWithFormat:@"STOR %@", ONB_uploadName];
			break;
		
		default:
			NSLog(@"Unrecognized PORT reply state!");
	}
	
	if (command)
	{
		[self ONB_sendCommand:command];
		[self ONB_readReply];
	}
}

- (void)ONB_didReadReplyWithCode:(unsigned int)code text:(NSString *)text
{
	NSString *communication = [NSString stringWithFormat:@"%d: %@", code, text];
	if ([ONB_delegate respondsToSelector:@selector(connection:receivedCommunicationFromServer:)])
		[ONB_delegate connection:self receivedCommunicationFromServer:communication];
	
	switch (ONB_controlState)
	{
		case ONBWaitingFor220:
			[self ONB_handle220ReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForAUTHReply:
			[self ONB_handleAUTHReplyWithCode:code text:text];
			break;

		case ONBWaitingForPBSZReply:
			[self ONB_handlePBSZReplyWithCode:code text:text];
			break;

		case ONBWaitingForPROTReply:
			[self ONB_handlePROTReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForUSERReply:
			[self ONB_handleUSERReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForPASSReply:
			[self ONB_handlePASSReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForPWDReply:
			[self ONB_handlePWDReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForCWDReply:
			[self ONB_handleCWDReplyWithCode:code text:text];
			break;

		case ONBWaitingForDELEReply:
			[self ONB_handleDELEReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForMKDReply:
			[self ONB_handleMKDReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForRMDReply:
			[self ONB_handleRMDReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForRNFRReply:
			[self ONB_handleRNFRReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForRNTOReply:
			[self ONB_handleRNTOReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForPASVReplyToLIST:
		case ONBWaitingForPASVReplyToLISTToResolveLinks:
		case ONBWaitingForPASVReplyToRETR:
		case ONBWaitingForPASVReplyToSTOR:
			[self ONB_handlePASVReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForPORTReplyToLIST:
		case ONBWaitingForPORTReplyToLISTToResolveLinks:
		case ONBWaitingForPORTReplyToRETR:
		case ONBWaitingForPORTReplyToSTOR:
			[self ONB_handlePORTReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForLISTReplyToResolveLinks:
		case ONBWaitingForLISTReply:
			[self ONB_handleLISTReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForRETRReply:
			[self ONB_handleRETRReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForPWDReplyToResolveLinks:
			[self ONB_handlePWDReplyForResolvingLinksWithCode:(int)code text:text];
			break;
		
		case ONBWaitingForCWDReplyToResolveLinks:
			[self ONB_handleCWDReplyForResolvingLinksWithCode:code text:text];
			break;
		
		case ONBWaitingForCWDReplyToOriginalDirectoryToResolveLinks:
			[self ONB_handleCWDReplyToOriginalDirectoryForResolvingLinksWithCode:code text:text];
			break;
		
		case ONBWaitingForTYPEReplyToRETR:
		case ONBWaitingForTYPEReplyToSTOR:
			[self ONB_handleTYPEReplyWithCode:code text:text];
			break;
		
		case ONBWaitingForSTORReplyAndDataConnectionToSendUploadData:
		case ONBWaitingForSTORReplyToSendUploadData:
		case ONBWaitingForSTORReply:
			[self ONB_handleSTORReplyWithCode:code text:text];
			break;
		
		default:
		{
			NSNumber *codeNumber = [NSNumber numberWithUnsignedInt:code];
			NSDictionary *unhandledReplyUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:codeNumber,
																								@"replyCode",
																								text,
																								@"replyText",
																								nil];
			NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain
													code:ONBFTPErrorUnexpectedReply
													userInfo:unhandledReplyUserInfo];
			[self ONB_transferFailedWithError:error];
		}
		break;
	}
}

- (void)ONB_constructReplyWithLine:(NSString *)line
{
	int code;
	BOOL gotCompleteReply = NO;

	NSScanner *scanner = [NSScanner scannerWithString:line];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

	if (! [ONB_replyBuffer length])
	{
		// There's nothing in the reply buffer right now, so this should either
		// be a complete reply or the beginning of a multi-line reply.
		if ((! [scanner scanInt:&code]) || (code < 100) || (code > 599))
		{
			NSString *fullReply = [ONB_replyBuffer stringByAppendingString:line];
			[ONB_replyBuffer setString:@""];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:fullReply forKey:@"reply"];
			NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain code:ONBFTPErrorMalformedReply userInfo:userInfo];
			[self ONB_transferFailedWithError:error];
			return;
		}
		
		// Is this the beginning of a multi-line reply, or is it just a single line?
		if ([scanner scanString:@" " intoString:nil])
			gotCompleteReply = YES;
		
		// The only other alternative is to have a "-" after the code.
		else if (! [scanner scanString:@"-" intoString:nil])
		{
			NSString *fullReply = [ONB_replyBuffer stringByAppendingString:line];
			[ONB_replyBuffer setString:@""];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:fullReply forKey:@"reply"];
			NSError *error = [NSError errorWithDomain:ONBFTPErrorDomain code:ONBFTPErrorMalformedReply userInfo:userInfo];
			[self ONB_transferFailedWithError:error];
			return;
		}
		
		[ONB_replyBuffer appendString:[line substringFromIndex:[scanner scanLocation]]];
	}
	else
	{
		// We're in the middle of a multi-line reply.  Check to see if this is the last line.
		if ([scanner scanInt:&code])
		{
			// If we scanned a three-digit integer, then if the next character is a space we have
			// found the last line.  Otherwise, this is an intermediate line.
			if (([scanner scanLocation] == 3) && [scanner scanString:@" " intoString:nil])
			{
				// We got the last line.
				gotCompleteReply = YES;
				[ONB_replyBuffer appendString:[line substringFromIndex:[scanner scanLocation]]];
			}
			else
				[ONB_replyBuffer appendString:line];
		}
		else
			[ONB_replyBuffer appendString:line];
	}
	
	// If we got a complete reply, call the appropriate method.  Otherwise, watch for another line.
	if (gotCompleteReply)
	{
		NSString *text = [NSString stringWithString:ONB_replyBuffer];
		[ONB_replyBuffer setString:@""];
		
		[self ONB_didReadReplyWithCode:code text:text];
	}
	else
		[self ONB_readLine];
}

- (void)ONB_readReply
{
	[self ONB_readLine];
}

- (void)ONB_didReadLine:(NSString *)line
{
	[self ONB_constructReplyWithLine:line];
}

- (void)ONB_sendCommand:(NSString *)command
{
	// If the command is "PASS password", filter out the password.
	NSString *displayCommand = command;
	NSRange passRange = [displayCommand rangeOfString:@"PASS" options:NSCaseInsensitiveSearch];
	if (passRange.location == 0)
		displayCommand = @"PASS xxx";

	if ([ONB_delegate respondsToSelector:@selector(connection:sentCommunicationToServer:)])
		[ONB_delegate connection:self sentCommunicationToServer:displayCommand];

	command = [command stringByAppendingString:@"\r\n"];
	NSData *data = [command dataUsingEncoding:NSASCIIStringEncoding];
	
	[ONB_controlSocket writeData:data timeout:-1.0 userInfo:nil];
}

- (void)socket:(ONBSocket *)socket
	didDisconnectWithError:(NSError *)error
	remainingData:(NSData *)remainingData
{
	if (socket == ONB_dataSocket)
	{
		[ONB_dataSocket setDelegate:nil];
		[ONB_dataSocket release];
		ONB_dataSocket = nil;
		
		if ((ONB_controlState == ONBWaitingForRETRReply) || (ONB_controlState == ONBWaitingForRETRData))
		{
			[ONB_downloadDataTimer invalidate];
			[ONB_downloadDataTimer release];
			ONB_downloadDataTimer = nil;
			
			[self ONB_handleDownloadData:remainingData lastTime:YES];
		}
		
		if ([error code] == ONBConnectionClosed)
		{
			switch (ONB_controlState)
			{
				case ONBWaitingForLISTReply:
				case ONBWaitingForLISTReplyToResolveLinks:
					ONB_LISTData = [remainingData retain];
					break;
				
				case ONBWaitingForLISTData:
				case ONBWaitingForLISTDataToResolveLinks:
					[self ONB_finishedLISTWithData:remainingData];
					break;
				
				case ONBWaitingForRETRReply:
					break;
				
				case ONBWaitingForRETRData:
					[self ONB_transferSucceededWithReturnInfo:nil];
					break;
				
				default:
					[self ONB_transferFailedWithError:error];
					break;
			}

			return;
		}
		
		[self ONB_transferFailedWithError:error];
		return;
	}
}

- (void)socket:(ONBSocket *)socket
	didReadData:(NSData *)data
	userInfo:(NSDictionary *)userInfo
{
	if (socket == ONB_controlSocket)
	{
		// Get rid of the \r in the line.
		NSMutableString *line = [[[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
		[line replaceCharactersInRange:NSMakeRange([line length]-2, 1) withString:@""];
		
		[self ONB_didReadLine:line];
	}
	
	else if ((socket == ONB_dataSocket) && [data length])
		[self ONB_handleDownloadData:data lastTime:NO];
}

- (void)socket:(ONBSocket *)socket
	didWriteDataWithUserInfo:(NSDictionary *)userInfo
{
	if (socket == ONB_dataSocket)
	{
		ONB_uploadWritesInProgress--;
		ONB_totalUploaded += [[userInfo objectForKey:@"dataLength"] unsignedIntValue];
	}
}

- (void)socketDidConnect:(ONBSocket *)socket
{
	if (socket == ONB_controlSocket)
	{
		if ([self useImplicitTLS])
		{
			[ONB_controlSocket setSSLServerMode:NO];
			[ONB_controlSocket setVerifySSLCertificates:NO];
			[ONB_controlSocket enableSSL];
		}
		else
		{
			ONB_controlState = ONBWaitingFor220;
			[self ONB_readReply];
		}
	}
	
	else if (socket == ONB_dataSocket)
	{
		if ([self useExplicitTLS] || [self useImplicitTLS])
		{
			[ONB_dataSocket setSSLServerMode:NO];
			[ONB_dataSocket setVerifySSLCertificates:NO];
			[ONB_dataSocket enableSSL];
		}
		
		if (ONB_controlState == ONBWaitingForDataConnectionToSendUploadData)
		{
			ONB_controlState = ONBSendingUploadData;
			ONB_uploadTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
																target:self
																selector:@selector(ONB_handleUploadData:)
																userInfo:nil
																repeats:YES] retain];
			[self ONB_handleUploadData:nil];
		}
		else if (ONB_controlState == ONBWaitingForSTORReplyAndDataConnectionToSendUploadData)
			ONB_controlState = ONBWaitingForSTORReplyToSendUploadData;
	}
}

- (void)socket:(ONBSocket *)socket
	acceptingConnectionsOnPort:(UInt16)port
{
	switch (ONB_controlState)
	{
		case ONBWaitingForDataSocketToStartToLIST:
		case ONBWaitingForDataSocketToStartToLISTToResolveLinks:
		case ONBWaitingForDataSocketToStartToRETR:
		case ONBWaitingForDataSocketToStartToSTOR:
		{
			switch (ONB_controlState)
			{
				case ONBWaitingForDataSocketToStartToLIST:
					ONB_controlState = ONBWaitingForPORTReplyToLIST;
					break;
				
				case ONBWaitingForDataSocketToStartToLISTToResolveLinks:
					ONB_controlState = ONBWaitingForPORTReplyToLISTToResolveLinks;
					break;
				
				case ONBWaitingForDataSocketToStartToRETR:
					ONB_controlState = ONBWaitingForPORTReplyToRETR;
					break;
				
				case ONBWaitingForDataSocketToStartToSTOR:
					ONB_controlState = ONBWaitingForPORTReplyToSTOR;
					break;
			}

			NSString *portString = [NSString stringWithFormat:@"%u,%u", port / 256, port % 256];
			NSMutableString *hostString = [NSMutableString stringWithString:[ONB_controlSocket localHost]];
			[hostString replaceOccurrencesOfString:@"."
										withString:@","
										options:0
										range:NSMakeRange(0, [hostString length])];
			
			[self ONB_sendCommand:[NSString stringWithFormat:@"PORT %@,%@", hostString, portString]];
			[self ONB_readReply];
		}
		break;
	}
}

- (void)socket:(ONBSocket *)socket
	didAcceptNewSocket:(ONBSocket *)newSocket
{
	[ONB_dataSocket setDelegate:nil];
	[ONB_dataSocket autorelease];
	ONB_dataSocket = [newSocket retain];
}

- (void)socketSSLHandshakeSucceeded:(ONBSocket *)socket
{
	if (socket == ONB_controlSocket)
	{
		if ([self useImplicitTLS])
		{
			ONB_controlState = ONBWaitingFor220;
			[self ONB_readReply];
		}
		else
		{
			ONB_controlState = ONBWaitingForPBSZReply;
			[self ONB_sendCommand:@"PBSZ 0"];
			[self ONB_readReply];
		}
	}
}

- (void)socket:(ONBSocket *)socket sslHandshakeFailedWithError:(NSError *)error
{
	NSLog(@"Handshake failed with error: %@", error);
	[self ONB_transferFailedWithError:error];
}

- (void)ONB_readLine
{
	NSData *terminator = [@"\r\n" dataUsingEncoding:NSASCIIStringEncoding];
	[ONB_controlSocket readUntilData:terminator timeout:-1.0 userInfo:nil];
}

- (void)ONB_setUserInfo:(NSDictionary *)userInfo
{
	[ONB_userInfo autorelease];
	ONB_userInfo = [userInfo retain];
}

- (void)ONB_transferFailedWithError:(NSError *)error
{
	ONB_controlState = ONBIdle;
	if ([ONB_delegate respondsToSelector:@selector(connection:failedToCompleteTaskWithUserInfo:error:)])
		[ONB_delegate connection:self failedToCompleteTaskWithUserInfo:ONB_userInfo error:error];
}

- (void)ONB_transferSucceededWithReturnInfo:(NSDictionary *)returnInfo
{
	NSDictionary *userInfo = ONB_userInfo;
	if (returnInfo)
	{
		userInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
		[(NSMutableDictionary *)userInfo addEntriesFromDictionary:returnInfo];
	}

	ONB_controlState = ONBIdle;
	if ([ONB_delegate respondsToSelector:@selector(connection:successfullyCompletedTaskWithUserInfo:)])
		[ONB_delegate connection:self successfullyCompletedTaskWithUserInfo:userInfo];
}

- (void)ONB_checkForDownloadData:(NSTimer *)timer
{
	[ONB_dataSocket readAllAvailableDataWithTimeout:-1.0 userInfo:nil];
}

- (void)ONB_handleDownloadData:(NSData *)data lastTime:(BOOL)lastTime
{
	NSData *translatedData = data;
	if ([self useASCIIMode])
	{
		NSData *beforeTranslation = data;

		if (ONB_untranslatedDownloadData)
		{
			NSMutableData *temp = [NSMutableData dataWithCapacity:[data length]+[ONB_untranslatedDownloadData length]];
			[temp appendData:ONB_untranslatedDownloadData];
			[temp appendData:data];
			beforeTranslation = temp;

			[ONB_untranslatedDownloadData release];
			ONB_untranslatedDownloadData = nil;
		}
		
		translatedData = localASCIIModeData(beforeTranslation, &ONB_untranslatedDownloadData, lastTime);
		
		if (ONB_untranslatedDownloadData)
			[ONB_untranslatedDownloadData retain];
	}
	
	ONB_totalDownloaded += [translatedData length];
	double percentComplete = ((double) ONB_totalDownloaded) / ((double) ONB_downloadSize) * 100.0;
	double speed = [ONB_dataSocket receiveSpeed];

	if ([ONB_delegate respondsToSelector:@selector(connection:downloadedData:speed:percentComplete:userInfo:)])
		[ONB_delegate connection:self
						downloadedData:translatedData
						speed:speed
						percentComplete:percentComplete
						userInfo:ONB_userInfo];
}

- (void)ONB_handleUploadData:(NSTimer *)timer
{
	double uploadSpeed = [ONB_dataSocket transferSpeed];
	double percentComplete = ((double) ONB_totalUploaded) / ((double) ONB_uploadSize) * 100.0;
	
	if ([ONB_delegate respondsToSelector:@selector(connection:uploadStatusSpeed:percentComplete:userInfo:)])
		[ONB_delegate connection:self uploadStatusSpeed:uploadSpeed percentComplete:percentComplete userInfo:ONB_userInfo];
	
	// Give a reasonable amount of data each time.
	if (uploadSpeed < 500.0)
		uploadSpeed = 500.0;
	
	// Don't queue too many socket writes at the same time.
	if (ONB_uploadWritesInProgress >= 10)
		return;

	// Try to keep the socket busy with about 4 seconds worth of write requests at a time.	
	if (! ONB_uploadEOF)
	{
		unsigned int bytesToRead = MAX(uploadSpeed * 0.4, 4096);
		NSData *data = [ONB_delegate provideUploadDataForConnection:self length:bytesToRead userInfo:ONB_userInfo];
		
		if (! data)
			ONB_uploadEOF = YES;
		
		NSData *translatedData = data ? data : [NSData data];
		if ([self useASCIIMode])
		{
			NSData *beforeTranslation = data;
			
			if (ONB_untranslatedUploadData)
			{
				NSMutableData *temp = [NSMutableData dataWithCapacity:[data length]+[ONB_untranslatedUploadData length]];
				[temp appendData:ONB_untranslatedUploadData];
				[temp appendData:data];
				beforeTranslation = temp;
				
				[ONB_untranslatedUploadData release];
				ONB_untranslatedUploadData = nil;
			}
			
			translatedData = networkASCIIModeData(beforeTranslation, &ONB_untranslatedUploadData, ONB_uploadEOF);
		
			if (ONB_untranslatedUploadData)
				[ONB_untranslatedUploadData retain];
		}
		
		unsigned int translatedLength = [translatedData length];
		if (translatedLength)
		{
			ONB_uploadWritesInProgress++;
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:translatedLength]
																forKey:@"dataLength"];

			[ONB_dataSocket writeData:translatedData timeout:-1.0 userInfo:userInfo];
		}
	}
	
	if (ONB_uploadEOF && (! ONB_uploadWritesInProgress))
	{
		NSLog(@"Done sending data");
		[ONB_uploadTimer invalidate];
		[ONB_uploadTimer autorelease];
		ONB_uploadTimer = nil;
		
		ONB_controlState = ONBWaitingForSTORReply;
		[self ONB_readReply];

		[ONB_dataSocket setDelegate:nil];
		[ONB_dataSocket release];
		ONB_dataSocket = nil;
	}
}

@end