//
//  ONBApplicationController.m
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-10-31.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import "ONBApplicationController.h"
#import "ONBFileSizeTransformer.h"
#import "ONBConnectionController.h"
#import "ONBQueue.h"
#import "ONBConnectionManagerCell.h"
#import "ONBDownloadFileQueueItem.h"
#import "ONBUploadFileQueueItem.h"
#import "ONBDownloadDirectoryQueueItem.h"
#import "ONBUploadDirectoryQueueItem.h"
#include <Security/Security.h>

#define ONBConnectionManagerToolbarIdentifier		@"ONBConnectionManagerToolbarIdentifier"
#define	ONBNewConnectionToolbarItemIdentifier		@"ONBNewConnectionToolbarItemIdentifier"
#define ONBConnectToolbarItemIdentifier				@"ONBConnectToolbarItemIdentifier"
#define ONBEditToolbarItemIdentifier				@"ONBEditToolbarItemIdentifier"
#define ONBDeleteToolbarItemIdentifier				@"ONBDeleteToolbarItemIdentifier"
#define ONBConsoleToolbarItemIdentifier				@"ONBConsoleToolbarItemIdentifier"

// Escape a string for use in a URL
NSString *urlEscapedString(NSString *string)
{
	NSString *returnString;
	returnString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																		(CFStringRef) string,
																		NULL,
																		NULL,
																		kCFStringEncodingUTF8);
	return [returnString autorelease];
}

// Private version of the public method below.  This one does the same thing, but
// gives the option of getting a reference for the keychain item - something which
// is so Carbon for my tastes that I don't want to expose the Cocoa code to it.
// If you pass anything besides NULL for itemRef and a non-nil NSString is returned
// then you will need to call CFRelease on itemRef.
NSString *ONB_passwordFromKeychain(NSString *host,
									NSString *user,
									NSNumber *port,
									SecKeychainItemRef *itemRef)
{
	// We can only look up a password from the keychain if a host
	// and a username are specified.
	if (! (host && user && [host length] && [user length]))
		return nil;

	UInt16 portInt = port ? [port intValue] : 21;

	const char *hostCString = [host UTF8String];
	UInt32 hostCStringLength = strlen(hostCString);

	const char *userCString = [user UTF8String];
	UInt32 userCStringLength = strlen(userCString);

	OSStatus result;
	UInt32 passwordLength;
	void *passwordData;

	result = SecKeychainFindInternetPassword(NULL,
											hostCStringLength,
											hostCString,
											0,
											NULL,
											userCStringLength,
											userCString,
											0,
											NULL,
											portInt,
											kSecProtocolTypeFTP,
											kSecAuthenticationTypeDefault,
											&passwordLength,
											&passwordData,
											itemRef);

	if (result == noErr)
	{
		NSString *password = [[NSString alloc] initWithBytes:passwordData
														length:passwordLength
														encoding:NSUTF8StringEncoding];
		SecKeychainItemFreeContent(NULL, passwordData);
		
		return [password autorelease];
	}
	
	return nil;
}

// Retrieve the FTP password for the given host, user, port pair from the keychain.
// If port is nil, 21 will be used.  If there is an error or the password is not
// on the keychain, nil will be returned.
NSString *passwordFromKeychain(NSString *host, NSString *user, NSNumber *port)
{
	return ONB_passwordFromKeychain(host, user, port, NULL);
}

// If a password for the given host, user, port pair already exists on the keychain,
// it will be changed.  Otherwise it will be added.  If port is nil, 21 will be used.
void addOrChangeKeychainPassword(NSString *host, NSString *user, NSNumber *port, NSString *password)
{
	// We can't do this if there's no password
	if (! (password && [password length]))
		return;

	SecKeychainItemRef itemRef = nil;
	const char *passwordCString = [password UTF8String];
	UInt32 passwordCStringLength = strlen(passwordCString);
	
	NSString *currentPassword;

	if (currentPassword = ONB_passwordFromKeychain(host, user, port, &itemRef))
	{
		// The item already exists in the keychain - modify it if we need to
		if (! [currentPassword isEqualToString:password])
			SecKeychainItemModifyAttributesAndData(itemRef,
													NULL,
													passwordCStringLength,
													passwordCString);
		CFRelease(itemRef);
		return;
	}
	
	// The item doesn't exist, so we will add it, but only if we've actually been
	// supplied a host and user
	if (! (host && user && [host length] && [user length]))
		return;

	UInt16 portInt = port ? [port intValue] : 21;

	const char *hostCString = [host UTF8String];
	UInt32 hostCStringLength = strlen(hostCString);

	const char *userCString = [user UTF8String];
	UInt32 userCStringLength = strlen(userCString);
	
	SecKeychainAddInternetPassword(NULL,
									hostCStringLength,
									hostCString,
									0,
									NULL,
									userCStringLength,
									userCString,
									0,
									NULL,
									portInt,
									kSecProtocolTypeFTP,
									kSecAuthenticationTypeDefault,
									passwordCStringLength,
									passwordCString,
									NULL);
}

@implementation ONBApplicationController

+ (void)initialize
{
	// Set up the pretty file size value transformer.
	ONBFileSizeTransformer *transformer = [[ONBFileSizeTransformer alloc] init];
	[NSValueTransformer setValueTransformer:transformer	forName:@"ONBFileSizeTransformer"];
	[transformer release];
	
	// Set up the initial values for the user defaults controller.
	NSNumber *yesNumber = [NSNumber numberWithBool:YES];
	NSNumber *noNumber = [NSNumber numberWithBool:NO];
	
	NSArray *ASCIITypes = [NSArray arrayWithObjects:@"asp", @"bat", @"c", @"cfm", @"cgi", @"conf", @"cpp",
													@"css", @"h", @"htm", @"html", @"java", @"m", @"php",
													@"phps", @"pl", @"py", @"rb", @"rtf", @"sh", @"shtml",
													@"tex", @"txt", @"xml", nil];
	
	NSDictionary *initialValues = [NSDictionary dictionaryWithObjectsAndKeys:noNumber,
																				@"disconnectWhenLastWindowClosed",
																				yesNumber,
																				@"startQueueImmediatelyOnFileAction",
																				noNumber,
																				@"autoASCIIMode",
																				ASCIITypes,
																				@"ASCIITypes",
																				@"TextEdit",
																				@"externalEditor",
																				nil];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValues];
}

- (void)awakeFromNib
{
	// Set up the default new bookmark
	ONBBookmark *newBookmark = [self newBookmark];
	[newBookmark setNickname:@"SourceForge"];
	[newBookmark setHost:@"ftp.sourceforge.net"];
	[newBookmark setPort:[NSNumber numberWithUnsignedInt:21]];

	// Set up the connection manager window's toolbar
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:ONBConnectionManagerToolbarIdentifier];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	
	[toolbar setDelegate:self];
	[connectionManagerWindow setToolbar:toolbar];
	
	[toolbar release];

	// Set up connection manager outline view
	[connectionsOutlineView setTarget:self];
	[connectionsOutlineView setDoubleAction:@selector(connectWithSelectedBookmarks:)];
	
	ONBConnectionManagerCell *cell = [[ONBConnectionManagerCell alloc] init];
	NSEnumerator *columnEnumerator = [[connectionsOutlineView tableColumns] objectEnumerator];
	NSTableColumn *column;
	
	while (column = [columnEnumerator nextObject])
		[column setDataCell:cell];
	
	[cell release];
	
	NSTableColumn *nameColumn = [connectionsOutlineView tableColumnWithIdentifier:@"name"];
	[connectionsOutlineView setOutlineTableColumn:nameColumn];
	
	// Make the font size smaller in the ASCII types table
	NSEnumerator *columnsEnumerator = [[ASCIITypesTable tableColumns] objectEnumerator];
	NSTableColumn *currentColumn;
	
	while (currentColumn = [columnsEnumerator nextObject])
	{
		NSCell *cell = [currentColumn dataCell];
		
		NSFont *oldFont = [cell font];
		NSFont *newFont = [NSFont fontWithName:[oldFont fontName] size:10.0];

		[cell setFont:newFont];
	}

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *hjalpMenu = (NSString *)[userDefaults objectForKey:@"hjalpmenu"];
	
	if ([hjalpMenu intValue])
	{
		NSMenu *mainMenu = [NSApp mainMenu];
		NSMenuItem *helpMenuItem = [[mainMenu itemArray] lastObject];

		UInt16 codePoint[2];
		codePoint[0] = 0xc3a4;
		codePoint[1] = 0;
		NSString *umlautA = [NSString stringWithUTF8String:(const char *)codePoint];
		NSString *title = [NSString stringWithFormat:@"Hj%@%@%@lp!",
									umlautA, umlautA, umlautA];
		[[helpMenuItem submenu] setTitle:title];
	}
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:ONBNewConnectionToolbarItemIdentifier,
										ONBConnectToolbarItemIdentifier,
										ONBEditToolbarItemIdentifier,
										ONBDeleteToolbarItemIdentifier,
										ONBConsoleToolbarItemIdentifier,
										nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:ONBNewConnectionToolbarItemIdentifier,
										ONBConnectToolbarItemIdentifier,
										ONBEditToolbarItemIdentifier,
										ONBDeleteToolbarItemIdentifier,
										ONBConsoleToolbarItemIdentifier,
										nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
			itemForItemIdentifier:(NSString *)identifier
			willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
	
	if ([identifier isEqualToString:ONBNewConnectionToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"New", @"");
		NSString *toolTip = NSLocalizedString(@"Create a new connection", @"");
	
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"NewConnection"]];
		
		[toolbarItem setTarget:newConnectionWindow];
		[toolbarItem setAction:@selector(makeKeyAndOrderFront:)];
	}
	
	else if ([identifier isEqualToString:ONBConnectToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Connect", @"");
		NSString *toolTip = NSLocalizedString(@"Connect to selected bookmark(s)", @"");
	
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"Connect"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(connectWithSelectedBookmarks:)];
	}

	else if ([identifier isEqualToString:ONBEditToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Edit", @"");
		NSString *toolTip = NSLocalizedString(@"Edit selected bookmark", @"");
	
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"EditBookmark"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(editSelectedBookmark:)];
	}

	else if ([identifier isEqualToString:ONBDeleteToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Delete", @"");
		NSString *toolTip = NSLocalizedString(@"Delete selected bookmark(s)", @"");
	
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"RemoveBookmark"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(deleteSelectedConnections:)];
	}

	else if ([identifier isEqualToString:ONBConsoleToolbarItemIdentifier])
	{
		NSString *label = NSLocalizedString(@"Console", @"");
		NSString *toolTip = NSLocalizedString(@"Show console window for selected connection(s)", @"");
	
		[toolbarItem setLabel:label];
		[toolbarItem setPaletteLabel:label];
		
		[toolbarItem setToolTip:toolTip];
		[toolbarItem setImage:[NSImage imageNamed:@"ShowConsole"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(showConsoleForSelectedConnections:)];
	}

	else
		toolbarItem = nil;
	
	return toolbarItem;
}

- (id)init
{
	if (! (self = [super init]))
		return nil;

	ONB_sizeTransformer = [[NSValueTransformer valueTransformerForName:@"ONBFileSizeTransformer"] retain];

	ONB_freeIdentifier = 0;
	ONB_newBookmark = [[ONBBookmark alloc] init];
	
	// Pull existing bookmarks from the user defaults database
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *rememberedBookmarks = [userDefaults arrayForKey:@"bookmarks"];
	if (! rememberedBookmarks)
	{
		ONB_outlineViewChildren = [[NSMutableDictionary alloc] initWithCapacity:1];
		ONB_connectionControllers = [[NSMutableArray alloc] initWithCapacity:1];
	}
	else
	{
		ONB_outlineViewChildren = [[NSMutableDictionary alloc] initWithCapacity:[rememberedBookmarks count]];
		ONB_connectionControllers = [[NSMutableArray alloc] initWithCapacity:[rememberedBookmarks count]];
		NSEnumerator *rememberedBookmarksEnumerator = [rememberedBookmarks objectEnumerator];
		NSDictionary *rememberedBookmark;
		
		while (rememberedBookmark = [rememberedBookmarksEnumerator nextObject])
		{
			if (! [rememberedBookmark isKindOfClass:[NSDictionary class]])
			{
				NSLog(@"Error: Bookmark is not an NSDictionary!");
				continue;
			}
			
			NSNumber *encodingVersion = [rememberedBookmark objectForKey:@"encodingVersion"];
			if (! encodingVersion)
			{
				NSLog(@"Error: No encoding version found for bookmark!");
				continue;
			}
			
			if ([encodingVersion unsignedIntValue] == 1)
			{
				ONBBookmark *bookmark = [[ONBBookmark alloc] init];
				
				NSString *nickname = [rememberedBookmark objectForKey:@"nickname"];
				NSString *host = [rememberedBookmark objectForKey:@"host"];
				NSNumber *port = [rememberedBookmark objectForKey:@"port"];
				NSString *user = [rememberedBookmark objectForKey:@"user"];
				NSString *password = passwordFromKeychain(host, user, port);
				NSNumber *usePassive = [rememberedBookmark objectForKey:@"usePassive"];
				NSNumber *SSLMode = [rememberedBookmark objectForKey:@"SSLMode"];
				NSNumber *useImplicitSSL = [rememberedBookmark objectForKey:@"useImplicitSSL"];
				NSString *initialPath = [rememberedBookmark objectForKey:@"initialPath"];
				
				// If the remembered bookmark doesn't have a key for whether or not to use
				// passive mode, the default is to use it.  The default is to not use SSL.
				if (! usePassive)
					usePassive = [NSNumber numberWithBool:YES];
				
				if (! SSLMode)
				{
					if (useImplicitSSL && [useImplicitSSL boolValue])
						SSLMode = [NSNumber numberWithUnsignedInt:ONBUseImplicitSSL];
					else
						SSLMode = [NSNumber numberWithUnsignedInt:ONBNoSSL];
				}
				
				[bookmark setNickname:nickname];
				[bookmark setHost:host];
				[bookmark setPort:port];
				[bookmark setUser:user];
				[bookmark setPassword:password];
				[bookmark setUsePassive:[usePassive boolValue]];
				[bookmark setSSLMode:SSLMode];
				[bookmark setInitialPath:initialPath];
				[bookmark setRemember:YES];

				ONBConnectionController *controller = [[ONBConnectionController alloc] initWithBookmark:bookmark];
				
				[[controller queue] addObserver:self
										forKeyPath:@"mainQueueItems"
										options:0
										context:controller];

				[[controller queue] addObserver:self
										forKeyPath:@"connectionStatus"
										options:0
										context:controller];

				[[controller queue] addObserver:self
										forKeyPath:@"currentlyRunningQueueItem"
										options:0
										context:controller];
				
				[[controller queue] addObserver:self
										forKeyPath:@"currentlyRunningQueueItem.progress"
										options:0
										context:controller];

				[[controller queue] addObserver:self
										forKeyPath:@"currentlyRunningQueueItem.speed"
										options:0
										context:controller];

				NSNumber *identifier = [NSNumber numberWithUnsignedInt:ONB_freeIdentifier++];
				[controller setIdentifier:identifier];
				[ONB_outlineViewChildren setObject:[NSMutableArray array] forKey:identifier];
				[ONB_connectionControllers addObject:controller];
				[controller release];

				[bookmark release];
			}
			else
			{
				NSLog(@"Error: Unrecognized encoding for bookmark!");
				continue;
			}
		}
	}
	
	return self;
}

- (void)dealloc
{
	[ONB_outlineViewChildren autorelease];
	[ONB_connectionControllers autorelease];
	[ONB_newBookmark autorelease];
	[super dealloc];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	// Work around a bug in Panther that causes the program to crash on quit if more than
	// one file type was dragged to the Finder at the same time while it was running.
	[[NSPasteboard pasteboardWithName:NSDragPboard] declareTypes:nil owner:nil];

	// Write the bookmarks that want to be remembered to the user defaults database
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *connectionControllers = [self connectionControllers];
	NSMutableArray *encodedBookmarks = [NSMutableArray arrayWithCapacity:[connectionControllers count]];
	NSEnumerator *controllerEnumerator = [connectionControllers objectEnumerator];
	ONBConnectionController *currentController;
	
	while (currentController = [controllerEnumerator nextObject])
	{
		[currentController deleteTemporaryFiles];
		ONBBookmark *currentBookmark = [currentController bookmark];

		if (! [currentBookmark remember])
			continue;
			
		NSString *nickname = [currentBookmark nickname];
		NSString *host = [currentBookmark host];
		NSNumber *port = [currentBookmark port];
		NSNumber *anonymous = [NSNumber numberWithBool:[currentBookmark anonymous]];
		NSString *user = [currentBookmark user];
		NSString *password = [currentBookmark password];
		NSNumber *usePassive = [NSNumber numberWithBool:[currentBookmark usePassive]];
		NSNumber *SSLMode = [currentBookmark SSLMode];
		NSString *initialPath = [currentBookmark initialPath];
		
		NSMutableDictionary *encodedBookmark = [NSMutableDictionary dictionaryWithCapacity:5];
		
		if (nickname)
			[encodedBookmark setObject:nickname forKey:@"nickname"];

		if (host)
			[encodedBookmark setObject:host forKey:@"host"];

		if (port)
			[encodedBookmark setObject:port forKey:@"port"];

		if (anonymous)
			[encodedBookmark setObject:anonymous forKey:@"anonymous"];

		if (user)
			[encodedBookmark setObject:user forKey:@"user"];
			
		if (usePassive)
			[encodedBookmark setObject:usePassive forKey:@"usePassive"];
		
		if (SSLMode)
			[encodedBookmark setObject:SSLMode forKey:@"SSLMode"];
		
		if (initialPath)
			[encodedBookmark setObject:initialPath forKey:@"initialPath"];
		
		[encodedBookmark setObject:[NSNumber numberWithUnsignedInt:1] forKey:@"encodingVersion"];
		
		// If this is not an anonymous login, store the password
		if (! [anonymous boolValue])
			addOrChangeKeychainPassword(host, user, port, password);

		[encodedBookmarks addObject:encodedBookmark];
	}
	
	[userDefaults setObject:encodedBookmarks forKey:@"bookmarks"];
}

// This is sent by Cocoa when there are no windows open and the user does something like
// double-click the application in Finder or click the dock icon.  We want to just open a new
// unconnected window for them.
- (BOOL)applicationOpenUntitledFile:(NSApplication *)application
{
	[connectionManagerWindow makeKeyAndOrderFront:self];
	return YES;
}

- (ONBBookmark *)newBookmark
{
	return ONB_newBookmark;
}

- (IBAction)makeNewConnection:(id)sender
{
	// Make any text box lose first responder status so that whatever it is bound
	// to will be updated.  Also close the new connection window.
	[newConnectionWindow makeFirstResponder:newConnectionWindow];
	[newConnectionWindow performClose:self];

	ONBBookmark *newBookmark = [[self newBookmark] copy];
	ONBConnectionController *controller = [[ONBConnectionController alloc] initWithBookmark:newBookmark];
	
	[self willChangeValueForKey:@"connectionControllers"];
	
	[[controller queue] addObserver:self
							forKeyPath:@"mainQueueItems"
							options:0
							context:controller];

	[[controller queue] addObserver:self
							forKeyPath:@"connectionStatus"
							options:0
							context:controller];
	
	[[controller queue] addObserver:self
							forKeyPath:@"currentlyRunningQueueItem"
							options:0
							context:controller];

	[[controller queue] addObserver:self
							forKeyPath:@"currentlyRunningQueueItem.progress"
							options:0
							context:controller];

	[[controller queue] addObserver:self
							forKeyPath:@"currentlyRunningQueueItem.speed"
							options:0
							context:controller];

	NSNumber *identifier = [NSNumber numberWithUnsignedInt:ONB_freeIdentifier++];
	[controller setIdentifier:identifier];
	[ONB_outlineViewChildren setObject:[NSMutableArray array] forKey:identifier];
	[ONB_connectionControllers addObject:controller];
	[connectionsOutlineView reloadData];
	[self didChangeValueForKey:@"connectionControllers"];
	
	[controller connectAndOpenWindow];
	[newBookmark release];
	[controller release];
}

- (NSArray *)connectionControllers
{
	return [NSArray arrayWithArray:ONB_connectionControllers];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
	NSArray *selectedConnections = [self selectedConnections];

	if ([[item itemIdentifier] isEqualToString:ONBConnectToolbarItemIdentifier])
	{
		// If all the selected connections are not connected, enable the button
		// and make it a connect button.  If all the selected connections are
		// connected, enable the button and make it a disconnect button.  If they
		// are mixed, disconnect it.
		
		unsigned int connected = 0;
		unsigned int disconnected = 0;
		NSEnumerator *connectionEnumerator = [selectedConnections objectEnumerator];
		ONBConnectionController *currentConnection;
		
		while (currentConnection = [connectionEnumerator nextObject])
		{
			BOOL isConnected = ([[currentConnection queue] connectionStatus] != 0);

			if (isConnected)
				connected++;
			else
				disconnected++;
		}
		
		BOOL shouldEnable = YES;
		BOOL shouldBeConnectButton = NO;
		
		if ((connected && disconnected) || ((! connected) && (! disconnected)))
		{
			shouldBeConnectButton = YES;
			shouldEnable = NO;
		}
		
		if (disconnected)
			shouldBeConnectButton = YES;
		
		if (shouldBeConnectButton)
		{
			NSString *label = NSLocalizedString(@"Connect", @"");
			NSString *toolTip = NSLocalizedString(@"Connect to selected bookmark(s)", @"");

			[item setLabel:label];
			[item setToolTip:toolTip];
			[item setImage:[NSImage imageNamed:@"Connect"]];
		
			[item setTarget:self];
			[item setAction:@selector(connectWithSelectedBookmarks:)];
		}
		else
		{
			NSString *label = NSLocalizedString(@"Disconnect", @"");
			NSString *toolTip = NSLocalizedString(@"Disconnect from selected bookmark(s)", @"");

			[item setLabel:label];
			[item setToolTip:toolTip];
			[item setImage:[NSImage imageNamed:@"Disconnect"]];
		
			[item setTarget:self];
			[item setAction:@selector(disconnectSelectedBookmarks:)];
		}
		
		return shouldEnable;
	}

	if ([[item itemIdentifier] isEqualToString:ONBEditToolbarItemIdentifier])
	{
		// Only enable the edit button if there is exactly one selected bookmark
		// and it is not currently connected.
		if ([selectedConnections count] == 1)
			if ([[[selectedConnections objectAtIndex:0] queue] connectionStatus] == 0)
				return YES;
		
		return NO;
	}

	if ([[item itemIdentifier] isEqualToString:ONBDeleteToolbarItemIdentifier])
	{
		// Only enable the delete button if there are selected connections
		return ([selectedConnections count]) ? YES : NO;
	}

	if ([[item itemIdentifier] isEqualToString:ONBConsoleToolbarItemIdentifier])
	{
		// Only enable the console button if there are selected connections
		return ([selectedConnections count]) ? YES : NO;
	}
	
	return YES;
}

- (void)outlineViewSelectionIsChanging:(NSNotification *)notification
{
	[self willChangeValueForKey:@"selectedConnections"];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[self didChangeValueForKey:@"selectedConnections"];

	// Re-evaluate whether toolbar items in the connection manager window should
	// be enabled.
	[[connectionManagerWindow toolbar] validateVisibleItems];
}

- (NSArray *)selectedConnections
{
	NSIndexSet *selectedRows = [connectionsOutlineView selectedRowIndexes];
	NSMutableArray *selectedConnections = [NSMutableArray arrayWithCapacity:[selectedRows count]];
	unsigned int currentRow = [selectedRows firstIndex];
	
	while (currentRow != NSNotFound)
	{
		[selectedConnections addObject:[connectionsOutlineView itemAtRow:currentRow]];
		currentRow = [selectedRows indexGreaterThanIndex:currentRow];
	}
	
	return selectedConnections;
}

- (void)connectWithSelectedBookmarks:(id)sender
{
	NSArray *selectedConnections = [self selectedConnections];
	
	if (! [selectedConnections count])
		return;
	
	NSEnumerator *selectedConnectionsEnumerator = [selectedConnections objectEnumerator];
	ONBConnectionController *currentConnection;
	
	while (currentConnection = [selectedConnectionsEnumerator nextObject])
		[currentConnection connectAndOpenWindow];
}

- (void)disconnectSelectedBookmarks:(id)sender
{
	NSArray *selectedConnections = [self selectedConnections];
	
	if (! [selectedConnections count])
		return;
	
	NSEnumerator *selectedConnectionsEnumerator = [selectedConnections objectEnumerator];
	ONBConnectionController *currentConnection;
	
	while (currentConnection = [selectedConnectionsEnumerator nextObject])
		[currentConnection disconnectAndCloseWindows];
}

- (void)deleteSelectedConnections:(id)sender
{
	[self disconnectSelectedBookmarks:sender];
	
	NSArray *selectedConnections = [self selectedConnections];
	NSEnumerator *connectionEnumerator = [selectedConnections objectEnumerator];
	ONBConnectionController *connectionController;
	
	while (connectionController = [connectionEnumerator nextObject])
	{
		[[connectionController queue] removeObserver:self forKeyPath:@"mainQueueItems"];
		[[connectionController queue] removeObserver:self forKeyPath:@"connectionStatus"];
		[[connectionController queue] removeObserver:self forKeyPath:@"currentlyRunningQueueItem"];
		[[connectionController queue] removeObserver:self forKeyPath:@"currentlyRunningQueueItem.progress"];
		[[connectionController queue] removeObserver:self forKeyPath:@"currentlyRunningQueueItem.speed"];
		[ONB_outlineViewChildren removeObjectForKey:[connectionController identifier]];
	}

	[ONB_connectionControllers removeObjectsInArray:selectedConnections];
	[connectionsOutlineView reloadData];
}

- (void)editSelectedBookmark:(id)sender
{
	// Can't edit one if there's already one being edited
	if ([self editBookmark])
	{
		[editBookmarkWindow makeKeyAndOrderFront:self];
		return;
	}

	NSArray *selectedConnections = [self selectedConnections];
	
	if ([selectedConnections count] != 1)
		return;
	
	ONBBookmark *editBookmark = [[selectedConnections objectAtIndex:0] bookmark];
	[self setEditBookmark:editBookmark];
	[editBookmarkWindow makeKeyAndOrderFront:self];
}

// Sent when the edit window is closing.  End the current edit to save changes
// and then set the bookmark currently being edited to nil.
- (void)windowWillClose:(NSNotification *)notification
{
	[editBookmarkWindow makeFirstResponder:editBookmarkWindow];
	[self setEditBookmark:nil];
	
	[connectionsOutlineView reloadData];
}

- (void)showConsoleForSelectedConnections:(id)sender
{
	NSEnumerator *connectionEnumerator = [[self selectedConnections] objectEnumerator];
	ONBConnectionController *currentConnectionController;
	
	while (currentConnectionController = [connectionEnumerator nextObject])
		[currentConnectionController showConsoleWindow];
}

- (ONBBookmark *)editBookmark
{
	return ONB_editBookmark;
}

- (void)setEditBookmark:(ONBBookmark *)editBookmark
{
	[ONB_editBookmark autorelease];
	ONB_editBookmark = [editBookmark retain];
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil)
		return [[self connectionControllers] count];
	
	if (! [item isKindOfClass:[ONBConnectionController class]])
		return 0;
	
	ONBConnectionController *connectionController = (ONBConnectionController *)item;
	NSNumber *identifier = [connectionController identifier];
	return [[ONB_outlineViewChildren objectForKey:identifier] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == nil)
		return YES;
	
	if (! [item isKindOfClass:[ONBConnectionController class]])
		return NO;
	
	ONBConnectionController *connectionController = (ONBConnectionController *)item;
	NSNumber *identifier = [connectionController identifier];
	return ([[ONB_outlineViewChildren objectForKey:identifier] count] != 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (item == nil)
		return [[self connectionControllers] objectAtIndex:index];
	
	if (! [item isKindOfClass:[ONBConnectionController class]])
		return nil;
	
	ONBConnectionController *connectionController = (ONBConnectionController *)item;
	NSNumber *identifier = [connectionController identifier];
	return [[ONB_outlineViewChildren objectForKey:identifier] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView
		objectValueForTableColumn:(NSTableColumn *)tableColumn
		byItem:(id)item
{
	NSString *identifier = [tableColumn identifier];

	if ([item isKindOfClass:[ONBConnectionController class]])
	{
		ONBConnectionController *connectionController = (ONBConnectionController *)item;
		ONBBookmark *bookmark = [connectionController bookmark];
		
		NSColor *largeTextColor;
		if ([[connectionController queue] connectionStatus])
			largeTextColor = [NSColor blackColor];
		else
			largeTextColor = [NSColor lightGrayColor];
		
		if ([identifier isEqualToString:@"name"])
		{
			NSString *nickname = [bookmark nickname];
			NSString *user = [bookmark user];
			NSString *host = [bookmark host];
			NSNumber *port = [bookmark port];
			
			NSString *largeText = nickname;
			NSString *userPart = @"";
			NSString *portPart = @"";
			NSString *smallText;
			
			if (port && ([port unsignedIntValue] != 21))
			{
				NSString *portFormat = NSLocalizedString(@" (port %@)", @"");
				portPart = [NSString stringWithFormat:portFormat, port];
			}
			
			if (user)
			{
				NSString *userFormat = NSLocalizedString(@"%@ at ", @"");
				userPart = [NSString stringWithFormat:userFormat, user];
			}

			NSString *format = NSLocalizedString(@"%@%@%@", @"");
			smallText = [NSString stringWithFormat:format, userPart, host, portPart];
		
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:largeText,
																			@"largeText",
																			smallText,
																			@"smallText",
																			largeTextColor,
																			@"largeTextColor",
																			nil];
			return dict;
		}
		
		if ([identifier isEqualToString:@"status"])
		{
			ONBQueue *queue = [connectionController queue];
			unsigned int connectionStatus = [queue connectionStatus];

			if (connectionStatus)
			{
				NSString *largeText;
				NSString *smallText;
				
				if (connectionStatus == 1)
					largeText = NSLocalizedString(@"Connecting", @"");
				else 
					largeText = NSLocalizedString(@"Connected", @"");
				
				unsigned int queueItems = [[queue mainQueueItems] count];
				ONBQueueItem *runningItem = [queue currentlyRunningQueueItem];
				double runningItemSpeed = [runningItem speed];
				
				if (runningItem && (! [queue currentlyRunningQueueItemIsControl]))
				{
					queueItems++;
					
					if ([runningItem isKindOfClass:[ONBDownloadFileQueueItem class]])
					{
						NSString *file = [(ONBDownloadFileQueueItem *)runningItem remoteFile];
						NSString *format = NSLocalizedString(@"Downloading %@", @"");
						largeText = [NSString stringWithFormat:format, file];
					}
					else if ([runningItem isKindOfClass:[ONBUploadFileQueueItem class]])
					{
						NSString *file = [(ONBUploadFileQueueItem *)runningItem localFile];
						NSString *format = NSLocalizedString(@"Uploading %@", @"");
						largeText = [NSString stringWithFormat:format, file];
					}
				}
				
				if (queueItems && (runningItemSpeed > 100.0))
				{
					NSNumber *speedNumber = [NSNumber numberWithDouble:runningItemSpeed];
					NSString *speedString = (NSString *)[ONB_sizeTransformer transformedValue:speedNumber];
					NSString *format = NSLocalizedString(@"%u incomplete queue items - %@ per sec", @"");
					smallText = [NSString stringWithFormat:format,
															queueItems,
															speedString];
				}
				else if (queueItems)
				{
					NSString *format = NSLocalizedString(@"%u incomplete queue items", @"");
					smallText = [NSString stringWithFormat:format, queueItems];
				}
				else
					smallText = NSLocalizedString(@"No queue items", @"");
				
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:largeText,
																				@"largeText",
																				smallText,
																				@"smallText",
																				largeTextColor,
																				@"largeTextColor",
																				nil];
				return dict;
			}
			else
				return nil;
		}
	}

	else if ([item isKindOfClass:[NSDictionary class]])
	{
		NSDictionary *dict = (NSDictionary *)item;
		ONBConnectionController *connectionController = [dict objectForKey:@"connectionController"];
		NSString *queueSection = [dict objectForKey:@"queueSection"];
		ONBQueueItem *object = nil;
		BOOL currentlyRunning = NO;
		
		if ([queueSection isEqualToString:@"currentlyRunningQueueItem"])
		{
			currentlyRunning = YES;
			object = [[connectionController queue] currentlyRunningQueueItem];
		}
		else if ([queueSection isEqualToString:@"mainQueueItems"])
		{
			NSNumber *queueIndex = [dict objectForKey:@"queueIndex"];
			object = [[[connectionController queue] mainQueueItems] objectAtIndex:[queueIndex unsignedIntValue]];
		}
		
		if ((! currentlyRunning) && [identifier isEqualToString:@"status"])
		{
			NSNumber *size = [NSNumber numberWithUnsignedInt:[object size]];
			NSString *smallText = nil;
			
			if (size)
				smallText = (NSString *)[ONB_sizeTransformer transformedValue:size];
			
			NSDictionary *dict;
			NSString *queued = NSLocalizedString(@"Queued", @"");

			if (smallText)
				dict = [NSDictionary dictionaryWithObjectsAndKeys:queued,
																	@"largeText",
																	smallText,
																	@"smallText",
																	nil];
			
			else
				dict = [NSDictionary dictionaryWithObjectsAndKeys:queued,
																	@"largeText",
																	[NSNumber numberWithBool:NO],
																	@"horizontallyCentered",
																	nil];
			return dict;
		}
		
		if ([object isKindOfClass:[ONBTransferFileQueueItem class]])
		{
			ONBTransferFileQueueItem *queueItem = (ONBTransferFileQueueItem *)object;

			if ([identifier isEqualToString:@"name"])
			{
				NSString *filename = [queueItem localFile];
				
				// If the file is to be downloaded, display the server's name for it instead
				// of the name of the file it is to be saved to locally.
				if ([queueItem isKindOfClass:[ONBDownloadFileQueueItem class]])
					filename = [queueItem remoteFile];

				NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:[filename pathExtension]];
				
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:image,
																				@"image",
																				filename,
																				@"largeText",
																				nil];
				return dict;
			}
			
			if (currentlyRunning && [identifier isEqualToString:@"status"])
			{
				NSString *largeText;
				NSString *smallText;
				NSString *progressText = nil;
				NSString *speedText = nil;
				
				if ([queueItem isKindOfClass:[ONBDownloadFileQueueItem class]])
					largeText = NSLocalizedString(@"Downloading", @"");
				else
					largeText = NSLocalizedString(@"Uploading", @"");
				
				NSNumber *size = [NSNumber numberWithUnsignedInt:[queueItem size]];
				double progress = [queueItem progress];
				double speed = [queueItem speed];
				if (progress && size)
				{
					float sizeFloat = [size floatValue];
					float percentageFloat = progress / 100.0;
					NSNumber *completed = [NSNumber numberWithFloat:sizeFloat * percentageFloat];
					NSString *completedString = (NSString *)[ONB_sizeTransformer transformedValue:completed];
					NSString *sizeString = (NSString *)[ONB_sizeTransformer transformedValue:size];
					NSString *format = NSLocalizedString(@"%@ of %@", @"");
					progressText = [NSString stringWithFormat:format, completedString, sizeString];
				}
				
				else if (progress)
				{
					NSString *format = NSLocalizedString(@"%0.2f percent complete", @"");
					progressText = [NSString stringWithFormat:format, progress];
				}
				
				if (speed > 100.0)
				{
					NSNumber *speedNumber = [NSNumber numberWithDouble:speed];
					NSString *formattedString = (NSString *)[ONB_sizeTransformer transformedValue:speedNumber];
					NSString *format = NSLocalizedString(@"%@ per sec", @"");
					speedText = [NSString stringWithFormat:format, formattedString];
				}
				
				if (progressText && speedText)
				{
					NSString *format = NSLocalizedString(@"%@ - %@", @"");
					smallText = [NSString stringWithFormat:format, progressText, speedText];
				}

				else if (progressText)
					smallText = progressText;
				
				else if (speedText)
					smallText = speedText;

				else
					smallText = NSLocalizedString(@"In progress", @"");
				
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:largeText,
																				@"largeText",
																				smallText,
																				@"smallText",
																				nil];
				return dict;
			}
		}
		
		else if ([object isKindOfClass:[ONBTransferDirectoryQueueItem class]])
		{
			ONBTransferDirectoryQueueItem *queueItem = (ONBTransferDirectoryQueueItem *)object;

			if ([identifier isEqualToString:@"name"])
			{
				NSString *filename = [[queueItem localDirectory] lastPathComponent];
				
				// If the directory is to be downloaded, display the server's name for it instead
				// of the name of the directory it is to be saved to locally.
				if ([queueItem isKindOfClass:[ONBDownloadDirectoryQueueItem class]])
					filename = [[queueItem remoteDirectory] lastPathComponent];
				
				NSImage *image = [NSImage imageNamed:@"GenericFolder"];
				
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:image,
																				@"image",
																				filename,
																				@"largeText",
																				nil];
				return dict;
			}
		}
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if ([(NSObject *)item isKindOfClass:[ONBConnectionController class]])
		return YES;
	
	return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
						ofObject:(id)object
						change:(NSDictionary *)change
						context:(void *)context
{
	if ([(NSObject *)context isKindOfClass:[ONBConnectionController class]])
	{
		// The connection controller's queue changed in some way.  If it's just a matter
		// of the currently running queue item telling us its speed and progress, then all
		// we must do is reload the connection's row in the outline view (to update the speed
		// or progress) and the row of its first child, if the queue item is not a control item.
		// Otherwise, we will rebuild all of the child items to make sure we are up to date.
		ONBConnectionController *connectionController = (ONBConnectionController *)context;
		NSNumber *identifier = [connectionController identifier];
		NSMutableArray *children = [ONB_outlineViewChildren objectForKey:identifier];
		ONBQueue *queue = [connectionController queue];
		
		// For some reason this only works if we check that there is a currently running
		// queue item and children in the array already below.  It doesn't have anything
		// to do with using objectAtIndex: below.  If we don't do it, then if you add two
		// download items to the queue, expand the connection in the connection manager,
		// and start the queue it will stop showing the second queue item after the first
		// finishes.  Honestly, I don't really understand the problem.  It might be a
		// timing issue (NSOutlineView needs to be reloaded a few times or on a different
		// call stack when an item is removed before we add another item back in?)  or
		// a bug in NSOutlineView.
		if (([keyPath isEqualToString:@"currentlyRunningQueueItem.progress"] ||
			[keyPath isEqualToString:@"currentlyRunningQueueItem.speed"])
			&& [queue currentlyRunningQueueItem]
			&& [children count])
		{
			// We don't need to do anything if this is a control queue item since the speed and
			// progress of those don't affect the connection manager display.
			if ([queue currentlyRunningQueueItemIsControl])
				return;
			
			// Reload the row for the connection and its first queue item (the one
			// currently running).
			[connectionsOutlineView reloadItem:connectionController];
			[connectionsOutlineView reloadItem:[children objectAtIndex:0]];
			
			return;
		}
		
		// This is more than just an update on speed and progress, so we must rebuild all
		// of the children.
		[children removeAllObjects];
		
		if ([queue currentlyRunningQueueItem] && (! [queue currentlyRunningQueueItemIsControl]))
		{
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:connectionController,
																			@"connectionController",
																			@"currentlyRunningQueueItem",
																			@"queueSection",
																			nil];
			[children addObject:dict];
		}
		
		unsigned int mainQueueItemsCount = [[queue mainQueueItems] count];
		unsigned int i;
		for (i = 0; i < mainQueueItemsCount; i++)
		{
			NSNumber *queueIndex = [NSNumber numberWithUnsignedInt:i];
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:connectionController,
																			@"connectionController",
																			@"mainQueueItems",
																			@"queueSection",
																			queueIndex,
																			@"queueIndex",
																			nil];
			[children addObject:dict];
		}
		
		[connectionsOutlineView reloadItem:connectionController reloadChildren:YES];
	}
}

- (IBAction)addASCIIType:(id)sender
{
	id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSMutableArray *ASCIITypes = [NSMutableArray arrayWithArray:[preferences valueForKey:@"ASCIITypes"]];
	NSString *newASCIIType = [[self newASCIIType] lowercaseString];
	
	if ((! newASCIIType) ||
		[newASCIIType isEqualToString:@""] ||
		[ASCIITypes containsObject:newASCIIType])
		return;
	
	[ASCIITypes addObject:newASCIIType];
	[preferences setValue:[NSArray arrayWithArray:ASCIITypes] forKey:@"ASCIITypes"];
	[self setNewASCIIType:nil];
}

- (IBAction)removeASCIIType:(id)sender
{
	unsigned int selectionIndex = [ASCIITypesController selectionIndex];
	if (selectionIndex == NSNotFound)
		return;

	id preferences = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSMutableArray *ASCIITypes = [NSMutableArray arrayWithArray:[preferences valueForKey:@"ASCIITypes"]];	
	[ASCIITypes removeObjectAtIndex:selectionIndex];
	[preferences setValue:[NSArray arrayWithArray:ASCIITypes] forKey:@"ASCIITypes"];
}

- (NSString *)newASCIIType
{
	return ONB_newASCIIType;
}

- (void)setNewASCIIType:(NSString *)newASCIIType
{
	[ONB_newASCIIType autorelease];
	ONB_newASCIIType = [newASCIIType copy];
}

@end