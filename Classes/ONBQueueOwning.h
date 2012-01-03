//
//  ONBQueueOwning.h
//  OneButton FTP
//
//  Created by Aaron Jacobs on 2004-12-23.
//  Copyright 2004-2008 Aaron Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ONBQueue;
@class ONBQueueItem;

@protocol ONBQueueOwning

- (void)queueItem:(ONBQueueItem *)queueItem succeededWithInfo:(NSDictionary *)info;
- (void)queueItem:(ONBQueueItem *)queueItem failedWithError:(NSError *)error;

- (void)queue:(ONBQueue *)queue receivedCommunicationFromServer:(NSString *)communication;
- (void)queue:(ONBQueue *)queue sentCommunicationToServer:(NSString *)communication;

@end