//
//  INTInspectorController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-23.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface INTInspectorController : NSWindowController
{
	@private
	NSView *INT_defaultView;
	NSWindowController *INT_observedWindowController;
}



@end
