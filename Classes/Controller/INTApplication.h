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
}


#pragma mark Handling user attention requests
- (BOOL)ignoresUserAttentionRequests;
- (void)setIgnoresUserAttentionRequests:(BOOL)ignores;

@end
