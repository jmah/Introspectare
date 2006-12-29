//
//  INTAppController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-04.
//  Copyright Playhaus 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INTShared.h"

@class INTLibrary;
@class INTEntriesController;
@class INTConstitutionsController;
@class INTInspectorController;


// NSUserDefaults keys
extern NSString *INTSyncAutomaticallyKey;
extern NSString *INTPrintInfoKey;


@interface INTAppController : NSObject 
{
	@public
	IBOutlet NSWindow *syncProgressPanel;
	IBOutlet NSProgressIndicator *syncProgressIndicator;
	
	@private
	INTLibrary *INT_library;
	NSUndoManager *INT_undoManager;
	
	INTEntriesController *INT_entriesControler;
	INTConstitutionsController *INT_constitutionsController;
	INTInspectorController *INT_inspectorController;
	
	NSString *INT_showHideInspectorMenuItemTitle;
	
	NSTimer *INT_entriesUpdateTimer; // Weak reference
	
	NSMutableDictionary *INT_objectsChangedSinceLastSync;
	NSMutableDictionary *INT_objectIdentifiersDeletedSinceLastSync;
	NSMutableSet *INT_uncommittedEntries;
	BOOL INT_syncSchemaRegistered;
	
	// INTSyncServices
	BOOL INT_isSyncing;
	NSDate *INT_lastSyncDate;
	NSDictionary *INT_syncObjectsByEntities;
	BOOL INT_isUsingSyncProgress;
}


#pragma mark Getting the app controller
+ (id)sharedAppController;

#pragma mark Accessing Introspectare data
- (INTLibrary *)library;
- (void)setLibrary:(INTLibrary *)library;

#pragma mark Managing undo and redo
- (NSUndoManager *)undoManager;

#pragma mark Managing entries
- (void)createEntriesUpToToday;

#pragma mark Managing editing
- (BOOL)commitEditing;
- (void)discardEditing;

#pragma mark Menu items
- (NSString *)showHideInspectorMenuItemTitle;

#pragma mark UI Actions
- (IBAction)save:(id)sender;
- (IBAction)revert:(id)sender;
- (IBAction)printDays:(id)sender;
- (IBAction)showDays:(id)sender;
- (IBAction)showConstitutions:(id)sender;
- (IBAction)showHideInspector:(id)sender;
- (IBAction)showInspector:(id)sender;
- (IBAction)synchronize:(id)sender;

@end
