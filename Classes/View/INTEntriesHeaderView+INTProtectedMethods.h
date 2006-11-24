//
//  INTEntriesHeaderView+INTProtectedMethods.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-25.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INTEntriesHeaderView.h"

@class INTConstitution;


@interface INTEntriesHeaderView (INTProtectedMethods)

#pragma mark Layout
- (float)headerWidthForConstitution:(INTConstitution *)constitution;

@end
