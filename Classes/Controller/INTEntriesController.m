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


@interface INTEntriesController (INTPrivateMethods)

#pragma mark Managing entries
- (void)createEntriesUpToToday;
- (void)scheduleUpdateTimer;
- (void)updateTimerDidFire:(NSTimer *)timer;

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
	
	NSSortDescriptor *dateDescending = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	[entriesArrayController setSortDescriptors:[NSArray arrayWithObject:dateDescending]];
	[dateDescending release];
	
	[self createEntriesUpToToday];
	[entriesArrayController rearrangeObjects];
	[entriesArrayController setSelectionIndex:0];
	[self scheduleUpdateTimer];
	
	// TODO Temp
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	INTEntriesView *ev = [[INTEntriesView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 500.0f, 500.0f)
													  calendar:gregorianCalendar];
	//[ev setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
	NSScrollView *sv = [[NSScrollView alloc] initWithFrame:[[newEntriesWindow contentView] bounds]];
	[sv setDocumentView:ev];
	[ev release];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:YES];
	[sv setBorderType:NSNoBorder];
	[sv setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
	[[newEntriesWindow contentView] addSubview:sv];
	[sv release];
	[[newEntriesWindow contentView] setAutoresizesSubviews:YES];
	[newEntriesWindow setInitialFirstResponder:ev];
	
	[ev bind:@"entries" toObject:entriesArrayController withKeyPath:@"arrangedObjects" options:nil];
	
	NSButtonCell *dataCell = [[INTCircleSwitchButtonCell alloc] initTextCell:[NSString string]];
	[dataCell setButtonType:NSSwitchButton];
	[ev setDataCell:dataCell];
	[dataCell release];
}


- (void)dealloc
{
	if (INT_updateTimer)
		[INT_updateTimer invalidate], INT_updateTimer = nil;
	
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
	}
}


- (void)scheduleUpdateTimer // INTEntriesController (INTPrivateMethods)
{
	if (INT_updateTimer)
		[INT_updateTimer invalidate];
	INT_updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
	                                                   target:self
	                                                 selector:@selector(updateTimerDidFire:)
	                                                 userInfo:nil
	                                                  repeats:YES];
}


- (void)updateTimerDidFire:(NSTimer *)timer // INTEntriesController (INTPrivateMethods)
{
	[self createEntriesUpToToday];
	[entriesArrayController rearrangeObjects];
}



#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window // NSObject (NSWindowDelegate)
{
	return [[INTAppController sharedAppController] undoManager];
}


@end
