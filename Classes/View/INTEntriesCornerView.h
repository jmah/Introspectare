//
//  INTEntriesCornerView.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-22.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INTEntriesView;


@interface INTEntriesCornerView : NSView
{
	@private
	INTEntriesView *INT_entriesView; // Weak reference
	NSTableHeaderCell *INT_cornerCell;
}


#pragma mark Creating an entries corner view
- (id)initWithFrame:(NSRect)frame entriesView:(INTEntriesView *)entriesView; // Designated initializer

#pragma mark Getting the entries view
- (INTEntriesView *)entriesView;

@end
