//
//  INTLibrary.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INTEntry;
@class INTPrinciple;
@class INTConstitution;


/*
 * The INTLibrary class acts as a container for a collection of constitutions,
 * principles, and days. It can serve as the root object for archiving and
 * provides some convenience methods.
 */
@interface INTLibrary : NSObject <NSCoding>
{
	@private
	NSArray *INT_constitutions;
	NSMutableDictionary *INT_entries;
}


#pragma mark Creating libraries
- (id)init; // Designated initializer

#pragma mark Accessing constitutions
- (NSArray *)constitutions; // NSArray of INTConstitution objects
- (void)setConstitutions:(NSArray *)constitutions;
- (INTConstitution *)constitutionForDate:(NSDate *)date;

#pragma mark Accessing entries
- (NSSet *)entries; // NSArray of INTEntry objects
- (void)setEntries:(NSSet *)entries;
- (void)addEntriesObject:(INTEntry *)entry;
- (void)removeEntriesObject:(INTEntry *)entry;
- (INTEntry *)entryForDayOfCommonEra:(int)day;
- (INTEntry *)addEntryForDayOfCommonEra:(int)day;

@end
