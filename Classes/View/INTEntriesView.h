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


@interface INTEntriesView : NSView
{
	@private
	INTLibrary *INT_library;
	NSCalendar *INT_calendar;
	float INT_rowHeight;
	float INT_interrowSpacing;
	float INT_headerHeight;
	float INT_columnWidth;
	NSFont *INT_headerFont;
	NSFont *INT_principleFont;
	INTEntriesHeaderView *INT_headerView;
	INTEntriesCornerView *INT_cornerView;
	NSSize INT_minimumFrameSize;
	NSArray *INT_cachedSortedEntries;
	BOOL INT_clipViewDidPostFrameChangeNotifications;
	float INT_prevClipViewFrameWidth;
}


#pragma mark Creating an entries view
- (id)initWithFrame:(NSRect)frame library:(INTLibrary *)library;
- (id)initWithFrame:(NSRect)frame library:(INTLibrary *)library calendar:(NSCalendar *)calendar; // Designated initializer

#pragma mark Getting the calendar
- (NSCalendar *)calendar;

#pragma mark Getting the library
- (INTLibrary *)library;

#pragma mark Setting display attributes
- (float)rowHeight;
- (void)setRowHeight:(float)rowHeight;
- (float)interrowSpacing;
- (void)setInterrowSpacing:(float)interrowSpacing;
- (float)headerHeight;
- (float)columnWidth;
- (void)setColumnWidth:(float)columnWidth;
- (NSFont *)headerFont;
- (void)setHeaderFont:(NSFont *)headerFont;
- (NSFont *)principleFont;
- (void)setPrincipleFont:(NSFont *)principleFont;

@end
