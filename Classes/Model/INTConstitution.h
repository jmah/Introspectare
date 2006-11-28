//
//  INTConstitution.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface INTConstitution : NSObject <NSCoding>
{
	@private
	NSString *INT_uuid;
	NSDate *INT_creationDate;
	NSString *INT_versionLabel;
	NSString *INT_note;
	NSMutableArray *INT_principles;
}


#pragma mark Creating constitutions
- (id)init; // Designated initializer

#pragma mark Accessing the constitution's unique identifier
- (NSString *)uuid;

#pragma mark Accessing attributes
- (NSDate *)creationDate;
- (NSString *)versionLabel;
- (void)setVersionLabel:(NSString *)versionLabel;
- (NSString *)note;
- (void)setNote:(NSString *)note;
- (NSArray *)principles;
- (void)setPrinciples:(NSArray *)principles;

@end
