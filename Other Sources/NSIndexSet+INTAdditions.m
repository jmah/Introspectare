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


- (NSIndexSet *)indexSetByTogglingIndexesInRange:(NSRange)range
{
	NSMutableIndexSet *newSet = [self mutableCopy];
	for (unsigned i = range.location; i < NSMaxRange(range); i++)
		if ([newSet containsIndex:i])
			[newSet removeIndex:i];
		else
			[newSet addIndex:i];
	return [newSet autorelease];
}


@end
