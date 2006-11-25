//
//  INTEntriesCornerView.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-22.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesCornerView.h"
#import "INTEntriesView.h"


@implementation INTEntriesCornerView

#pragma mark Creating an entries header view

- (id)initWithFrame:(NSRect)frame entriesView:(INTEntriesView *)entriesView // Designated initializer
{
	if ((self = [super initWithFrame:frame]))
	{
		INT_entriesView = entriesView;
		INT_cornerCell = [[NSTableHeaderCell alloc] initTextCell:[NSString string]];
	}
	return self;
}


- (void)dealloc
{
	[INT_cornerCell release], INT_cornerCell = nil;
	
	[super dealloc];
}



#pragma mark Getting the entries view

- (INTEntriesView *)entriesView
{
	return INT_entriesView;
}



#pragma mark Examining coordinate system modifications

- (BOOL)isFlipped // NSView
{
	return YES;
}



#pragma mark Drawing

- (void)drawRect:(NSRect)rect // NSView
{
	float hh = [[self entriesView] headerHeight];
	
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	NSRect cornerRect = NSMakeRect(NSMinX([self bounds]), NSMinY([self bounds]), NSWidth([self bounds]), hh);
	[INT_cornerCell drawWithFrame:cornerRect inView:self];
	
	cornerRect = NSOffsetRect(cornerRect, 0.0f, hh);
	[INT_cornerCell drawWithFrame:cornerRect inView:self];
	
	cornerRect = NSOffsetRect(cornerRect, 0.0f, hh);
	[INT_cornerCell drawWithFrame:cornerRect inView:self];
}



#pragma mark Displaying

- (BOOL)isOpaque // NSView
{
	return YES;
}


@end
