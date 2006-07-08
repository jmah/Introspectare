//
//  INTConstitutionsController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTLibrary;


@interface INTConstitutionsController : NSWindowController
{
	@public
	IBOutlet NSView *constitutionInspectorView;
	IBOutlet NSView *principleInspectorView;
	IBOutlet NSTableColumn *constitutionsDateColumn;
	IBOutlet NSTextField *constitutionInspectorDateField;
	IBOutlet NSTextField *principleInspectorDateField;
	IBOutlet NSTableView *principlesTableView;
	IBOutlet NSTableView *constitutionsTableView;
	IBOutlet NSArrayController *principlesArrayController;
	IBOutlet NSArrayController *constitutionsArrayController;
}


#pragma mark Accessing Introspectare data
- (INTLibrary *)library;

@end
