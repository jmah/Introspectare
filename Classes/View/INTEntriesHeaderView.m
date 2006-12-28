//
//  INTEntriesHeaderView.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-22.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesHeaderView.h"
#import "INTEntriesHeaderView+INTProtectedMethods.h"
#import "NSIndexSet+INTAdditions.h"
#import "INTEntriesView.h"
#import "INTEntriesView+INTProtectedMethods.h"
#import "INTEntriesHeaderCell.h"
#import "INTEntry.h"
#import "INTConstitution.h"
#import "INTAppController.h"
#import "INTAppController+INTSyncServices.h"


@interface INTEntriesHeaderView (INTPrivateMethods)

#pragma mark Drawing
- (void)drawMonth:(int)month withHintedFrame:(NSRect)frame;
- (NSRect)visibleRectExcludingConstitutionLabelExtraWidth;

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
		
		INT_constitutionLabelExtraWidth = 0.0f;
		INT_toolTipStrings = [[NSMutableArray alloc] init];
	}
	return self;
}


- (void)dealloc
{
	[INT_entriesView removeObserver:self
						 forKeyPath:@"columnWidth"];
	[INT_entriesView removeObserver:self
						 forKeyPath:@"headerFont"];
	
	[INT_headerCell release], INT_headerCell = nil;
	[INT_dateFormatter release], INT_dateFormatter = nil;
	[INT_toolTipStrings release], INT_toolTipStrings = nil;
	
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
	if ((point.x - NSMinX([self visibleRect])) < INT_constitutionLabelExtraWidth)
		// Click is in the constitution label; do nothing
		return;
	else if (point.y > ([[self entriesView] headerHeight] * 2.0f))
	{
		INTEntriesView *ev = [self entriesView];
		
		BOOL shouldSelectRange = ([event modifierFlags] & NSShiftKeyMask) != 0;
		BOOL shouldExtendSelection = ([event modifierFlags] & NSCommandKeyMask) != 0;
		
		id observedObject = [[ev infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
		unsigned firstIndex = NSNotFound;
		if (!shouldSelectRange && !shouldExtendSelection)
		{
			if (observedObject)
				[observedObject setValue:[NSIndexSet indexSet] forKeyPath:[[ev infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
			else
				[ev setSelectionIndexes:[NSIndexSet indexSet]];
		}
		
		NSIndexSet *originalIndexes = [[[ev selectionIndexes] copy] autorelease];
		[ev setEventTrackingSelection:YES];
		NSEvent *lastNonPeriodicEvent = event;
		[NSEvent startPeriodicEventsAfterDelay:0.2f withPeriod:0.05f];
		do
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			unsigned currIndex = NSNotFound;
			NSIndexSet *newIndexes;
			
			if ([ev entryAtXLocation:point.x])
				currIndex = [[ev sortedEntries] indexOfObject:[ev entryAtXLocation:point.x]];
			
			if (firstIndex == NSNotFound)
				firstIndex = currIndex;
			
			if (currIndex != NSNotFound)
			{
				if (shouldSelectRange)
				{
					if ([[ev selectionIndexes] count] == 0)
						newIndexes = [NSIndexSet indexSetWithIndex:currIndex];
					else
					{
						unsigned first = MIN([[ev selectionIndexes] firstIndex], currIndex);
						unsigned last = MAX([[ev selectionIndexes] lastIndex], currIndex);
						newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(first, last - first + 1)];
					}
				}
				else
				{
					unsigned first = MIN(firstIndex, currIndex);
					unsigned last = MAX(firstIndex, currIndex);
					if (shouldExtendSelection)
						newIndexes = [originalIndexes indexSetByTogglingIndexesInRange:NSMakeRange(first, last - first + 1)];
					else
						newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(first, last - first + 1)];
				}
			}
			else
			{
				if (shouldSelectRange)
				{
					if ([[ev selectionIndexes] count] == 0)
						newIndexes = [NSIndexSet indexSet];
					else
					{
						unsigned first = [[ev selectionIndexes] firstIndex];
						unsigned last = [[ev selectionIndexes] lastIndex];
						newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(first, last - first + 1)];
					}
				}
				else
					newIndexes = [ev selectionIndexes];
			}
			
			// Tell the controller to adjust its selection indexes, if there is one
			if (observedObject)
			{
				if (([newIndexes count] > 0) || ![observedObject avoidsEmptySelection])
					[observedObject setValue:newIndexes forKeyPath:[[ev infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
			}
			else
				[ev setSelectionIndexes:newIndexes];
			
			if ((point.x - NSMinX([self visibleRect])) < INT_constitutionLabelExtraWidth)
			{
				// Adjust location in window to take into account constitution label extra width for correct autoscrolling
				NSPoint newLocation = NSMakePoint([lastNonPeriodicEvent locationInWindow].x - INT_constitutionLabelExtraWidth, [lastNonPeriodicEvent locationInWindow].y);
				NSEvent *newEvent = [NSEvent mouseEventWithType:[lastNonPeriodicEvent type]
													   location:newLocation
												  modifierFlags:[lastNonPeriodicEvent modifierFlags]
													  timestamp:[lastNonPeriodicEvent timestamp]
												   windowNumber:[lastNonPeriodicEvent windowNumber]
														context:[lastNonPeriodicEvent context]
													eventNumber:[lastNonPeriodicEvent eventNumber]
													 clickCount:[lastNonPeriodicEvent clickCount]
													   pressure:[lastNonPeriodicEvent pressure]];
				[self autoscroll:newEvent];
			}
			else
				[self autoscroll:lastNonPeriodicEvent];
			
			[pool release];
			
			event = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
									   untilDate:[NSDate distantFuture]
										  inMode:NSEventTrackingRunLoopMode
										 dequeue:YES];
			if ([event type] != NSPeriodic)
				lastNonPeriodicEvent = event;
			point = [self convertPoint:[lastNonPeriodicEvent locationInWindow] fromView:nil];
		} while ([event type] != NSLeftMouseUp);
		[NSEvent stopPeriodicEvents];
		
		[ev setEventTrackingSelection:NO];
		// Scroll selected entries to visible
		[ev setSelectionIndexes:[ev selectionIndexes]];
	}
}



#pragma mark Layout

- (float)headerWidthForConstitution:(INTConstitution *)constitution // INTEntriesHeaderView (INTProtectedMethods)
{
	float width = 0.0f;
	
	[INT_headerCell setStringValue:NSLocalizedString(@"INTConstitutionHeaderTitle", @"Constitution header title")];
	width = fmaxf(width, [INT_headerCell cellSize].width);
	
	if ([constitution versionLabel])
	{
		[INT_headerCell setStringValue:[constitution versionLabel]];
		width = fmaxf(width, [INT_headerCell cellSize].width);
	}
	
	return width;
}



#pragma mark Drawing

- (void)drawRect:(NSRect)rect // NSView
{
	if ([[INTAppController sharedAppController] isSyncing])
		return;
	
	float hh = [[self entriesView] headerHeight];
	
	[INT_toolTipStrings removeAllObjects];
	[self removeAllToolTips];
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	if ([[[self entriesView] sortedEntries] count] == 0)
	{
		// No entries; just draw filler
		[INT_headerCell setStringValue:[NSString string]];
		NSRect fillerFrame = NSMakeRect(0.0f, 0.0f, NSWidth([self visibleRect]) + 1.0f, hh);
		[INT_headerCell drawWithFrame:fillerFrame inView:self];
		fillerFrame = NSOffsetRect(fillerFrame, 0.0f, hh);
		[INT_headerCell drawWithFrame:fillerFrame inView:self];
		fillerFrame = NSOffsetRect(fillerFrame, 0.0f, hh);
		[INT_headerCell drawWithFrame:fillerFrame inView:self];
		return;
	}
	
	BOOL isYearInitialized = NO;
	int currYear = 0;
	float currYearMinX = 0.0f;
	int currMonth = -1;
	float currMonthMinX = 0.0f;
	
	
	// Run through once to find the constituion label extra width
	{
		INT_constitutionLabelExtraWidth = 0.0f;
		
		float currConstitutionMinX = 0.0f;
		float currEntryMaxX = 0.0f;
		float currEntryMinX = currEntryMaxX;
		float prevConstitutionWidth = 0.0f;
		float currConstitutionWidth = 0.0f;
		INTConstitution *currConstitution = nil;
		NSEnumerator *entries = [[[self entriesView] sortedEntries] objectEnumerator];
		INTEntry *currEntry;
		while ((currEntry = [entries nextObject]))
		{
			if ([currEntry constitution] != currConstitution)
			{
				BOOL hadPrevConstitution = (currConstitution != nil);
				float prevConstitutionMinMinX = currConstitutionMinX;
				float prevConstitutionMaxMinX = currEntryMaxX - [[self entriesView] columnWidth] - prevConstitutionWidth;
				
				currConstitution = [currEntry constitution];
				currConstitutionMinX = currEntryMaxX;
				currConstitutionWidth = [[self entriesView] widthForConstitution:currConstitution] + [[self entriesView] intercellSpacing].width;
				currEntryMaxX += currConstitutionWidth;
				
				if (hadPrevConstitution)
				{
					float prevDisplayMinX = NSMinX([self visibleRect]);
					prevDisplayMinX = MAX(prevConstitutionMinMinX, prevDisplayMinX);
					prevDisplayMinX = MIN(prevConstitutionMaxMinX, prevDisplayMinX);
					
					if (prevDisplayMinX == NSMinX([self visibleRect]))
					{
						INT_constitutionLabelExtraWidth = prevConstitutionWidth;
						break;
					}
				}
				
				prevConstitutionWidth = currConstitutionWidth;
			}
			currEntryMinX = currEntryMaxX;
			currEntryMaxX += [[self entriesView] columnWidth] + [[self entriesView] intercellSpacing].width;
		}
		if (currConstitution && (INT_constitutionLabelExtraWidth == 0.0f))
		{
			float currDisplayMinX = NSMinX([self visibleRect]);
			currDisplayMinX = MAX(currConstitutionMinX, currDisplayMinX);
			currDisplayMinX = MIN(currEntryMaxX - [[self entriesView] columnWidth] - currConstitutionWidth, currDisplayMinX);
			
			if (currDisplayMinX == NSMinX([self visibleRect]))
				INT_constitutionLabelExtraWidth = currConstitutionWidth;
		}
	}
	
	
	// Now do the actual drawing
	INTConstitution *currConstitution = nil;
	float currConstitutionWidth = NAN;
	float currConstitutionMinX = 0.0f;
	NSMutableArray *constitutionPositions = [[NSMutableArray alloc] init];
	float currEntryMaxX = 0.0f;
	float currEntryMinX = currEntryMaxX;
	NSEnumerator *entries = [[[self entriesView] sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		const unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
		NSDateComponents *components = [[[self entriesView] calendar] components:unitFlags fromDate:[currEntry date]];
		
		// Save constitution positions, but don't draw them on-screen yet
		if ([currEntry constitution] != currConstitution)
		{
			if (currConstitution)
				[constitutionPositions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					currConstitution, @"constitution",
					[NSNumber numberWithFloat:currConstitutionMinX], @"minMinX",
					[NSNumber numberWithFloat:(currEntryMaxX - [[self entriesView] columnWidth] - currConstitutionWidth)], @"maxMinX",
					nil]];
			
			currConstitution = [currEntry constitution];
			currConstitutionMinX = currEntryMaxX;
			currConstitutionWidth = [[self entriesView] widthForConstitution:currConstitution] + [[self entriesView] intercellSpacing].width;
			float prevEntryMaxX = currEntryMaxX;
			currEntryMaxX += currConstitutionWidth;
			
			// Break the month header
			if (currMonth != -1)
			{
				float monthWidth = prevEntryMaxX - currMonthMinX;
				NSRect monthCellFrame = NSMakeRect(currMonthMinX, hh, monthWidth, hh);
				[self drawMonth:currMonth withHintedFrame:monthCellFrame];
				currMonth = [components month];
				currMonthMinX += monthWidth + currConstitutionWidth;
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
			NSRect yearCellFrame = NSMakeRect(currYearMinX, 0.0f, yearWidth, hh);
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
		
		INTEntriesHeaderCell *cell = [INT_headerCell copy];
		float entryWidth = currEntryMaxX - currEntryMinX;
		NSRect entryCellFrame = NSMakeRect(currEntryMinX, hh * 2.0f, entryWidth, hh);
		[cell setStringValue:[self dayAsString:[components day]]];
		if ([currEntry isUnread])
		{
			NSString *unreadToolTip = NSLocalizedString(@"INTUnreadEntryToolTip", @"Unread entry tool tip");
			[cell setTintColor:[NSColor colorWithDeviceRed:0.53f green:0.71f blue:0.92f alpha:0.6f]];
			[INT_toolTipStrings addObject:unreadToolTip];
			[self addToolTipRect:entryCellFrame
						   owner:unreadToolTip
						userData:NULL];
		}
		else if ([[currEntry note] length] > 0)
		{
			NSString *noteToolTip = [NSString stringWithFormat:NSLocalizedString(@"INTEntryNoteToolTip", @"Entry note tool tip"), [currEntry note]];
			[cell setTintColor:[[NSColor yellowColor] colorWithAlphaComponent:0.4f]];
			[INT_toolTipStrings addObject:noteToolTip];
			[self addToolTipRect:entryCellFrame
						   owner:noteToolTip
						userData:NULL];
		}
		[cell drawWithFrame:entryCellFrame inView:self];
		[cell release];
	}
	
	if (currConstitution)
		[constitutionPositions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			currConstitution, @"constitution",
			[NSNumber numberWithFloat:currConstitutionMinX], @"minMinX",
			[NSNumber numberWithFloat:(currEntryMaxX - [[self entriesView] columnWidth] - currConstitutionWidth)], @"maxMinX",
			nil]];
	
	
	// Draw constitutions
	INTEntriesHeaderCell *constitutionCell = [INT_headerCell copy];
	NSEnumerator *constitutionPositionsEnum = [constitutionPositions objectEnumerator];
	NSDictionary *constitutionPosition;
	while ((constitutionPosition = [constitutionPositionsEnum nextObject]))
	{
		float minMinX = [[constitutionPosition objectForKey:@"minMinX"] floatValue];
		float maxMinX = [[constitutionPosition objectForKey:@"maxMinX"] floatValue];
		float minX = NSMinX([self visibleRect]);
		minX = MAX(minMinX, minX);
		minX = MIN(maxMinX, minX);
		
		INTConstitution *constitution = [constitutionPosition objectForKey:@"constitution"];
		[constitutionCell setTintColor:[[NSColor blackColor] colorWithAlphaComponent:0.6f]];
		[constitutionCell setTextColor:[NSColor whiteColor]];
		
		float constitutionWidth = [[self entriesView] widthForConstitution:constitution] + [[self entriesView] intercellSpacing].width;
		NSRect constitutionFrame = NSMakeRect(minX, hh, constitutionWidth, hh);
		[constitutionCell setStringValue:NSLocalizedString(@"INTConstitutionHeaderTitle", @"Constitution header title")];
		[constitutionCell drawWithFrame:constitutionFrame inView:self];
		
		NSRect labelFrame = NSOffsetRect(constitutionFrame, 0.0f, hh);
		[constitutionCell setStringValue:[constitution versionLabel]];
		[constitutionCell drawWithFrame:labelFrame inView:self];
	}
	[constitutionCell release];
	[constitutionPositions release];
	
	
	// Draw final month and year cells
	// Add one pixel to the width to avoid drawing the right divider bar
	float yearWidth = NSMaxX([self visibleRect]) - currYearMinX;
	NSRect yearCellFrame = NSMakeRect(currYearMinX, 0.0f, yearWidth + 1.0f, hh);
	if (!NSIsEmptyRect(yearCellFrame))
	{
		[INT_headerCell setStringValue:[self yearAsString:currYear]];
		[INT_headerCell drawWithFrame:yearCellFrame inView:self];
	}
	
	float monthWidth = currEntryMaxX - currMonthMinX;
	NSRect monthCellFrame = NSMakeRect(currMonthMinX, hh, monthWidth + 1.0f, hh);
	if (!NSIsEmptyRect(monthCellFrame))
		[self drawMonth:currMonth withHintedFrame:monthCellFrame];
	
	// Fill any empty space on the right
	[INT_headerCell setStringValue:[NSString string]];
	NSRect monthFillerFrame = NSMakeRect(currEntryMaxX, hh, NSWidth([self visibleRect]) - currEntryMaxX + 1.0f, hh);
	if (!NSIsEmptyRect(monthFillerFrame))
		[INT_headerCell drawWithFrame:monthFillerFrame inView:self];
	NSRect entryFillerFrame = NSOffsetRect(monthFillerFrame, 0.0f, hh);
	if (!NSIsEmptyRect(entryFillerFrame))
		[INT_headerCell drawWithFrame:entryFillerFrame inView:self];
}


- (void)drawMonth:(int)month withHintedFrame:(NSRect)frame // INTEntriesHeaderView (INTPrivateMethods)
{
	NSRect visRect = [self visibleRectExcludingConstitutionLabelExtraWidth];
	NSRect realFrame = frame;
	NSString *monthString = [self monthAsString:month];
	[INT_headerCell setStringValue:monthString];
	float textWidth = [INT_headerCell cellSize].width;
	
	// Calculate text frame
	NSRect textFrame = NSInsetRect(frame, (NSWidth(frame) - textWidth) / 2.0f, 0.0f);
	
	if (textWidth < NSWidth(NSIntersectionRect(visRect, frame)))
	{
		if (!NSContainsRect(visRect, textFrame))
		{
			if (NSMinX(textFrame) < NSMinX(visRect))
			{
				float xShift = (NSMinX(visRect) - NSMinX(textFrame)) * 2.0f;
				realFrame.origin.x += xShift;
				realFrame.size.width -= xShift;
			}
			else
				realFrame.size.width -= (NSMaxX(textFrame) - NSMaxX(visRect)) * 2.0f;
		}
	}
	else
		realFrame = NSIntersectionRect(visRect, frame);
	
	[NSGraphicsContext saveGraphicsState];
	[NSBezierPath clipRect:visRect];
	[INT_headerCell drawWithFrame:realFrame inView:self];
	[NSGraphicsContext restoreGraphicsState];
	
	[INT_toolTipStrings addObject:monthString];
	[self addToolTipRect:NSIntersectionRect(visRect, realFrame)
				   owner:monthString
				userData:NULL];
}


- (NSRect)visibleRectExcludingConstitutionLabelExtraWidth // INTEntriesHeaderView (INTPrivateMethods)
{
	NSRect rect = [self visibleRect];
	rect = NSInsetRect(rect, INT_constitutionLabelExtraWidth / 2.0f, 0.0f);
	rect = NSOffsetRect(rect, INT_constitutionLabelExtraWidth / 2.0f, 0.0f);
	return rect;
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
