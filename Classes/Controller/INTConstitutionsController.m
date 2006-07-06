//
//  INTConstitutionsController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTConstitutionsController.h"


@implementation INTConstitutionsController

#pragma mark Initializing and deallocating

- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"INTConstitutionsWindowFrame"];
	
	// Attach a date formatter
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[[constitutionDateColumn dataCell] setFormatter:dateFormatter];
	[constitutionInspectorDateField setFormatter:dateFormatter];
	[principleInspectorDateField setFormatter:dateFormatter];
	[dateFormatter release];
}



#pragma mark Persistence

- (NSManagedObjectContext *)managedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}



#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window // NSObject (NSWindowDelegate)
{
	return [[self managedObjectContext] undoManager];
}


@end
