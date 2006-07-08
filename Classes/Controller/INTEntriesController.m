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


@interface INTEntriesController (INTPrivateMethods)

#pragma mark Managing entries
- (void)createEntriesUpToToday;

@end


@implementation INTEntriesController

#pragma mark Initializing

- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"INTEntriesWindowFrame"];
	
	// Attach a date formatter
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[[entriesDateColumn dataCell] setFormatter:dateFormatter];
	[dateFormatter release];
	
	[self createEntriesUpToToday];
	
	NSSortDescriptor *dateDescending = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	[entriesArrayController setSortDescriptors:[NSArray arrayWithObject:dateDescending]];
	[dateDescending release];
	
}



#pragma mark Accessing Introspectare data

- (INTLibrary *)library
{
	return [[INTAppController sharedAppController] library];
}



#pragma mark Managing editing

- (BOOL)commitEditing
{
	return ([annotatedPrinciplesArrayController commitEditing] && [entriesArrayController commitEditing]);
}


- (void)discardEditing
{
	[annotatedPrinciplesArrayController discardEditing];
	[entriesArrayController discardEditing];
}



#pragma mark Managing entries

- (void)createEntriesUpToToday // INTEntriesController (INTPrivateMethods)
{
	if ([[[self library] constitutions] count] > 0)
	{
		// Find oldest constitution creation date
		NSSortDescriptor *dateAscending = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		NSArray *sortedConstitutions = [[[self library] constitutions] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateAscending]];
		NSDate *oldestConstitutionCreationDate = [[sortedConstitutions objectAtIndex:0] creationDate];
		int oldestConstitutionDayOfCommonEra = [[oldestConstitutionCreationDate dateWithCalendarFormat:nil timeZone:nil] dayOfCommonEra];
		int todayDayOfCommonEra = [[NSCalendarDate calendarDate] dayOfCommonEra];
		
		for (int currDay = oldestConstitutionDayOfCommonEra;
			 currDay <= todayDayOfCommonEra;
			 currDay++)
			[[self library] addEntryForDayOfCommonEra:currDay];
		[dateAscending release];
		
		[entriesArrayController rearrangeObjects];
		[entriesArrayController setSelectionIndex:0];
	}
}



#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window // NSObject (NSWindowDelegate)
{
	return [[INTAppController sharedAppController] undoManager];
}


@end
