//
//  INTAppController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-04.
//  Copyright Playhaus 2006. All rights reserved.
//

#import "INTAppController.h"
#import "INTAppController+INTPersistence.h"
#import "INTAppController+INTBackupQuickPick.h"
#import "INTAppController+INTSyncServices.h"
#import "INTShared.h"
#import "INTEntriesController.h"
#import "INTConstitutionsController.h"
#import "INTInspectorController.h"
#import "INTLibrary.h"
#import "INTEntry.h"
#import "INTConstitution.h"
#import "INTPrinciple.h"
#import "INTAnnotatedPrinciple.h"


static INTAppController *sharedAppController = nil;


@interface INTAppController (INTPrivateMethods)

#pragma mark Managing undo and redo
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue;

#pragma mark Tracking changed objects
- (void)objectChanged:(id)object;
- (void)objectDeleted:(id)object;

#pragma mark Managing the inspector
- (void)setShowHideInspectorMenuItemTitle:(NSString *)title;
- (void)inspectorDidBecomeKey:(NSNotification *)notification;

#pragma mark Trickle syncing
- (void)inactiveSyncTimerHit:(NSTimer *)timer;

@end


@implementation INTAppController

#pragma mark Getting the app controller

+ (id)sharedAppController
{
	if (!sharedAppController)
		sharedAppController = [[INTAppController alloc] init];
	return sharedAppController;
}


#pragma mark Creating an application controller

- (id)init // Designated initializer
{
	if (sharedAppController)
	{
		[self release];
		self = [sharedAppController retain];
	}
	else if ((self = [super init]))
	{
		[self setLibrary:[[[INTLibrary alloc] init] autorelease]];
		INT_undoManager = [[NSUndoManager alloc] init];
		INT_isSyncing = NO;
		INT_lastSyncDate = [[NSDate distantPast] copy];
		INT_syncSchemaRegistered = NO;
		
		INT_objectsChangedSinceLastSync = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[NSMutableSet set], @"INTEntry",
			[NSMutableSet set], @"INTConstitution",
			[NSMutableSet set], @"INTPrinciple",
			[NSMutableSet set], @"INTAnnotatedPrinciple",
			nil];
		INT_objectIdentifiersDeletedSinceLastSync = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[NSMutableSet set], @"INTEntry",
			[NSMutableSet set], @"INTConstitution",
			[NSMutableSet set], @"INTPrinciple",
			[NSMutableSet set], @"INTAnnotatedPrinciple",
			nil];
		
		[self setShowHideInspectorMenuItemTitle:NSLocalizedString(@"INTShowInspectorMenuTitle", @"Show Inspector menu item")];
		
		sharedAppController = self;
	}
	return self;
}


- (void)awakeFromNib
{
	[syncProgressIndicator setUsesThreadedAnimation:YES];
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[INT_library release], INT_library = nil;
	[INT_undoManager release], INT_undoManager = nil;
	[INT_showHideInspectorMenuItemTitle release], INT_showHideInspectorMenuItemTitle = nil;
	[INT_entriesControler release], INT_entriesControler = nil;
	[INT_constitutionsController release], INT_constitutionsController = nil;
	[INT_inspectorController release], INT_inspectorController = nil;
	[INT_lastSyncDate release], INT_lastSyncDate = nil;
	[INT_objectsChangedSinceLastSync release], INT_objectsChangedSinceLastSync = nil;
	[INT_objectIdentifiersDeletedSinceLastSync release], INT_objectIdentifiersDeletedSinceLastSync = nil;
	
	[super dealloc];
}



#pragma mark Accessing Introspectare data

- (INTLibrary *)library
{
	return INT_library;
}


- (void)setLibrary:(INTLibrary *)library
{
	INTLibrary *oldLibrary = INT_library;
	
	// Unobserve old library
	{
		[oldLibrary removeObserver:self forKeyPath:@"entries"];
		[oldLibrary removeObserver:self forKeyPath:@"constitutions"];
		[oldLibrary removeObserver:self forKeyPath:@"principles"];
		
		NSEnumerator *entries = [[oldLibrary entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
		{
			[entry removeObserver:self forKeyPath:@"note"];
			[entry removeObserver:self forKeyPath:@"unread"];
			[entry removeObserver:self forKeyPath:@"annotatedPrinciples"];
			
			NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
			INTAnnotatedPrinciple *annotatedPrinciple;
			while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
				[annotatedPrinciple removeObserver:self forKeyPath:@"upheld"];
		}
		
		NSEnumerator *constitutions = [[oldLibrary constitutions] objectEnumerator];
		INTConstitution *constitution;
		while ((constitution = [constitutions nextObject]))
		{
			[constitution removeObserver:self forKeyPath:@"versionLabel"];
			[constitution removeObserver:self forKeyPath:@"note"];
			[constitution removeObserver:self forKeyPath:@"principles"];
			
			NSEnumerator *principles = [[constitution principles] objectEnumerator];
			INTPrinciple *principle;
			while ((principle = [principles nextObject]))
			{
				[principle removeObserver:self forKeyPath:@"label"];
				[principle removeObserver:self forKeyPath:@"explanation"];
				[principle removeObserver:self forKeyPath:@"note"];
			}
		}
	}
	
	NSEnumerator *modifiedObjectClasses = [INT_objectsChangedSinceLastSync objectEnumerator];
	NSMutableSet *modifiedObjects;
	while ((modifiedObjects = [modifiedObjectClasses nextObject]))
		[modifiedObjects removeAllObjects];
	NSEnumerator *deletedObjectClasses = [INT_objectIdentifiersDeletedSinceLastSync objectEnumerator];
	NSMutableSet *deletedObjects;
	while ((deletedObjects = [deletedObjectClasses nextObject]))
		[deletedObjects removeAllObjects];
	
	INT_library = [library retain];
	[oldLibrary release];
	
	// Observe new library
	{
		NSKeyValueObservingOptions options = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
		
		[library addObserver:self forKeyPath:@"entries" options:options context:NULL];
		[library addObserver:self forKeyPath:@"constitutions" options:options context:NULL];
		[library addObserver:self forKeyPath:@"principles" options:options context:NULL];
		
		NSEnumerator *entries = [[library entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
		{
			[entry addObserver:self forKeyPath:@"note" options:options context:NULL];
			[entry addObserver:self forKeyPath:@"unread" options:options context:NULL];
			[entry addObserver:self forKeyPath:@"annotatedPrinciples" options:options context:NULL];
			
			NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
			INTAnnotatedPrinciple *annotatedPrinciple;
			while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
				[annotatedPrinciple addObserver:self forKeyPath:@"upheld" options:options context:NULL];
		}
		
		NSEnumerator *constitutions = [[library constitutions] objectEnumerator];
		INTConstitution *constitution;
		while ((constitution = [constitutions nextObject]))
		{
			[constitution addObserver:self forKeyPath:@"versionLabel" options:options context:NULL];
			[constitution addObserver:self forKeyPath:@"note" options:options context:NULL];
			[constitution addObserver:self forKeyPath:@"principles" options:options context:NULL];
			
			NSEnumerator *principles = [[constitution principles] objectEnumerator];
			INTPrinciple *principle;
			while ((principle = [principles nextObject]))
			{
				[principle addObserver:self forKeyPath:@"label" options:options context:NULL];
				[principle addObserver:self forKeyPath:@"explanation" options:options context:NULL];
				[principle addObserver:self forKeyPath:@"note" options:options context:NULL];
			}
		}
	}
}



#pragma mark Change notification

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	id newValue = [change objectForKey:NSKeyValueChangeNewKey];
	if (oldValue == [NSNull null])
		oldValue = nil;
	if (newValue == [NSNull null])
		newValue = nil;
	
	if (object != [self library])
		[self objectChanged:object];
	
	NSKeyValueObservingOptions options = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
	if (object == [self library])
	{
		if ([keyPath isEqualToString:@"entries"])
		{
			NSEnumerator *oldEntries = [oldValue objectEnumerator];
			INTEntry *oldEntry;
			while ((oldEntry = [oldEntries nextObject]))
			{
				[oldEntry removeObserver:self forKeyPath:@"note"];
				[oldEntry removeObserver:self forKeyPath:@"unread"];
				[oldEntry removeObserver:self forKeyPath:@"annotatedPrinciples"];
				[self objectDeleted:oldEntry];
				
				NSEnumerator *annotatedPrinciples = [[oldEntry annotatedPrinciples] objectEnumerator];
				INTAnnotatedPrinciple *annotatedPrinciple;
				while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
				{
					[annotatedPrinciple removeObserver:self forKeyPath:@"upheld"];
					[self objectDeleted:annotatedPrinciple];
				}
			}
			
			NSEnumerator *newEntries = [newValue objectEnumerator];
			INTEntry *newEntry;
			while ((newEntry = [newEntries nextObject]))
			{
				[newEntry addObserver:self forKeyPath:@"note" options:options context:NULL];
				[newEntry addObserver:self forKeyPath:@"unread" options:options context:NULL];
				[newEntry addObserver:self forKeyPath:@"annotatedPrinciples" options:options context:NULL];
				[self objectChanged:newEntry];
				
				NSEnumerator *annotatedPrinciples = [[newEntry annotatedPrinciples] objectEnumerator];
				INTAnnotatedPrinciple *annotatedPrinciple;
				while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
				{
					[annotatedPrinciple addObserver:self forKeyPath:@"upheld" options:options context:NULL];
					[self objectChanged:annotatedPrinciple];
				}
			}
		}
		else if ([keyPath isEqualToString:@"constitutions"])
		{
			NSEnumerator *oldConstitutions = [oldValue objectEnumerator];
			INTConstitution *oldConstitution;
			while ((oldConstitution = [oldConstitutions nextObject]))
			{
				[oldConstitution removeObserver:self forKeyPath:@"versionLabel"];
				[oldConstitution removeObserver:self forKeyPath:@"note"];
				[oldConstitution removeObserver:self forKeyPath:@"principles"];
				[self objectDeleted:oldConstitution];
				
				NSEnumerator *principles = [[oldConstitution principles] objectEnumerator];
				INTPrinciple *principle;
				while ((principle = [principles nextObject]))
				{
					[principle removeObserver:self forKeyPath:@"label"];
					[principle removeObserver:self forKeyPath:@"explanation"];
					[principle removeObserver:self forKeyPath:@"note"];
					[self objectDeleted:principle];
				}
			}
			
			NSEnumerator *newConstitutions = [newValue objectEnumerator];
			INTConstitution *newConstitution;
			while ((newConstitution = [newConstitutions nextObject]))
			{
				[newConstitution addObserver:self forKeyPath:@"versionLabel" options:options context:NULL];
				[newConstitution addObserver:self forKeyPath:@"note" options:options context:NULL];
				[newConstitution addObserver:self forKeyPath:@"principles" options:options context:NULL];
				[self objectChanged:newConstitution];
				
				NSEnumerator *principles = [[newConstitution principles] objectEnumerator];
				INTPrinciple *principle;
				while ((principle = [principles nextObject]))
				{
					[principle addObserver:self forKeyPath:@"label" options:options context:NULL];
					[principle addObserver:self forKeyPath:@"explanation" options:options context:NULL];
					[principle addObserver:self forKeyPath:@"note" options:options context:NULL];
					[self objectChanged:principle];
				}
			}
		}
	}
	else if ([object isKindOfClass:[INTConstitution class]] && [keyPath isEqualToString:@"principles"])
	{
		NSEnumerator *oldPrinciples = [oldValue objectEnumerator];
		INTPrinciple *oldPrinciple;
		while ((oldPrinciple = [oldPrinciples nextObject]))
		{
			[oldPrinciple removeObserver:self forKeyPath:@"label"];
			[oldPrinciple removeObserver:self forKeyPath:@"explanation"];
			[oldPrinciple removeObserver:self forKeyPath:@"note"];
			[self objectDeleted:oldPrinciple];
		}
		
		NSEnumerator *newPrinciples = [newValue objectEnumerator];
		INTPrinciple *newPrinciple;
		while ((newPrinciple = [newPrinciples nextObject]))
		{
			[newPrinciple addObserver:self forKeyPath:@"label" options:options context:NULL];
			[newPrinciple addObserver:self forKeyPath:@"explanation" options:options context:NULL];
			[newPrinciple addObserver:self forKeyPath:@"note" options:options context:NULL];
			[self objectChanged:newPrinciple];
		}
	}
	else if ([object isKindOfClass:[INTEntry class]] && [keyPath isEqualToString:@"annotatedPrinciples"])
	{
		NSEnumerator *oldAnnotatedPrinciples = [oldValue objectEnumerator];
		INTAnnotatedPrinciple *oldAnnotatedPrinciple;
		while ((oldAnnotatedPrinciple = [oldAnnotatedPrinciples nextObject]))
		{
			[oldAnnotatedPrinciple removeObserver:self forKeyPath:@"upheld"];
			[self objectDeleted:oldAnnotatedPrinciple];
		}
		
		NSEnumerator *newAnnotatedPrinciples = [newValue objectEnumerator];
		INTAnnotatedPrinciple *newAnnotatedPrinciple;
		while ((newAnnotatedPrinciple = [newAnnotatedPrinciples nextObject]))
		{
			[newAnnotatedPrinciple addObserver:self forKeyPath:@"upheld" options:options context:NULL];
			[self objectChanged:newAnnotatedPrinciple];
		}
	}
	
	
	// Undo management
	if (![[self undoManager] isUndoRegistrationEnabled])
		return;
	
	NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
	id settingValue = oldValue;
	
	if (changeKind != NSKeyValueChangeSetting)
	{
		NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
		settingValue = [[[object valueForKeyPath:keyPath] mutableCopy] autorelease];
		if (changeKind == NSKeyValueChangeInsertion)
		{
			if (indexes)
				[settingValue removeObjectsAtIndexes:indexes];
			else
				[settingValue minusSet:newValue];
		}
		else if (changeKind == NSKeyValueChangeRemoval)
		{
			if (indexes)
				[settingValue insertObjects:oldValue atIndexes:indexes];
			else
				[settingValue unionSet:oldValue];
		}
		else if (changeKind == NSKeyValueChangeReplacement)
			[settingValue replaceObjectsAtIndexes:indexes withObjects:oldValue];
	}
	
	[[[self undoManager] prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:object toValue:settingValue];
	
	
	// Set undo action name
	if ([[self undoManager] isUndoing])
	{
		// Swap old and new if undoing
		id temp = oldValue;
		oldValue = newValue;
		newValue = temp;
	}
	
	if ([object isKindOfClass:[INTEntry class]])
	{
		// Assume changing of unread status is secondary; only set a name if there is not already one
		if ([keyPath isEqualToString:@"unread"] && ![[self undoManager] undoActionName])
		{
			if ([newValue boolValue] == YES)
				[[self undoManager] setActionName:NSLocalizedString(@"INTMarkAsUnreadUndoAction", @"Mark as Unread undo action")];
			else
				[[self undoManager] setActionName:NSLocalizedString(@"INTMarkAsReadUndoAction", @"Mark as Read undo action")];
		}
		else if ([keyPath isEqualToString:@"note"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangeEntryNoteUndoAction", @"Change Entry Note undo action")];
	}
	else if ([object isKindOfClass:[INTAnnotatedPrinciple class]])
	{
		if (![[self undoManager] isUndoing] && ![[self undoManager] isRedoing])
		{
			// Mark entry as read
			BOOL foundEntry = NO;
			NSEnumerator *entries = [[[self library] entries] objectEnumerator];
			INTEntry *entry;
			while (!foundEntry && (entry = [entries nextObject]))
			{
				NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
				INTAnnotatedPrinciple *annotatedPrinciple;
				while (!foundEntry && (annotatedPrinciple = [annotatedPrinciples nextObject]))
					if (annotatedPrinciple == object)
						foundEntry = YES;
				if (foundEntry)
					if ([entry isUnread])
						[entry setUnread:NO];
			}
		}
		
		if ([keyPath isEqualToString:@"upheld"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangeAnnotatedPrincipleUpheldUndoAction", @"Change annotated principle upheld undo action")];
	}
	else if ([object isKindOfClass:[INTConstitution class]])
	{
		if ([keyPath isEqualToString:@"versionLabel"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangeConstitutionVersionLabelUndoAction", @"Change Constitution Version Label undo action")];
		else if ([keyPath isEqualToString:@"note"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangeConstitutionNoteUndoAction", @"Change Constitution Note undo action")];
		else if ([keyPath isEqualToString:@"principles"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangeConstitutionPrinciplesUndoAction", @"Change Constitution Principles undo action")];

	}
	else if ([object isKindOfClass:[INTPrinciple class]])
	{
		if ([keyPath isEqualToString:@"label"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangePrincipleLabelUndoAction", @"Change Principle Label undo action")];
		else if ([keyPath isEqualToString:@"explanation"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangePrincipleExplanationUndoAction", @"Change Principle Explanation undo action")];
		else if ([keyPath isEqualToString:@"note"])
			[[self undoManager] setActionName:NSLocalizedString(@"INTChangePrincipleNoteUndoAction", @"Change Principle Note undo action")];
	}
}



#pragma mark Managing undo and redo

- (NSUndoManager *)undoManager
{
	return INT_undoManager;
}


- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue // INTAppController (INTPrivateMethods)
{
	[object setValue:newValue forKeyPath:keyPath];
}



#pragma mark Tracking changed objects

- (void)objectChanged:(id)object // INTAppController (INTPrivateMethods)
{
	if (![self isSyncing])
	{
		NSString *className = nil;
		if ([object isKindOfClass:[INTEntry class]])
			className = @"INTEntry";
		else if ([object isKindOfClass:[INTConstitution class]])
			className = @"INTConstitution";
		else if ([object isKindOfClass:[INTPrinciple class]])
			className = @"INTPrinciple";
		else if ([object isKindOfClass:[INTAnnotatedPrinciple class]])
			className = @"INTAnnotatedPrinciple";
		else
			NSLog(@"-[INTAppController objectChanged:] Unknown class: %@", className);
		
		if (className)
			[[INT_objectsChangedSinceLastSync objectForKey:className] addObject:object];
	}
}


- (void)objectDeleted:(id)object // INTAppController (INTPrivateMethods)
{
	if (![self isSyncing])
	{
		NSString *className = nil;
		if ([object isKindOfClass:[INTEntry class]])
			className = @"INTEntry";
		else if ([object isKindOfClass:[INTConstitution class]])
			className = @"INTConstitution";
		else if ([object isKindOfClass:[INTPrinciple class]])
			className = @"INTPrinciple";
		else if ([object isKindOfClass:[INTAnnotatedPrinciple class]])
			className = @"INTAnnotatedPrinciple";
		else
			NSLog(@"-[INTAppController objectDeleted:] Unknown class: %@", className);
		
		if (className)
		{
			[[INT_objectsChangedSinceLastSync objectForKey:className] removeObject:object];
			[[INT_objectIdentifiersDeletedSinceLastSync objectForKey:className] addObject:[object uuid]];
		}
	}
}



#pragma mark Managing editing

- (BOOL)commitEditing
{
	return ((INT_entriesControler ? [INT_entriesControler commitEditing] : YES) &&
			(INT_constitutionsController ? [INT_constitutionsController commitEditing] : YES));
}


- (void)discardEditing
{
	if (INT_entriesControler)
		[INT_entriesControler discardEditing];
	if (INT_constitutionsController)
		[INT_constitutionsController discardEditing];
}



#pragma mark Menu items

- (NSString *)showHideInspectorMenuItemTitle
{
	return INT_showHideInspectorMenuItemTitle;
}



#pragma mark Managing the inspector

- (void)setShowHideInspectorMenuItemTitle:(NSString *)title // INTAppController (INTPrivateMethods)
{
	id oldValue = INT_showHideInspectorMenuItemTitle;
	INT_showHideInspectorMenuItemTitle = [title copy];
	[oldValue release];
}


- (void)inspectorDidBecomeKey:(NSNotification *)notification // INTAppController (INTPrivateMethods)
{
	[self setShowHideInspectorMenuItemTitle:NSLocalizedString(@"INTHideInspectorMenuTitle", @"Hide Inspector menu item")];
}


- (void)inspectorWillClose:(NSNotification *)notification // INTAppController (INTPrivateMethods)
{
	[self setShowHideInspectorMenuItemTitle:NSLocalizedString(@"INTShowInspectorMenuTitle", @"Show Inspector menu item")];
}



#pragma mark UI Actions

- (IBAction)save:(id)sender
{
	if ([self commitEditing])
	{
		NSError *error = nil;
		if (![self saveToFile:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]
						error:&error])
			[NSApp presentError:error];
	}
}


- (IBAction)revert:(id)sender
{
	[self discardEditing];
	NSError *error = nil;
	if (![self loadFromFile:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]
					  error:&error])
		[NSApp presentError:error];
}


- (IBAction)showDays:(id)sender
{
	if (!INT_entriesControler)
		INT_entriesControler = [[INTEntriesController alloc] initWithWindowNibName:@"Entries"];
	[INT_entriesControler showWindow:self];
}


- (IBAction)showConstitutions:(id)sender
{
	if (!INT_constitutionsController)
		INT_constitutionsController = [[INTConstitutionsController alloc] initWithWindowNibName:@"Constitutions"];
	[INT_constitutionsController showWindow:self];
}


- (IBAction)showHideInspector:(id)sender
{
	if (!INT_inspectorController)
	{
		INT_inspectorController = [[INTInspectorController alloc] initWithWindowNibName:@"Inspector"];
		
		// Watch for the inspector closing and opening so we can update the menu item title
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(inspectorWillClose:)
													 name:NSWindowWillCloseNotification
												   object:[INT_inspectorController window]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(inspectorDidBecomeKey:)
													 name:NSWindowDidBecomeKeyNotification
												   object:[INT_inspectorController window]];
	}
	
	if ([[INT_inspectorController window] isVisible])
		[INT_inspectorController close];
	else
		[INT_inspectorController showWindow:self];
}


- (IBAction)showInspector:(id)sender
{
	if (!INT_inspectorController)
		[self showHideInspector:self];
	if (![[INT_inspectorController window] isVisible])
		[INT_inspectorController showWindow:self];
}


- (IBAction)synchronize:(id)sender
{
	if (!INT_syncSchemaRegistered)
	{
		NSString *alertTitle = NSLocalizedString(@"INTSyncWhenSchemaNotRegisteredAlertTitle", @"Sync when sync schema not registered alert title");
		NSString *alertMessage = NSLocalizedString(@"INTSyncWhenSchemaNotRegisteredAlertMessage", @"Sync when sync schema not registered alert message");
		NSString *defaultButtonTitle = NSLocalizedString(@"INTSyncWhenSchemaNotRegisteredDefaultButton", @"Sync when sync schema not registered alert default button"); // (OK)
		NSString *alternateButtonTitle = nil;
		NSString *otherButtonTitle = nil;
		
		NSRunAlertPanel(alertTitle, alertMessage, defaultButtonTitle, alternateButtonTitle, otherButtonTitle);
	}
	else
		[self sync];
}



#pragma mark Trickle syncing

- (void)inactiveSyncTimerHit:(NSTimer *)timer
{
	[INT_inactiveSyncTimer invalidate], INT_inactiveSyncTimer = nil;
	[self syncWhileInactive];
}



#pragma mark NSApplication delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification // NSObject (NSApplicationDelegate)
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self introspectareBackupQuickPickDestinationPath]])
	{
		BOOL success = [self installIntrospetareBackupQuickPick];
		if (!success)
			NSLog(@"Failed to install Introspectare Backup QuickPick");
	}
	
	INT_syncSchemaRegistered = [self registerSyncSchema];
	if (INT_syncSchemaRegistered)
		[self registerForSyncNotifications];
	else
		NSLog(@"Failed to register sync schema");
	
	NSError *error = nil;
	if (![self loadFromFile:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]
					  error:&error])
		[NSApp presentError:error];
	
	[self showDays:self];
	[self syncWhileInactive];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender // NSObject (NSApplicationDelegate)
{
	NSApplicationTerminateReply reply = NSTerminateCancel;
	
	// Save the data on quit
	if ([self commitEditing])
	{
		// Perform a save
		NSError *saveError = nil;
		BOOL didSave = [self saveToFile:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]
								  error:&saveError];
		
		if (didSave)
			reply = NSTerminateNow;
		else
		{
			BOOL didRecover = [NSApp presentError:saveError];
			if (didRecover)
				reply = NSTerminateNow;
			else
			{
				// Run save error alert
				NSString *alertTitle = NSLocalizedString(@"INTSaveErrorAlertTitle", @"Save error alert title");
				NSString *alertMessage = NSLocalizedString(@"INTSaveErrorAlertMessage", @"Save error alert message");
				NSString *defaultButtonTitle = NSLocalizedString(@"INTSaveErrorDefaultButton", @"Save error alert default button"); // (Cancel)
				NSString *alternateButtonTitle = NSLocalizedString(@"INTSaveErrorAlternateButton", @"Save error alert alternate button"); // (Quit Anyway)
				NSString *otherButtonTitle = nil;
				
				int alertReturn = NSRunAlertPanel(alertTitle, alertMessage, defaultButtonTitle, alternateButtonTitle, otherButtonTitle);
				if (alertReturn == NSAlertAlternateReturn)
					reply = NSTerminateNow;
			}
		}
	}
	
	return reply;
}


- (void)applicationWillTerminate:(NSNotification *)notification // NSObject (NSApplicationDelegate)
{
	[INT_constitutionsController close];
	[INT_entriesControler close];
	[self syncBeforeApplicationTerminates];
}


- (void)applicationDidBecomeActive:(NSNotification *)notification // NSObject (NSApplicationDelegate)
{
	if (INT_inactiveSyncTimer)
		[INT_inactiveSyncTimer invalidate], INT_inactiveSyncTimer = nil;
}


- (void)applicationDidResignActive:(NSNotification *)notification // NSObject (NSApplicationDelegate)
{
	[INT_inactiveSyncTimer invalidate], INT_inactiveSyncTimer = nil;
	if (![self isSyncing] && INT_syncSchemaRegistered)
		INT_inactiveSyncTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
																 target:self
															   selector:@selector(inactiveSyncTimerHit:)
															   userInfo:NULL
																repeats:NO];
}


@end
