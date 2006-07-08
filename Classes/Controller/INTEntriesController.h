//
//  INTEntriesController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTLibrary;


@interface INTEntriesController : NSWindowController
{
	@public
	IBOutlet NSTableColumn *entriesDateColumn;
	IBOutlet NSArrayController *entriesArrayController;
	IBOutlet NSArrayController *annotatedPrinciplesArrayController;
}


#pragma mark Accessing Introspectare data
- (INTLibrary *)library;

#pragma mark Managing editing
- (BOOL)commitEditing;
- (void)discardEditing;

@end
