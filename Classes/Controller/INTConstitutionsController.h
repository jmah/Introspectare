//
//  INTConstitutionsController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface INTConstitutionsController : NSWindowController
{
	@public
	IBOutlet NSView *constitutionInspectorView;
	IBOutlet NSView *principleInspectorView;
	IBOutlet NSTableColumn *constitutionDateColumn;
	IBOutlet NSTextField *constitutionInspectorDateField;
	IBOutlet NSTextField *principleInspectorDateField;
}


#pragma mark Core Data
- (NSManagedObjectContext *)managedObjectContext;

@end
