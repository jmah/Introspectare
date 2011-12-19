//
//  INTConstitutionsController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTConstitutionsController.h"
#import "INTShared.h"
#import "INTAppController.h"
#import "INTLibrary.h"
#import "INTConstitution.h"
#import "INTActiveControlEnumerator.h"


#pragma mark Pasteboard data types
static NSString *INTPrincipleIndexSetDataType = @"INTPrincipleIndexSetDataType";


#pragma mark -


@interface INTConstitutionsController (INTPrivateMethods)

#pragma mark Managing the inspector panel
- (void)setInspectorView:(NSView *)inspectorView;
- (void)windowDidUpdate:(NSNotification *)notification;

@end


@implementation INTConstitutionsController

#pragma mark Initializing

- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"INTConstitutionsWindowFrame"];
	
	// Watch window to update inspector
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidUpdate:)
												 name:NSWindowDidUpdateNotification
											   object:[self window]];
	
	// Attach a date formatter
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[[constitutionsDateColumn dataCell] setFormatter:dateFormatter];
	[constitutionInspectorDateField setFormatter:dateFormatter];
	[principleInspectorDateField setFormatter:dateFormatter];
	[dateFormatter release];
	
	// Set up principle dragging
	[constitutionsTableView registerForDraggedTypes:[NSArray arrayWithObject:INTPrincipleArrayDataType]];
	[principlesTableView registerForDraggedTypes:[NSArray arrayWithObjects:INTPrincipleArrayDataType, INTPrincipleIndexSetDataType, nil]];
	
	// Sort constitutions by date
	NSSortDescriptor *dateDescending = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	[constitutionsArrayController setSortDescriptors:[NSArray arrayWithObject:dateDescending]];
	[dateDescending release];
	
	[constitutionsArrayController setSelectionIndex:0];
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidUpdateNotification
												  object:[self window]];
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
	return ([principlesArrayController commitEditing] && [constitutionsArrayController commitEditing]);
}


- (void)discardEditing
{
	[principlesArrayController discardEditing];
	[constitutionsArrayController discardEditing];
}



#pragma mark UI actions

- (IBAction)addConstitution:(id)sender
{
	[constitutionsArrayController add:sender];
	[[self window] makeFirstResponder:constitutionsTableView];
	[[INTAppController sharedAppController] showInspector:self];
}


- (IBAction)addPrinciple:(id)sender
{
	[principlesArrayController add:sender];
	[[self window] makeFirstResponder:principlesTableView];
	[[INTAppController sharedAppController] showInspector:self];
}



#pragma mark Managing the inspector panel

- (NSView *)inspectorView
{
	return INT_currInspectorView;
}


- (void)setInspectorView:(NSView *)inspectorView // INTConstitutionsController (INTPrivateMethods)
{
	INT_currInspectorView = inspectorView;
}


- (void)windowDidUpdate:(NSNotification *)notification // INTConstitutionsController (INTPrivateMethods)
{
	NSResponder *currFirstResponder = [[self window] firstResponder];
	if (INT_previousFirstResponder != currFirstResponder)
	{
		INT_previousFirstResponder = currFirstResponder;
		
		// Update inspector view
		NSView *newInspectorView = nil;
		
		NSEnumerator *activeControlEnum = [[self window] activeControlEnumerator];
		NSResponder *currResponder;
		while (!newInspectorView && (currResponder = [activeControlEnum nextObject]))
		{
			if (currResponder == principlesTableView)
				newInspectorView = principleInspectorView;
			else if (currResponder == constitutionsTableView)
				newInspectorView = constitutionInspectorView;
		}
		
		[self setInspectorView:newInspectorView];
	}
}



#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window // NSObject (NSWindowDelegate)
{
	return [[INTAppController sharedAppController] undoManager];
}



#pragma mark NSTableViewDataSource methods

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	BOOL success = NO;
	if (tableView == principlesTableView)
	{
		// Copy both the principles, and the selected indexes (for reordering) to the pasteboard
		[pboard declareTypes:[NSArray arrayWithObjects:INTPrincipleIndexSetDataType, INTPrincipleArrayDataType, nil] owner:self];
		
		NSArray *principleArray = [[principlesArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
		NSData *principleArrayData = [NSKeyedArchiver archivedDataWithRootObject:principleArray];
		[pboard setData:principleArrayData forType:INTPrincipleArrayDataType];
		
		NSData *draggedIndexData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
		[pboard setData:draggedIndexData forType:INTPrincipleIndexSetDataType];
		success = YES;
	}
	return success;
}


- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	NSDragOperation dragOperation = NSDragOperationNone;
	if (tableView == principlesTableView)
	{
		// Don't allow dropping on another principle
		[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
		if ([info draggingSource] == tableView)
			dragOperation = NSDragOperationMove;
		else
			dragOperation = NSDragOperationCopy;
	}
	else if (tableView == constitutionsTableView)
	{
		// Only allow drop on on a constitution
		if (operation == NSTableViewDropOn)
			dragOperation = NSDragOperationCopy;
	}
	return dragOperation;
}


- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	BOOL success = NO;
	NSPasteboard *pboard = [info draggingPasteboard];
	if (tableView == principlesTableView)
	{
		if ([info draggingSource] == principlesTableView)
		{
			// Reorder principles
			NSData *movedPrincipleData = [pboard dataForType:INTPrincipleIndexSetDataType];
			NSIndexSet *movedPrincipleIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:movedPrincipleData];
			
			// Move principles from old indexes to (row)
			NSArray *principles = [[principlesArrayController arrangedObjects] objectsAtIndexes:movedPrincipleIndexes];
			[principlesArrayController removeObjectsAtArrangedObjectIndexes:movedPrincipleIndexes];
			
			// Removing the principles changes the insertion row
			unsigned int countOfRemovedObjectsAboveRow = 0;
			unsigned int currIndex = row;
			while ((currIndex = [movedPrincipleIndexes indexLessThanIndex:currIndex]) != NSNotFound)
				countOfRemovedObjectsAboveRow++;
			
			// Insert the principles back in at the new location
			NSEnumerator *principleEnum = [principles objectEnumerator];
			INTPrinciple *currPrinciple;
			unsigned int insertionIndex = row - countOfRemovedObjectsAboveRow;
			while ((currPrinciple = [principleEnum nextObject]))
				[principlesArrayController insertObject:currPrinciple
								  atArrangedObjectIndex:insertionIndex++];
			[principlesArrayController setSelectedObjects:principles];
			success = YES;
		}
		else
		{
			// Insert principles into array
			NSData *newPrincipleArrayData = [pboard dataForType:INTPrincipleArrayDataType];
			NSArray *newPrincipleArray = [NSKeyedUnarchiver unarchiveObjectWithData:newPrincipleArrayData];
			NSEnumerator *newPrincipleEnum = [newPrincipleArray objectEnumerator];
			INTPrinciple *newPrinciple;
			unsigned int insertionIndex = MAX(row, 0); // If no objects are in the table, row is -1
			while ((newPrinciple = [newPrincipleEnum nextObject]))
				if (![[principlesArrayController arrangedObjects] containsObject:newPrinciple])
					[principlesArrayController insertObject:newPrinciple
									  atArrangedObjectIndex:insertionIndex++];
			[principlesArrayController setSelectedObjects:newPrincipleArray];
			success = YES;
		}
	}
	else if (tableView == constitutionsTableView)
	{
		INTConstitution *constitution = [[constitutionsArrayController arrangedObjects] objectAtIndex:row];
		NSMutableArray *principles = [[constitution principles] mutableCopy];
		
		NSData *newPrincipleArrayData = [pboard dataForType:INTPrincipleArrayDataType];
		NSArray *newPrincipleArray = [NSKeyedUnarchiver unarchiveObjectWithData:newPrincipleArrayData];
		NSEnumerator *newPrincipleEnum = [newPrincipleArray objectEnumerator];
		INTPrinciple *newPrinciple;
		while ((newPrinciple = [newPrincipleEnum nextObject]))
			if (![principles containsObject:newPrinciple])
				[principles addObject:newPrinciple];
		
		[constitution setPrinciples:principles];
		[principles release];
		success = YES;
	}
	return success;
}


@end
