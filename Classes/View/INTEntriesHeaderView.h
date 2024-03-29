//
//  INTEntriesHeaderView.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-22.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTEntriesView;
@class INTEntriesHeaderCell;


@interface INTEntriesHeaderView : NSView
{
	@private
	INTEntriesView *INT_entriesView; // Weak reference
	INTEntriesHeaderCell *INT_headerCell;
	NSDateFormatter *INT_dateFormatter;
	
	float INT_constitutionLabelExtraWidth;
	NSMutableArray *INT_toolTipStrings;
}


#pragma mark Creating an entries header view
- (id)initWithFrame:(NSRect)frame entriesView:(INTEntriesView *)entriesView; // Designated initializer

#pragma mark Getting the entries view
- (INTEntriesView *)entriesView;

@end
