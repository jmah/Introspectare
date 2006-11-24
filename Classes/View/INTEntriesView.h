//
//  INTEntriesView.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-21.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTLibrary;
@class INTEntriesHeaderView;
@class INTEntriesCornerView;
@class INTAnnotatedPrinciple;


@interface INTEntriesView : NSView
{
	@private
	INTLibrary *INT_library;
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
	NSArray *INT_cachedSortedEntries;
	BOOL INT_clipViewDidPostFrameChangeNotifications;
	float INT_prevClipViewFrameWidth;
	NSCell *INT_principleLabelCell;
	NSActionCell *INT_dataCell;
	INTAnnotatedPrinciple *INT_selectedAnnotatedPrinciple; // Weak reference
	NSActionCell *INT_selectedDataCell; // Weak reference
}


#pragma mark Creating an entries view
- (id)initWithFrame:(NSRect)frame library:(INTLibrary *)library;
- (id)initWithFrame:(NSRect)frame library:(INTLibrary *)library calendar:(NSCalendar *)calendar; // Designated initializer

#pragma mark Getting the calendar
- (NSCalendar *)calendar;

#pragma mark Getting the library
- (INTLibrary *)library;

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

@end
