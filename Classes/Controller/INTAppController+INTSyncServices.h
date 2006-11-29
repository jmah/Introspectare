//
//  INTAppController+INTSyncServices.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-28.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SyncServices/SyncServices.h>
#import "INTAppController.h"


@interface INTAppController (INTSyncServices)

#pragma mark Synchronization
- (BOOL)registerSyncSchema;
- (ISyncClient *)syncClient;
- (void)registerForSyncNotifications;
- (void)syncClient:(ISyncClient *)client mightWantToSynEntityNames:(NSArray *)entityNames;
- (NSDate *)lastSyncDate;
- (void)sync;
- (void)syncBeforeApplicationTerminates;
- (void)syncWhileInactive;
- (BOOL)isSyncing;
- (NSArray *)objectsForEntityName:(NSString *)entityName;
- (void)removeAllObjectsForEntityName:(NSString *)entityName;
- (NSDictionary *)recordForObject:(id)object entityName:(NSString *)entityName; // Returns the sync record
- (id)objectWithRecordIdentifier:(NSString *)identifier entityName:(NSString *)entityName;
- (id)objectWithRecordIdentifier:(NSString *)identifier entityName:(NSString *)entityName unresolvedRelationships:(NSArray *)unresolvedRelationships;
- (BOOL)handleSyncChange:(ISyncChange *)change forEntityName:(NSString *)entityName newRecordIdentifier:(NSString **)outRecordIdentifier unresolvedRelationships:(NSArray **)outUnresolvedRelationships;
- (BOOL)resolveRelationships:(NSArray *)unresolvedRelationships withRecordIdentifierMapping:(NSDictionary *)recordIdentifierMapping;

@end
