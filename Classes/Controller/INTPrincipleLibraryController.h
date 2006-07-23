//
//  INTPrincipleLibraryController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTLibrary;


@interface INTPrincipleLibraryController : NSWindowController
{
	@public
	IBOutlet NSView *principleInspectorView;
	IBOutlet NSTableColumn *dateColumn;
	IBOutlet NSTextField *inspectorDateField;
	IBOutlet NSTableView *principleLibraryTableView;
	IBOutlet NSArrayController *principlesArrayController;
}


#pragma mark Accessing Introspectare data
- (INTLibrary *)library;

#pragma mark Managing editing
- (BOOL)commitEditing;
- (void)discardEditing;

#pragma mark Managing the inspector panel
- (NSView *)inspectorView;

@end
