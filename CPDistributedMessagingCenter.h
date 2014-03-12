/**
 * This header is generated by class-dump-z 0.1-11s.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: /System/Library/PrivateFrameworks/AppSupport.framework/AppSupport
 */

#import <Foundation/NSObject.h>

@class NSLock, NSMutableDictionary, NSOperationQueue, NSString, NSDictionary, NSError;

@interface CPDistributedMessagingCenter : NSObject {
	NSString* _centerName;
	NSLock* _lock;
	unsigned _sendPort;
	CFMachPortRef _invalidationPort;
	NSOperationQueue* _asyncQueue;
	CFRunLoopSourceRef _serverSource;
	NSString* _requiredEntitlement;
	NSMutableDictionary* _callouts;
}
+(CPDistributedMessagingCenter*)centerNamed:(NSString*)serverName;
-(BOOL)sendMessageName:(NSString*)name userInfo:(NSDictionary*)info;
-(void)runServerOnCurrentThread;
-(void)runServerOnCurrentThreadProtectedByEntitlement:(id)entitlement;
-(void)stopServer;
-(void)registerForMessageName:(NSString*)messageName target:(id)target selector:(SEL)selector;
@end
