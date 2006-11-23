//
//  INTEntriesView.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-21.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesView.h"
#import "INTEntriesView+INTProtectedMethods.h"
#import "INTLibrary.h"
#import "INTEntry.h"
#import "INTConstitution.h"
#import "INTEntriesHeaderView.h"
#import "INTEntriesCornerView.h"


@interface INTEntriesView (INTPrivateMethods)

#pragma mark Managing entries
- (void)cacheSortedEntries;

#pragma mark Getting auxiliary views for enclosing an scroll view
- (NSView *)headerView;
- (NSView *)cornerView;

#pragma mark Displaying
- (void)updateFrameSize;

@end


#pragma mark -


@implementation INTEntriesView

#pragma mark Creating an entries view

- (id)initWithFrame:(NSRect)frame library:(INTLibrary *)library
{
	return [self initWithFrame:frame library:library calendar:[NSCalendar currentCalendar]];
}


- (id)initWithFrame:(NSRect)frame library:(INTLibrary *)library calendar:(NSCalendar *)calendar // Designated initializer
{
	if ((self = [super initWithFrame:frame]))
	{
		if (![calendar isEqual:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]])
		{
			[self release];
			[NSException raise:NSInvalidArgumentException format:@"INTEntriesView only supports Gregorian calendars"];
			return nil;
		}
		
		INT_library = [library retain];
		INT_calendar = [calendar retain];
		INT_rowHeight = 20.0;
		INT_headerHeight = 16.0;
		INT_columnWidth = 22.0;
		INT_headerFont = [NSFont fontWithName:@"Lucida Grande" size:11.0];
		INT_principleFont = [NSFont fontWithName:@"Lucida Grande" size:13.0];
		
		NSRect headerFrame = NSMakeRect(0.0, 0.0, NSWidth(frame), 3.0 * [self headerHeight]);
		INT_headerView = [[INTEntriesHeaderView alloc] initWithFrame:headerFrame
														 entriesView:self];
		
		NSRect cornerFrame = NSMakeRect(0.0, 0.0, 20.0, NSHeight(headerFrame));
		INT_cornerView = [[INTEntriesCornerView alloc] initWithFrame:cornerFrame
														 entriesView:self];
		[self cacheSortedEntries];
		[self updateFrameSize];
		
		[library addObserver:self
				  forKeyPath:@"entries"
					 options:0
					 context:NULL];
	}
	return self;
}


- (void)awakeFromNib
{
	
}


- (void)dealloc
{
	[INT_library removeObserver:self
					 forKeyPath:@"entries"];
	
	[INT_library release], INT_library = nil;
	[INT_calendar release], INT_calendar = nil;
	[INT_headerFont release], INT_headerFont = nil;
	[INT_principleFont release], INT_principleFont = nil;
	[INT_headerView release], INT_headerView = nil;
	[INT_cornerView release], INT_cornerView = nil;
	[INT_cachedSortedEntries release], INT_cachedSortedEntries = nil;
	
	[super dealloc];
}



#pragma mark Getting the calendar

- (NSCalendar *)calendar
{
	return INT_calendar;
}



#pragma mark Getting the library

- (INTLibrary *)library
{
	return INT_library;
}



#pragma mark Setting display attributes

- (float)rowHeight
{
	return INT_rowHeight;
}


- (void)setRowHeight:(float)rowHeight
{
	INT_rowHeight = rowHeight;
	[[self enclosingScrollView] setVerticalLineScroll:rowHeight];
	[self setNeedsDisplay:YES];
}


- (float)headerHeight
{
	return INT_headerHeight;
}


- (float)columnWidth
{
	return INT_columnWidth;
}


- (void)setColumnWidth:(float)columnWidth
{
	INT_columnWidth = columnWidth;
	[[self enclosingScrollView] setHorizontalLineScroll:columnWidth];
	[self setNeedsDisplay:YES];
}


- (NSFont *)headerFont
{
	return INT_headerFont;
}


- (void)setHeaderFont:(NSFont *)headerFont
{
	id oldValue = INT_headerFont;
	INT_headerFont = [headerFont retain];
	[oldValue release];
	[self setNeedsDisplay:YES];
}


- (NSFont *)principleFont
{
	return INT_principleFont;
}


- (void)setPrincipleFont:(NSFont *)principleFont
{
	id oldValue = INT_principleFont;
	INT_principleFont = [principleFont retain];
	[oldValue release];
	[self setNeedsDisplay:YES];
}



#pragma mark Change notification

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	BOOL handled = NO;
	if (object == [self library])
	{
		if ([keyPath isEqualToString:@"entries"])
		{
			[self cacheSortedEntries];
			[self updateFrameSize];
			[self setNeedsDisplay:YES];
			handled = YES;
		}
	}
	if (!handled)
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



#pragma mark Managing entries

- (void)cacheSortedEntries // INTEntriesView (INTPrivateMethods)
{
	NSSortDescriptor *dateAscending = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	[INT_cachedSortedEntries release];
	INT_cachedSortedEntries = [[[[[self library] entries] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateAscending]] retain];
	[dateAscending release];
}


- (NSArray *)sortedEntries // INTEntriesView (INTProtectedMethods)
{
	return INT_cachedSortedEntries;
}



#pragma mark Managing the view hierarchy

- (void)viewDidMoveToSuperview
{
	NSScrollView *sv = [self enclosingScrollView];
	if (sv)
	{
		[sv setHorizontalLineScroll:[self columnWidth]];
		[sv setVerticalLineScroll:[self rowHeight]];
		[[sv contentView] setCopiesOnScroll:NO];
	}
	else
		NSLog(@"The INTEntriesView expects to be enclosed in an NSScrollView");
}



#pragma mark Displaying

- (void)updateFrameSize // INTEntriesView (INTPrivateMethods)
{
	// TODO Temp constant
	[self setFrameSize:NSMakeSize([[self sortedEntries] count] * [self columnWidth], 100.0)];
}



#pragma mark Drawing the entries view

- (void)drawRect:(NSRect)rect
{
	[[NSColor greenColor] set];
	NSRectFill(rect);
	[[NSColor redColor] set];
	NSRectFill(NSInsetRect([self bounds], 10.0, 10.0));
	
	[[NSColor blueColor] set];
	NSRectFill(NSMakeRect(NSMinX([self visibleRect]), 0.0, 100.0, NSHeight([self bounds])));
}



#pragma mark Examining coordinate system modifications

- (BOOL)isFlipped
{
	return YES;
}



#pragma mark Getting auxiliary views for enclosing an scroll view

- (NSView *)headerView // INTEntriesView (INTPrivateMethods)
{
	return INT_headerView;
}


- (NSView *)cornerView // INTEntriesView (INTPrivateMethods)
{
	return INT_cornerView;
}


@end
