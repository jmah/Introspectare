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

#pragma mark Getting auxiliary views for enclosing an scroll view
- (NSView *)headerView;
- (NSView *)cornerView;

#pragma mark Displaying
- (void)updateFrameSize;

#pragma mark Managing clip view bounds changes
- (void)clipViewFrameDidChangeChange:(NSNotification *)notification;

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
		[dataCell setControlView:self];
		INT_dataCell = dataCell;
		
		[self setFocusRingType:NSFocusRingTypeExterior];
		
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
	[INT_dataCell setControlView:self];
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
}


- (void)keyDown:(NSEvent *)event // NSResponder
{
	NSLog(@"%@", event);
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
	float height = (maxPrincipleCount * [self rowHeight]) + ((maxPrincipleCount - 1) * [self intercellSpacing].height);
	float width = ([[self sortedEntries] count] * [self columnWidth]) + (([[self sortedEntries] count] - 1) * [self intercellSpacing].width);
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
		float currAnnotatedPrincipleMaxY = -[self intercellSpacing].height;
		NSEnumerator *annotatedPrinciples = [[currEntry annotatedPrinciples] objectEnumerator];
		INTAnnotatedPrinciple *currAnnotatedPrinciple;
		while ((currAnnotatedPrinciple = [annotatedPrinciples nextObject]))
		{
			float currAnnotatedPrincipleMinY = currAnnotatedPrincipleMaxY + [self intercellSpacing].height;
			currAnnotatedPrincipleMaxY += [self rowHeight] + [self intercellSpacing].height;
			if (currAnnotatedPrincipleMaxY < NSMinY(rect))
				continue;
			if (currAnnotatedPrincipleMinY > NSMaxY(rect))
				break;
			
			NSRect gridFrame = NSMakeRect(currEntryMinX, currAnnotatedPrincipleMinY, [self columnWidth], [self rowHeight]);
			
			NSActionCell *cell = [self dataCell];
			int state = [currAnnotatedPrinciple isUpheld] ? NSOffState : NSOnState;
			[cell setState:state];
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
