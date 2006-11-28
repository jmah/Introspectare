//
//  INTPrinciple.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface INTPrinciple : NSObject <NSCoding>
{
	@private
	NSString *INT_uuid;
	NSDate *INT_creationDate;
	NSString *INT_label;
	NSString *INT_explanation;
	NSString *INT_note;
}


#pragma mark Creating principles
- (id)init; // Designated initializer

#pragma mark Accessing the principles's unique identifier
- (NSString *)uuid;

#pragma mark Accessing attributes
- (NSDate *)creationDate;
- (NSString *)label;
- (void)setLabel:(NSString *)label;
- (NSString *)explanation;
- (void)setExplanation:(NSString *)explanation;
- (NSString *)note;
- (void)setNote:(NSString *)note;

@end
