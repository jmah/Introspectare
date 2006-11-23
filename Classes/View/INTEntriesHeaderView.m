//
//  INTEntriesHeaderView.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-22.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesHeaderView.h"
#import "INTEntriesView.h"
#import "INTEntriesView+INTProtectedMethods.h"
#import "INTLibrary.h"
#import "INTEntry.h"


@interface INTEntriesHeaderView (INTPrivateMethods)

#pragma mark Drawing
- (void)drawHeaderString:(NSString *)string inFrame:(NSRect)frame;
- (void)drawMonth:(int)month withHintedFrame:(NSRect)frame;

#pragma mark Displaying date components
- (NSString *)yearAsString:(int)year;
- (NSString *)monthAsString:(int)month;
- (NSString *)dayAsString:(int)day;

@end


#pragma mark -


@implementation INTEntriesHeaderView

#pragma mark Creating an entries header view

- (id)initWithFrame:(NSRect)frame entriesView:(INTEntriesView *)entriesView // Designated initializer
{
	if ((self = [super initWithFrame:frame]))
	{
		INT_entriesView = entriesView;
		
		[entriesView addObserver:self
					  forKeyPath:@"columnWidth"
						 options:NSKeyValueObservingOptionNew
						 context:NULL];
		[entriesView addObserver:self
					  forKeyPath:@"headerFont"
						 options:NSKeyValueObservingOptionNew
						 context:NULL];
		
		INT_headerCell = [[NSTableHeaderCell alloc] initTextCell:[NSString string]];
		[INT_headerCell setFont:[[self entriesView] headerFont]];
		[INT_headerCell setAlignment:NSCenterTextAlignment];
		[INT_headerCell setLineBreakMode:NSLineBreakByTruncatingTail];
		
		INT_dateFormatter = [[NSDateFormatter alloc] init];
		[INT_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[INT_dateFormatter setDateStyle:NSDateFormatterLongStyle];
	}
	return self;
}


- (void)dealloc
{
	[INT_headerCell release], INT_headerCell = nil;
	
	[INT_entriesView removeObserver:self
						 forKeyPath:@"columnWidth"];
	[INT_entriesView removeObserver:self
						 forKeyPath:@"headerFont"];
	
	[INT_dateFormatter release], INT_dateFormatter = nil;
	
	[super dealloc];
}



#pragma mark Getting the entries view

- (INTEntriesView *)entriesView
{
	return INT_entriesView;
}



#pragma mark Change notification

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	BOOL handled = NO;
	if (object == [self entriesView])
	{
		if ([keyPath isEqualToString:@"columnWidth"])
		{
			[self setNeedsDisplay:YES];
			handled = YES;
		}
		else if ([keyPath isEqualToString:@"headerFont"])
		{
			[INT_headerCell setFont:[change objectForKey:NSKeyValueChangeNewKey]];
			[self setNeedsDisplay:YES];
			handled = YES;
		}
	}
	if (!handled)
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



#pragma mark Managing the view hierarchy

- (void)viewDidMoveToSuperview // NSView
{
	if ([[self superview] isKindOfClass:[NSClipView class]])
	{
		NSClipView *cv = (NSClipView *)[self superview];
		[cv setCopiesOnScroll:NO];
	}
}



#pragma mark Examining coordinate system modifications

- (BOOL)isFlipped // NSView
{
	return YES;
}



#pragma mark Managing live resize

- (void)viewDidEndLiveResize // NSView
{
	[self setNeedsDisplay:YES];
}



#pragma mark Drawing

- (void)drawRect:(NSRect)rect // NSView
{
	float hh = [[self entriesView] headerHeight];
	
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	if ([[[self entriesView] sortedEntries] count] == 0)
		return;
	
	BOOL isYearInitialized = NO;
	int currYear = 0;
	float currYearMinX = 0.0;
	int currMonth = -1;
	float currMonthMinX = 0.0;
	
	
	float currEntryMaxX = 0.0;
	float currEntryMinX = currEntryMaxX;
	NSEnumerator *entries = [[[self entriesView] sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		currEntryMinX = currEntryMaxX;
		currEntryMaxX += [[self entriesView] columnWidth] + [[self entriesView] intercellSpacing].width;
		
		const unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
		NSDateComponents *components = [[[self entriesView] calendar] components:unitFlags fromDate:[currEntry date]];
		if (currMonth == -1)
			// Run once
			currMonth = [components month];
		
		if (currEntryMaxX < NSMinX([self visibleRect]))
		{
			// Entry is off-screen to left
			// Keep track of beginning of current month to keep it quasi-centered
			if (currMonth != [components month])
			{
				currMonth = [components month];
				currMonthMinX = currEntryMinX;
			}
			continue;
		}
		if (currEntryMinX > NSMaxX([self visibleRect]))
		{
			// Entry is off-screen to right
			// Find end of current month to keep it quasi-centered
			if (currMonth == [components month])
				continue;
			else
			{
				currEntryMaxX = currEntryMinX;
				break;
			}
		}
		
		// Current entry is on-screen
		if (!isYearInitialized)
		{
			// Run once
			isYearInitialized = YES;
			currYear = [components year];
			currYearMinX = NSMinX([self visibleRect]);
		}
		
		if ([components year] != currYear)
		{
			float yearWidth = currEntryMinX - currYearMinX;
			NSRect yearCellFrame = NSMakeRect(currYearMinX, 0.0, yearWidth, hh);
			[self drawHeaderString:[self yearAsString:currYear] inFrame:yearCellFrame];
			currYear = [components year];
			currYearMinX = currEntryMinX;
		}
		
		if ([components month] != currMonth)
		{
			float monthWidth = currEntryMinX - currMonthMinX;
			NSRect monthCellFrame = NSMakeRect(currMonthMinX, hh, monthWidth, hh);
			[self drawMonth:currMonth withHintedFrame:monthCellFrame];
			currMonth = [components month];
			currMonthMinX = currEntryMinX;
		}
		
		float entryWidth = currEntryMaxX - currEntryMinX;
		NSRect entryCellFrame = NSMakeRect(currEntryMinX, hh * 2.0, entryWidth, hh);
		[self drawHeaderString:[self dayAsString:[components day]] inFrame:entryCellFrame];
		
		if ([currEntry isUnread])
		{
			[NSGraphicsContext saveGraphicsState];
			[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusDarker];
			[[[NSColor yellowColor] colorWithAlphaComponent:0.6] set];
			[NSBezierPath fillRect:entryCellFrame];
			[NSGraphicsContext restoreGraphicsState];
		}
	}
	
	
	// Draw final month and year cells
	// Add one pixel to the width to avoid drawing the right divider bar
	float yearWidth = NSMaxX([self visibleRect]) - currYearMinX;
	NSRect yearCellFrame = NSMakeRect(currYearMinX, 0.0, yearWidth + 1.0, hh);
	if (!NSIsEmptyRect(yearCellFrame))
		[self drawHeaderString:[self yearAsString:currYear] inFrame:yearCellFrame];
	
	float monthWidth = currEntryMaxX - currMonthMinX;
	NSRect monthCellFrame = NSMakeRect(currMonthMinX, hh, monthWidth + 1.0, hh);
	if (!NSIsEmptyRect(monthCellFrame))
		[self drawMonth:currMonth withHintedFrame:monthCellFrame];
	
	// Fill any empty space on the right
	NSRect monthFillerFrame = NSMakeRect(currEntryMaxX, hh, NSWidth([self visibleRect]) - currEntryMaxX + 1.0, hh);
	if (!NSIsEmptyRect(monthFillerFrame))
		[self drawHeaderString:@"" inFrame:monthFillerFrame];
	NSRect entryFillerFrame = NSOffsetRect(monthFillerFrame, 0.0, hh);
	if (!NSIsEmptyRect(entryFillerFrame))
		[self drawHeaderString:@"" inFrame:entryFillerFrame];
}



- (void)drawHeaderString:(NSString *)string inFrame:(NSRect)frame // INTEntriesHeaderView (INTPrivateMethods)
{
	[NSGraphicsContext saveGraphicsState];
	// NSTableHeaderCell likes to draw below it should, so we'll clip it
	[NSBezierPath clipRect:frame];
	[INT_headerCell setStringValue:string];
	[INT_headerCell drawWithFrame:frame inView:self];
	[NSGraphicsContext restoreGraphicsState];
}



- (void)drawMonth:(int)month withHintedFrame:(NSRect)frame // INTEntriesHeaderView (INTPrivateMethods)
{
	NSRect realFrame = frame;
	NSString *monthString = [self monthAsString:month];
	[INT_headerCell setStringValue:monthString];
	float textWidth = [INT_headerCell cellSize].width;
	
	// Calculate text frame
	NSRect textFrame = NSInsetRect(frame, (NSWidth(frame) - textWidth) / 2.0, 0.0);
	
	if (textWidth < NSWidth(NSIntersectionRect([self visibleRect], frame)))
	{
		if (!NSContainsRect([self visibleRect], textFrame))
		{
			if (NSMinX(textFrame) < NSMinX([self visibleRect]))
			{
				float xShift = (NSMinX([self visibleRect]) - NSMinX(textFrame)) * 2.0;
				realFrame.origin.x += xShift;
				realFrame.size.width -= xShift;
			}
			else
				realFrame.size.width -= (NSMaxX(textFrame) - NSMaxX([self visibleRect])) * 2.0;
		}
	}
	else
		realFrame = NSIntersectionRect([self visibleRect], frame);
	[self drawHeaderString:monthString inFrame:realFrame];
}


- (BOOL)wantsDefaultClipping // NSView
{
	return NO;
}



#pragma mark Displaying

- (BOOL)isOpaque // NSView
{
	return YES;
}



#pragma mark Displaying date components

- (NSString *)yearAsString:(int)year // INTEntriesHeaderView (INTPrivateMethods)
{
	return [NSString stringWithFormat:@"%d", year];
}


- (NSString *)monthAsString:(int)month // INTEntriesHeaderView (INTPrivateMethods)
{
	return [[INT_dateFormatter monthSymbols] objectAtIndex:(month - 1)];
}


- (NSString *)dayAsString:(int)day // INTEntriesHeaderView (INTPrivateMethods)
{
	return [NSString stringWithFormat:@"%d", day];
}


@end
