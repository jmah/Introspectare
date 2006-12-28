//
//  INTApplication.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-30.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface INTApplication : NSApplication
{
	@private
	BOOL INT_ignoresUserAttentionRequests;
	id INT_idleTarget;
	SEL INT_idleSelector;
	NSTimeInterval INT_idleInterval;
	NSTimer *INT_idleTimer;
}


#pragma mark Handling user attention requests
- (BOOL)ignoresUserAttentionRequests;
- (void)setIgnoresUserAttentionRequests:(BOOL)ignores;

#pragma mark Idle notifications
- (void)performSelector:(SEL)selector withTarget:(id)target afterIdleInterval:(NSTimeInterval)idleTime;

@end
