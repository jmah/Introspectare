//
//  INTEntry+INTSyncServices.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INTEntry.h"


@interface INTEntry (INTSyncServices)

#pragma mark Creating entries
- (id)initWithDayOfCommonEra:(int)dayOfCommonEra;

#pragma mark Accessing the constitution
- (void)setConstitution:(INTConstitution *)constitution creatingAnnotatedPrinciples:(BOOL)createAnnotatedPrinciples;

#pragma mark Accessing principles
- (void)setAnnotatedPrinciples:(NSArray *)annotatedPrinciples;

@end
