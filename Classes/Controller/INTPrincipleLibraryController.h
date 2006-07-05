//
//  INTPrincipleLibraryController.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface INTPrincipleLibraryController : NSWindowController
{
	@public
	IBOutlet NSView *principleInspectorView;
}


#pragma mark Core Data
- (NSManagedObjectContext *)managedObjectContext;

@end
