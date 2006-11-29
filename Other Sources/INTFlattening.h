//
//  INTFlattening.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray (INTFlattening)

#pragma mark Flattening the array
- (NSArray *)flattenedArray;

@end


@interface NSSet (INTFlattening)

#pragma mark Flattening the set
- (NSArray *)flattenedArray;

@end
