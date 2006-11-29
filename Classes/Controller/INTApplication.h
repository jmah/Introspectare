//
//  INTApplication.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface INTApplication : NSApplication
{
	@private
	BOOL INT_delegateRespondsToDidSendEvent;
}

@end


@interface NSObject (INTApplicationDelegate)

- (void)applicationDidSendEvent:(NSEvent *)event;

@end
