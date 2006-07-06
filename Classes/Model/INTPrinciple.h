//
//  INTPrinciple.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <CoreData/CoreData.h>

@class INTConstitution;


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
- (void)addConstitutionsObject:(INTConstitution *)constitution;
- (void)removeConstitutionsObject:(INTConstitution *)constitution;
- (void)addDailyPrinciplesObject:(NSManagedObject *)dailyPrinciple;
- (void)removeDailyPrinciplesObject:(NSManagedObject *)dailyPrinciple;

@end
