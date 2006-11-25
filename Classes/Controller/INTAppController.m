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


static INTAppController *sharedAppController = nil;


@interface INTAppController (INTPrivateMethods)

#pragma mark Accessing Introspectare data
- (void)setLibrary:(INTLibrary *)library;

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
		INT_library = [[INTLibrary alloc] init];
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


- (void)setLibrary:(INTLibrary *)library // INTAppController (INTPrivateMethods)
{
	id oldValue = INT_library;
	INT_library = [library retain];
	[oldValue release];
}



#pragma mark Managing undo and redo

- (NSUndoManager *)undoManager
{
	return INT_undoManager;
}



#pragma mark Managing editing

- (BOOL)commitEditing
{
	return ((INT_entriesControler ?  [INT_entriesControler commitEditing] : YES) &&
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


- (NSString *)dataFileName
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
	NSString *dataFilePath = [dataFolderPath stringByAppendingPathComponent:[self dataFileName]];
	
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
			NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"INTDataFileIsDirectoryErrorRecoverySuggestion", @"Data file is directory error recovery suggestion"), [self dataFileName], dataFilePath];
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
		NSString *dataFilePath = [[self dataFolderPath] stringByAppendingPathComponent:[self dataFileName]];
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
	
	NSString *dataFilePath = [[self dataFolderPath] stringByAppendingPathComponent:[self dataFileName]];
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
