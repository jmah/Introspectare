//
//  INTPrincipleLibraryController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTPrincipleLibraryController.h"


@implementation INTPrincipleLibraryController

#pragma mark Initializing and deallocating

- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"INTPrincipleLibaryWindowFrame"];
	
	// Attach a date formatter
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[[dateColumn dataCell] setFormatter:dateFormatter];
	[inspectorDateField setFormatter:dateFormatter];
	[dateFormatter release];
}



#pragma mark Persistence

- (NSManagedObjectContext *)managedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}


@end
