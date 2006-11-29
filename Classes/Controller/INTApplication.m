//
//  INTApplication.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTApplication.h"


@implementation INTApplication

#pragma mark Creating an application object

- (id)init // Designated initializer
{
	if ((self = [super init]))
	{
		INT_delegateRespondsToDidSendEvent = NO;
	}
	return self;
}



#pragma mark Running the event loop

- (void)sendEvent:(NSEvent *)event // NSApplication
{
	[super sendEvent:event];
	if (INT_delegateRespondsToDidSendEvent)
		[[self delegate] applicationDidSendEvent:event];
}



#pragma mark Assigning a delegate

- (void)setDelegate:(id)delegate // NSApplication
{
	INT_delegateRespondsToDidSendEvent = [delegate respondsToSelector:@selector(applicationDidSendEvent:)];
	[super setDelegate:delegate];
}


@end
