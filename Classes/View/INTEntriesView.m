//
//  INTEntriesView.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-21.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesView.h"
#import "INTEntriesView+INTProtectedMethods.h"
#import "NSIndexSet+INTAdditions.h"
#import "INTEntry.h"
#import "INTConstitution.h"
#import "INTPrinciple.h"
#import "INTAnnotatedPrinciple.h"
#import "INTEntriesHeaderView.h"
#import "INTEntriesHeaderView+INTProtectedMethods.h"
#import "INTEntriesCornerView.h"
#import "INTAppController.h"
#import "INTAppController+INTSyncServices.h"


static const float INTPrincipleLabelXPadding = 2.0f;


@interface INTEntriesView (INTPrivateMethods)

#pragma mark Managing bindings
- (void)beginObservingEntries:(NSArray *)entries;
- (void)endObservingEntries:(NSArray *)entries;

#pragma mark Action methods
- (void)selectedAnnotatedPrincipleClicked:(id)sender;
- (void)markSelectedEntriesAsRead:(id)sender;
- (void)markSelectedEntriesAsUnread:(id)sender;

#pragma mark Managing the view hierarchy
- (void)windowDidChangeKey:(NSNotification *)notification;
- (void)applicationDidChangeActive:(NSNotification *)notification;

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
- (NSRect)rectForEntry:(INTEntry *)entry;

@end


#pragma mark -


@implementation INTEntriesView

#pragma mark Initialization

+ (void)initialize
{
	[self exposeBinding:@"entries"];
	[self exposeBinding:@"selectionIndexes"];
}



#pragma mark Creating an entries view

- (id)initWithFrame:(NSRect)frame
{
	return [self initWithFrame:frame calendar:[NSCalendar currentCalendar]];
}


- (id)initWithFrame:(NSRect)frame calendar:(NSCalendar *)calendar // Designated initializer
{
	if ((self = [super initWithFrame:frame]))
	{
		if (![[calendar calendarIdentifier] isEqual:NSGregorianCalendar])
		{
			[self release];
			[NSException raise:NSInvalidArgumentException format:@"INTEntriesView only supports Gregorian calendars"];
			return nil;
		}
		
		INT_calendar = [calendar retain];
		INT_backgroundColor = [[NSColor whiteColor] retain];
		INT_rowHeight = 22.0f;
		INT_intercellSpacing = NSMakeSize(1.0f, 1.0f);
		INT_headerHeight = 16.0f;
		INT_columnWidth = 22.0f;
		INT_headerFont = [NSFont fontWithName:@"Lucida Grande" size:11.0f];
		
		NSRect headerFrame = NSMakeRect(0.0f, 0.0f, NSWidth(frame), 3.0f * [self headerHeight]);
		INT_headerView = [[INTEntriesHeaderView alloc] initWithFrame:headerFrame
														 entriesView:self];
		
		NSRect cornerFrame = NSMakeRect(0.0f, 0.0f, 20.0f, NSHeight(headerFrame));
		INT_cornerView = [[INTEntriesCornerView alloc] initWithFrame:cornerFrame
														 entriesView:self];
		
		INT_prevClipViewFrameWidth = NAN;
		INT_selectionIndexes = [[NSIndexSet indexSet] retain];
		INT_observedEntries = [[NSArray alloc] init];
		
		// Create default principle label cell
		INT_principleLabelCell = [[NSTextFieldCell alloc] initTextCell:[NSString string]];
		[INT_principleLabelCell setFont:[NSFont fontWithName:@"Lucida Grande" size:13.0f]];
		[INT_principleLabelCell setLineBreakMode:NSLineBreakByTruncatingTail];
		[INT_principleLabelCell setAlignment:NSLeftTextAlignment];
		[INT_principleLabelCell setControlView:self];
		
		// Create default data cell
		NSButtonCell *dataCell = [[NSButtonCell alloc] initTextCell:[NSString string]];
		// Set an attributed title, otherwise the button cell will generate one each time it's drawn
		[dataCell setAttributedTitle:[[[NSAttributedString alloc] initWithString:[NSString string]] autorelease]];
		[dataCell setButtonType:NSSwitchButton];
		INT_dataCell = dataCell;
		
		INT_constitutionLabelExtraWidth = 0.0f;
		INT_isEventTrackingSelection = NO;
		
		// Create contextual menu items
		INT_markAsReadItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"INTMarkAsReadContextualMenuTitle", @"Mark as Read menu title")
														action:@selector(markSelectedEntriesAsRead:)
												 keyEquivalent:[NSString string]];
		[INT_markAsReadItem setTarget:self];
		
		INT_markAsUnreadItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"INTMarkAsUnreadContextualMenuTitle", @"Mark as Unread menu title")
														  action:@selector(markSelectedEntriesAsUnread:)
												   keyEquivalent:[NSString string]];
		[INT_markAsUnreadItem setTarget:self];
		
		INT_showInspectorItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"INTShowInspectorContextualMenuTitle", @"Show Inspector menu title")
														   action:@selector(showInspector:)
													keyEquivalent:[NSString string]];
		[INT_showInspectorItem setTarget:[INTAppController sharedAppController]];
		
		
		[self setFocusRingType:NSFocusRingTypeExterior];
		
		[self updateFrameSize];
	}
	return self;
}


- (oneway void)release
{
	if ([self retainCount] == 1)
		/*
		 * The INTEntriesHeaderView key-value observes this object, and removes
		 * those observations in its -dealloc method. The KVO swizzled -dealloc
		 * method of this class runs before our dealloc is called, so if the
		 * entries view is released in -[INTEntriesView dealloc], it will try
		 * to remove itself as an observer and cause KVO to throw (because it
		 * has already been torn down). So we check if we are about to be
		 * dealloc'ed here (the retain count is 1 going on 0), release the
		 * header view now before KVO cleans up.
		 */
		[INT_headerView release], INT_headerView = nil;
	[super release];
}


- (void)dealloc
{
	[self unbind:@"selectionIndexes"];
	[self unbind:@"entries"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	/*[INT_headerView release], INT_headerView = nil;*/ // See comment in -release
	[INT_calendar release], INT_calendar = nil;
	[INT_backgroundColor release], INT_backgroundColor = nil;
	[INT_headerFont release], INT_headerFont = nil;
	[INT_principleLabelCell release], INT_principleLabelCell = nil;
	[INT_dataCell release], INT_dataCell = nil;
	[INT_selectionIndexes release], INT_selectionIndexes = nil;
	[INT_cornerView release], INT_cornerView = nil;
	[INT_markAsReadItem release], INT_markAsReadItem = nil;
	[INT_markAsUnreadItem release], INT_markAsUnreadItem = nil;
	[INT_showInspectorItem release], INT_showInspectorItem = nil;
	[INT_observedEntries release], INT_observedEntries = nil;
	
	[super dealloc];
}



#pragma mark Getting the calendar

- (NSCalendar *)calendar
{
	return INT_calendar;
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
	[[self enclosingScrollView] setVerticalLineScroll:([self rowHeight] + [self intercellSpacing].height)];
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
	[[self enclosingScrollView] setHorizontalLineScroll:([self columnWidth] + [self intercellSpacing].width)];
	[[self enclosingScrollView] setVerticalLineScroll:([self rowHeight] + [self intercellSpacing].height)];
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
	[[self enclosingScrollView] setHorizontalLineScroll:([self columnWidth] + [self intercellSpacing].width)];
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



#pragma mark Modifying the frame rectangle

- (NSSize)minimumFrameSize
{
	return INT_minimumFrameSize;
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



#pragma mark Managing bindings

- (void)bind:(NSString *)binding toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
	if ([binding isEqualToString:@"entries"])
	{
		INT_entriesContainer = [observableController retain];
		INT_entriesKeyPath = [keyPath copy];
		[observableController addObserver:self forKeyPath:keyPath options:0 context:NULL];
		
		NSArray *entries = [observableController valueForKeyPath:keyPath];
		[self beginObservingEntries:entries];
		[INT_observedEntries release], INT_observedEntries = [entries copy];
		
		[self updateFrameSize];
		
		if ([observableController isKindOfClass:[NSArrayController class]])
		{
			NSArrayController *ac = (NSArrayController *)observableController;
			NSSortDescriptor *dateAscending = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
			[ac setSortDescriptors:[NSArray arrayWithObject:dateAscending]];
			[dateAscending release];
			if (![self infoForBinding:@"selectionIndexes"])
				[self bind:@"selectionIndexes" toObject:ac withKeyPath:@"selectionIndexes" options:nil];
		}
	}
	else
		[super bind:binding toObject:observableController withKeyPath:keyPath options:options];
}


- (void)unbind:(NSString *)binding // <NSKeyValueBindingCreation>
{
	if ([binding isEqualToString:@"entries"])
	{
		[INT_entriesContainer removeObserver:self forKeyPath:INT_entriesKeyPath];
		[INT_entriesContainer release], INT_entriesContainer = nil;
		[INT_entriesKeyPath release], INT_entriesKeyPath = nil;
		
		[self endObservingEntries:INT_observedEntries];
		[INT_observedEntries release], INT_observedEntries = [[NSArray alloc] init];
		
		[self updateFrameSize];
	}
	[super unbind:binding];
}


- (void)beginObservingEntries:(NSArray *)entries // INTEntriesView (INTPrivateMethods)
{
	NSEnumerator *entriesEnumerator = [entries objectEnumerator];
	INTEntry *entry;
	while ((entry = [entriesEnumerator nextObject]))
	{
		[entry addObserver:self forKeyPath:@"unread" options:0 context:NULL];
		[entry addObserver:self forKeyPath:@"note" options:0 context:NULL];
		[entry addObserver:self forKeyPath:@"constitution" options:0 context:NULL];
		[entry addObserver:self forKeyPath:@"constitution.versionLabel" options:0 context:NULL];
		[entry addObserver:self forKeyPath:@"annotatedPrinciples" options:0 context:NULL];
		NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
		INTAnnotatedPrinciple *annotatedPrinciple;
		while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
		{
			[annotatedPrinciple addObserver:self forKeyPath:@"upheld" options:0 context:entry];
			[annotatedPrinciple addObserver:self forKeyPath:@"principle.label" options:0 context:NULL];
		}
	}
}


- (void)endObservingEntries:(NSArray *)entries // INTEntriesView (INTPrivateMethods)
{
	NSEnumerator *entriesEnumerator = [entries objectEnumerator];
	INTEntry *entry;
	while ((entry = [entriesEnumerator nextObject]))
	{
		[entry removeObserver:self forKeyPath:@"note"];
		[entry removeObserver:self forKeyPath:@"unread"];
		[entry removeObserver:self forKeyPath:@"constitution"];
		[entry removeObserver:self forKeyPath:@"constitution.versionLabel"];
		[entry removeObserver:self forKeyPath:@"annotatedPrinciples"];
		NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
		INTAnnotatedPrinciple *annotatedPrinciple;
		while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
		{
			[annotatedPrinciple removeObserver:self forKeyPath:@"upheld"];
			[annotatedPrinciple removeObserver:self forKeyPath:@"principle.label"];
		}
	}
}



#pragma mark Change notification

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	BOOL handled = NO;
	if (object == INT_entriesContainer)
	{
		if ([keyPath isEqualToString:INT_entriesKeyPath])
		{
			NSMutableArray *oldEntries = [INT_observedEntries mutableCopy];
			[oldEntries removeObjectsInArray:[self sortedEntries]];
			[self endObservingEntries:oldEntries];
			[oldEntries release];
			
			NSMutableArray *newEntries = [[self sortedEntries] mutableCopy];
			[newEntries removeObjectsInArray:INT_observedEntries];
			[self beginObservingEntries:newEntries];
			[newEntries release];
			
			[INT_observedEntries release];
			INT_observedEntries = [[self sortedEntries] copy];
			
			[self updateFrameSize];
			[self setNeedsDisplay:YES];
			handled = YES;
		}
	}
	if ([object isKindOfClass:[INTEntry class]])
	{
		if ([keyPath isEqualToString:@"unread"] || [keyPath isEqualToString:@"note"])
		{
			[[self headerView] setNeedsDisplay:YES];
			handled = YES;
		}
		else if ([keyPath isEqualToString:@"annotatedPrinciples"] || [keyPath isEqualToString:@"constitution"] || [keyPath isEqualToString:@"constitution.versionLabel"])
		{
			[self updateFrameSize];
			[self setNeedsDisplay:YES];
			[[self headerView] setNeedsDisplay:YES];
			handled = YES;
		}
	}
	if ([object isKindOfClass:[INTAnnotatedPrinciple class]])
	{
		if ([keyPath isEqualToString:@"upheld"])
		{
			INTEntry *entry = (INTEntry *)context;
			NSRect rect = [self rectForAnnotatedPrinciple:object ofEntry:entry];
			[self setNeedsDisplayInRect:rect];
			handled = YES;
		}
		else if ([keyPath isEqualToString:@"principle.label"])
		{
			[self updateFrameSize];
			[self setNeedsDisplay:YES];
			handled = YES;
		}
	}
	
	if (!handled)
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



#pragma mark Managing selection

- (NSIndexSet *)selectionIndexes
{
	return INT_selectionIndexes;
}


- (void)setSelectionIndexes:(NSIndexSet *)indexes
{
	NSIndexSet *oldIndexes = INT_selectionIndexes;
	INT_selectionIndexes = [indexes copy];
	
	unsigned currIndex = [oldIndexes firstIndex];
	while (currIndex != NSNotFound)
	{
		if (currIndex < [[self sortedEntries] count])
			[self setNeedsDisplayInRect:[self rectForEntry:[[self sortedEntries] objectAtIndex:currIndex]]];
		currIndex = [oldIndexes indexGreaterThanIndex:currIndex];
	}
	
	NSRect visibleRectExcludingConstitutionLabelExtraWidth = [self visibleRect];
	visibleRectExcludingConstitutionLabelExtraWidth = NSInsetRect(visibleRectExcludingConstitutionLabelExtraWidth, INT_constitutionLabelExtraWidth / 2.0f, 0.0f);
	visibleRectExcludingConstitutionLabelExtraWidth = NSOffsetRect(visibleRectExcludingConstitutionLabelExtraWidth, INT_constitutionLabelExtraWidth / 2.0f, 0.0f);
	
	NSIndexSet *newIndexes = INT_selectionIndexes;
	BOOL oneEntryVisible = NO;
	currIndex = [newIndexes firstIndex];
	while (currIndex != NSNotFound)
	{
		NSRect entryRect = [self rectForEntry:[[self sortedEntries] objectAtIndex:currIndex]];
		[self setNeedsDisplayInRect:entryRect];
		currIndex = [newIndexes indexGreaterThanIndex:currIndex];
		
		if (NSContainsRect(visibleRectExcludingConstitutionLabelExtraWidth, entryRect))
			oneEntryVisible = YES;
	}
	
	// Don't scroll when event tracking
	if (![self isEventTrackingSelection] && !oneEntryVisible && ([newIndexes count] > 0))
		// Scroll to make the first selected entry visible
		[self scrollEntryToVisible:[[self sortedEntries] objectAtIndex:[newIndexes firstIndex]]];
	
	[oldIndexes release];
}


- (NSArray *)selectedObjects
{
	id observedObject = [[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
	if (observedObject)
		return [observedObject selectedObjects];
	else
		return [[self sortedEntries] objectsAtIndexes:[self selectionIndexes]];
}



#pragma mark Managing entries

- (NSArray *)sortedEntries // INTEntriesView (INTProtectedMethods)
{
	return [INT_entriesContainer valueForKeyPath:INT_entriesKeyPath];
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
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSApplicationDidBecomeActiveNotification
												  object:NSApp];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSApplicationDidResignActiveNotification
												  object:NSApp];
}


- (void)viewDidMoveToSuperview // NSView
{
	NSScrollView *sv = [self enclosingScrollView];
	if (sv)
	{
		[sv setHorizontalLineScroll:([self columnWidth] + [self intercellSpacing].width)];
		[sv setVerticalLineScroll:([self rowHeight] + [self intercellSpacing].height)];
		[[sv contentView] setCopiesOnScroll:NO];
		INT_prevClipViewFrameWidth = NSWidth([[sv contentView] frame]);
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clipViewFrameDidChangeChange:)
													 name:NSViewFrameDidChangeNotification
												   object:[sv contentView]];
		INT_clipViewDidPostFrameChangeNotifications = [[sv contentView] postsFrameChangedNotifications];
		[[sv contentView] setPostsFrameChangedNotifications:YES];
		
		[self clipViewFrameDidChangeChange:nil];
	}
	else if ([self superview])
		NSLog(@"The INTEntriesView expects to be enclosed in an NSScrollView");
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidChangeActive:)
												 name:NSApplicationDidBecomeActiveNotification
											   object:NSApp];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidChangeActive:)
												 name:NSApplicationDidResignActiveNotification
											   object:NSApp];
}


- (void)viewWillMoveToWindow:(NSWindow *)newWindow // NSView
{
	if ([self window])
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSWindowDidResignKeyNotification
													  object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSWindowDidBecomeKeyNotification
													  object:[self window]];
	}
	if (newWindow)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidChangeKey:)
													 name:NSWindowDidResignKeyNotification
												   object:newWindow];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidChangeKey:)
													 name:NSWindowDidBecomeKeyNotification
												   object:newWindow];
	}
}


- (void)windowDidChangeKey:(NSNotification *)notification // INTEntriesView (INTPrivateMethods)
{
	[self setNeedsDisplay:YES];
}


- (void)applicationDidChangeActive:(NSNotification *)notification // INTEntriesView (INTPrivateMethods)
{
	if ([[self window] isKeyWindow])
		[self setNeedsDisplay:YES];
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
		[self setNeedsDisplay:YES];
		return YES;
	}
	else
		return NO;
}


- (BOOL)resignFirstResponder // NSResponder
{
	if ([super resignFirstResponder])
	{
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
	if ((point.x - NSMinX([self visibleRect])) < INT_constitutionLabelExtraWidth)
		// Click is in the constitution label; do nothing
		return;
	else if (dataCell)
	{
		[dataCell setTarget:self];
		[dataCell setAction:@selector(selectedAnnotatedPrincipleClicked:)];
		[dataCell sendActionOn:NSLeftMouseUpMask];
		INT_selectedDataCell = dataCell;
		INT_selectedAnnotatedPrinciple = [self annotatedPrincipleAtPoint:point];
		
		do
		{
			if (NSPointInRect(point, cellFrame))
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[dataCell setHighlighted:YES];
				[self displayRect:cellFrame];
				BOOL trackUntilMouseUp = [[dataCell class] prefersTrackingUntilMouseUp];
				BOOL shouldEndTracking = [dataCell trackMouse:event inRect:cellFrame ofView:self untilMouseUp:trackUntilMouseUp];
				[dataCell setHighlighted:NO];
				[self displayRect:cellFrame];
				[pool release];
				
				if (shouldEndTracking)
					break;
			}
			event = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)];
			point = [self convertPoint:[event locationInWindow] fromView:nil];
		} while ([event type] == NSLeftMouseDragged);
		
		INT_selectedAnnotatedPrinciple = nil;
		INT_selectedDataCell = nil;
	}
	else
	{
		BOOL shouldSelectRange = ([event modifierFlags] & NSShiftKeyMask) != 0;
		BOOL shouldExtendSelection = ([event modifierFlags] & NSCommandKeyMask) != 0;
		
		id observedObject = [[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
		unsigned firstIndex = NSNotFound;
		if (!shouldSelectRange && !shouldExtendSelection)
		{
			if (observedObject)
				[observedObject setValue:[NSIndexSet indexSet] forKeyPath:[[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
			else
				[self setSelectionIndexes:[NSIndexSet indexSet]];
		}
		
		NSIndexSet *originalIndexes = [[self selectionIndexes] copy];
		[self setEventTrackingSelection:YES];
		NSEvent *lastNonPeriodicEvent = event;
		
		[NSEvent startPeriodicEventsAfterDelay:0.2f withPeriod:0.05f];
		do
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			unsigned currIndex = NSNotFound;
			NSIndexSet *newIndexes;
			
			if ([self entryAtXLocation:point.x])
				currIndex = [[self sortedEntries] indexOfObject:[self entryAtXLocation:point.x]];
			
			if (firstIndex == NSNotFound)
				firstIndex = currIndex;
			
			if (currIndex != NSNotFound)
			{
				if (shouldSelectRange)
				{
					if ([[self selectionIndexes] count] == 0)
						newIndexes = [NSIndexSet indexSetWithIndex:currIndex];
					else
					{
						unsigned first = MIN([[self selectionIndexes] firstIndex], currIndex);
						unsigned last = MAX([[self selectionIndexes] lastIndex], currIndex);
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
					if ([[self selectionIndexes] count] == 0)
						newIndexes = [NSIndexSet indexSet];
					else
					{
						unsigned first = [[self selectionIndexes] firstIndex];
						unsigned last = [[self selectionIndexes] lastIndex];
						newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(first, last - first + 1)];
					}
				}
				else
					newIndexes = [self selectionIndexes];
			}
			
			// Tell the controller to adjust its selection indexes, if there is one
			if (observedObject)
			{
				if (([newIndexes count] > 0) || ![observedObject avoidsEmptySelection])
					[observedObject setValue:newIndexes forKeyPath:[[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
			}
			else
				// Just do it ourselves
				[self setSelectionIndexes:newIndexes];
			
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
		
		[originalIndexes release];
		[self setEventTrackingSelection:NO];
		
		// Scroll selected entries to visible
		[self setSelectionIndexes:[self selectionIndexes]];
	}
}



#pragma mark Action methods

- (void)moveLeft:(id)sender // NSResponder
{
	unsigned newIndex = NSNotFound;
	if ([[self selectionIndexes] count] == 0)
	{
		if ([[self sortedEntries] count] > 0)
			newIndex = [[self sortedEntries] count] - 1;
	}
	else if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
	{
		// Select the last entry of the previous month
		unsigned entryIndex = [[self selectionIndexes] firstIndex];
		INTEntry *entry = [[self sortedEntries] objectAtIndex:entryIndex];
		int month = [[[self calendar] components:NSMonthCalendarUnit fromDate:[entry date]] month];
		int targetEntryIndex;
		for (targetEntryIndex = entryIndex; targetEntryIndex > 0; targetEntryIndex--)
		{
			INTEntry *currEntry = [[self sortedEntries] objectAtIndex:targetEntryIndex];
			if ([[[self calendar] components:NSMonthCalendarUnit fromDate:[currEntry date]] month] != month)
				break;
		}
		
		newIndex = targetEntryIndex;
	}
	else
	{
		if ([[self selectionIndexes] containsIndex:0])
			newIndex = 0;
		else
			newIndex = [[self selectionIndexes] firstIndex] - 1;
	}
	
	// Extend selection if shift is down
	NSIndexSet *newIndexes;
	if (newIndex != NSNotFound)
	{
		if (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) && ([[self selectionIndexes] count] > 0))
			newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newIndex, [[self selectionIndexes] lastIndex] - newIndex + 1)];
		else
			newIndexes = [NSIndexSet indexSetWithIndex:newIndex];
		[self scrollEntryToVisible:[[self sortedEntries] objectAtIndex:newIndex]];
	}
	else
		newIndexes = [NSIndexSet indexSet];
	
	// Tell the controller to adjust its selection indexes, if there is one
	id observedObject = [[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
	if (observedObject)
	{
		if (([newIndexes count] > 0) || ![observedObject avoidsEmptySelection])
			[observedObject setValue:newIndexes forKeyPath:[[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
	}
	else
		// Just do it ourselves
		[self setSelectionIndexes:newIndexes];
}


- (void)moveRight:(id)sender // NSResponder
{
	unsigned newIndex = NSNotFound;
	if ([[self selectionIndexes] count] == 0)
	{
		if ([[self sortedEntries] count] > 0)
			newIndex = 0;
	}
	else if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
	{
		// Select the first entry of the next month
		unsigned entryIndex = [[self selectionIndexes] firstIndex];
		INTEntry *entry = [[self sortedEntries] objectAtIndex:entryIndex];
		int month = [[[self calendar] components:NSMonthCalendarUnit fromDate:[entry date]] month];
		unsigned targetEntryIndex;
		for (targetEntryIndex = entryIndex; targetEntryIndex < ([[self sortedEntries] count] - 1); targetEntryIndex++)
		{
			INTEntry *currEntry = [[self sortedEntries] objectAtIndex:targetEntryIndex];
			if ([[[self calendar] components:NSMonthCalendarUnit fromDate:[currEntry date]] month] != month)
				break;
		}
		
		newIndex = targetEntryIndex;
	}
	else
	{
		if ([[self selectionIndexes] containsIndex:([[self sortedEntries] count] - 1)])
			newIndex = [[self sortedEntries] count] - 1;
		else
			newIndex = [[self selectionIndexes] lastIndex] + 1;
	}
	
	// Extend selection if shift is down
	NSIndexSet *newIndexes;
	if (newIndex != NSNotFound)
	{
		if (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) && ([[self selectionIndexes] count] > 0))
			newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([[self selectionIndexes] firstIndex], newIndex - [[self selectionIndexes] firstIndex] + 1)];
		else
			newIndexes = [NSIndexSet indexSetWithIndex:newIndex];
		[self scrollEntryToVisible:[[self sortedEntries] objectAtIndex:newIndex]];
	}
	else
		newIndexes = [NSIndexSet indexSet];
	
	// Tell the controller to adjust its selection indexes, if there is one
	id observedObject = [[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
	if (observedObject)
	{
		if (([newIndexes count] > 0) || ![observedObject avoidsEmptySelection])
			[observedObject setValue:newIndexes forKeyPath:[[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
	}
	else
		// Just do it ourselves
		[self setSelectionIndexes:newIndexes];
}


- (void)selectedAnnotatedPrincipleClicked:(id)sender // INTEntriesView (INTPrivateMethods)
{
	[INT_selectedAnnotatedPrinciple setUpheld:!([INT_selectedDataCell state] == NSOnState)];
}


- (void)markSelectedEntriesAsRead:(id)sender // INTEntriesView (INTPrivateMethods)
{
	if ([[self selectionIndexes] count] > 0)
		[[self selectedObjects] setValue:[NSNumber numberWithBool:NO]
							  forKeyPath:@"unread"];
}


- (void)markSelectedEntriesAsUnread:(id)sender // INTEntriesView (INTPrivateMethods)
{
	if ([[self selectionIndexes] count] > 0)
		[[self selectedObjects] setValue:[NSNumber numberWithBool:YES]
							  forKeyPath:@"unread"];
}



#pragma mark Context-sensitive menus

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	BOOL eventInSelection = NO;
	NSEnumerator *selectedEntries = [[self selectedObjects] objectEnumerator];
	INTEntry *entry;
	while (!eventInSelection && (entry = [selectedEntries nextObject]))
		if (NSPointInRect(point, [self rectForEntry:entry]))
			eventInSelection = YES;
	
	// The click was outside all selected entries; select the one that was clicked
	if (!eventInSelection)
	{
		if (!((point.x - NSMinX([self visibleRect])) < INT_constitutionLabelExtraWidth))
		{
			// Click is not in the constitution label; do nothing
			if ([self entryAtPoint:point])
			{
				NSIndexSet *newIndexes = [NSIndexSet indexSetWithIndex:[[self sortedEntries] indexOfObject:[self entryAtPoint:point]]];
				
				// Tell the controller to adjust its selection indexes, if there is one
				id observedObject = [[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedObjectKey];
				if (observedObject)
				{
					if (([newIndexes count] > 0) || ![observedObject avoidsEmptySelection])
						[observedObject setValue:newIndexes forKeyPath:[[self infoForBinding:@"selectionIndexes"] objectForKey:NSObservedKeyPathKey]];
				}
				else
					// Just do it ourselves
					[self setSelectionIndexes:newIndexes];
				
				eventInSelection = YES;
			}
		}
	}
	
	
	NSMenu *menu = [[NSMenu alloc] initWithTitle:[NSString string]];
	if (eventInSelection && ([[self selectionIndexes] count] > 0))
	{
		NSArray *unreadStatuses = [[self selectedObjects] valueForKeyPath:@"unread"];
		// Key-value coding gives back booleans as 1/0, not YES/NO
		if ([unreadStatuses containsObject:[NSNumber numberWithInt:1]])
			[menu addItem:INT_markAsReadItem];
		if ([unreadStatuses containsObject:[NSNumber numberWithInt:0]])
			[menu addItem:INT_markAsUnreadItem];
		[menu addItem:[NSMenuItem separatorItem]];
	}
	[menu addItem:INT_showInspectorItem];
	return [menu autorelease];
}



#pragma mark Scrolling

- (BOOL)scrollEntryToVisible:(INTEntry *)entry
{
	NSRect rect = [self rectForEntry:entry];
	rect = NSInsetRect(rect, -(INT_constitutionLabelExtraWidth / 2.0f), 0.0f);
	rect = NSOffsetRect(rect, -(INT_constitutionLabelExtraWidth / 2.0f), 0.0f);
	return [self scrollRectToVisible:rect];
}


- (BOOL)isEventTrackingSelection // INTEntriesView (INTProtectedMethods)
{
	return INT_isEventTrackingSelection;
}


- (void)setEventTrackingSelection:(BOOL)tracking // INTEntriesView (INTProtectedMethods)
{
	INT_isEventTrackingSelection = tracking;
}




#pragma mark Displaying

- (void)updateFrameSize // INTEntriesView (INTPrivateMethods)
{
	unsigned maxPrincipleCount = 0;
	INTConstitution *currConstitution = nil;
	float width = -[self intercellSpacing].width;
	NSEnumerator *entries = [[self sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		if ([currEntry constitution] != currConstitution)
		{
			currConstitution = [currEntry constitution];
			width += [self widthForConstitution:currConstitution] + [self intercellSpacing].width;
		}
		maxPrincipleCount = MAX([[currEntry annotatedPrinciples] count], maxPrincipleCount);
		width += [self columnWidth] + [self intercellSpacing].width;
	}
	
	float height = (maxPrincipleCount * [self rowHeight]) + (MAX(0, (int)maxPrincipleCount - 1) * [self intercellSpacing].height);
	INT_minimumFrameSize = NSMakeSize(width, height);
	
	[self clipViewFrameDidChangeChange:nil];
}



#pragma mark Managing clip view bounds changes

- (void)clipViewFrameDidChangeChange:(NSNotification *)notification // INTEntriesView (INTProtectedMethods)
{
	BOOL wasMaxXVisible = abs(NSMaxX([self visibleRect]) - NSMaxX([self frame])) < 1.0f;
	
	NSSize newFrameSize = [self minimumFrameSize];
	NSSize newClipViewSize = [[[self enclosingScrollView] contentView] bounds].size;
	newFrameSize.width  = fmaxf(newClipViewSize.width , newFrameSize.width );
	newFrameSize.height = fmaxf(newClipViewSize.height, newFrameSize.height);
	
	if (!NSEqualSizes([self frame].size, newFrameSize))
	{
		[self setFrameSize:newFrameSize];
		if (wasMaxXVisible)
			[self scrollPoint:NSMakePoint(NSMaxX([self frame]) - NSWidth([self visibleRect]), NSMinY([self visibleRect]))];
	}
	
	NSSize headerFrameSize = [[self headerView] frame].size;
	headerFrameSize.width = newFrameSize.width;
	if (!NSEqualSizes([[self headerView] frame].size, headerFrameSize))
		[[self headerView] setFrameSize:headerFrameSize];
	
	[self setNeedsDisplay:YES];
	[[self headerView] setNeedsDisplay:YES];
}



#pragma mark Drawing

- (void)drawRect:(NSRect)rect // NSView
{
	if ([[INTAppController sharedAppController] isSyncing])
		return;
	
	[self removeAllToolTips];
	
	// Draw background
	[[self backgroundColor] set];
	NSRectFill(rect);
	
	
	// Draw entries
	INTConstitution *currConstitution = nil;
	float currConstitutionWidth = NAN;
	float currConstitutionMinX = 0.0f;
	NSMutableArray *constitutionPositions = [[NSMutableArray alloc] init];
	unsigned prevEntryIndex = 0;
	float currEntryMaxX = -[self intercellSpacing].width;
	NSEnumerator *entries = [[self sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		// Save constitution positions, but don't draw them on-screen yet
		if ([currEntry constitution] != currConstitution)
		{
			if (currConstitution)
				[constitutionPositions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					currConstitution, @"constitution",
					[NSNumber numberWithFloat:currConstitutionMinX], @"minMinX",
					[NSNumber numberWithFloat:(currEntryMaxX - [self columnWidth] - currConstitutionWidth)], @"maxMinX",
					nil]];
			
			currConstitution = [currEntry constitution];
			currConstitutionMinX = currEntryMaxX + [self intercellSpacing].width;
			currConstitutionWidth = [self widthForConstitution:currConstitution];
			currEntryMaxX += currConstitutionWidth + [self intercellSpacing].width;
		}
		
		float currEntryMinX = currEntryMaxX + [self intercellSpacing].width;
		currEntryMaxX += [self columnWidth] + [self intercellSpacing].width;
		prevEntryIndex++;
		if (currEntryMaxX < NSMinX(rect))
			continue;
		if (currEntryMinX > NSMaxX(rect))
			continue;
		
		[[NSColor gridColor] set];
		[NSBezierPath fillRect:NSMakeRect(currEntryMaxX, NSMinY([self bounds]), [self intercellSpacing].height, NSHeight([self bounds]))];
		
		if ([[self selectionIndexes] containsIndex:(prevEntryIndex - 1)])
		{
			// Entry is selected
			if ([[self window] isKeyWindow] && ([[self window] firstResponder] == self))
				[[NSColor selectedControlColor] set];
			else
				[[NSColor secondarySelectedControlColor] set];
			[NSBezierPath fillRect:[self rectForEntry:currEntry]];
		}
		
		
		float currPrincipleMaxY = -[self intercellSpacing].height;
		NSEnumerator *principles = [[[currEntry constitution] principles] objectEnumerator];
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
			
			NSSize cellSize = [cell cellSizeForBounds:NSMakeRect(0.0f, 0.0f, NSWidth(gridFrame), NSHeight(gridFrame))];
			
			NSRect cellFrame = gridFrame;
			cellFrame.origin.x = NSMidX(gridFrame) - cellSize.width / 2.0f;
			cellFrame.origin.y = NSMidY(gridFrame) - cellSize.height / 2.0f;
			cellFrame.size = cellSize;
			
			[cell drawWithFrame:cellFrame inView:self];
		}
	}
	
	if (currConstitution)
		[constitutionPositions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			currConstitution, @"constitution",
			[NSNumber numberWithFloat:currConstitutionMinX], @"minMinX",
			[NSNumber numberWithFloat:(currEntryMaxX - [self columnWidth] - [self intercellSpacing].width - currConstitutionWidth)], @"maxMinX",
			nil]];
	
	
	// Draw constitutions
	INT_constitutionLabelExtraWidth = 0.0f;
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
		float constitutionWidth = [self widthForConstitution:constitution];
		
		[[self backgroundColor] set];
		NSRectFill(NSMakeRect(minX, NSMinY([self bounds]), constitutionWidth, NSHeight([self bounds])));
		
		float currPrincipleMaxY = -[self intercellSpacing].height;
		NSCell *principleCell = [self principleLabelCell];
		NSEnumerator *principles = [[constitution principles] objectEnumerator];
		INTPrinciple *currPrinciple;
		while ((currPrinciple = [principles nextObject]))
		{
			float currPrincipleMinY = currPrincipleMaxY + [self intercellSpacing].height;
			currPrincipleMaxY += [self rowHeight] + [self intercellSpacing].height;
			if (currPrincipleMaxY < NSMinY(rect))
				continue;
			if (currPrincipleMinY > NSMaxY(rect))
				break;
			
			[principleCell setStringValue:[currPrinciple label]];
			
			// The frame of the text cell (inset by the principle label padding)
			NSRect cellFrame = NSInsetRect(NSMakeRect(minX, currPrincipleMinY, constitutionWidth, [self rowHeight]), INTPrincipleLabelXPadding, 0.0f);
			cellFrame = NSOffsetRect(cellFrame, 0.0f, (NSHeight(cellFrame) - [principleCell cellSize].height) / 2.0f);
			[principleCell drawWithFrame:cellFrame inView:self];
			
			// The full frame of the principle, including padding, for tooltip
			NSRect toolTipFrame = NSMakeRect(minX, currPrincipleMinY, constitutionWidth, currPrincipleMaxY - currPrincipleMinY);
			[self addToolTipRect:toolTipFrame
						   owner:[currPrinciple explanation]
						userData:NULL];
		}
		
		[[NSColor gridColor] set];
		[NSBezierPath fillRect:NSMakeRect(minX + constitutionWidth, NSMinY([self bounds]), [self intercellSpacing].height, NSHeight([self bounds]))];
		
		if (minX == NSMinX([self visibleRect]))
			INT_constitutionLabelExtraWidth = constitutionWidth;
	}
	
	[constitutionPositions release];
	
	
	// Draw grid
	[[NSColor gridColor] set];
	for (float y = [self rowHeight]; y < NSHeight([self bounds]); y += [self rowHeight] + [self intercellSpacing].width)
		[NSBezierPath fillRect:NSMakeRect(NSMinX([self bounds]), y, NSWidth([self bounds]), [self intercellSpacing].width)];
	for (float x = currEntryMaxX; x < NSWidth([self bounds]); x += [self columnWidth] + [self intercellSpacing].height)
		[NSBezierPath fillRect:NSMakeRect(x, NSMinY([self bounds]), [self intercellSpacing].height, NSHeight([self bounds]))];
}



#pragma mark Layout

- (INTEntry *)entryAtXLocation:(float)x // INTEntriesView (INTProtectedMethods)
{
	if ((x < NSMinX([self bounds])) || (x > NSMaxX([self bounds])))
		return nil;
	
	INTConstitution *currConstitution = nil;
	float currEntryMaxX = -[self intercellSpacing].width;
	NSEnumerator *entries = [[self sortedEntries] objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entries nextObject]))
	{
		if ([currEntry constitution] != currConstitution)
		{
			currConstitution = [currEntry constitution];
			currEntryMaxX += [self widthForConstitution:currConstitution] + [self intercellSpacing].width;
		}
		float currEntryMinX = currEntryMaxX + [self intercellSpacing].width;
		currEntryMaxX += [self columnWidth] + [self intercellSpacing].width;
		
		if ((x >= currEntryMinX) && (x <= currEntryMaxX))
			return currEntry;
	}
	
	// Not found
	return nil;
}


- (INTEntry *)entryAtPoint:(NSPoint)point // INTEntriesView (INTPrivateMethods)
{
	if (NSPointInRect(point, [self bounds]))
		return [self entryAtXLocation:point.x];
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
		INTPrinciple *principle = [[[entry constitution] principles] objectAtIndex:principleIndex];
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
	unsigned annotatedPrincipleIndex = [[[entry constitution] principles] indexOfObject:[annotatedPrinciple principle]];
	if (![[self sortedEntries] containsObject:entry] || (annotatedPrincipleIndex == NSNotFound))
		return NSZeroRect;
	else
	{
		NSRect entryRect = [self rectForEntry:entry];
		NSRect principleRowRect = NSMakeRect(NSMinX([self bounds]),
											 annotatedPrincipleIndex * ([self rowHeight] + [self intercellSpacing].height),
											 NSWidth([self bounds]),
											 [self rowHeight]);
		return NSIntersectionRect(entryRect, principleRowRect);
	}
}


- (NSRect)rectForEntry:(INTEntry *)entry // INTEntriesView (INTPrivateMethods)
{
	if (![[self sortedEntries] containsObject:entry])
		return NSZeroRect;
	else
	{
		INTConstitution *currConstitution = nil;
		float currEntryMaxX = -[self intercellSpacing].width;
		NSEnumerator *entries = [[self sortedEntries] objectEnumerator];
		INTEntry *currEntry;
		while ((currEntry = [entries nextObject]))
		{
			if ([currEntry constitution] != currConstitution)
			{
				currConstitution = [currEntry constitution];
				currEntryMaxX += [self widthForConstitution:currConstitution] + [self intercellSpacing].width;
			}
			float currEntryMinX = currEntryMaxX + [self intercellSpacing].width;
			currEntryMaxX += [self columnWidth] + [self intercellSpacing].width;
			
			if (currEntry == entry)
				return NSMakeRect(currEntryMinX,
								  NSMinY([self bounds]),
								  [self columnWidth],
								  NSHeight([self bounds]));
		}
		
		NSLog(@"Unexpectedly couldn't get rect for entry");
		return NSZeroRect;
	}
}


- (float)widthForConstitution:(INTConstitution *)constitution // INTEntriesView (INTProtectedMethods)
{
	float maxCellWidth = 0.0f;
	NSCell *cell = [self principleLabelCell];
	NSEnumerator *principles = [[constitution principles] objectEnumerator];
	INTPrinciple *principle;
	while ((principle = [principles nextObject]))
	{
		if ([principle label])
		{
			[cell setStringValue:[principle label]];
			maxCellWidth = fmaxf(maxCellWidth, [cell cellSize].width);
		}
	}
	maxCellWidth += 2.0f * INTPrincipleLabelXPadding;
	
	return ceilf(MAX(maxCellWidth, [(INTEntriesHeaderView *)[self headerView] headerWidthForConstitution:constitution]));
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
