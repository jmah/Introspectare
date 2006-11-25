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

#pragma mark Scrolling
- (BOOL)isEventTrackingSelection;
- (void)setEventTrackingSelection:(BOOL)tracking;

#pragma mark Layout
- (INTEntry *)entryAtXLocation:(float)x;
- (float)widthForConstitution:(INTConstitution *)constitution;

@end
