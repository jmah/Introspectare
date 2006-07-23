//
//  INTActiveControlEnumerator.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-23.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTActiveControlEnumerator.h"


@implementation INTActiveControlEnumerator

#pragma mark Creating an active control enumerator

- (id)initWithWindow:(NSWindow *)window
{
	if ((self = [super init]))
	{
		INT_window = window;
		INT_currResponder = nil;
	}
	return self;
}


- (void)dealloc
{
	[super dealloc];
}



#pragma mark Enumerating active controls

- (id)nextObject // NSEnumerator
{
	if (INT_currResponder)
	{
#warning Test this method
		// Check if the current responder is the window's field editor
		if ([INT_currResponder isKindOfClass:[NSTextView class]] &&
		    (INT_currResponder == [INT_window fieldEditor:NO forObject:nil]))
			// The current responder is the field editor; the next responder will be the control being edited
			INT_currResponder = [(NSTextView *)INT_currResponder delegate];
		else
			INT_currResponder = [INT_currResponder nextResponder];
	}
	else
		INT_currResponder = [INT_window firstResponder];
	
	return INT_currResponder;
}


@end


#pragma mark -


@implementation NSWindow (INTActiveControlEnumerator)

#pragma mark Enumerating active controls

- (NSEnumerator *)activeControlEnumerator
{
	return [[[INTActiveControlEnumerator alloc] initWithWindow:self] autorelease];
}


@end
