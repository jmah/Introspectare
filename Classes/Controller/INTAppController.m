//
//  INTAppController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-04.
//  Copyright Playhaus 2006. All rights reserved.
//

#import "INTAppController.h"
#import "INTShared.h"
#import "INTEntriesController.h"
#import "INTConstitutionsController.h"
#import "INTPrincipleLibraryController.h"
#import "INTInspectorController.h"
#import "INTLibrary.h"
#import "INTEntry.h"
#import "INTConstitution.h"
#import "INTPrinciple.h"
#import "INTAnnotatedPrinciple.h"
#import "INTAppController+INTBackupQuickPick.h"


static INTAppController *sharedAppController = nil;


@interface INTAppController (INTPrivateMethods)

#pragma mark Managing undo and redo
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue;

#pragma mark Persistence
- (BOOL)ensureDataFileReadable:(NSError **)outError;

#pragma mark Managing the inspector
- (void)setShowHideInspectorMenuItemTitle:(NSString *)title;
- (void)inspectorDidBecomeKey:(NSNotification *)notification;

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
		[self setShowHideInspectorMenuItemTitle:NSLocalizedString(@"INTShowInspectorMenuTitle", @"Show Inspector menu item")];
		
		sharedAppController = self;
	}
	return self;
}


- (void)awakeFromNib
{
	NSError *error = nil;
	if (![self loadData:&error])
		[NSApp presentError:error];
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[INT_library release], INT_library = nil;
	[INT_undoManager release], INT_undoManager = nil;
	[INT_showHideInspectorMenuItemTitle release], INT_showHideInspectorMenuItemTitle = nil;
	[INT_entriesControler release], INT_entriesControler = nil;
	[INT_constitutionsController release], INT_constitutionsController = nil;
	[INT_principleLibraryController release], INT_principleLibraryController = nil;
	[INT_inspectorController release], INT_inspectorController = nil;
	
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
		}
		
		NSEnumerator *principles = [[oldLibrary principles] objectEnumerator];
		INTPrinciple *principle;
		while ((principle = [principles nextObject]))
		{
			[principle removeObserver:self forKeyPath:@"label"];
			[principle removeObserver:self forKeyPath:@"explanation"];
			[principle removeObserver:self forKeyPath:@"note"];
		}
	}
	
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
		}
		
		NSEnumerator *principles = [[library principles] objectEnumerator];
		INTPrinciple *principle;
		while ((principle = [principles nextObject]))
		{
			[principle addObserver:self forKeyPath:@"label" options:options context:NULL];
			[principle addObserver:self forKeyPath:@"explanation" options:options context:NULL];
			[principle addObserver:self forKeyPath:@"note" options:options context:NULL];
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
				NSEnumerator *annotatedPrinciples = [[oldEntry annotatedPrinciples] objectEnumerator];
				INTAnnotatedPrinciple *annotatedPrinciple;
				while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
					[annotatedPrinciple removeObserver:self forKeyPath:@"upheld"];
			}
			
			NSEnumerator *newEntries = [newValue objectEnumerator];
			INTEntry *newEntry;
			while ((newEntry = [newEntries nextObject]))
			{
				[newEntry addObserver:self forKeyPath:@"note" options:options context:NULL];
				[newEntry addObserver:self forKeyPath:@"unread" options:options context:NULL];
				NSEnumerator *annotatedPrinciples = [[newEntry annotatedPrinciples] objectEnumerator];
				INTAnnotatedPrinciple *annotatedPrinciple;
				while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
					[annotatedPrinciple addObserver:self forKeyPath:@"upheld" options:options context:NULL];
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
			}
			
			NSEnumerator *newConstitutions = [newValue objectEnumerator];
			INTConstitution *newConstitution;
			while ((newConstitution = [newConstitutions nextObject]))
			{
				[newConstitution addObserver:self forKeyPath:@"versionLabel" options:options context:NULL];
				[newConstitution addObserver:self forKeyPath:@"note" options:options context:NULL];
				[newConstitution addObserver:self forKeyPath:@"principles" options:options context:NULL];
			}
		}
		else if ([keyPath isEqualToString:@"principles"])
		{
			NSEnumerator *oldPrinciples = [oldValue objectEnumerator];
			INTPrinciple *oldPrinciple;
			while ((oldPrinciple = [oldPrinciples nextObject]))
			{
				[oldPrinciple removeObserver:self forKeyPath:@"label"];
				[oldPrinciple removeObserver:self forKeyPath:@"explanation"];
				[oldPrinciple removeObserver:self forKeyPath:@"note"];
			}
			
			NSEnumerator *newPrinciples = [newValue objectEnumerator];
			INTPrinciple *newPrinciple;
			while ((newPrinciple = [newPrinciples nextObject]))
			{
				[newPrinciple addObserver:self forKeyPath:@"label" options:options context:NULL];
				[newPrinciple addObserver:self forKeyPath:@"explanation" options:options context:NULL];
				[newPrinciple addObserver:self forKeyPath:@"note" options:options context:NULL];
			}
		}
	}
	else
	{
		// Everything else is for undo management
		NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
		id settingValue = newValue;
		
		if (changeKind != NSKeyValueChangeSetting)
		{
			NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
			settingValue = [[[object valueForKeyPath:keyPath] mutableCopy] autorelease];
			if (changeKind == NSKeyValueChangeInsertion)
				[settingValue removeObjectsAtIndexes:indexes];
			else if (changeKind == NSKeyValueChangeRemoval)
				[settingValue insertObjects:oldValue atIndexes:indexes];
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
			{
				[[self undoManager] setActionName:NSLocalizedString(@"INTChangeConstitutionPrinciplesUndoAction", @"Change Constitution Principles undo action")];
				
				NSEnumerator *oldPrinciples = [oldValue objectEnumerator];
				INTPrinciple *oldPrinciple;
				while ((oldPrinciple = [oldPrinciples nextObject]))
				{
					[oldPrinciple removeObserver:self forKeyPath:@"label"];
					[oldPrinciple removeObserver:self forKeyPath:@"explanation"];
					[oldPrinciple removeObserver:self forKeyPath:@"note"];
				}
				
				NSEnumerator *newPrinciples = [newValue objectEnumerator];
				INTPrinciple *newPrinciple;
				while ((newPrinciple = [newPrinciples nextObject]))
				{
					[newPrinciple addObserver:self forKeyPath:@"label" options:options context:NULL];
					[newPrinciple addObserver:self forKeyPath:@"explanation" options:options context:NULL];
					[newPrinciple addObserver:self forKeyPath:@"note" options:options context:NULL];
				}
			}
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



#pragma mark Managing editing

- (BOOL)commitEditing
{
	return ((INT_entriesControler ? [INT_entriesControler commitEditing] : YES) &&
			(INT_constitutionsController ? [INT_constitutionsController commitEditing] : YES) &&
			(INT_principleLibraryController ? [INT_principleLibraryController commitEditing] : YES));
}


- (void)discardEditing
{
	if (INT_entriesControler)
		[INT_entriesControler discardEditing];
	if (INT_constitutionsController)
		[INT_constitutionsController discardEditing];
	if (INT_principleLibraryController)
		[INT_principleLibraryController discardEditing];
}



#pragma mark Persistence

- (NSString *)dataFolderPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *appSupportPath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	return [appSupportPath stringByAppendingPathComponent:@"Introspectare"];
}


- (NSString *)dataFilename
{
	return [NSUserName() stringByAppendingPathExtension:@"intspec"];
}


/*
 * Attempts to create the data directory (if it does not already exist), and
 * returns YES if creation succeeded and the data file is writable.
 */
- (BOOL)ensureDataFileReadable:(NSError **)outError // INTAppController (INTPrivateMethods)
{
	BOOL success = NO;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *dataFolderPath = [self dataFolderPath];
	NSString *dataFilePath = [dataFolderPath stringByAppendingPathComponent:[self dataFilename]];
	
	// Check that the data folder exists
	BOOL dataFolderIsDirectory = NO;
	BOOL dataFolderExists = [fileManager fileExistsAtPath:dataFolderPath isDirectory:&dataFolderIsDirectory];
	if (!dataFolderExists)
		dataFolderIsDirectory = [fileManager createDirectoryAtPath:dataFolderPath attributes:nil];
	
	if (!dataFolderIsDirectory)
	{
		NSString *errorDescription = NSLocalizedString(@"INTDataFolderCreationErrorDescription", @"Data folder creation error description");
		NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"INTDataFolderCreationErrorRecoverySuggestion", @"Data folder creation error recovery suggestion"), dataFolderPath];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			errorDescription, NSLocalizedDescriptionKey,
			recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
			nil];
		NSError *dataFolderCreationError = [NSError errorWithDomain:INTErrorDomain
															   code:INTDataFolderCreationError
														   userInfo:userInfo];
		if (outError)
			*outError = dataFolderCreationError;
	}
	else
	{
		// There is a directory at dataFolderPath
		BOOL dataFileIsDirectory = NO;
		BOOL dataFileExists = [fileManager fileExistsAtPath:dataFilePath isDirectory:&dataFileIsDirectory];
		if (dataFileExists && dataFileIsDirectory)
		{
			NSString *errorDescription = NSLocalizedString(@"INTDataFileIsDirectoryErrorDescription", @"Data file is directory error description");
			NSString *failureReason = NSLocalizedString(@"INTDataFileIsDirectoryErrorFailureReason", @"Data file is directory error failure reason");
			NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"INTDataFileIsDirectoryErrorRecoverySuggestion", @"Data file is directory error recovery suggestion"), [self dataFilename], dataFilePath];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				errorDescription, NSLocalizedDescriptionKey,
				failureReason, NSLocalizedFailureReasonErrorKey,
				recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
				nil];
			NSError *dataFileIsDirectoryError = [NSError errorWithDomain:INTErrorDomain
																	code:INTDataFileIsDirectoryError
																userInfo:userInfo];
			if (outError)
				*outError = dataFileIsDirectoryError;
		}
		else
			success = YES;
	}
	
	return success;
}


- (BOOL)loadData:(NSError **)outError
{
	BOOL success = NO;
	
	BOOL dataFileIsReadable = [self ensureDataFileReadable:outError];
	if (dataFileIsReadable)
	{
		NSString *dataFilePath = [[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:dataFilePath])
		{
			INTLibrary *newLibrary = nil;
			BOOL dataFileRaisedLoadError = NO;
			@try
			{
				newLibrary = [[NSKeyedUnarchiver unarchiveObjectWithFile:dataFilePath] retain];
			}
			@catch (NSException *e)
			{
				if ([e name] == NSInvalidArgumentException)
					dataFileRaisedLoadError = YES;
				else
					@throw e;
			}
			
			if (dataFileRaisedLoadError)
			{
				NSString *errorDescription = NSLocalizedString(@"INTDataFileLoadErrorDescription", @"Data file load error description");
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					errorDescription, NSLocalizedDescriptionKey,
					nil];
				NSError *dataFileLoadError = [NSError errorWithDomain:INTErrorDomain
																 code:INTDataFileLoadError
															 userInfo:userInfo];
				if (outError)
					*outError = dataFileLoadError;
			}
			else
			{
				[self setLibrary:newLibrary];
				success = YES;
			}
		}
		else
		{
			// An empty data file implies an empty library
			INTLibrary *newLibrary = [[INTLibrary alloc] init];
			[self setLibrary:newLibrary];
			success = YES;
			[newLibrary release];
		}
	}
	
	return success;
}


- (BOOL)saveData:(NSError **)outError
{
	BOOL success = NO;
	
	NSString *dataFilePath = [[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]];
	BOOL dataFileIsReadable = [self ensureDataFileReadable:outError];
	if (dataFileIsReadable)
	{
		if ([NSKeyedArchiver archiveRootObject:[self library] toFile:dataFilePath])
			success = YES;
		else
		{
			NSString *errorDescription = NSLocalizedString(@"INTDataFileSaveErrorDescription", @"Data file save error description");
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				errorDescription, NSLocalizedDescriptionKey,
				nil];
			NSError *dataFileSaveError = [NSError errorWithDomain:INTErrorDomain
															 code:INTDataFileSaveError
														 userInfo:userInfo];
			if (outError)
				*outError = dataFileSaveError;
		}
	}
	
	return success;
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
		if (![self saveData:&error])
			[NSApp presentError:error];
	}
}


- (IBAction)revert:(id)sender
{
	[self discardEditing];
	NSError *error = nil;
	if (![self loadData:&error])
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


- (IBAction)showPrinciples:(id)sender
{
	if (!INT_principleLibraryController)
		INT_principleLibraryController = [[INTPrincipleLibraryController alloc] initWithWindowNibName:@"PrincipleLibrary"];
	[INT_principleLibraryController showWindow:self];
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



#pragma mark NSApplication delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification // NSObject (NSApplicationDelegate)
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self introspectareBackupQuickPickDestinationPath]])
	{
		BOOL success = [self installIntrospetareBackupQuickPick];
		if (!success)
			NSLog(@"Error while attempting to install Introspectare Backup QuickPick");
	}
	
	[self showDays:self];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender // NSObject (NSApplicationDelegate)
{
	NSApplicationTerminateReply reply = NSTerminateCancel;
	
	// Save the data on quit
	if ([self commitEditing])
	{
		// Perform a save
		NSError *saveError = nil;
		BOOL didSave = [self saveData:&saveError];
		
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
	[INT_principleLibraryController close];
	[INT_constitutionsController close];
	[INT_entriesControler close];
}


@end
