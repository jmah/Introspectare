//
//  INTEntriesView+INTProtectedMethods.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-23.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INTEntriesView.h"

@class INTEntry;
@class INTConstitution;


@interface INTEntriesView (INTProtectedMethods)

#pragma mark Managing entries
- (NSArray *)sortedEntries;

#pragma mark Calculating element positions
//- (float)xPositionForEntry:(INTEntry *)entry;
//- (float)xPositionForConstitution:(INTConstitution *)constitution;

@end
