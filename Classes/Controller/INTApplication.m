//
//  INTApplication.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-30.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTApplication.h"


// NSNotification names
NSString *INTApplicationIdleNotificationName = @"INTApplicationIdleNotification";

static NSNotification *idleNotification = nil;


@interface INTApplication (INTPrivateMethods)

#pragma mark Idle notifications
- (void)applicationIsIdle:(NSNotification *)notification;

@end


@implementation INTApplication

#pragma mark Creating and initializing an NSApplication object

- (void)finishLaunching
{
	[super finishLaunching];
	if (!idleNotification)
		idleNotification = [[NSNotification notificationWithName:INTApplicationIdleNotificationName object:self] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationIsIdle:)
												 name:INTApplicationIdleNotificationName
											   object:self];
}



#pragma mark Handling user attention requests

- (BOOL)ignoresUserAttentionRequests
{
	return INT_ignoresUserAttentionRequests;
}


- (void)setIgnoresUserAttentionRequests:(BOOL)ignores
{
	INT_ignoresUserAttentionRequests = ignores;
}


- (int)requestUserAttention:(NSRequestUserAttentionType)requestType // NSApplication
{
	if ([self ignoresUserAttentionRequests])
		return 0;
	else
		return [super requestUserAttention:requestType];
}



#pragma mark Running the event loop

- (void)sendEvent:(NSEvent *)event
{
	if (INT_idleTarget)
		[[NSNotificationQueue defaultQueue] enqueueNotification:idleNotification
												   postingStyle:NSPostWhenIdle
												   coalesceMask:NSNotificationCoalescingOnName
													   forModes:nil];
	[super sendEvent:event];
}



#pragma mark Idle notifications

- (void)performSelector:(SEL)selector withTarget:(id)target afterIdleInterval:(NSTimeInterval)idleTime
{
	/*
	 * This method currently only allows one target/selector pair to be
	 * scheduled at a time. It would be nice to generalize this to call an
	 * arbitrary number of callbacks. There would also need to be a way to
	 * cancel a callback.
	 */
	INT_idleSelector = selector;
	INT_idleTarget = target;
	INT_idleInterval = idleTime;
	[[NSNotificationQueue defaultQueue] enqueueNotification:idleNotification
											   postingStyle:NSPostWhenIdle
											   coalesceMask:NSNotificationCoalescingOnName
												   forModes:nil];
}


- (void)applicationIsIdle:(NSNotification *)notification // INTApplication (INTPrivateMethods)
{
	[INT_idleTimer invalidate], INT_idleTimer = nil;
	if (INT_idleTarget)
		INT_idleTimer = [NSTimer scheduledTimerWithTimeInterval:INT_idleInterval
														 target:self
													   selector:@selector(idleTimerExpired:)
													   userInfo:nil
														repeats:NO];
}


- (void)idleTimerExpired:(NSTimer *)timer // INTApplication (INTPrivateMethods)
{
	INT_idleTimer = nil;
	[INT_idleTarget performSelector:INT_idleSelector];
	INT_idleTarget = nil;
	INT_idleSelector = NULL;
}


@end
