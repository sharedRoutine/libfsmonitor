#import <fsmonitor.h>
#import "NSDistributedNotificationCenter.h"

#define FSE_INVALID             -1
#define FSE_CREATE_FILE          0
#define FSE_DELETE               1
#define FSE_STAT_CHANGED         2
#define FSE_RENAME               3
#define FSE_CONTENT_MODIFIED     4
#define FSE_EXCHANGE             5
#define FSE_FINDER_INFO_CHANGED  6
#define FSE_CREATE_DIR           7
#define FSE_CHOWN                8
#define FSE_XATTR_MODIFIED       9
#define FSE_XATTR_REMOVED       10

#define URL_STD(url) [[url path] stringByStandardizingPath]

@implementation FSMonitor

- (id)init{

	self = [super init];
	if(!self)
		return nil;

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(daemonCallback:) name:@"FSMONITORD_CALLBACK" object:nil];

	self.typeFilter = FSMonitorEventTypeAll;
	self.directoryFilter = [NSMutableArray new];
	[self.directoryFilter release];

	return self;
}

- (void)daemonCallback:(NSNotification *)notification {
	if(![[self.delegate class] conformsToProtocol:@protocol(FSMonitorDelegate)])
		return;

	NSDictionary *eventInfo = [notification userInfo];
	NSMutableDictionary *delegateEventInfo = [eventInfo mutableCopy];

	int type = [[delegateEventInfo objectForKey:@"TYPE"] intValue];

	if([self typeFilterAllowsEventType:type]){
		[delegateEventInfo removeObjectForKey:@"FILE"];
		if([NSURL URLWithString:[[eventInfo objectForKey:@"FILE"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]])
			[delegateEventInfo setObject:[NSURL URLWithString:[[eventInfo objectForKey:@"FILE"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forKey:@"FILE"];
		else{
			NSLog(@"URL is nil. Path: %@ truncated?", [[eventInfo objectForKey:@"FILE"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
			return;
		}

		if([delegateEventInfo objectForKey:@"DEST_FILE"]){
			[delegateEventInfo removeObjectForKey:@"DEST_FILE"];

			if([NSURL URLWithString:[[eventInfo objectForKey:@"DEST_FILE"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]])
				[delegateEventInfo setObject:[NSURL URLWithString:[[eventInfo objectForKey:@"DEST_FILE"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forKey:@"DEST_FILE"];
			else{
				NSLog(@"Dest URL is nil. Path: %@ truncated?", [[eventInfo objectForKey:@"DEST_FILE"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
				return;
			}
		}

		[delegateEventInfo removeObjectForKey:@"TYPE"];
		[delegateEventInfo setObject:@([self convertEventType:[[eventInfo objectForKey:@"TYPE"] intValue]]) forKey:@"TYPE"];

		if([self checkFilterWithEventInfo:delegateEventInfo])
			[[self delegate] monitor:self recievedEventInfo:delegateEventInfo];
	}

	[delegateEventInfo release];
}

- (void)addDirectoryFilter:(NSURL*)url recursive:(BOOL)recursive{
	for(NSDictionary *dictionary in self.directoryFilter){
		if([[dictionary objectForKey:@"URL"] isEqual:url])
			return;
	}

	[self.directoryFilter addObject:[NSDictionary dictionaryWithObjectsAndKeys:url, @"URL", @(recursive), @"RECURSIVE", nil]];
}

- (void)removeDirectoryFilter:(NSURL*)url{
	for(NSDictionary *dictionary in self.directoryFilter){
		if([[dictionary objectForKey:@"URL"] isEqual:url])
			[self.directoryFilter removeObject:dictionary];
	}
}

- (BOOL)checkFilterWithEventInfo:(NSDictionary*)eventInfo{
	BOOL directoryMatch = false;

	for(NSDictionary *dictionary in self.directoryFilter){
		if([URL_STD([eventInfo objectForKey:@"FILE"]) isEqualToString:URL_STD([dictionary objectForKey:@"URL"])])//Directory itself
			directoryMatch = true;
		if([URL_STD([[eventInfo objectForKey:@"FILE"] URLByDeletingLastPathComponent]) isEqualToString:URL_STD([dictionary objectForKey:@"URL"])])//Top level files/dirs
			directoryMatch = true;
		if([[dictionary objectForKey:@"RECURSIVE"] boolValue] == true){//Deep
			if([URL_STD([eventInfo objectForKey:@"FILE"]) hasPrefix:URL_STD([dictionary objectForKey:@"URL"])])
				directoryMatch = true;
		}
	}

	return directoryMatch;
}

- (FSMonitorEventType)convertEventType:(int)eventType{
	switch(eventType){
		case FSE_CREATE_FILE:
			return FSMonitorEventTypeFileCreation;
		case FSE_DELETE:
			return FSMonitorEventTypeDeletion;
		case FSE_RENAME:
			return FSMonitorEventTypeRename;
		case FSE_CONTENT_MODIFIED:
			return FSMonitorEventTypeModification;
		case FSE_CREATE_DIR:
			return FSMonitorEventTypeDirectoryCreation;
		case FSE_CHOWN:
			return FSMonitorEventTypeOwnershipChange;
		default:
			return FSMonitorEventTypeNone;
	}
}

- (BOOL)typeFilterAllowsEventType:(int)eventType{
	switch(eventType){
		case FSE_CREATE_FILE:
			return (self.typeFilter & FSMonitorEventTypeFileCreation);
		case FSE_DELETE:
			return (self.typeFilter & FSMonitorEventTypeDeletion);
		case FSE_RENAME:
			return (self.typeFilter & FSMonitorEventTypeRename);
		case FSE_CONTENT_MODIFIED:
			return (self.typeFilter & FSMonitorEventTypeModification);
		case FSE_CREATE_DIR:
			return (self.typeFilter & FSMonitorEventTypeDirectoryCreation);
		case FSE_CHOWN:
			return (self.typeFilter & FSMonitorEventTypeOwnershipChange);
		default:
			return false;
	}
}

- (void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"FSMONITORD_CALLBACK" object:nil];
	[self.directoryFilter release];
	[super dealloc];
}

@end