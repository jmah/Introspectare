//
//  INTEntriesHeaderCell.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-25.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface INTEntriesHeaderCell : NSTableHeaderCell
{
	@private
	NSTextFieldCell *INT_textFieldCell;
	NSColor *INT_tintColor;
}


#pragma mark Creating an entries header cell
- (id)initTextCell:(NSString *)string; // Designated initializer

#pragma mark Modifying the cell's tint
- (NSColor *)tintColor;
- (void)setTintColor:(NSColor *)tintColor;

@end
