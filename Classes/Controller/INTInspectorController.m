//
//  INTInspectorController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-23.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTInspectorController.h"
#import "INTShared.h"
#import "INTAppController.h"
#import "INTLibrary.h"


@interface INTInspectorController (INTPrivateMethods)

#pragma mark Managing the inspector view
- (void)mainWindowDidChange:(NSNotification *)notification;
- (void)windowDidBecomeMain:(NSWindow *)window;
- (void)windowDidResignMain:(NSWindow *)window;
- (NSView *)inspectorView;
- (void)setInspectorView:(NSView *)newView;

@end


@implementation INTInspectorController

#pragma mark Initializing

- (void)awakeFromNib
{
	[self setWindowFrameAutosaveName:@"INTInspectorFrame"];
}


- (void)dealloc
{
	[INT_defaultView release], INT_defaultView = nil;
	[super dealloc];
}



#pragma mark Showing and closing the window

- (IBAction)showWindow:(id)sender // NSWIndowController
{
	[super showWindow:sender];
	
	INT_defaultView = [[[self window] contentView] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(mainWindowDidChange:)
	                                             name:NSWindowDidResignMainNotification
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(mainWindowDidChange:)
	                                             name:NSWindowDidBecomeMainNotification
	                                           object:nil];
	
	[self windowDidBecomeMain:[NSApp mainWindow]];
}


- (void)close // NSWindowController
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:NSWindowDidBecomeMainNotification
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:NSWindowDidResignMainNotification
	                                              object:nil];
	
	if (INT_observedWindowController)
	{
		[INT_observedWindowController removeObserver:self
										  forKeyPath:@"inspectorView"];
		INT_observedWindowController = nil;
	}
	
	[super close];
}



#pragma mark Managing the inspector view

- (void)mainWindowDidChange:(NSNotification *)notification // INTInspectorController (INTPrivateMethods)
{
	if ([[notification name] isEqualToString:NSWindowDidResignMainNotification])
		[self windowDidResignMain:[notification object]];
	else if ([[notification name] isEqualToString:NSWindowDidBecomeMainNotification])
		[self windowDidBecomeMain:[notification object]];
}


- (void)windowDidBecomeMain:(NSWindow *)window // INTInspectorController (INTPrivateMethods)
{
	NSView *newInspectorView = INT_defaultView;
	NSWindowController *windowController = [window windowController];
	if (windowController && [windowController respondsToSelector:@selector(inspectorView)])
	{
		INT_observedWindowController = windowController;
		[INT_observedWindowController addObserver:self
									   forKeyPath:@"inspectorView"
										  options:NSKeyValueObservingOptionNew
										  context:NULL];
		newInspectorView = [INT_observedWindowController valueForKey:@"inspectorView"];
		if (!newInspectorView)
			newInspectorView = INT_defaultView;
	}
	[self setInspectorView:newInspectorView];
}


- (void)windowDidResignMain:(NSWindow *)window // INTInspectorController (INTPrivateMethods)
{
	if (INT_observedWindowController)
	{
		[INT_observedWindowController removeObserver:self
										  forKeyPath:@"inspectorView"];
		INT_observedWindowController = nil;
	}
	[self setInspectorView:INT_defaultView];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context // NSObject
{
	BOOL handled = NO;
	if (object == INT_observedWindowController)
		if ([keyPath isEqualToString:@"inspectorView"])
		{
			NSView *newInspectorView = [change objectForKey:NSKeyValueChangeNewKey];
			if (!newInspectorView)
				newInspectorView = INT_defaultView;
			[self setInspectorView:newInspectorView];
			handled = YES;
		}
	
	if (!handled)
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
}



- (NSView *)inspectorView // INTInspectorController (INTPrivateMethods)
{
	return [[self window] contentView];
}


- (void)setInspectorView:(NSView *)newView // INTInspectorController (INTPrivateMethods)
{
	[[self window] setContentView:newView];
}



#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window // NSObject (NSWindowDelegate)
{
	return [[INTAppController sharedAppController] undoManager];
}


@end
