//
//  INTFlattening.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTFlattening.h"


@implementation NSArray (INTFlattening)

#pragma mark Flattening the array

- (NSArray *)flattenedArray
{
	int count = [self count];
	NSMutableArray *flattened = [NSMutableArray arrayWithCapacity:count];
	
	NSEnumerator *enumerator = [self objectEnumerator];
	id object;
	while ((object = [enumerator nextObject]))
	{
		if ([object respondsToSelector:@selector(flattenedArray)])
			[flattened addObjectsFromArray:[object flattenedArray]];
		else
			[flattened addObject:object];
	}
	
	return flattened;
}


@end


@implementation NSSet (INTFlattening)

#pragma mark Flattening the set

- (NSArray *)flattenedArray
{
	return [[self allObjects] flattenedArray];
}


@end
