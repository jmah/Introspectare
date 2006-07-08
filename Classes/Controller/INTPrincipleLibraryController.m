//
//  INTPrincipleLibraryController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTPrincipleLibraryController.h"
#import "INTShared.h"
#import "INTAppController.h"
#import "INTLibrary.h"


@implementation INTPrincipleLibraryController

#pragma mark Initializing

- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"INTPrincipleLibaryWindowFrame"];
	
	// Attach a date formatter
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[[dateColumn dataCell] setFormatter:dateFormatter];
	[inspectorDateField setFormatter:dateFormatter];
	[dateFormatter release];
}



#pragma mark Accessing Introspectare data

- (INTLibrary *)library
{
	return [[INTAppController sharedAppController] library];
}



#pragma mark Managing editing

- (BOOL)commitEditing
{
	return [principlesArrayController commitEditing];
}


- (void)discardEditing
{
	[principlesArrayController discardEditing];
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
	if (tableView == principleLibraryTableView)
	{
		NSArray *principleArray = [[principlesArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
		NSData *principleArrayData = [NSKeyedArchiver archivedDataWithRootObject:principleArray];
		[pboard declareTypes:[NSArray arrayWithObject:INTPrincipleArrayDataType] owner:self];
		[pboard setData:principleArrayData forType:INTPrincipleArrayDataType];
		success = YES;
	}
	return success;
}


@end
