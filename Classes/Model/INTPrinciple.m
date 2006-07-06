//
//  INTPrinciple.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTPrinciple.h"
#import "INTConstitution.h"


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

- (void)addConstitutionsObject:(INTConstitution *)constitution
{
	NSSet *changedObjects = [NSSet setWithObject:constitution];
	
	[self willChangeValueForKey:@"constitutions"
	            withSetMutation:NSKeyValueUnionSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey:@"constitutions"] addObject:constitution];
	
	[self didChangeValueForKey:@"constitutions"
	           withSetMutation:NSKeyValueUnionSetMutation
	              usingObjects:changedObjects];
}


- (void)removeConstitutionsObject:(INTConstitution *)constitution
{
	NSSet *changedObjects = [NSSet setWithObject:constitution];
	
	[self willChangeValueForKey:@"constitutions"
	            withSetMutation:NSKeyValueMinusSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey:@"constitutions"] removeObject:constitution];
	
	[self didChangeValueForKey:@"constitutions"
	           withSetMutation:NSKeyValueMinusSetMutation
	              usingObjects:changedObjects];
}


- (void)addDailyPrinciplesObject:(NSManagedObject *)dailyPrinciple
{
	NSSet *changedObjects = [NSSet setWithObject:dailyPrinciple];
	
	[self willChangeValueForKey:@"dailyPrinciples"
	            withSetMutation:NSKeyValueUnionSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey:@"dailyPrinciples"] addObject:dailyPrinciple];
	
	[self didChangeValueForKey:@"dailyPrinciples"
	           withSetMutation:NSKeyValueUnionSetMutation
	              usingObjects:changedObjects];
}


- (void)removeDailyPrinciplesObject:(NSManagedObject *)dailyPrinciple
{
	NSSet *changedObjects = [NSSet setWithObject:dailyPrinciple];
	
	[self willChangeValueForKey:@"dailyPrinciples"
	            withSetMutation:NSKeyValueMinusSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey:@"dailyPrinciples"] removeObject:dailyPrinciple];
	
	[self didChangeValueForKey:@"dailyPrinciples"
	           withSetMutation:NSKeyValueMinusSetMutation
	              usingObjects:changedObjects];
}


@end
