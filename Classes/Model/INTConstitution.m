//
//  INTConstitution.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTConstitution.h"


@implementation INTConstitution

#pragma mark Initializing and deallocating

- (void)awakeFromInsert // NSManagedObject
{
	[self setCreationDate:[NSDate date]];
}



#pragma mark Attributes

- (NSString *)versionNumber
{
	[self willAccessValueForKey:@"versionNumber"];
	NSString *version = [self primitiveValueForKey:@"versionNumber"];
	[self didAccessValueForKey:@"versionNumber"];
	return version;
}


- (void)setVersionNumber:(NSString *)version
{
	[self willChangeValueForKey:@"versionNumber"];
	[self setPrimitiveValue:version forKey:@"versionNumber"];
	[self didChangeValueForKey:@"versionNumber"];
}


- (NSString *)notes
{
	[self willAccessValueForKey:@"notes"];
	NSString *notes = [self primitiveValueForKey:@"notes"];
	[self didAccessValueForKey:@"notes"];
	return notes;
}


- (void)setNotes:(NSString *)notes
{
	[self willChangeValueForKey:@"notes"];
	[self setPrimitiveValue:notes forKey:@"notes"];
	[self didChangeValueForKey:@"notes"];
}


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



#pragma mark Relationships

- (void)addDaysObject:(NSManagedObject *)day
{
	NSSet *changedObjects = [NSSet setWithObject:day];
	
	[self willChangeValueForKey:@"days"
	            withSetMutation:NSKeyValueUnionSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey:@"days"] addObject:day];
	
	[self didChangeValueForKey:@"days"
	           withSetMutation:NSKeyValueUnionSetMutation
	              usingObjects:changedObjects];
}

- (void)removeDaysObject:(NSManagedObject *)day
{
	NSSet *changedObjects = [NSSet setWithObject:day];
	
	[self willChangeValueForKey:@"days"
	            withSetMutation:NSKeyValueMinusSetMutation
	               usingObjects:changedObjects];
	
	[[self primitiveValueForKey: @"days"] removeObject:day];
	
	[self didChangeValueForKey:@"days"
	           withSetMutation:NSKeyValueMinusSetMutation
	              usingObjects:changedObjects];
}


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
