//
//  INTEntriesHeaderCell.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-25.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntriesHeaderCell.h"


@implementation INTEntriesHeaderCell

#pragma mark Drawing

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	[NSGraphicsContext saveGraphicsState];
	// NSTableHeaderCell likes to draw below it should, so we'll clip it
	[NSBezierPath clipRect:frame];
	[super drawWithFrame:frame inView:controlView];
	[NSGraphicsContext restoreGraphicsState];
}


@end
