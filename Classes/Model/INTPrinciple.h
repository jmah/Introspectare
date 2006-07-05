//
//  INTPrinciple.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface INTPrinciple : NSManagedObject
{
}


#pragma mark Attributes
- (NSDate *)creationDate;
- (void)setCreationDate:(NSDate *)date;
- (NSString *)label;
- (void)setLabel:(NSString *)label;
- (NSString *)explanation;
- (void)setExplanation:(NSString *)explanation;
- (NSString *)note;
- (void)setNote:(NSString *)note;


#pragma mark Relationships
- (void)addOrderedPrinciplesObject:(NSManagedObject *)orderedPrinciple;
- (void)removeOrderedPrinciplesObject:(NSManagedObject *)orderedPrinciple;

@end
