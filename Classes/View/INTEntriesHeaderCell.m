//
//  INTEntriesHeaderCell.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-25.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesHeaderCell.h"


@implementation INTEntriesHeaderCell

#pragma mark Creating an entries header cell

- (id)initTextCell:(NSString *)string // Designated initializer
{
	if ((self = [super initTextCell:string]))
	{
		INT_textFieldCell = [[NSTextFieldCell alloc] initTextCell:string];
		INT_tintColor = [[NSColor clearColor] retain];
	}
	return self;
}


- (void)dealloc
{
	[INT_textFieldCell release], INT_textFieldCell = nil;
	[INT_tintColor release], INT_tintColor = nil;
	
	[super dealloc];
}



#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	INTEntriesHeaderCell *copiedCell = [super copyWithZone:zone];
	copiedCell->INT_textFieldCell = [INT_textFieldCell copyWithZone:zone];
	copiedCell->INT_tintColor = [INT_tintColor copyWithZone:zone];
	return copiedCell;
}



#pragma mark Modifying textual attributes of cells

- (void)setFont:(NSFont *)font // NSCell
{
	[super setFont:font];
	[INT_textFieldCell setFont:font];
}


- (void)setAlignment:(NSTextAlignment)mode // NSCell
{
	[super setAlignment:mode];
	[INT_textFieldCell setAlignment:mode];
}


- (void)setLineBreakMode:(NSLineBreakMode)mode // NSCell
{
	[super setLineBreakMode:mode];
	[INT_textFieldCell setLineBreakMode:mode];
}


- (void)setWraps:(BOOL)wraps // NSCell
{
	[super setWraps:wraps];
	[INT_textFieldCell setWraps:wraps];
}


- (void)setStringValue:(NSString *)string // NSCell
{
	[super setStringValue:string];
	[INT_textFieldCell setStringValue:string];
}


- (void)setTextColor:(NSColor *)color // NSCell
{
	[super setTextColor:color];
	[INT_textFieldCell setTextColor:color];
}



#pragma mark Modifying the cell's tint

- (NSColor *)tintColor
{
	return INT_tintColor;
}


- (void)setTintColor:(NSColor *)tintColor
{
	id oldValue = INT_tintColor;
	INT_tintColor = [tintColor copy];
	[oldValue release];
}



#pragma mark Drawing

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	[NSGraphicsContext saveGraphicsState];
	// NSTableHeaderCell likes to draw below it should, so we'll clip it
	[NSBezierPath clipRect:frame];
	
	// If we have a custom tint or text color, we have to draw the text separately
	if (![[self tintColor] isEqual:[NSColor clearColor]] || ![[self textColor] isEqual:[NSColor headerTextColor]])
	{
		[super setStringValue:[NSString string]];
		
		// Keep track of this here, because -[NSTableHeaderCell drawWithFrame:inView:] will reset it
		NSColor *textColor = [self textColor];
		[super drawWithFrame:frame inView:controlView];
		[self setTextColor:textColor];
	
		[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusDarker];
		[[self tintColor] set];
		[NSBezierPath fillRect:frame];
		
		[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeSourceOver];
		NSRect textCellFrame = NSInsetRect(frame, 0.0f, 1.0f);
		[INT_textFieldCell drawInteriorWithFrame:textCellFrame inView:controlView];
		
		[super setStringValue:[INT_textFieldCell stringValue]];
	}
	else
		[super drawWithFrame:frame inView:controlView];
	
	[NSGraphicsContext restoreGraphicsState];
}


@end
