//
//  INTLibrary+INTEntriesView.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-23.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INTLibrary.h"


@interface INTLibrary (INTEntriesView)

#pragma mark Accessing constitutions
- (unsigned)constitutionCountBeforeDate:(NSDate *)date;

@end
