//
//  INTEntriesHeaderView.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-22.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTEntriesView;


@interface INTEntriesHeaderView : NSView
{
	@private
	INTEntriesView *INT_entriesView; // Weak reference
	NSTableHeaderCell *INT_headerCell;
	NSDateFormatter *INT_dateFormatter;
}


#pragma mark Creating an entries header view
- (id)initWithFrame:(NSRect)frame entriesView:(INTEntriesView *)entriesView; // Designated initializer

#pragma mark Getting the entries view
- (INTEntriesView *)entriesView;

@end
