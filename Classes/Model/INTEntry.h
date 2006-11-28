//
//  INTEntry.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INTConstitution;


@interface INTEntry : NSObject <NSCoding>
{
	@private
	NSString *INT_uuid;
	int INT_dayOfCommonEra;
	NSDate *INT_cachedDate;
	NSString *INT_note;
	INTConstitution *INT_constitution;
	NSArray *INT_annotatedPrinciples;
	BOOL INT_unread;
}


#pragma mark Creating entries
- (id)initWithDayOfCommonEra:(int)dayOfCommonEra constitution:(INTConstitution *)constitution; // Designated initializer

#pragma mark Accessing the entry's unique identifier
- (NSString *)uuid;

#pragma mark Accessing the day
- (int)dayOfCommonEra;
- (NSDate *)date;

#pragma mark Accessing the note
- (NSString *)note;
- (void)setNote:(NSString *)note;

#pragma mark Accessing the constitution
- (INTConstitution *)constitution;

#pragma mark Accessing the unread status
- (BOOL)isUnread;
- (void)setUnread:(BOOL)unread;

#pragma mark Accessing principles
- (NSArray *)annotatedPrinciples; // NSArray of mutable INTAnnotatedPrinciple objects

@end
