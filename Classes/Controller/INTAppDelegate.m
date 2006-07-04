//
//  INTAppDelegate.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-04.
//  Copyright Playhaus 2006. All rights reserved.
//

#import "INTAppDelegate.h"


@implementation INTAppDelegate


- (void) dealloc
{
	[managedObjectContext release], managedObjectContext = nil;
	[persistentStoreCoordinator release], persistentStoreCoordinator = nil;
	[managedObjectModel release], managedObjectModel = nil;
	
	[super dealloc];
}


- (NSString *)applicationSupportFolder
{
	/*
	 * Returns the support folder for the application, used to store the
	 * Core Data store file. This code uses a folder named "Introspectare" for
	 * the content, either in the NSApplicationSupportDirectory location or
	 * (if the former cannot be found), the system's temporary directory.
	 */
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	return [basePath stringByAppendingPathComponent:@"Introspectare"];
}


- (NSManagedObjectModel *)managedObjectModel
{
	/*
	 * Creates, retains, and returns the managed object model for the
	 * application by merging all of the models found in the application
	 * bundle and all of the framework bundles.
	 */
	
	if (managedObjectModel != nil)
		return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject:[NSBundle mainBundle]];
	[allBundles addObjectsFromArray:[NSBundle allFrameworks]];
	
	managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:[allBundles allObjects]] retain];
	[allBundles release];
	
	return managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	/*
	 * Returns the persistent store coordinator for the application. This
	 * implementation will create and return a coordinator, having added the
	 * application's store to it. (The folder for the store is created, if
	 * necessary.)
	 */
	
	if (persistentStoreCoordinator != nil)
		return persistentStoreCoordinator;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *applicationSupportFolder = [self applicationSupportFolder];
	
	if (![fileManager fileExistsAtPath:applicationSupportFolder
	                       isDirectory:NULL])
		[fileManager createDirectoryAtPath:applicationSupportFolder
		                        attributes:nil];
	
	NSString *storePath = [applicationSupportFolder stringByAppendingPathComponent:@"Introspectare.xml"];
	NSURL *storeURL = [NSURL fileURLWithPath:storePath];
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	NSError *error = nil;
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType
	                                              configuration:nil
	                                                        URL:storeURL
	                                                    options:nil
	                                                      error:&error])
		[[NSApplication sharedApplication] presentError:error];
	
	return persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext
{
	/*
	 * Returns the managed object context for the application (which is
	 * already bound to the persistent store coordinator for the application.)
	 */
	
	if (managedObjectContext != nil)
		return managedObjectContext;
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil)
	{
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator: coordinator];
	}
	
	return managedObjectContext;
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	/*
	 * Returns the NSUndoManager for the application. In this case, the
	 * manager returned is that of the managed object context for the
	 * application.
	 */
	return [[self managedObjectContext] undoManager];
}


- (IBAction) saveAction:(id)sender
{
	/*
	 * Performs the save action for the application, which is to send the
	 * -save: message to the application's managed object context. Any
	 * encountered errors are presented to the user.
	 */
	
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error])
		[[NSApplication sharedApplication] presentError:error];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	/*
	 * Implementation of the applicationShouldTerminate: method, used here to
	 * handle the saving of changes in the application managed object context
	 * before the application terminates.
	 */
	
	NSError *error = nil;
	int reply = NSTerminateNow;
	
	if (managedObjectContext)
	{
		if ([managedObjectContext commitEditing])
			if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
			{
				/*
				 * This error handling simply presents error information in a
				 * panel with an "OK" button, which does not include any
				 * attempt at error recovery (meaning, attempting to fix the
				 * error.)  As a result, this implementation will present the
				 * information to the user and then follow up with a panel
				 * asking if the user wishes to "Quit anyway", without saving
				 * the changes.
				 *
				 * Typically, this process should be altered to include
				 * application-specific recovery steps.
				 */
				
				BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
				if (errorResult == YES)
					reply = NSTerminateCancel;
				else
				{
					int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
					if (alertReturn == NSAlertAlternateReturn)
						reply = NSTerminateCancel;
				}
			}
		else
			reply = NSTerminateCancel;
	}
	
	return reply;
}


@end
