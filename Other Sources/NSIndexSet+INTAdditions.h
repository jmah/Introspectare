//
//  NSIndexSet+INTAdditions.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-26.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSIndexSet (INTAdditions)

- (NSIndexSet *)indexSetByAddingIndex:(unsigned)index;
- (NSIndexSet *)indexSetByAddingIndexesInRange:(NSRange)range;
- (NSIndexSet *)indexSetByTogglingIndexesInRange:(NSRange)range;

@end
