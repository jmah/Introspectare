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

#pragma mark Registering for sync
- (BOOL)registerSyncSchema;
- (void)registerForSyncNotifications;

#pragma mark Accessing sync status
- (BOOL)isSyncing;
- (NSDate *)lastSyncDate;

#pragma mark Initiating sync actions
- (void)sync;
- (void)syncBeforeApplicationTerminates;
- (void)syncWhileInactive;

@end
