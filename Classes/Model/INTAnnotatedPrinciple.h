//
//  INTAnnotatedPrinciple.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INTPrinciple;


@interface INTAnnotatedPrinciple : NSObject <NSCoding>
{
	@private
	INTPrinciple *INT_principle;
	BOOL INT_upheld;
}


#pragma mark Creating annotated principles
- (id)initWithPrinciple:(INTPrinciple *)principle; // Designated initializer

#pragma mark Accessing the principle
- (INTPrinciple *)principle;

#pragma mark Managing annotations
- (BOOL)isUpheld;
- (void)setUpheld:(BOOL)upheld;

@end
