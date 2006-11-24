//
//  INTEntriesHeaderView.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-22.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesHeaderView.h"
#import "INTEntriesHeaderView+INTProtectedMethods.h"
#import "INTEntriesView.h"
#import "INTEntriesView+INTProtectedMethods.h"
#import "INTEntriesHeaderCell.h"
#import "INTEntry.h"
#import "INTConstitution.h"


@interface INTEntriesHeaderView (INTPrivateMethods)

#pragma mark Event methods
- (void)mouseDragTimerHit:(NSTimer *)timer;

#pragma mark Drawing
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
		
		INT_headerCell = [[INTEntriesHeaderCell alloc] initTextCell:[NSString string]];
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



#pragma mark Event methods

- (void)mouseDown:(NSEvent *)event // NSResponder
{
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	if (point.y > ([[self entriesView] headerHeight] * 2.0))
	{
	// Track mouse while down
		do
		{
			NSTimer *mouseDragTimer = [NSTimer timerWithTimeInterval:0.04
															  target:self
															selector:@selector(mouseDragTimerHit:)
															userInfo:event
															 repeats:YES];
			[mouseDragTimer fire];
			[[NSRunLoop currentRunLoop] addTimer:mouseDragTimer forMode:NSEventTrackingRunLoopMode];
			
			event = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)];
			[mouseDragTimer invalidate];
		} while ([event type] == NSLeftMouseDragged);
		
		INTEntriesView *ev = [self entriesView];
		if ([[ev selectionIndexes] count] > 0)
			[ev scrollEntryToVisible:[[ev sortedEntries] objectAtIndex:[[ev selectionIndexes] firstIndex]]];
	}
}


- (void)mouseDragTimerHit:(NSTimer *)timer // INTEntriesHeaderView (INTPrivateMethods)
{
	NSEvent *event = (NSEvent *)[timer userInfo];
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	NSIndexSet *newIndexes;
	
	if ((point.y > ([[self entriesView] headerHeight] * 2.0)) && [[self entriesView] entryAtXLocation:point.x])
		newIndexes = [NSIndexSet indexSetWithIndex:[[[self entriesView] sortedEntries] indexOfObject:[[self entriesView] entryAtXLocation:point.x]]];
	else
		newIndexes = [NSIndexSet indexSet];
	
	// Tell the controller to adjust its selection indexes, if there is one
	id observingObject = [[[self entriesView] infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
	if (observingObject)
		[observingObject setValue:newIndexes forKeyPath:[[[self entriesView] infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
	else
		[[self entriesView] setSelectionIndexes:newIndexes];
	
	[self autoscroll:event];
}



#pragma mark Layout

- (float)headerWidthForConstitution:(INTConstitution *)constitution // INTEntriesHeaderView (INTProtectedMethods)
{
	float width = 0.0;
	
	[INT_headerCell setStringValue:NSLocalizedString(@"INTConstitutionHeaderTitle", @"Constitution header title")];
	width = fmaxf(width, [INT_headerCell cellSize].width);
	
	[INT_headerCell setStringValue:[constitution versionLabel]];
	width = fmaxf(width, [INT_headerCell cellSize].width);
	
	return width;
}



#pragma mark Drawing

- (void)drawRect:(NSRect)rect // NSView
{
	float hh = [[self entriesView] headerHeight];
	
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	if ([[[self entriesView] sortedEntries] count] == 0)
	{
		// No entries; just draw filler
		[INT_headerCell setStringValue:[NSString string]];
		NSRect fillerFrame = NSMakeRect(0.0, 0.0, NSWidth([self visibleRect]) + 1.0, hh);
		[INT_headerCell drawWithFrame:fillerFrame inView:self];
		fillerFrame = NSOffsetRect(fillerFrame, 0.0, hh);
		[INT_headerCell drawWithFrame:fillerFrame inView:self];
		fillerFrame = NSOffsetRect(fillerFrame, 0.0, hh);
		[INT_headerCell drawWithFrame:fillerFrame inView:self];
		return;
	}
	
	BOOL isYearInitialized = NO;
	int currYear = 0;
	float currYearMinX = 0.0;
	int currMonth = -1;
	float currMonthMinX = 0.0;
	
	
	INTConstitution *currConstitution = nil;
	float currEntryMaxX = 0.0;
	float currEntryMinX = currEntryMaxX;
	NSEnumerator *entries = [[[self entriesView] sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		const unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
		NSDateComponents *components = [[[self entriesView] calendar] components:unitFlags fromDate:[currEntry date]];
		
		if ([currEntry constitution] != currConstitution)
		{
			currConstitution = [currEntry constitution];
			float constitutionMinX = currEntryMaxX;
			float constitutionWidth = [[self entriesView] widthForConstitution:currConstitution] + [[self entriesView] intercellSpacing].width;
			float prevEntryMaxX = currEntryMaxX;
			currEntryMaxX += constitutionWidth;
			
			if (((constitutionMinX + constitutionWidth) >= NSMinX(rect)) || (constitutionMinX <= NSMaxX(rect)))
			{
				// Constitution is on-screen
				NSRect constitutionFrame = NSMakeRect(constitutionMinX, hh, constitutionWidth, hh);
				[INT_headerCell setStringValue:NSLocalizedString(@"INTConstitutionHeaderTitle", @"Constitution header title")];
				[INT_headerCell drawWithFrame:constitutionFrame inView:self];
				
				NSRect labelFrame = NSOffsetRect(constitutionFrame, 0.0, hh);
				[INT_headerCell setStringValue:[currConstitution versionLabel]];
				[INT_headerCell drawWithFrame:labelFrame inView:self];
				
				[NSGraphicsContext saveGraphicsState];
				[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusDarker];
				[[[NSColor blackColor] colorWithAlphaComponent:0.6] set];
				[NSBezierPath fillRect:NSUnionRect(constitutionFrame, labelFrame)];
				[NSGraphicsContext restoreGraphicsState];
			}
			
			// Break the month header
			if (currMonth != -1)
			{
				float monthWidth = prevEntryMaxX - currMonthMinX;
				NSRect monthCellFrame = NSMakeRect(currMonthMinX, hh, monthWidth, hh);
				[self drawMonth:currMonth withHintedFrame:monthCellFrame];
				currMonth = [components month];
				currMonthMinX += monthWidth + constitutionWidth;
			}
		}
		
		currEntryMinX = currEntryMaxX;
		currEntryMaxX += [[self entriesView] columnWidth] + [[self entriesView] intercellSpacing].width;
		
		if (currMonth == -1)
		{
			currMonth = [components month];
			currMonthMinX = currEntryMinX;
		}
		
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
			[INT_headerCell setStringValue:[self yearAsString:currYear]];
			[INT_headerCell drawWithFrame:yearCellFrame inView:self];
			currYear = [components year];
			currYearMinX += yearWidth;
		}
		
		if ([components month] != currMonth)
		{
			float monthWidth = currEntryMinX - currMonthMinX;
			NSRect monthCellFrame = NSMakeRect(currMonthMinX, hh, monthWidth, hh);
			[self drawMonth:currMonth withHintedFrame:monthCellFrame];
			currMonth = [components month];
			currMonthMinX += monthWidth;
		}
		
		float entryWidth = currEntryMaxX - currEntryMinX;
		NSRect entryCellFrame = NSMakeRect(currEntryMinX, hh * 2.0, entryWidth, hh);
		[INT_headerCell setStringValue:[self dayAsString:[components day]]];
		[INT_headerCell drawWithFrame:entryCellFrame inView:self];
		
		if ([currEntry isUnread])
		{
			[NSGraphicsContext saveGraphicsState];
			[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusDarker];
			[[[NSColor yellowColor] colorWithAlphaComponent:0.6] set];
			[NSBezierPath fillRect:entryCellFrame];
			[NSGraphicsContext restoreGraphicsState];
		}
		else if ([[currEntry note] length] > 0)
		{
			[NSGraphicsContext saveGraphicsState];
			[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusDarker];
			[[[NSColor greenColor] colorWithAlphaComponent:0.3] set];
			[NSBezierPath fillRect:entryCellFrame];
			[NSGraphicsContext restoreGraphicsState];
		}
	}
	
	
	// Draw final month and year cells
	// Add one pixel to the width to avoid drawing the right divider bar
	float yearWidth = NSMaxX([self visibleRect]) - currYearMinX;
	NSRect yearCellFrame = NSMakeRect(currYearMinX, 0.0, yearWidth + 1.0, hh);
	if (!NSIsEmptyRect(yearCellFrame))
	{
		[INT_headerCell setStringValue:[self yearAsString:currYear]];
		[INT_headerCell drawWithFrame:yearCellFrame inView:self];
	}
	
	float monthWidth = currEntryMaxX - currMonthMinX;
	NSRect monthCellFrame = NSMakeRect(currMonthMinX, hh, monthWidth + 1.0, hh);
	if (!NSIsEmptyRect(monthCellFrame))
		[self drawMonth:currMonth withHintedFrame:monthCellFrame];
	
	// Fill any empty space on the right
	[INT_headerCell setStringValue:[NSString string]];
	NSRect monthFillerFrame = NSMakeRect(currEntryMaxX, hh, NSWidth([self visibleRect]) - currEntryMaxX + 1.0, hh);
	if (!NSIsEmptyRect(monthFillerFrame))
		[INT_headerCell drawWithFrame:monthFillerFrame inView:self];
	NSRect entryFillerFrame = NSOffsetRect(monthFillerFrame, 0.0, hh);
	if (!NSIsEmptyRect(entryFillerFrame))
		[INT_headerCell drawWithFrame:entryFillerFrame inView:self];
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
	[INT_headerCell drawWithFrame:realFrame inView:self];
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
