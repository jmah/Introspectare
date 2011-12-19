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


@interface _INTHeaderViewResponder : NSObject

- (NSView *)headerView;

@end


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
	INT_entriesView = [[INTEntriesView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 500.0f, 500.0f)
												   calendar:gregorianCalendar];
	
	[entriesScrollView setDocumentView:INT_entriesView];
	[[self window] makeFirstResponder:INT_entriesView];
	
	[INT_entriesView bind:@"entries" toObject:entriesArrayController withKeyPath:@"arrangedObjects" options:nil];
	
	NSButtonCell *dataCell = [[INTCircleSwitchButtonCell alloc] initTextCell:[NSString string]];
	[INT_entriesView setDataCell:dataCell];
	[dataCell release];
	[INT_entriesView release];
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



#pragma mark Printing

- (void)print:(id)sender
{
	/*
	 * This implementation is currently a little too naive. As each page is
	 * "scrolled" across, the width of the constitution label is not taken
	 * into account, so the left bit of each page is covered up by that label.
	 */
	
	
	NSPrintInfo *info = [[NSPrintInfo sharedPrintInfo] copy];
	
	// Apply required print info settings
	[info setHorizontalPagination:NSAutoPagination];
	[info setVerticalPagination:NSAutoPagination];
	
	// Create a new entries view and enclose it in a scroll view so the header view is correctly laid out
	// Frame size is arbitrary; it will be changed below
	NSScrollView *printScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 200.0f, 200.0f)];
	[printScrollView setHasHorizontalScroller:NO];
	[printScrollView setHasVerticalScroller:NO];
	[printScrollView setBorderType:NSBezelBorder];
	
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	INTEntriesView *printEntriesView = [[INTEntriesView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 500.0f, 500.0f)
												   calendar:gregorianCalendar];
	
	[printScrollView setDocumentView:printEntriesView];
	[printEntriesView release];
	
	[printEntriesView bind:@"entries" toObject:entriesArrayController withKeyPath:@"arrangedObjects" options:nil];
	[printEntriesView setDataCell:[INT_entriesView dataCell]];
	
	// Deselect all entries for printing
	NSIndexSet *selectionIndexes = [[printEntriesView selectionIndexes] copy];
	[printEntriesView setSelectionIndexes:[NSIndexSet indexSet]];
	
	// Calculatate new size of scroll view
	NSSize printScrollViewSize = [NSScrollView frameSizeForContentSize:[printEntriesView minimumFrameSize]
												 hasHorizontalScroller:[printScrollView hasHorizontalScroller]
												   hasVerticalScroller:[printScrollView hasVerticalScroller]
															borderType:[printScrollView borderType]];
	if ([printEntriesView respondsToSelector:@selector(headerView)])
		printScrollViewSize.height += NSHeight([[(_INTHeaderViewResponder *)printEntriesView headerView] frame]);
	[printScrollView setFrameSize:printScrollViewSize];
	
	
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:printScrollView
														  printInfo:info];
	[op runOperation];
	
	[printEntriesView setSelectionIndexes:selectionIndexes];
	[printEntriesView unbind:@"entries"];
	[printScrollView release];
	
	[info release];
}



#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window // NSObject (NSWindowDelegate)
{
	return [[INTAppController sharedAppController] undoManager];
}


@end
