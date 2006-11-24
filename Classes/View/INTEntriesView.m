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
#import "INTAnnotatedPrinciple.h"
#import "INTEntriesHeaderView.h"
#import "INTEntriesCornerView.h"


@interface INTEntriesView (INTPrivateMethods)

#pragma mark Managing entries
- (void)cacheSortedEntries;

#pragma mark Event handling
- (void)selectedAnnotatedPrincipleClicked:(id)sender;

#pragma mark Getting auxiliary views for enclosing an scroll view
- (NSView *)headerView;
- (NSView *)cornerView;

#pragma mark Displaying
- (void)updateFrameSize;

#pragma mark Managing clip view bounds changes
- (void)clipViewFrameDidChangeChange:(NSNotification *)notification;

#pragma mark Layout
- (INTEntry *)entryAtPoint:(NSPoint)point;
- (INTAnnotatedPrinciple *)annotatedPrincipleAtPoint:(NSPoint)point;
- (NSActionCell *)dataCellAtPoint:(NSPoint)point frame:(NSRect *)outFrame;
- (NSRect)rectForAnnotatedPrinciple:(INTAnnotatedPrinciple *)annotatedPrinciple ofEntry:(INTEntry *)entry;

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
		INT_backgroundColor = [[NSColor whiteColor] retain];
		INT_rowHeight = 22.0;
		INT_intercellSpacing = NSMakeSize(1.0, 1.0);
		INT_headerHeight = 16.0;
		INT_columnWidth = 22.0;
		INT_headerFont = [NSFont fontWithName:@"Lucida Grande" size:11.0];
		
		NSRect headerFrame = NSMakeRect(0.0, 0.0, NSWidth(frame), 3.0 * [self headerHeight]);
		INT_headerView = [[INTEntriesHeaderView alloc] initWithFrame:headerFrame
														 entriesView:self];
		
		NSRect cornerFrame = NSMakeRect(0.0, 0.0, 20.0, NSHeight(headerFrame));
		INT_cornerView = [[INTEntriesCornerView alloc] initWithFrame:cornerFrame
														 entriesView:self];
		
		INT_prevClipViewFrameWidth = NAN;
		
		INT_principleLabelCell = [[NSTextFieldCell alloc] initTextCell:[NSString string]];
		[INT_principleLabelCell setFont:[NSFont fontWithName:@"Lucida Grande" size:13.0]];
		[INT_principleLabelCell setLineBreakMode:NSLineBreakByTruncatingTail];
		[INT_principleLabelCell setAlignment:NSLeftTextAlignment];
		[INT_principleLabelCell setControlView:self];
		
		NSButtonCell *dataCell = [[NSButtonCell alloc] initTextCell:[NSString string]];
		// Set an attributed title, otherwise the button cell will generate one each time it's drawn
		[dataCell setAttributedTitle:[[[NSAttributedString alloc] initWithString:[NSString string]] autorelease]];
		[dataCell setButtonType:NSSwitchButton];
		INT_dataCell = dataCell;
		
		[self setFocusRingType:NSFocusRingTypeExterior];
		
		[self cacheSortedEntries];
		[self updateFrameSize];
		
		// Observe interesting things
#warning TODO Redo this so we bind to a controller instead (and so get entry selection)
		[library addObserver:self
				  forKeyPath:@"entries"
					 options:0
					 context:NULL];
		
		NSEnumerator *entries = [[library entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
		{
			[entry addObserver:self
					forKeyPath:@"annotatedPrinciples"
					   options:0
					   context:NULL];
			[entry addObserver:self
					forKeyPath:@"unread"
					   options:0
					   context:NULL];
			NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
			INTAnnotatedPrinciple *annotatedPrinciple;
			while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
				[annotatedPrinciple addObserver:self
									 forKeyPath:@"upheld"
										options:0
										context:NULL];
		}
		
		[library addObserver:self
				  forKeyPath:@"constitutions"
					 options:0
					 context:NULL];
		NSEnumerator *constitutions = [[library constitutions] objectEnumerator];
		INTConstitution *constitution;
		while ((constitution = [constitutions nextObject]))
		{
			[constitution addObserver:self
						   forKeyPath:@"versionLabel"
							  options:0
							  context:NULL];
			[constitution addObserver:self
						   forKeyPath:@"principles"
							  options:0
							  context:NULL];
		}
		
		[library addObserver:self
				  forKeyPath:@"principles"
					 options:0
					 context:NULL];
		NSEnumerator *principles = [[library principles] objectEnumerator];
		INTPrinciple *principle;
		while ((principle = [principles nextObject]))
		{
			[principle addObserver:self
						forKeyPath:@"label"
						   options:0
						   context:NULL];
		}
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
	[INT_backgroundColor release], INT_backgroundColor = nil;
	[INT_headerFont release], INT_headerFont = nil;
	[INT_principleLabelCell release], INT_principleLabelCell = nil;
	[INT_dataCell release], INT_dataCell = nil;
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

- (NSColor *)backgroundColor
{
	return INT_backgroundColor;
}


- (void)setBackgroundColor:(NSColor *)color
{
	id oldValue = INT_backgroundColor;
	INT_backgroundColor = [color retain];
	[self setNeedsDisplay:YES];
	[oldValue release];
}


- (float)rowHeight
{
	return INT_rowHeight;
}


- (void)setRowHeight:(float)rowHeight
{
	INT_rowHeight = rowHeight;
	[self updateFrameSize];
	[[self enclosingScrollView] setVerticalLineScroll:rowHeight];
	[self setNeedsDisplay:YES];
}


- (NSSize)intercellSpacing
{
	return INT_intercellSpacing;
}


- (void)setIntercellSpacing:(NSSize)intercellSpacing
{
	INT_intercellSpacing = intercellSpacing;
	[self updateFrameSize];
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
	[self updateFrameSize];
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
	[[self headerView] setNeedsDisplay:YES];
}


- (NSFont *)principleFont
{
	return [[self principleLabelCell] font];
}


- (void)setPrincipleFont:(NSFont *)principleFont
{
	[[self principleLabelCell] setFont:principleFont];
	[self setNeedsDisplay:YES];
}



#pragma mark Setting component cells

- (NSCell *)principleLabelCell
{
	return INT_principleLabelCell;
}


- (void)setPrincipleLabelCell:(NSCell *)cell
{
	id oldValue = INT_principleLabelCell;
	INT_principleLabelCell = [cell copy];
	[INT_principleLabelCell setControlView:self];
	[oldValue release];
	[self setNeedsDisplay:YES];
}


- (NSActionCell *)dataCell
{
	return INT_dataCell;
}


- (void)setDataCell:(NSActionCell *)cell
{
	id oldValue = INT_dataCell;
	INT_dataCell = [cell copy];
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
	else if ([object isKindOfClass:[INTAnnotatedPrinciple class]])
	{
		NSEnumerator *entries = [[[self library] entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
			if ([[entry annotatedPrinciples] indexOfObjectIdenticalTo:object] != NSNotFound)
				break;
		NSRect rect = [self rectForAnnotatedPrinciple:object ofEntry:entry];
		if (!NSIsEmptyRect(rect))
			[self setNeedsDisplayInRect:rect];
		else
			NSLog(@"Received change for an unexpected annotated principle");
		handled = YES;
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

- (void)viewWillMoveToSuperview:(NSView *)newSuperview // NSView
{
	if ([[self superview] isKindOfClass:[NSClipView class]])
	{
		NSClipView *cv = (NSClipView *)[self superview];
		[cv setPostsFrameChangedNotifications:INT_clipViewDidPostFrameChangeNotifications];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSViewFrameDidChangeNotification
													  object:cv];
	}
}


- (void)viewDidMoveToSuperview // NSView
{
	NSScrollView *sv = [self enclosingScrollView];
	if (sv)
	{
		[sv setHorizontalLineScroll:[self columnWidth]];
		[sv setVerticalLineScroll:[self rowHeight]];
		[[sv contentView] setCopiesOnScroll:NO];
		INT_prevClipViewFrameWidth = NSWidth([[sv contentView] frame]);
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clipViewFrameDidChangeChange:)
													 name:NSViewFrameDidChangeNotification
												   object:[sv contentView]];
		INT_clipViewDidPostFrameChangeNotifications = [[sv contentView] postsFrameChangedNotifications];
		[[sv contentView] setPostsFrameChangedNotifications:YES];
	}
	else
		NSLog(@"The INTEntriesView expects to be enclosed in an NSScrollView");
}



#pragma mark Managing the key view loop

- (BOOL)canBecomeKeyView // NSView
{
	return YES;
}



#pragma mark Changing the first responder

- (BOOL)accepsFirstResponder // NSResponder
{
	return YES;
}


- (BOOL)becomeFirstResponder // NSResponder
{
	if ([super becomeFirstResponder])
	{
		//[self setNeedsDisplay:YES];
		[self setKeyboardFocusRingNeedsDisplayInRect:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
		return YES;
	}
	else
		return NO;
}


- (BOOL)resignFirstResponder // NSResponder
{
	if ([super resignFirstResponder])
	{
		[self setKeyboardFocusRingNeedsDisplayInRect:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
		[self setNeedsDisplay:YES];
		return YES;
	}
	else
		return NO;
}



#pragma mark Event methods

- (void)mouseDown:(NSEvent *)event // NSResponder
{
	[[self window] makeFirstResponder:self];
	
	// Track mouse while down
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	NSRect cellFrame;
	NSActionCell *dataCell = [self dataCellAtPoint:point frame:&cellFrame];
	if (dataCell)
	{
		[dataCell setTarget:self];
		[dataCell setAction:@selector(selectedAnnotatedPrincipleClicked:)];
		[dataCell sendActionOn:NSLeftMouseUpMask];
		INT_selectedDataCell = dataCell;
		INT_selectedAnnotatedPrinciple = [self annotatedPrincipleAtPoint:point];
		
		do
		{
			point = [self convertPoint:[event locationInWindow] fromView:nil];
			if (NSPointInRect(point, cellFrame))
			{
				[dataCell setHighlighted:YES];
				[self displayRect:cellFrame];
				BOOL trackUntilMouseUp = [[dataCell class] prefersTrackingUntilMouseUp];
				BOOL shouldEndTracking = [dataCell trackMouse:event inRect:cellFrame ofView:self untilMouseUp:trackUntilMouseUp];
				[dataCell setHighlighted:NO];
				[self displayRect:cellFrame];
				
				if (shouldEndTracking)
					break;
			}
			event = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)];
		} while ([event type] == NSLeftMouseDragged);
		
		INT_selectedAnnotatedPrinciple = nil;
		INT_selectedDataCell = nil;
	}
}


- (void)selectedAnnotatedPrincipleClicked:(id)sender // INTEntriesView (INTPrivateMethods)
{
	[INT_selectedAnnotatedPrinciple setUpheld:!([INT_selectedDataCell state] == NSOnState)];
}



#pragma mark Displaying

- (BOOL)isOpaque // NSView
{
	return YES;
}


- (void)updateFrameSize // INTEntriesView (INTPrivateMethods)
{
	unsigned maxPrincipleCount = 0;
	NSEnumerator *entries = [[self sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
		maxPrincipleCount = MAX([[currEntry annotatedPrinciples] count], maxPrincipleCount);
	float height = (maxPrincipleCount * [self rowHeight]) + (MAX(0, (int)maxPrincipleCount - 1) * [self intercellSpacing].height);
	float width = ([[self sortedEntries] count] * [self columnWidth]) + (MAX(0, (int)[[self sortedEntries] count] - 1) * [self intercellSpacing].width);
	INT_minimumFrameSize = NSMakeSize(width, height);
}



#pragma mark Managing clip view bounds changes

- (void)clipViewFrameDidChangeChange:(NSNotification *)notification // INTEntriesView (INTProtectedMethods)
{
	NSSize newFrameSize = INT_minimumFrameSize;
	NSSize newClipViewSize = [[notification object] bounds].size;
	newFrameSize.width  = fmaxf(newClipViewSize.width , newFrameSize.width );
	newFrameSize.height = fmaxf(newClipViewSize.height, newFrameSize.height);
	
	if (!NSEqualSizes([self frame].size, newFrameSize))
		[self setFrameSize:newFrameSize];
	
	NSSize headerFrameSize = [[self headerView] frame].size;
	headerFrameSize.width = newFrameSize.width;
	if (!NSEqualSizes([[self headerView] frame].size, headerFrameSize))
		[[self headerView] setFrameSize:headerFrameSize];
	
	[self setNeedsDisplay:YES];
	[[self headerView] setNeedsDisplay:YES];
}



#pragma mark Drawing the entries view

- (void)drawRect:(NSRect)rect // NSView
{
	// Draw background
	[[self backgroundColor] set];
	NSRectFill(rect);
	
	
	// Draw entries and constitutions
	// TODO Draw constitutions
	float currEntryMaxX = -[self intercellSpacing].width;
	NSEnumerator *entries = [[self sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		float currEntryMinX = currEntryMaxX + [self intercellSpacing].width;
		currEntryMaxX += [self columnWidth] + [self intercellSpacing].width;
		if (currEntryMaxX < NSMinX(rect))
			continue;
		if (currEntryMinX > NSMaxX(rect))
			break;
		
		if (NO)// If entry is selected
		{
			[[NSColor selectedControlColor] set];
			[NSBezierPath fillRect:NSMakeRect(currEntryMinX, NSMinY([self bounds]), [self columnWidth], NSHeight([self bounds]))];
		}
		
		// TODO Draw all annotatedPrinciples from the same constitution in the same order
		float currPrincipleMaxY = -[self intercellSpacing].height;
		NSEnumerator *principles = [[[[self library] constitutionForDate:[currEntry date]] principles] objectEnumerator];
		INTPrinciple *currPrinciple;
		while ((currPrinciple = [principles nextObject]))
		{
			float currPrincipleMinY = currPrincipleMaxY + [self intercellSpacing].height;
			currPrincipleMaxY += [self rowHeight] + [self intercellSpacing].height;
			if (currPrincipleMaxY < NSMinY(rect))
				continue;
			if (currPrincipleMinY > NSMaxY(rect))
				break;
			
			NSEnumerator *annotatedPrinciples = [[currEntry annotatedPrinciples] objectEnumerator];
			INTAnnotatedPrinciple *currAnnotatedPrinciple;
			while ((currAnnotatedPrinciple = [annotatedPrinciples nextObject]))
				if ([currAnnotatedPrinciple principle] == currPrinciple)
					break;
			NSAssert(currAnnotatedPrinciple != nil, @"If an entry's constitution contains a principle, a corresponding annotated principle should exist");
			
			NSRect gridFrame = NSMakeRect(currEntryMinX, currPrincipleMinY, [self columnWidth], [self rowHeight]);
			
			NSActionCell *cell = [self dataCell];
			int state = [currAnnotatedPrinciple isUpheld] ? NSOffState : NSOnState;
			[cell setState:state];
			
			if (currAnnotatedPrinciple == INT_selectedAnnotatedPrinciple)
				cell = INT_selectedDataCell;
			
			NSSize cellSize = [cell cellSizeForBounds:NSMakeRect(0.0, 0.0, NSWidth(gridFrame), NSHeight(gridFrame))];
			
			NSRect cellFrame = gridFrame;
			cellFrame.origin.x = NSMidX(gridFrame) - cellSize.width / 2.0;
			cellFrame.origin.y = NSMidY(gridFrame) - cellSize.height / 2.0;
			cellFrame.size = cellSize;
			
			[cell drawWithFrame:cellFrame inView:self];
		}
	}
	
	
	// Draw grid
	[[NSColor gridColor] set];
	for (float y = [self rowHeight]; y < NSHeight([self bounds]); y += [self rowHeight] + [self intercellSpacing].width)
		[NSBezierPath fillRect:NSMakeRect(NSMinX([self bounds]), y, NSWidth([self bounds]), [self intercellSpacing].width)];
	for (float x = [self columnWidth]; x < NSWidth([self bounds]); x += [self columnWidth] + [self intercellSpacing].height)
		[NSBezierPath fillRect:NSMakeRect(x, NSMinY([self bounds]), [self intercellSpacing].height, NSHeight([self bounds]))];
}



#pragma mark Layout

- (INTEntry *)entryAtPoint:(NSPoint)point // INTEntriesView (INTPrivateMethods)
{
	if (!NSPointInRect(point, [self bounds]))
		return nil;
	
	unsigned entryIndex = floorf((point.x + [self intercellSpacing].width) / ([self columnWidth] + [self intercellSpacing].width));
	if (entryIndex < [[self sortedEntries] count])
		return [[self sortedEntries] objectAtIndex:entryIndex];
	else
		return nil;
}


- (INTAnnotatedPrinciple *)annotatedPrincipleAtPoint:(NSPoint)point // INTEntriesView (INTPrivateMethods)
{
	INTEntry *entry = [self entryAtPoint:point];
	if (!entry)
		return nil;
	
	unsigned principleIndex = floorf((point.y + [self intercellSpacing].height) / ([self rowHeight] + [self intercellSpacing].height));
	if (principleIndex < [[entry annotatedPrinciples] count])
	{
		INTPrinciple *principle = [[[[self library] constitutionForDate:[entry date]] principles] objectAtIndex:principleIndex];
		NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
		INTAnnotatedPrinciple *annotatedPrinciple;
		while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
			if ([annotatedPrinciple principle] == principle)
				break;
		NSAssert(annotatedPrinciple != nil, @"If an entry's constitution contains a principle, a corresponding annotated principle should exist");
		return annotatedPrinciple;
	}
	else
		return nil;
}


- (NSActionCell *)dataCellAtPoint:(NSPoint)point frame:(NSRect *)outFrame // INTEntriesView (INTPrivateMethods)
{
	INTEntry *entry = [self entryAtPoint:point];
	INTAnnotatedPrinciple *annotatedPrinciple = [self annotatedPrincipleAtPoint:point];
	if (!entry || !annotatedPrinciple)
		return nil;
	
	if (outFrame)
		*outFrame = [self rectForAnnotatedPrinciple:annotatedPrinciple ofEntry:entry];
	
	NSActionCell *cell = [[self dataCell] copy];
	int state = [annotatedPrinciple isUpheld] ? NSOffState : NSOnState;
	[cell setState:state];
	
	return [cell autorelease];
}


- (NSRect)rectForAnnotatedPrinciple:(INTAnnotatedPrinciple *)annotatedPrinciple ofEntry:(INTEntry *)entry // INTEntriesView (INTPrivateMethods)
{
	unsigned entryIndex = [[self sortedEntries] indexOfObject:entry];
	unsigned annotatedPrincipleIndex = [[[[self library] constitutionForDate:[entry date]] principles] indexOfObject:[annotatedPrinciple principle]];
	if ((entryIndex == NSNotFound) || (annotatedPrincipleIndex == NSNotFound))
		return NSZeroRect;
	else
		return NSMakeRect(entryIndex * ([self columnWidth] + [self intercellSpacing].width),
						  annotatedPrincipleIndex * ([self rowHeight] + [self intercellSpacing].height),
						  [self columnWidth],
						  [self rowHeight]);
}



#pragma mark Examining coordinate system modifications

- (BOOL)isFlipped // NSView
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
