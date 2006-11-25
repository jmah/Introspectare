//
//  INTCircleSwitchButtonCell.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-25.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTCircleSwitchButtonCell.h"


#pragma mark Size constants

static const float INTRegularSizeWidth = 8.f;
static const float INTSmallSizeWidth = 6.f;
static const float INTMiniSizeWidth = 4.f;



#pragma mark Helper functions

static NSRect INTMakeCenteredRect(NSRect enclosingRect, NSSize size)
{
	NSRect rect = enclosingRect;
	rect.size = size;
	rect.origin.x += (NSWidth(enclosingRect) - size.width) / 2.f;
	rect.origin.y += (NSHeight(enclosingRect) - size.height) / 2.f;
	return rect;
}


#pragma mark -


@implementation INTCircleSwitchButtonCell

#pragma mark Drawing

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView // NSCell
{
	NSRect circleFrame = INTMakeCenteredRect(cellFrame, [self cellSize]);
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:circleFrame];
	
	[NSGraphicsContext saveGraphicsState];
	[[NSColor whiteColor] set];
	[circle fill];
	
	[[NSColor grayColor] set];
	[circle stroke];
	
	if ([self state] == NSOnState)
		[circle fill];
	
	if ([self isHighlighted])
	{
		[[NSColor lightGrayColor] set];
		[circle fill];
	}
	[NSGraphicsContext restoreGraphicsState];
}



#pragma mark Determining cell sizes

- (NSSize)cellSize // NSCell
{
	NSSize size = NSZeroSize;
	switch ([self controlSize])
	{
		case NSRegularControlSize:
			size = NSMakeSize(INTRegularSizeWidth, INTRegularSizeWidth);
			break;
		case NSSmallControlSize:
			size = NSMakeSize(INTSmallSizeWidth, INTSmallSizeWidth);
			break;
		case NSMiniControlSize:
			size = NSMakeSize(INTMiniSizeWidth, INTMiniSizeWidth);
			break;
	}
	return size;
}


@end
