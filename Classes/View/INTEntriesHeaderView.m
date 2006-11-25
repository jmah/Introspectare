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
		
		INT_constitutionLabelExtraWidth = 0.0;
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
	if (point.y > ([[self entriesView] headerHeight] * 2.0))
	{
		// Track mouse while down
		NSEvent *lastNonPeriodicEvent = event;
		[NSEvent startPeriodicEventsAfterDelay:0.2 withPeriod:0.05];
		INTEntriesView *ev = [self entriesView];
		NSIndexSet *initialSelectionIndexes = [[ev selectionIndexes] copy];
		do
		{
			NSIndexSet *newIndexes;
			
			if ((point.y > ([[self entriesView] headerHeight] * 2.0)) && [[self entriesView] entryAtXLocation:point.x])
				newIndexes = [NSIndexSet indexSetWithIndex:[[[self entriesView] sortedEntries] indexOfObject:[[self entriesView] entryAtXLocation:point.x]]];
			else
				newIndexes = [NSIndexSet indexSet];
			
			// Tell the controller to adjust its selection indexes, if there is one
			id observingObject = [[[self entriesView] infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
			if (observingObject)
			{
				if (([newIndexes count] > 0) || ![observingObject avoidsEmptySelection])
					[observingObject setValue:newIndexes forKeyPath:[[[self entriesView] infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
			}
			else
				[[self entriesView] setSelectionIndexes:newIndexes];
			
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
			
			event = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
									   untilDate:[NSDate distantFuture]
										  inMode:NSEventTrackingRunLoopMode
										 dequeue:YES];
			if ([event type] != NSPeriodic)
				lastNonPeriodicEvent = event;
			point = [self convertPoint:[lastNonPeriodicEvent locationInWindow] fromView:nil];
		} while ([event type] != NSLeftMouseUp);
		[NSEvent stopPeriodicEvents];
		
		if (([[ev selectionIndexes] count] > 0) && ![initialSelectionIndexes isEqual:[ev selectionIndexes]])
			[ev scrollEntryToVisible:[[ev sortedEntries] objectAtIndex:[[ev selectionIndexes] firstIndex]]];
		[initialSelectionIndexes release];
	}
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
	
	[INT_toolTipStrings release];
	INT_toolTipStrings = [[NSMutableArray alloc] init];
	[self removeAllToolTips];
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
	NSImage *currConstitutionLabelsImage = nil;
	float currConstitutionMinX = 0.0;
	NSMutableArray *constitutionLabels = [[NSMutableArray alloc] init];
	float currEntryMaxX = 0.0;
	float currEntryMinX = currEntryMaxX;
	NSEnumerator *entries = [[[self entriesView] sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		const unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
		NSDateComponents *components = [[[self entriesView] calendar] components:unitFlags fromDate:[currEntry date]];
		
		// Save constitution labels in images, but don't draw them on-screen yet
		if ([currEntry constitution] != currConstitution)
		{
			if (currConstitutionLabelsImage)
				[constitutionLabels addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[currConstitutionLabelsImage autorelease], @"image",
					[NSNumber numberWithFloat:currConstitutionMinX], @"minMinX",
					[NSNumber numberWithFloat:(currEntryMaxX - [[self entriesView] columnWidth] - [currConstitutionLabelsImage size].width)], @"maxMinX",
					nil]];
			
			currConstitution = [currEntry constitution];
			currConstitutionMinX = currEntryMaxX;
			float currConstitutionWidth = [[self entriesView] widthForConstitution:currConstitution] + [[self entriesView] intercellSpacing].width;
			float prevEntryMaxX = currEntryMaxX;
			currEntryMaxX += currConstitutionWidth;
			
			// Draw current principle labels in image
			currConstitutionLabelsImage = [[NSImage alloc] initWithSize:NSMakeSize(currConstitutionWidth, hh * 2.0)];
			[currConstitutionLabelsImage setFlipped:YES];
			
			[currConstitutionLabelsImage lockFocus];
			
			[[NSColor whiteColor] set];
			NSRectFill(NSMakeRect(0.0, 0.0, [currConstitutionLabelsImage size].width, [currConstitutionLabelsImage size].height));
			
			// Constitution is on-screen
			INTEntriesHeaderCell *cell = [INT_headerCell copy];
			[cell setTintColor:[[NSColor blackColor] colorWithAlphaComponent:0.6]];
			[cell setTextColor:[NSColor whiteColor]];
			
			NSRect constitutionFrame = NSMakeRect(0.0, 0.0, currConstitutionWidth, hh);
			[cell setStringValue:NSLocalizedString(@"INTConstitutionHeaderTitle", @"Constitution header title")];
			[cell drawWithFrame:constitutionFrame inView:self];
			
			NSRect labelFrame = NSOffsetRect(constitutionFrame, 0.0, hh);
			[cell setStringValue:[currConstitution versionLabel]];
			[cell drawWithFrame:labelFrame inView:self];
			
			[currConstitutionLabelsImage unlockFocus];
			
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
		
		INTEntriesHeaderCell *cell = [INT_headerCell copy];
		float entryWidth = currEntryMaxX - currEntryMinX;
		NSRect entryCellFrame = NSMakeRect(currEntryMinX, hh * 2.0, entryWidth, hh);
		[cell setStringValue:[self dayAsString:[components day]]];
		if ([currEntry isUnread])
		{
			NSString *unreadToolTip = NSLocalizedString(@"INTUnreadEntryToolTip", @"Unread entry tool tip");
			[cell setTintColor:[NSColor colorWithDeviceRed:0.53 green:0.71 blue:0.92 alpha:0.8]];
			[INT_toolTipStrings addObject:unreadToolTip];
			[self addToolTipRect:entryCellFrame
						   owner:unreadToolTip
						userData:NULL];
		}
		else if ([[currEntry note] length] > 0)
		{
			NSString *noteToolTip = [NSString stringWithFormat:NSLocalizedString(@"INTEntryNoteToolTip", @"Entry note tool tip"), [currEntry note]];
			[cell setTintColor:[[NSColor yellowColor] colorWithAlphaComponent:0.4]];
			[INT_toolTipStrings addObject:noteToolTip];
			[self addToolTipRect:entryCellFrame
						   owner:noteToolTip
						userData:NULL];
		}
		[cell drawWithFrame:entryCellFrame inView:self];
	}
	
	if (currConstitutionLabelsImage)
		[constitutionLabels addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[currConstitutionLabelsImage autorelease], @"image",
			[NSNumber numberWithFloat:currConstitutionMinX], @"minMinX",
			[NSNumber numberWithFloat:(currEntryMaxX - [[self entriesView] columnWidth] - [currConstitutionLabelsImage size].width)], @"maxMinX",
			nil]];
	
	
	// Draw constitutions
	INT_constitutionLabelExtraWidth = 0.0;
	NSEnumerator *constitutionLabelsEnum = [constitutionLabels objectEnumerator];
	NSDictionary *constitutionLabel;
	while ((constitutionLabel = [constitutionLabelsEnum nextObject]))
	{
		float minMinX = [[constitutionLabel objectForKey:@"minMinX"] floatValue];
		float maxMinX = [[constitutionLabel objectForKey:@"maxMinX"] floatValue];
		float minX = NSMinX([self visibleRect]);
		minX = MAX(minMinX, minX);
		minX = MIN(maxMinX, minX);
		
		NSImage *image = [constitutionLabel objectForKey:@"image"];
		[image compositeToPoint:NSMakePoint(minX, NSMaxY([self bounds]))
					  operation:NSCompositeSourceOver];
		
		if (minX == NSMinX([self visibleRect]))
			INT_constitutionLabelExtraWidth = [image size].width;
	}
	
	[constitutionLabels release];
	
	
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
	NSRect visRect = [self visibleRectExcludingConstitutionLabelExtraWidth];
	NSRect realFrame = frame;
	NSString *monthString = [self monthAsString:month];
	[INT_headerCell setStringValue:monthString];
	float textWidth = [INT_headerCell cellSize].width;
	
	// Calculate text frame
	NSRect textFrame = NSInsetRect(frame, (NSWidth(frame) - textWidth) / 2.0, 0.0);
	
	if (textWidth < NSWidth(NSIntersectionRect(visRect, frame)))
	{
		if (!NSContainsRect(visRect, textFrame))
		{
			if (NSMinX(textFrame) < NSMinX(visRect))
			{
				float xShift = (NSMinX(visRect) - NSMinX(textFrame)) * 2.0;
				realFrame.origin.x += xShift;
				realFrame.size.width -= xShift;
			}
			else
				realFrame.size.width -= (NSMaxX(textFrame) - NSMaxX(visRect)) * 2.0;
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
	rect = NSInsetRect(rect, INT_constitutionLabelExtraWidth / 2.0, 0.0);
	rect = NSOffsetRect(rect, INT_constitutionLabelExtraWidth / 2.0, 0.0);
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
