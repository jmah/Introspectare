//
//  INTPrinciple.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTPrinciple.h"


@implementation INTPrinciple

#pragma mark Initializing and deallocating

- (void)awakeFromInsert // NSManagedObject
{
	[self setCreationDate:[NSDate date]];
}



#pragma mark Attributes

- (NSDate *)creationDate
{
	[self willAccessValueForKey:@"creationDate"];
	NSDate *date = [self primitiveValueForKey:@"creationDate"];
	[self didAccessValueForKey:@"creationDate"];
	return date;
}


- (void)setCreationDate:(NSDate *)date
{
	[self willChangeValueForKey:@"creationDate"];
	[self setPrimitiveValue:date forKey:@"creationDate"];
	[self didChangeValueForKey:@"creationDate"];
}


- (NSString *)label
{
	[self willAccessValueForKey:@"label"];
	NSString *label = [self primitiveValueForKey:@"label"];
	[self didAccessValueForKey:@"label"];
	return label;
}


- (void)setLabel:(NSString *)label
{
	[self willChangeValueForKey:@"label"];
	[self setPrimitiveValue:label forKey:@"label"];
	[self didChangeValueForKey:@"label"];
}


- (NSString *)explanation
{
	[self willAccessValueForKey:@"explanation"];
	NSString *explanation = [self primitiveValueForKey:@"explanation"];
	[self didAccessValueForKey:@"explanation"];
	return explanation;
}


- (void)setExplanation:(NSString *)explanation
{
	[self willChangeValueForKey:@"explanation"];
	[self setPrimitiveValue:explanation forKey:@"explanation"];
	[self didChangeValueForKey:@"explanation"];
}


- (NSString *)note
{
	[self willAccessValueForKey:@"note"];
	NSString *note = [self primitiveValueForKey:@"note"];
	[self didAccessValueForKey:@"note"];
	return note;
}


- (void)setNote:(NSString *)note
{
	[self willChangeValueForKey:@"note"];
	[self setPrimitiveValue:note forKey:@"note"];
	[self didChangeValueForKey:@"note"];
}



#pragma mark Relationships

- (void)addOrderedPrinciplesObject:(NSManagedObject *)orderedPrinciple
{
	NSSet *changedObjects = [NSSet setWithObject:orderedPrinciple];
	
	[self willChangeValueForKey:@"orderedPrinciples"
	            withSetMutation:NSKeyValueUnionSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey:@"orderedPrinciples"] addObject:orderedPrinciple];
	
	[self didChangeValueForKey:@"orderedPrinciples"
	           withSetMutation:NSKeyValueUnionSetMutation
	              usingObjects:changedObjects];
}


- (void)removeOrderedPrinciplesObject:(NSManagedObject *)orderedPrinciple
{
	NSSet *changedObjects = [NSSet setWithObject:orderedPrinciple];
	
	[self willChangeValueForKey:@"orderedPrinciples"
	            withSetMutation:NSKeyValueMinusSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey:@"orderedPrinciples"] removeObject:orderedPrinciple];
	
	[self didChangeValueForKey:@"orderedPrinciples"
	           withSetMutation:NSKeyValueMinusSetMutation
	              usingObjects:changedObjects];
}


@end
