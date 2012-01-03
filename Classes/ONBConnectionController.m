//
//  ONBConnectionController.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2005-04-21.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBConnectionController.h"
#import "ONBQueue.h"
#import "ONBDaughterController.h"
#import "ONBBookmark.h"
#import "ONBChangeDirectoryQueueItem.h"
#import "ONBCurrentPathQueueItem.h"
#import "ONBListQueueItem.h"
#import "ONBUploadFileQueueItem.h"
#import "ONBUploadDirectoryQueueItem.h"
#import "ONBFileListing.h"
#import "ONBDownloadFileQueueItem.h"
#import "ONBDownloadDirectoryQueueItem.h"
#import "ONBRemoveFileQueueItem.h"
#import "ONBRemoveDirectoryQueueItem.h"
#import "ONBCreateDirectoryQueueItem.h"
#import "ONBRenameQueueItem.h"
#import "ONBConsoleController.h"
#import "ONBFileMonitor.h"

@implementation ONBConnectionController

- (id)init
{
	return [self initWithBookmark:nil];
}

- (id)initWithBookmark:(ONBBookmark *)bookmark;
{
	if (! (self = [super init]))
		return nil;
	
	ONB_windowControllers = [[NSMutableDictionary alloc] initWithCapacity:1];
	ONB_daughterControllers = [[NSMutableDictionary alloc] initWithCapacity:1];
	ONB_currentPaths = [[NSMutableDictionary alloc] initWithCapacity:1];
	
	ONB_editItems = [[NSMutableArray alloc] init];
	ONB_editItemMonitor = [[ONBFileMonitor alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(fileChangeNotification:)
												name:nil
												object:ONB_editItemMonitor];

	ONB_bookmark = [bookmark copy];
	ONB_queue = [[ONBQueue alloc] initWithOwner:self bookmark:[self bookmark]];
	
	ONB_firstPath = nil;
	
	// Observe the currently running queue item of our queue so that we can update the run/pause
	// queue button whenever the running item changes.  Also observer changes in the list of
	// main queue items so we can disable the button when there are no queue items left.
	
	// We also want to observe the currently running queue item so that we can tell our daughter
	// controllers whether or not to animate their progress bars.
	[[self queue] addObserver:self
					forKeyPath:@"willContinueRunningMainQueue"
					options:0
					context:nil];
	
	[[self queue] addObserver:self
					forKeyPath:@"mainQueueItems"
					options:0
					context:nil];

	[[self queue] addObserver:self
					forKeyPath:@"currentlyRunningQueueItem"
					options:0
					context:nil];
	
	[[self queue] addObserver:self
					forKeyPath:@"currentlyRunningQueueItem.progress"
					options:0
					context:nil];

	[[self queue] addObserver:self
					forKeyPath:@"connectionStatus"
					options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
					context:nil];

	// Set up the console window controller.
	ONB_consoleWindowController = [[NSWindowController alloc] initWithWindowNibName:@"ConsoleWindow"];
	ONB_consoleController = [[ONB_consoleWindowController window] delegate];

	NSString *user = [bookmark user];
	if (! user)
		user = @"anonymous";
	
	NSString *format = NSLocalizedString(@"Console: %@@%@", @"");
	NSString *title = [NSString stringWithFormat:format,
									user,
									[bookmark host]];
	[ONB_consoleController setWindowTitle:title];

	return self;
}

- (void)dealloc
{
	[[self queue] removeObserver:self forKeyPath:@"willContinueRunningMainQueue"];
	[[self queue] removeObserver:self forKeyPath:@"mainQueueItems"];
	[[self queue] removeObserver:self forKeyPath:@"currentlyRunningQueueItem"];
	[[self queue] removeObserver:self forKeyPath:@"currentlyRunningQueueItem.progress"];
	[[self queue] removeObserver:self forKeyPath:@"connectionStatus"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[ONB_editItems release];
	[ONB_editItemMonitor release];
	
	[ONB_windowControllers autorelease];
	[ONB_bookmark autorelease];
	[ONB_queue autorelease];
	
	[self setIdentifier:nil];

	[super dealloc];
}

- (ONBBookmark *)bookmark
{
	return ONB_bookmark;
}

- (void)showConsoleWindow
{
	[ONB_consoleWindowController showWindow:self];
}

- (void)connectAndOpenWindow
{
	NSArray *existingWindowControllers = [self windowControllers];
	if ([existingWindowControllers count])
	{
		NSEnumerator *windowControllerEnumerator = [existingWindowControllers objectEnumerator];
		NSWindowController *currentWindowController;
		
		while (currentWindowController = [windowControllerEnumerator nextObject])
			[currentWindowController showWindow:self];
		
		return;
	}
	
	ONB_selfInitiatedDisconnect = NO;

	ONBBookmark *bookmark = [self bookmark];
	
	NSNumber *identifier = [self ONB_freeWindowIdentifer];
	
	NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"ConnectionWindow"];
	ONBDaughterController *daughterController = [[windowController window] delegate];

	[self setWindowController:windowController forIdentifier:identifier];
	[self setDaughterController:daughterController forIdentifier:identifier];
	
	[daughterController setController:self];
	[daughterController setIdentifier:identifier];
	
	NSString *user = [bookmark user];
	if (! user)
		user = @"anonymous";
	
	NSString *format = NSLocalizedString(@"%@@%@", @"");
	NSString *title = [NSString stringWithFormat:format,
									user,
									[bookmark host]];
	[daughterController setWindowTitle:title];
	
	BOOL running = ([[self queue] currentlyRunningQueueItem]) ? YES : NO;
	[daughterController setTransferInProgress:running];
	
	[windowController showWindow:self];
	[windowController release];
	
	// The code below to switch to the initial path for the bookmark will work
	// fine the first time, since we start out where the server starts us out.
	// However, if the initial path is a relative (instead of absolute) path, then
	// the second time it will not, unless we capture where the server starts
	// us out so that we can create an absolute initial path.  The line below
	// initiates this process.
	if (! ONB_firstPath)
		[self getCurrentPathForIdentifier:[NSNumber numberWithInt:-1]];
	
	NSString *initialPath = [bookmark initialPath];
	if (initialPath && (! [initialPath isEqualToString:@""]))
	{
		if (ONB_firstPath)
			initialPath = [ONB_firstPath stringByAppendingPathComponent:initialPath];

		[self changeDirectoryTo:initialPath identifier:identifier];
	}
	else if (ONB_firstPath && (! [ONB_firstPath isEqualToString:@""]))
			[self changeDirectoryTo:ONB_firstPath identifier:identifier];
	else
	{
		[self getCurrentPathForIdentifier:identifier];
		[self refreshListingsForIdentifier:identifier];
	}
}

- (void)disconnectAndCloseWindows
{
	// The user can call this method and this method is automatically called when
	// we detect that the queue has been disconnected, so this method will be called
	// twice when the user calls it, since it disconnects the queue and is thus called
	// again.  We prevent this by indicating to the code that detects when the queue has
	// been disconnected that we initiated the disconnection.
	ONB_selfInitiatedDisconnect = YES;

	ONBQueue *queue = [self queue];
	[queue disconnect];
	[queue clearControlQueue];
	
	[ONB_firstPath release];
	ONB_firstPath = nil;
	
	NSEnumerator *windowControllerEnumerator = [[self windowControllers] objectEnumerator];
	NSWindowController *windowController;
	
	while (windowController = [windowControllerEnumerator nextObject])
		[[windowController window] performClose:self];

	NSString *disconnectedString = NSLocalizedString(@"Disconnected", @"");
	NSString *appendString = [NSString stringWithFormat:@"\n----------------- %@ -----------------\n\n\n\n\n\n",
														disconnectedString];
	NSColor *color = [NSColor redColor];
	NSFont *font = [NSFont fontWithName:@"Monaco" size:10.0];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,
												NSFontAttributeName,
												color,
												NSForegroundColorAttributeName,
												nil];
	NSAttributedString *text = [[[NSAttributedString alloc] initWithString:appendString
																attributes:attributes] autorelease];
	[ONB_consoleController appendText:text];
}

- (void)changeDirectoryTo:(NSString *)directory identifier:(NSNumber *)identifier
{
	ONBDaughterController *daughterController = [self daughterControllerWithIdentifier:identifier];
	[daughterController setFileListings:[NSArray array]];
	
	NSString *currentPath = [self currentPathForWindowWithIdentifier:identifier];
	if (! currentPath)
		currentPath = @"";
	
	NSString *newPath;
	
	if ([directory isAbsolutePath])
		newPath = directory;
	else
		newPath = [currentPath stringByAppendingPathComponent:directory];
	
	ONBChangeDirectoryQueueItem *changeDirectoryItem = [[ONBChangeDirectoryQueueItem alloc] init];
	[changeDirectoryItem setDirectory:newPath];

	ONBQueue *queue = [self queue];
	unsigned int index = [[queue controlQueueItems] count];
	[queue insertObject:changeDirectoryItem inControlQueueItemsAtIndex:index];

	[changeDirectoryItem release];
	
	[self getCurrentPathForIdentifier:identifier];
	[self refreshListingsForIdentifier:identifier];
}

- (void)getCurrentPathForIdentifier:(NSNumber *)identifier
{
	ONBCurrentPathQueueItem *currentPathItem = [[ONBCurrentPathQueueItem alloc] init];
	[currentPathItem setContextInfo:[NSDictionary dictionaryWithObject:identifier forKey:@"identifier"]];

	ONBQueue *queue = [self queue];
	unsigned int index = [[queue controlQueueItems] count];
	[queue insertObject:currentPathItem inControlQueueItemsAtIndex:index];
	
	[currentPathItem release];
}

- (ONBQueue *)queue
{
	return ONB_queue;
}

// Since we currently support only one window, just return 1.
- (NSNumber *)ONB_freeWindowIdentifer
{
	return [NSNumber numberWithUnsignedInt:1];
}

- (NSWindowController *)windowControllerWithIdentifier:(NSNumber *)identifier
{
	return [ONB_windowControllers objectForKey:identifier];
}

- (ONBDaughterController *)daughterControllerWithIdentifier:(NSNumber *)identifier
{
	return [ONB_daughterControllers objectForKey:identifier];
}

- (NSString *)currentPathForWindowWithIdentifier:(NSNumber *)identifier
{
	return [ONB_currentPaths objectForKey:identifier];
}

- (void)setWindowController:(NSWindowController *)controller forIdentifier:(NSNumber *)identifier
{
	[ONB_windowControllers setObject:controller forKey:identifier];
}

- (void)setDaughterController:(ONBDaughterController *)controller forIdentifier:(NSNumber *)identifier
{
	[ONB_daughterControllers setObject:controller forKey:identifier];
}

- (void)setCurrentPath:(NSString *)currentPath forWindowWithIdentifier:(NSNumber *)identifier
{
	[ONB_currentPaths setObject:currentPath forKey:identifier];

	ONBBookmark *bookmark = [self bookmark];
	ONBDaughterController *daughterController = [self daughterControllerWithIdentifier:identifier];
	NSString *user = [bookmark user];
	if (! user)
		user = @"anonymous";
	NSString *title = [NSString stringWithFormat:@"%@@%@:%@",
									user,
									[bookmark host],
									currentPath];
	[daughterController setWindowTitle:title];
}

- (void)queueItem:(ONBQueueItem *)queueItem succeededWithInfo:(NSDictionary *)info
{
	NSNumber *identifier = [[queueItem contextInfo] objectForKey:@"identifier"];
	BOOL editItem = [[[queueItem contextInfo] objectForKey:@"editItem"] boolValue];
	NSArray *fileListings = [info objectForKey:@"directoryListing"];
	NSString *currentPath = [info objectForKey:@"currentPath"];
	
	if (currentPath)
	{
		if ([identifier isEqualToNumber:[NSNumber numberWithInt:-1]])
			ONB_firstPath = [currentPath copy];
		else
			[self setCurrentPath:currentPath forWindowWithIdentifier:identifier];
	}
	
	if (fileListings)
	{
		// Add a ".." listing.
		ONBFileListing *parentDirectory = [[[ONBFileListing alloc] initWithName:@".."
																			owner:nil
																			group:nil
																			permissionsMode:0
																			lastModified:nil
																			type:ONBDirectory
																			size:nil
																			isSymbolicLink:NO
																			linkedFile:nil] autorelease];

		NSMutableArray *mutableListings = [NSMutableArray arrayWithArray:fileListings];
		[mutableListings insertObject:parentDirectory atIndex:0];
	
		ONBDaughterController *controller = [self daughterControllerWithIdentifier:identifier];
		[controller setFileListings:mutableListings];
	}
	
	if (editItem)
	{
		ONBDownloadFileQueueItem *downloadItem = (ONBDownloadFileQueueItem *)queueItem;
		NSString *localDirectory = [downloadItem localDirectory];
		NSString *localFile = [downloadItem localFile];
		NSString *remoteDirectory = [downloadItem remoteDirectory];
		NSString *remoteFile = [downloadItem remoteFile];
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:localDirectory,
																			@"localDirectory",
																			localFile,
																			@"localFile",
																			remoteDirectory,
																			@"remoteDirectory",
																			remoteFile,
																			@"remoteFile",
																			nil];
		
		[ONB_editItems addObject:userInfo];

		id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
		NSString *externalEditor = [preferences valueForKey:@"externalEditor"];
		NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
		
		if (! [sharedWorkspace fullPathForApplication:externalEditor])
		{
			NSString *informativeText = NSLocalizedString(@"Please make sure that you have typed its name correctly in the OneButton FTP preferences and that it is installed in the proper place for applications.", @"");
			NSString *messageFormat = NSLocalizedString(@"Could not find editor %@.", @"");
		
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert setMessageText:[NSString stringWithFormat:messageFormat, externalEditor]];
			[alert setInformativeText:informativeText];
			[alert addButtonWithTitle:@"OK"];
			[alert setAlertStyle:NSInformationalAlertStyle];
			[alert runModal];
		}
		
		NSString *fullPath = [localDirectory stringByAppendingPathComponent:localFile];
		[ONB_editItemMonitor monitorFileAtPath:fullPath userInfo:userInfo];
		[sharedWorkspace openFile:fullPath withApplication:externalEditor];
	}
}

- (void)queueItem:(ONBQueueItem *)queueItem failedWithError:(NSError *)error
{
	NSLog(@"%@ failed with error: %@", queueItem, error);
}

- (void)queue:(ONBQueue *)queue receivedCommunicationFromServer:(NSString *)communication
{
	NSString *appendString = [NSString stringWithFormat:@"\n%@", communication];
	NSColor *color = [NSColor blueColor];
	NSFont *font = [NSFont fontWithName:@"Monaco" size:10.0];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,
												NSFontAttributeName,
												color,
												NSForegroundColorAttributeName,
												nil];
	NSAttributedString *text = [[[NSAttributedString alloc] initWithString:appendString
																attributes:attributes] autorelease];
	[ONB_consoleController appendText:text];
}

- (void)queue:(ONBQueue *)queue sentCommunicationToServer:(NSString *)communication
{
	NSString *appendString = [NSString stringWithFormat:@"\n%@", communication];
	NSColor *color = [NSColor greenColor];
	NSFont *font = [NSFont fontWithName:@"Monaco" size:10.0];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,
												NSFontAttributeName,
												color,
												NSForegroundColorAttributeName,
												nil];
	NSAttributedString *text = [[[NSAttributedString alloc] initWithString:appendString
																attributes:attributes] autorelease];
	[ONB_consoleController appendText:text];
}

- (void)fileNames:(NSArray *)fileNames
		droppedOnRemoteSubdirectory:(NSString *)subdirectory
		identifier:(NSNumber *)identifier
{
	[self addLocalFiles:fileNames
			toQueueAtIndex:[[[self queue] mainQueueItems] count]
			remoteSubdirectory:subdirectory
			identifier:identifier];
	
	id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
	if ([[preferences valueForKey:@"startQueueImmediatelyOnFileAction"] boolValue])
		[[self queue] runQueue];
}

- (void)addLocalFiles:(NSArray *)fileNames
		toQueueAtIndex:(unsigned int)index
		remoteSubdirectory:(NSString *)subdirectory
		identifier:(NSNumber *)identifier
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *destination = [self currentPathForWindowWithIdentifier:identifier];
	destination = [destination stringByAppendingPathComponent:subdirectory];
	
	NSEnumerator *fileNameEnumerator = [fileNames objectEnumerator];
	NSString *currentFileName;
	NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:[fileNames count]];
		
	while (currentFileName = [fileNameEnumerator nextObject])
	{
		// Check to see if we can read the file
		if (! [fileManager isReadableFileAtPath:currentFileName])
			continue;
	
		// Get file attributes
		NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:currentFileName traverseLink:YES];
		NSString *fileType = [fileAttributes objectForKey:NSFileType];
		if ([fileType isEqualToString:NSFileTypeRegular])
		{			
			ONBUploadFileQueueItem *queueItem = [[ONBUploadFileQueueItem alloc] init];
			[queueItem setLocalDirectory:[currentFileName stringByDeletingLastPathComponent]];
			[queueItem setLocalFile:[currentFileName lastPathComponent]];
			[queueItem setRemoteDirectory:destination];
			[queueItem setRemoteFile:[currentFileName lastPathComponent]];

			[itemsArray addObject:queueItem];
			
			[queueItem release];
		}

		else if ([fileType isEqualToString:NSFileTypeDirectory])
		{
			ONBUploadDirectoryQueueItem *queueItem;
			queueItem = [[ONBUploadDirectoryQueueItem alloc] init];
			NSString *lastComponent = [currentFileName lastPathComponent];
			NSString *remoteDirectory = destination;
			remoteDirectory = [remoteDirectory stringByAppendingPathComponent:lastComponent];
				
			[queueItem setLocalDirectory:currentFileName];
			[queueItem setRemoteDirectory:remoteDirectory];
				
			[itemsArray addObject:queueItem];
				
			[queueItem release];
		}
	}

	[[self queue] insertObjects:itemsArray inMainQueueItemsAtIndex:index];
}

- (void)fileNames:(NSArray *)fileNames
		droppedOnQueueViewAtIndex:(unsigned int)index
		identifier:(NSNumber *)identifier
{
	[self addLocalFiles:fileNames toQueueAtIndex:index remoteSubdirectory:@"" identifier:identifier];
}

- (void)editFilesForRemoteListings:(NSArray *)listings
						identifier:(NSNumber *)identifier
{
	NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:[listings count]];
	NSEnumerator *listingEnumerator = [listings objectEnumerator];
	ONBFileListing *listing;
	
	while (listing = [listingEnumerator nextObject])
	{
		// Find an unused temporary filename
		NSString *name = [listing name];
		NSString *temporaryFileTemplate = [NSString stringWithFormat:@"%@.XXXXXX", name];
		NSString *tempDirectory = NSTemporaryDirectory();
		NSString *temporaryFilePath = [tempDirectory stringByAppendingPathComponent:temporaryFileTemplate];
		
		NSData *originalData = [temporaryFilePath dataUsingEncoding:NSASCIIStringEncoding];
		NSMutableData *mutableData = [NSMutableData dataWithData:originalData];
		
		// Add a null byte the end of the string
		[mutableData setLength:[originalData length]+1];
		
		char *template = [mutableData mutableBytes];
		int ret = mkstemp(template);
		
		if (ret == -1)
		{
			NSLog(@"Error creating temporary file: %d", errno);
			return;
		}
		
		close(ret);
		
		[mutableData setLength:[originalData length]];
		
		temporaryFilePath = [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
		temporaryFilePath = [temporaryFilePath autorelease];
		
		NSString *temporaryFileName = [temporaryFilePath lastPathComponent];
		
		NSString *currentPath = [self currentPathForWindowWithIdentifier:identifier];
	
		ONBDownloadFileQueueItem *downloadItem = [[[ONBDownloadFileQueueItem alloc] init] autorelease];
		[downloadItem setSize:[[listing size] unsignedIntValue]];
	
		[downloadItem setLocalDirectory:tempDirectory];
		[downloadItem setLocalFile:temporaryFileName];
		[downloadItem setRemoteDirectory:currentPath];
		[downloadItem setRemoteFile:[listing name]];
		
		[downloadItem setContextInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																	forKey:@"editItem"]];
		
		[itemsArray addObject:downloadItem];
	}

	ONBQueue *queue = [self queue];
	[queue insertObjects:itemsArray inControlQueueItemsAtIndex:[[queue controlQueueItems] count]];
	[queue runControlQueue]; 
}

- (void)fileChangeNotification:(NSNotification *)notification
{
	if (! [[notification name] isEqualToString:ONBFileWrittenNotification])
		return;
	
	NSDictionary *userInfo = [notification userInfo];
	NSString *localDirectory = [userInfo objectForKey:@"localDirectory"];
	NSString *localFile = [userInfo objectForKey:@"localFile"];
	NSString *remoteDirectory = [userInfo objectForKey:@"remoteDirectory"];
	NSString *remoteFile = [userInfo objectForKey:@"remoteFile"];
	
	ONBUploadFileQueueItem *queueItem = [[[ONBUploadFileQueueItem alloc] init] autorelease];
	[queueItem setLocalDirectory:localDirectory];
	[queueItem setLocalFile:localFile];
	[queueItem setRemoteFile:remoteFile];
	[queueItem setRemoteDirectory:remoteDirectory];
	
	ONBQueue *queue = [self queue];
	[queue insertObject:queueItem inControlQueueItemsAtIndex:[[queue controlQueueItems] count]];
	[queue runControlQueue];
}

- (void)addRemoteListings:(NSArray *)listings
			toQueueAtIndex:(unsigned int)index
			identifier:(NSNumber *)identifier
{
	NSString *currentPath = [self currentPathForWindowWithIdentifier:identifier];

	NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:[listings count]];
	NSEnumerator *listingEnumerator = [listings objectEnumerator];
	ONBFileListing *currentListing;
	NSString *desktopDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/"];
	
	while (currentListing = [listingEnumerator nextObject])
	{
		if ([currentListing isDirectory])
		{
			NSString *name = [currentListing name];

			// We don't want to let the user download the ".." folder, otherwise unexpected
			// stuff could happen.
			if ([name isEqualToString:@".."])
				continue;

			ONBDownloadDirectoryQueueItem *downloadItem;
			downloadItem = [[ONBDownloadDirectoryQueueItem alloc] init];
			
			[downloadItem setRemoteDirectory:[currentPath stringByAppendingPathComponent:name]];
			[downloadItem setLocalDirectory:[desktopDirectory stringByAppendingPathComponent:name]];
			
			[itemsArray addObject:downloadItem];

			[downloadItem release];
		}
		
		else if ([currentListing isRegularFile])
		{
			ONBDownloadFileQueueItem *downloadItem = [[ONBDownloadFileQueueItem alloc] init];
			[downloadItem setSize:[[currentListing size] unsignedIntValue]];
		
			// Find an unused filename on the desktop
			NSString *downloadName = [currentListing name];
			NSFileManager *fileManager = [NSFileManager defaultManager];
			unsigned int i=1;
			while ([fileManager fileExistsAtPath:[desktopDirectory stringByAppendingPathComponent:downloadName]])
			{
				downloadName = [NSString stringWithFormat:@"%@.%u", [currentListing name], i];
				i++;
			}
		
			[downloadItem setLocalDirectory:desktopDirectory];
			[downloadItem setLocalFile:downloadName];
			[downloadItem setRemoteDirectory:currentPath];
			[downloadItem setRemoteFile:[currentListing name]];
		
			[itemsArray addObject:downloadItem];
		
			[downloadItem release];
		}
	}

	[[self queue] insertObjects:itemsArray inMainQueueItemsAtIndex:index];
}

- (void)addRemoteListings:(NSArray *)listings
			toQueueAtIndex:(unsigned int)index
			localDestination:(NSString *)destination
			identifier:(NSNumber *)identifier
{
	NSString *currentPath = [self currentPathForWindowWithIdentifier:identifier];

	NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:[listings count]];
	NSEnumerator *listingEnumerator = [listings objectEnumerator];
	ONBFileListing *currentListing;
	
	while (currentListing = [listingEnumerator nextObject])
	{
		if ([currentListing isDirectory])
		{
			NSString *name = [currentListing name];

			// We don't want to let the user download the ".." folder, otherwise unexpected
			// stuff could happen.
			if ([name isEqualToString:@".."])
				continue;

			ONBDownloadDirectoryQueueItem *downloadItem;
			downloadItem = [[ONBDownloadDirectoryQueueItem alloc] init];
			
			[downloadItem setRemoteDirectory:[currentPath stringByAppendingPathComponent:name]];
			[downloadItem setLocalDirectory:[destination stringByAppendingPathComponent:name]];
			
			[itemsArray addObject:downloadItem];

			[downloadItem release];
		}
		
		else if ([currentListing isRegularFile])
		{
			ONBDownloadFileQueueItem *downloadItem = [[ONBDownloadFileQueueItem alloc] init];
			[downloadItem setSize:[[currentListing size] unsignedIntValue]];
		
			[downloadItem setLocalDirectory:destination];
			[downloadItem setLocalFile:[currentListing name]];
			[downloadItem setRemoteDirectory:currentPath];
			[downloadItem setRemoteFile:[currentListing name]];
		
			[itemsArray addObject:downloadItem];
		
			[downloadItem release];
		}
	}

	[[self queue] insertObjects:itemsArray inMainQueueItemsAtIndex:index];
}

- (void)remoteListings:(NSArray *)listings
			droppedToLocalPath:(NSString *)path
			identifier:(NSNumber *)identifier
{
	[self addRemoteListings:listings
				toQueueAtIndex:[[[self queue] mainQueueItems] count]
				localDestination:path
				identifier:identifier];

	id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
	if ([[preferences valueForKey:@"startQueueImmediatelyOnFileAction"] boolValue])
		[[self queue] runQueue];
}

- (void)addRemoteListingsToEndOfQueue:(NSArray *)listings
			identifier:(NSNumber *)identifier
{
	[self addRemoteListings:listings
			toQueueAtIndex:[[[self queue] mainQueueItems] count]
			identifier:identifier];
}

- (void)deleteRemoteListings:(NSArray *)listings
			identifier:(NSNumber *)identifier
{
	NSString *currentPath = [self currentPathForWindowWithIdentifier:identifier];

	NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:[listings count]];
	NSEnumerator *listingEnumerator = [listings objectEnumerator];
	ONBFileListing *currentListing;
	
	while (currentListing = [listingEnumerator nextObject])
	{
		ONBQueueItem *removeItem = nil;
		NSString *fullPath = [currentPath stringByAppendingPathComponent:[currentListing name]];

		if ([currentListing isRegularFile])
		{
			removeItem = [[ONBRemoveFileQueueItem alloc] init];
			[(ONBRemoveFileQueueItem *)removeItem setFile:fullPath];
		}
		else if ([currentListing isDirectory])
		{
			removeItem = [[ONBRemoveDirectoryQueueItem alloc] init];
			[(ONBRemoveDirectoryQueueItem *)removeItem setDirectory:fullPath];
		}
		
		if (removeItem)
		{
			[itemsArray addObject:removeItem];
			[removeItem release];
		}
	}
	
	[[self queue] insertObjects:itemsArray inControlQueueItemsAtIndex:[[[self queue] controlQueueItems] count]];
	
	[self refreshListingsForIdentifier:identifier];
}

- (void)refreshListingsForIdentifier:(NSNumber *)identifier
{
	ONBDaughterController *daughterController = [self daughterControllerWithIdentifier:identifier];
	[daughterController setFileListings:[NSArray array]];

	ONBQueue *queue = [self queue];
	
	ONBListQueueItem *listItem = [[ONBListQueueItem alloc] init];
	[listItem setContextInfo:[NSDictionary dictionaryWithObject:identifier forKey:@"identifier"]];
	[queue insertObject:listItem inControlQueueItemsAtIndex:[[queue controlQueueItems] count]];
	[listItem release];

	[queue runControlQueue];
}

- (void)createNewDirectory:(NSString *)directory identifier:(NSNumber *)identifier
{
	ONBCreateDirectoryQueueItem *createItem = [[ONBCreateDirectoryQueueItem alloc] init];
	[createItem setDirectory:directory];
	
	ONBQueue *queue = [self queue];
	[queue insertObject:createItem inControlQueueItemsAtIndex:[[queue controlQueueItems] count]];
	
	[self refreshListingsForIdentifier:identifier];
}

- (void)renameFile:(NSString *)name to:(NSString *)newName identifier:(NSNumber *)identifier
{
	ONBRenameQueueItem *renameItem = [[ONBRenameQueueItem alloc] init];
	[renameItem setFile:name];
	[renameItem setNewName:newName];

	ONBQueue *queue = [self queue];
	[queue insertObject:renameItem inControlQueueItemsAtIndex:[[queue controlQueueItems] count]];
	[renameItem release];
	
	[self refreshListingsForIdentifier:identifier];
}

- (BOOL)canRunPauseQueue
{
	return ([[[self queue] mainQueueItems] count] ? YES : NO);
}

- (NSImage *)runPauseQueueImage
{
	ONBQueue *queue = [self queue];

	if ([[queue mainQueueItems] count] && [queue willContinueRunningMainQueue])
		return scaleImageToFitButton(@"PauseQueue");
	else
		return scaleImageToFitButton(@"RunQueue");
}

- (void)removeQueueItemsAtIndexes:(NSIndexSet *)indexes identifier:(NSNumber *)identifier
{
	[[self queue] removeObjectsFromMainQueueItemsAtIndexes:indexes];
}

- (void)runPauseQueueForIdentifier:(NSNumber *)identifier
{
	ONBQueue *queue = [self queue];

	if ([[queue mainQueueItems] count] && [queue willContinueRunningMainQueue])
		[queue pauseQueue];
	else
		[queue runQueue];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
						ofObject:(id)object
						change:(NSDictionary *)change
						context:(void *)context
{
	if ([object isEqual:[self queue]] && [keyPath isEqualToString:@"willContinueRunningMainQueue"])
	{
		[self willChangeValueForKey:@"runPauseQueueImage"];
		[self didChangeValueForKey:@"runPauseQueueImage"];
	}

	else if ([object isEqual:[self queue]] && [keyPath isEqualToString:@"mainQueueItems"])
	{
		[self willChangeValueForKey:@"runPauseQueueImage"];
		[self didChangeValueForKey:@"runPauseQueueImage"];

		[self willChangeValueForKey:@"canRunPauseQueue"];
		[self didChangeValueForKey:@"canRunPauseQueue"];
	}

	else if ([object isEqual:[self queue]] && [keyPath isEqualToString:@"currentlyRunningQueueItem"])
	{
		// Tell all the daughter controllers whether or not something is in progress
		// so they can decide whether or not to animate their progress bars.  We do
		// it this way instead of bindings because daughter windows come and go, and
		// the application crashes if a daughter window is deallocated while its progress
		// still has bindings (the next time currentlyRunningQueueItem is updated).
		NSEnumerator *daughterControllerEnumerator = [self daughterControllerEnumerator];
		ONBDaughterController *daughterController;
		
		ONBQueueItem *currentlyRunningQueueItem = [[self queue] currentlyRunningQueueItem];
		BOOL running = (currentlyRunningQueueItem) ? YES : NO;
		double progress = (currentlyRunningQueueItem) ? [currentlyRunningQueueItem progress] : 0.0;
		
		while (daughterController = [daughterControllerEnumerator nextObject])
		{
			[daughterController setTransferInProgress:running];
			[daughterController setTransferProgress:progress];
		}
	}

	else if ([object isEqual:[self queue]] && [keyPath isEqualToString:@"currentlyRunningQueueItem.progress"])
	{
		NSEnumerator *daughterControllerEnumerator = [self daughterControllerEnumerator];
		ONBDaughterController *daughterController;

		ONBQueueItem *currentlyRunningQueueItem = [[self queue] currentlyRunningQueueItem];
		double progress = (currentlyRunningQueueItem) ? [currentlyRunningQueueItem progress] : 0.0;
		
		while (daughterController = [daughterControllerEnumerator nextObject])
			[daughterController setTransferProgress:progress];
	}

	else if ([object isEqual:[self queue]] && [keyPath isEqualToString:@"connectionStatus"])
	{
		unsigned int oldSetting = [[change objectForKey:NSKeyValueChangeOldKey] unsignedIntValue];
		unsigned int newSetting = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntValue];
		
		if (oldSetting && (! newSetting))
		{
			if (ONB_selfInitiatedDisconnect)
				ONB_selfInitiatedDisconnect = NO;
			
			else
				[self disconnectAndCloseWindows];
		}
	}
}

- (NSArray *)windowControllers
{
	return [ONB_windowControllers allValues];
}

- (NSEnumerator *)daughterControllerEnumerator
{
	return [ONB_daughterControllers objectEnumerator];
}

- (void)windowClosingForIdentifier:(NSNumber *)identifier
{
	[self destroyIdentifier:identifier];
	
	// Disconnect if this was the last window and the user has set that preference.
	if (! [[self windowControllers] count])
	{
		id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
		if ([[preferences valueForKey:@"disconnectWhenLastWindowClosed"] boolValue])
			[self disconnectAndCloseWindows];
	}
}

- (void)destroyIdentifier:(NSNumber *)identifier
{
	[ONB_daughterControllers removeObjectForKey:identifier];
	[ONB_windowControllers removeObjectForKey:identifier];
	[ONB_currentPaths removeObjectForKey:identifier];
}

- (NSNumber *)identifier
{
	return ONB_identifier;
}

- (void)setIdentifier:(NSNumber *)identifier
{
	[ONB_identifier autorelease];
	ONB_identifier = [identifier copy];
}

- (void)deleteTemporaryFiles
{
	// Go through and delete any temporary files created for editing.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *editItemEnumerator = [ONB_editItems objectEnumerator];
	NSDictionary *currentEditItem;
	
	while (currentEditItem = [editItemEnumerator nextObject])
	{
		NSString *localDirectory = [currentEditItem objectForKey:@"localDirectory"];
		NSString *localFile = [currentEditItem objectForKey:@"localFile"];
		NSString *fullPath = [localDirectory stringByAppendingPathComponent:localFile];
		
		[fileManager removeFileAtPath:fullPath handler:nil];
	}
}

@end