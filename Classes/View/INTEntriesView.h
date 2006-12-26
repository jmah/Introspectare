//
//  INTEntriesView.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-21.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTEntry;
@class INTEntriesHeaderView;
@class INTEntriesCornerView;
@class INTAnnotatedPrinciple;


@interface INTEntriesView : NSView
{
	@private
	NSCalendar *INT_calendar;
	NSColor *INT_backgroundColor;
	float INT_rowHeight;
	NSSize INT_intercellSpacing;
	float INT_headerHeight;
	float INT_columnWidth;
	NSFont *INT_headerFont;
	INTEntriesHeaderView *INT_headerView;
	INTEntriesCornerView *INT_cornerView;
	NSSize INT_minimumFrameSize;
	BOOL INT_clipViewDidPostFrameChangeNotifications;
	float INT_prevClipViewFrameWidth;
	NSCell *INT_principleLabelCell;
	NSActionCell *INT_dataCell;
	NSIndexSet *INT_selectionIndexes;
	INTAnnotatedPrinciple *INT_selectedAnnotatedPrinciple; // Weak reference
	NSActionCell *INT_selectedDataCell; // Weak reference
	BOOL INT_isEventTrackingSelection;
	
	float INT_constitutionLabelExtraWidth;
	
	// Contextual menu items
	NSMenuItem *INT_markAsReadItem;
	NSMenuItem *INT_markAsUnreadItem;
	NSMenuItem *INT_showInspectorItem;
	
	// Bindings
	NSObject *INT_entriesContainer;
	NSString *INT_entriesKeyPath;
	
	NSArray *INT_observedEntries;
}


#pragma mark Creating an entries view
- (id)initWithFrame:(NSRect)frame;
- (id)initWithFrame:(NSRect)frame calendar:(NSCalendar *)calendar; // Designated initializer

#pragma mark Getting the calendar
- (NSCalendar *)calendar;

#pragma mark Setting display attributes
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)color;
- (float)rowHeight;
- (void)setRowHeight:(float)rowHeight;
- (NSSize)intercellSpacing;
- (void)setIntercellSpacing:(NSSize)spacing;
- (float)headerHeight;
- (float)columnWidth;
- (void)setColumnWidth:(float)columnWidth;
- (NSFont *)headerFont;
- (void)setHeaderFont:(NSFont *)headerFont;
- (NSFont *)principleFont;
- (void)setPrincipleFont:(NSFont *)principleFont;

#pragma mark Setting component cells
- (NSCell *)principleLabelCell;
- (void)setPrincipleLabelCell:(NSCell *)cell;
- (NSActionCell *)dataCell;
- (void)setDataCell:(NSActionCell *)cell;

#pragma mark Managing selection
- (NSIndexSet *)selectionIndexes;
- (void)setSelectionIndexes:(NSIndexSet *)indexes;
- (NSArray *)selectedObjects;

#pragma mark Scrolling
- (BOOL)scrollEntryToVisible:(INTEntry *)entry;

@end
