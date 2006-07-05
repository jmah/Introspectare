//
//  INTController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-04.
//  Copyright Playhaus 2006. All rights reserved.
//

#import "INTController.h"
#import "INTConstitutionsController.h"
#import "INTPrincipleLibraryController.h"


@implementation INTController

#pragma mark Initializing and deallocating

- (id)init // Designated initializer
{
	if ((self = [super init]))
	{
		// Load the managed object model
		NSBundle *myBundle = [NSBundle mainBundle];
		NSString *momPath = [myBundle pathForResource:@"Introspectare" ofType:@"mom"];
		NSURL *momURL = [NSURL fileURLWithPath:momPath];
		INT_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
		
		
		// Create the persistent store coordinator
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *dataFolderPath = [self dataFolderPath];
		
		if (![fileManager fileExistsAtPath:dataFolderPath isDirectory:NULL])
			[fileManager createDirectoryAtPath:dataFolderPath attributes:nil];
		
		NSString *storePath = [dataFolderPath stringByAppendingPathComponent:@"Introspectare.xml"];
		NSURL *storeURL = [NSURL fileURLWithPath:storePath];
		
		INT_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		NSError *storeError = nil;
		id defaultStore = [INT_persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType
		                                                              configuration:nil
		                                                                        URL:storeURL
		                                                                    options:nil
		                                                                      error:&storeError];
		if (defaultStore)
		{
			// Create the managed object context
			INT_managedObjectContext = [[NSManagedObjectContext alloc] init];
			[INT_managedObjectContext setPersistentStoreCoordinator:INT_persistentStoreCoordinator];
		}
		else
		{
			NSLog(@"Could not create a persistent store coordinator! Error: %@", storeError);
			[self release], self = nil;
		}
	}
	return self;
}


- (void) dealloc
{
	[INT_managedObjectContext release], INT_managedObjectContext = nil;
	[INT_managedObjectModel release], INT_managedObjectModel = nil;
	[INT_persistentStoreCoordinator release], INT_persistentStoreCoordinator = nil;
	
	[super dealloc];
}



#pragma mark Persistence

- (NSString *)dataFolderPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *appSupportPath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	return appSupportPath;
}


- (NSManagedObjectContext *)managedObjectContext
{
	return INT_managedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel
{
	return INT_managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	return INT_persistentStoreCoordinator;
}



#pragma mark UI Actions

- (IBAction)performSave:(id)sender
{
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error])
		[NSApp presentError:error];
}


- (IBAction)showDays:(id)sender
{
#warning Implement
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


- (IBAction)showInspector:(id)sender
{
#warning Implement
}



#pragma mark NSApplication delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification // NSObject (NSApplicationDelegate)
{
#warning Implement
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender // NSObject (NSApplicationDelegate)
{
	NSApplicationTerminateReply reply = NSTerminateCancel;
	
	// Save the managed object context on save
	if ([[self managedObjectContext] commitEditing])
	{
		if (![[self managedObjectContext] hasChanges])
			reply = NSTerminateNow;
		else
		{
			// Perform a save
			NSError *saveError = nil;
			BOOL didSave = [[self managedObjectContext] save:&saveError];
			
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
	}
	
	return reply;
}


@end
