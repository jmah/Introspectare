//
//  NSIndexSet+INTAdditions.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-26.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "NSIndexSet+INTAdditions.h"


@implementation NSIndexSet (INTAdditions)

- (NSIndexSet *)indexSetByAddingIndex:(unsigned)index
{
	NSMutableIndexSet *newSet = [self mutableCopy];
	[newSet addIndex:index];
	return [newSet autorelease];
}


- (NSIndexSet *)indexSetByAddingIndexesInRange:(NSRange)range
{
	NSMutableIndexSet *newSet = [self mutableCopy];
	[newSet addIndexesInRange:range];
	return [newSet autorelease];
}


@end
