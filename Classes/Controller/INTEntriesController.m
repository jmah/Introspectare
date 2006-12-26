//
//  INTEntriesController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesController.h"
#import "INTShared.h"
#import "INTAppController.h"
#import "INTLibrary.h"
#import "INTConstitution.h"
#import "INTEntry.h"
#import "INTAnnotatedPrinciple.h"
#import "INTPrinciple.h"
#import "INTEntriesView.h"
#import "INTCircleSwitchButtonCell.h"
#import "NSCalendarDate+INTAdditions.h"


@implementation INTEntriesController

#pragma mark Initializing

- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"INTEntriesWindowFrame"];
	
	// Configure inspector panel
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[inspectorDateField setFormatter:dateFormatter];
	[dateFormatter release];
	
	// Configure array controller
	NSSortDescriptor *dateAscending = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	[entriesArrayController setSortDescriptors:[NSArray arrayWithObject:dateAscending]];
	[dateAscending release];
	
	[entriesArrayController rearrangeObjects];
	[entriesArrayController setSelectionIndex:([[entriesArrayController arrangedObjects] count] - 1)];
	
	// Create entries view
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	INTEntriesView *entriesView = [[INTEntriesView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 500.0f, 500.0f)
															   calendar:gregorianCalendar];
	
	[entriesScrollView setDocumentView:entriesView];
	[[self window] makeFirstResponder:entriesView];
	
	[entriesView bind:@"entries" toObject:entriesArrayController withKeyPath:@"arrangedObjects" options:nil];
	
	NSButtonCell *dataCell = [[INTCircleSwitchButtonCell alloc] initTextCell:[NSString string]];
	[entriesView setDataCell:dataCell];
	[dataCell release];
	
	[entriesView release];
}


- (void)dealloc
{
	[super dealloc];
}



#pragma mark Accessing Introspectare data

- (INTLibrary *)library
{
	return [[INTAppController sharedAppController] library];
}



#pragma mark Managing editing

- (BOOL)commitEditing
{
	return [entriesArrayController commitEditing];
}


- (void)discardEditing
{
	[entriesArrayController discardEditing];
}



#pragma mark Managing the inspector panel

- (NSView *)inspectorView
{
	return entryInspectorView;
}



#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window // NSObject (NSWindowDelegate)
{
	return [[INTAppController sharedAppController] undoManager];
}


@end
