//
//  INTController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-04.
//  Copyright Playhaus 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTConstitutionsController;
@class INTPrincipleLibraryController;


@interface INTController : NSObject 
{
	@private
	NSManagedObjectContext *INT_managedObjectContext;
	NSManagedObjectModel *INT_managedObjectModel;
	NSPersistentStoreCoordinator *INT_persistentStoreCoordinator;
	
	INTConstitutionsController *INT_constitutionsController;
	INTPrincipleLibraryController *INT_principleLibraryController;
}


#pragma mark Persistence
- (NSString *)dataFolderPath;
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

#pragma mark UI Actions
- (IBAction)performSave:(id)sender;
- (IBAction)showDays:(id)sender;
- (IBAction)showConstitutions:(id)sender;
- (IBAction)showPrinciples:(id)sender;
- (IBAction)showInspector:(id)sender;

@end
