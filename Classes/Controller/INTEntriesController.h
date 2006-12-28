//
//  INTEntriesController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTLibrary;
@class INTEntriesView;


@interface INTEntriesController : NSWindowController
{
	@public
	IBOutlet NSArrayController *entriesArrayController;
	IBOutlet NSView *entryInspectorView;
	IBOutlet NSTextField *inspectorDateField;
	IBOutlet NSScrollView *entriesScrollView;
	
	@private
	INTEntriesView *INT_entriesView; // Weak reference
}


#pragma mark Accessing Introspectare data
- (INTLibrary *)library;

#pragma mark Managing editing
- (BOOL)commitEditing;
- (void)discardEditing;

#pragma mark Managing the inspector panel
- (NSView *)inspectorView;

#pragma mark Printing
- (void)print:(id)sender;

@end
