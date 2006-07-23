//
//  INTActiveControlEnumerator.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-23.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*
 * This class takes a window and enumerates its "active" controls. The purpose
 * of using this enumerator, instead of repeatedly calling -nextResponder on
 * an NSResponder object, is that it handles the field editor differently. If
 * there is a field editor, it will be followed by the control being edited,
 * and enumeration will proceed up that control's responder chain.
 *
 * The window is not retained.
 *
 * If the window's first responder changes during enumeration, the behavior is
 * undefined.
 */


@interface INTActiveControlEnumerator : NSEnumerator
{
	@private
	NSWindow *INT_window; // Weak reference
	NSResponder *INT_currResponder; // Weak reference
	
}


#pragma mark Creating an active control enumerator
- (id)initWithWindow:(NSWindow *)window;

@end


@interface NSWindow (INTActiveControlEnumerator)

#pragma mark Enumerating active controls
- (NSEnumerator *)activeControlEnumerator;

@end
