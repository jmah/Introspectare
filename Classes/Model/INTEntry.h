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
	int INT_dayOfCommonEra;
	NSDate *INT_cachedDate;
	NSString *INT_note;
	INTConstitution *INT_constitution;
	NSArray *INT_annotatedPrinciples;
}


#pragma mark Creating entries
- (id)initWithDayOfCommonEra:(int)dayOfCommonEra constitution:(INTConstitution *)constitution; // Designated initializer

#pragma mark Accessing the day
- (int)dayOfCommonEra;
- (NSDate *)date;

#pragma mark Accessing the note
- (NSString *)note;
- (void)setNote:(NSString *)note;

#pragma mark Accessing the constitution
- (INTConstitution *)constitution;

#pragma mark Accessing principles
- (NSArray *)annotatedPrinciples; // NSArray of mutable INTAnnotatedPrinciple objects

@end
