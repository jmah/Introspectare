//
//  INTConstitution.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface INTConstitution : NSManagedObject
{
}


#pragma mark Attributes
- (NSString *)versionNumber;
- (void)setVersionNumber:(NSString *)version;
- (NSString *)notes;
- (void)setNotes:(NSString *)note;
- (NSDate *)creationDate;
- (void)setCreationDate:(NSDate *)date;

#pragma mark Relationships
- (void)addDaysObject:(NSManagedObject *)day;
- (void)removeDaysObject:(NSManagedObject *)day;
- (void)addOrderedPrinciplesObject:(NSManagedObject *)orderedPrinciple;
- (void)removeOrderedPrinciplesObject:(NSManagedObject *)orderedPrinciple;

@end
