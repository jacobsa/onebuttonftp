/*-*- Mode: ObjC; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4  -*-*/
/*
 * InterThreadMessaging -- InterThreadMessaging.m
 * Created by toby on Tue Jun 19 2001.
 *
 */
 
// This collection of categories is based on the public domain code by
// Toby Paterson (tpater@mac.com), a discussion about which can be found
// here: http://www.cocoadev.com/index.pl?InterThreadMessaging
//
// The modifications to that code by Aaron Jacobs, including those listed
// in the accompanying header file, are copyright Aaron Jacobs.

#import <pthread.h>
#import "InterThreadMessaging.h"


/* There are four types of messages that can be posted between threads: a
   notification to be posted to the default notification centre and selectors
   to be performed with a varying number of arguments.  (I was tempted to
   implement all three in terms of performSelector:withObject:withObject:
   and passing in nil for the empty arguments, but then it occurred to me
   that perhaps the receiver has overridden performSelector: and
   performSelector:withObject:.  So I think I must disambiguate between
   them all.) */

typedef enum InterThreadMessageType InterThreadMessageType;
enum InterThreadMessageType
{
    kITMPerformSelector0Args = 1,
    kITMPerformSelector1Args,
    kITMPerformSelector2Args,
	kITMPerformSelector3Args
};


/* The message contents are carried between threads in this struct.  The
   struct is allocated in the sending thread and freed in the receiving thread.
   It is carried between the threads in an NSPortMessage - the NSPortMessage
   contains a single NSData argument, which is a wrapper around the pointer to
   this struct. */

typedef struct InterThreadMessage InterThreadMessage;
struct InterThreadMessage
{
    InterThreadMessageType type;
    union {
        struct {
            SEL selector;
            id receiver;
            id arg1;
            id arg2;
			id arg3;
        } sel;
    } data;
};



/* Each thread is associated with an NSPort.  This port is used to deliver
   messages to the target thread. */

static NSMapTable *pThreadMessagePorts = NULL;
static pthread_mutex_t pGate = { 0 };

@interface InterThreadManager : NSObject
+ (void) threadDied:(NSNotification *)notification;
+ (void) handlePortMessage:(NSPortMessage *)msg;
@end

static void
createMessagePortForThread (NSThread *thread, NSRunLoop *runLoop)
{
    NSPort *port;

    assert(nil != thread);
    assert(nil != runLoop);
    assert(NULL != pThreadMessagePorts);

    pthread_mutex_lock(&pGate);

    port = NSMapGet(pThreadMessagePorts, thread);
    if (nil == port) {
        port = [[NSPort allocWithZone:NULL] init];
        [port setDelegate:[InterThreadManager class]];
        [port scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        NSMapInsertKnownAbsent(pThreadMessagePorts, thread, port);

        /* Transfer ownership of this port to the map table. */
        [port release];
    }

    pthread_mutex_unlock(&pGate);
}

static NSPort *
messagePortForThread (NSThread *thread)
{
    NSPort *port;

    assert(nil != thread);
    assert(NULL != pThreadMessagePorts);

    pthread_mutex_lock(&pGate);
    port = NSMapGet(pThreadMessagePorts, thread);
    pthread_mutex_unlock(&pGate);

    if (nil == port) {
        [NSException raise:NSInvalidArgumentException
                     format:@"Thread %@ is not prepared to receive "
                            @"inter-thread messages.  You must invoke "
                            @"+prepareForInterThreadMessages first.", thread];
    }

    return port;
}

static void
removeMessagePortForThread (NSThread *thread, NSRunLoop *runLoop)
{
    NSPort *port;

    assert(nil != thread);
    assert(NULL != pThreadMessagePorts);

    pthread_mutex_lock(&pGate);
    
    port = (NSPort *) NSMapGet(pThreadMessagePorts, thread);
    if (nil != port) {
        [port removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        NSMapRemove(pThreadMessagePorts, thread);
    }

    pthread_mutex_unlock(&pGate);
}




@implementation NSThread (InterThreadMessaging)

+ (void) prepareForInterThreadMessages
{
    /* Force the class initialization. */
    [InterThreadManager class];

    createMessagePortForThread([NSThread currentThread],
                               [NSRunLoop currentRunLoop]);
}

@end




@interface NSThread (SecretStuff)
- (NSRunLoop *) runLoop;
@end

@implementation InterThreadManager

+ (void) initialize
{
    /* Create the mutex - this should be invoked by the Objective-C runtime
       (in a thread-safe manner) before any one can use this module, so I
       don't think I need to worry about race conditions here. */
    if (nil == pThreadMessagePorts) {
        pthread_mutex_init(&pGate, NULL);

        pThreadMessagePorts =
            NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,
                             NSObjectMapValueCallBacks, 0);

        [[NSNotificationCenter defaultCenter]
            addObserver:[self class]
            selector:@selector(threadDied:)
            name:NSThreadWillExitNotification
            object:nil];
    }
}

+ (void) threadDied:(NSNotification *)notification
{
    NSThread *thread;
    NSRunLoop *runLoop;

    thread = [notification object];
    runLoop = [thread runLoop];
    if (nil != runLoop) {
        removeMessagePortForThread(thread, [thread runLoop]);
    }
}

+ (void) handlePortMessage:(NSPortMessage *)portMessage
{
    InterThreadMessage *msg;
    NSArray *components;
    NSData *data;

    components = [portMessage components];
    assert(1 == [components count]);

    data = [components objectAtIndex:0];
    msg = *((InterThreadMessage **) [data bytes]);
    
    switch (msg->type)
    {
        case kITMPerformSelector0Args:
            [msg->data.sel.receiver performSelector:msg->data.sel.selector];
            [msg->data.sel.receiver release];
            break;

        case kITMPerformSelector1Args:
            [msg->data.sel.receiver performSelector:msg->data.sel.selector
                                    withObject:msg->data.sel.arg1];
            [msg->data.sel.receiver release];
            [msg->data.sel.arg1 release];
            break;

        case kITMPerformSelector2Args:
            [msg->data.sel.receiver performSelector:msg->data.sel.selector
                                    withObject:msg->data.sel.arg1
                                    withObject:msg->data.sel.arg2];
            [msg->data.sel.receiver release];
            [msg->data.sel.arg1 release];
            [msg->data.sel.arg2 release];
            break;

        case kITMPerformSelector3Args:
		{
			id receiver = msg->data.sel.receiver;
			SEL selector = msg->data.sel.selector;
			id arg1 = msg->data.sel.arg1;
			id arg2 = msg->data.sel.arg2;
			id arg3 = msg->data.sel.arg3;

			NSMethodSignature *signature = [receiver methodSignatureForSelector:selector];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

			[invocation setTarget:receiver];
			[invocation setSelector:selector];
			[invocation setArgument:&arg1 atIndex:2];
			[invocation setArgument:&arg2 atIndex:3];
			[invocation setArgument:&arg3 atIndex:4];
			[invocation invoke];
			
            [receiver release];
            [arg1 release];
            [arg2 release];
            [arg3 release];
		}
		break;

        default:
            assert(0);
    }

    free(msg);
}

@end





static void
performSelector (InterThreadMessageType type, SEL selector, id receiver,
                 id object1, id object2, id object3, NSThread *thread, NSDate *limitDate)
{
    InterThreadMessage *msg;

    assert(NULL != selector);
    
    if (nil != receiver)
	{
        msg = (InterThreadMessage *) malloc(sizeof(struct InterThreadMessage));
        bzero(msg, sizeof(struct InterThreadMessage));
        msg->type = type;
        msg->data.sel.selector = selector;
        msg->data.sel.receiver = [receiver retain];
        msg->data.sel.arg1 = [object1 retain];
        msg->data.sel.arg2 = [object2 retain];
        msg->data.sel.arg3 = [object3 retain];

		NSPortMessage *portMessage;
		NSMutableArray *components;
		NSPort *port;
		NSData *data;
		BOOL retval;

		if (nil == thread) { thread = [NSThread currentThread]; }
		port = messagePortForThread(thread);
		assert(nil != port);

		data = [[NSData alloc] initWithBytes:&msg length:sizeof(void *)];
		components = [[NSMutableArray alloc] initWithObjects:&data count:1];
		portMessage = [[NSPortMessage alloc] initWithSendPort:port
												receivePort:nil
												components:components];

		if (nil == limitDate) { limitDate = [NSDate distantFuture]; }
		retval = [portMessage sendBeforeDate:limitDate];
		[portMessage release];
		[components release];
		[data release];
		
		if (!retval)
		{
			[receiver release];
			[object1 release];
			[object2 release];
			[object3 release];
			
			[NSException raise:NSPortTimeoutException
						format:@"Can't send message to thread %@: timeout "
								@"before date %@", thread, limitDate];
		}
    }
}




@implementation NSObject (InterThreadMessaging)

- (void) performSelector:(SEL)selector
         inThread:(NSThread *)thread
{
    performSelector(kITMPerformSelector0Args, selector, self, nil, nil, nil,
                    thread, nil);
}

- (void) performSelector:(SEL)selector
         inThread:(NSThread *)thread
         beforeDate:(NSDate *)limitDate
{
    performSelector(kITMPerformSelector0Args, selector, self, nil, nil, nil,
                    thread, limitDate);
}

- (void) performSelector:(SEL)selector
         withObject:(id)object
         inThread:(NSThread *)thread
{
    performSelector(kITMPerformSelector1Args, selector, self, object, nil, nil,
                    thread, nil);
}

- (void) performSelector:(SEL)selector
         withObject:(id)object
         inThread:(NSThread *)thread
         beforeDate:(NSDate *)limitDate
{
    performSelector(kITMPerformSelector1Args, selector, self, object, nil, nil,
                    thread, limitDate);
}

- (void) performSelector:(SEL)selector
         withObject:(id)object1
         withObject:(id)object2
         inThread:(NSThread *)thread
{
    performSelector(kITMPerformSelector2Args, selector, self, object1, object2, nil,
                    thread, nil);
}

- (void) performSelector:(SEL)selector
         withObject:(id)object1
         withObject:(id)object2
         inThread:(NSThread *)thread
         beforeDate:(NSDate *)limitDate
{
    performSelector(kITMPerformSelector2Args, selector, self, object1, object2, nil,
                    thread, limitDate);
}

- (void) performSelector:(SEL)selector
         withObject:(id)object1
         withObject:(id)object2
         withObject:(id)object3
         inThread:(NSThread *)thread
{
    performSelector(kITMPerformSelector3Args, selector, self, object1, object2, object3,
                    thread, nil);
}

- (void) performSelector:(SEL)selector
         withObject:(id)object1
         withObject:(id)object2
         withObject:(id)object3
         inThread:(NSThread *)thread
         beforeDate:(NSDate *)limitDate
{
    performSelector(kITMPerformSelector3Args, selector, self, object1, object2, object3,
                    thread, limitDate);
}

@end