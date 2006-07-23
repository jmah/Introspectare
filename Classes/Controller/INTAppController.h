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
@class INTPrincipleLibraryController;
@class INTInspectorController;


@interface INTAppController : NSObject 
{
	@private
	INTLibrary *INT_library;
	NSUndoManager *INT_undoManager;
	
	INTEntriesController *INT_entriesControler;
	INTConstitutionsController *INT_constitutionsController;
	INTPrincipleLibraryController *INT_principleLibraryController;
	INTInspectorController *INT_inspectorController;
	
	NSString *INT_showHideInspectorMenuItemTitle;
}


#pragma mark Getting the app controller
+ (id)sharedAppController;

#pragma mark Accessing Introspectare data
- (INTLibrary *)library;

#pragma mark Managing undo and redo
- (NSUndoManager *)undoManager;

#pragma mark Managing editing
- (BOOL)commitEditing;
- (void)discardEditing;

#pragma mark Persistence
- (NSString *)dataFolderPath;
- (NSString *)dataFileName;
- (BOOL)loadData:(NSError **)outError;
- (BOOL)saveData:(NSError **)outError;

#pragma mark Menu items
- (NSString *)showHideInspectorMenuItemTitle;

#pragma mark UI Actions
- (IBAction)save:(id)sender;
- (IBAction)revert:(id)sender;
- (IBAction)showDays:(id)sender;
- (IBAction)showConstitutions:(id)sender;
- (IBAction)showPrinciples:(id)sender;
- (IBAction)showHideInspector:(id)sender;

@end
