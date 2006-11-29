//
//  INTAnnotatedPrinciple+INTSyncServices.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INTAnnotatedPrinciple.h"


@interface INTAnnotatedPrinciple (INTSyncServices)

#pragma mark Accessing the principle
- (void)setPrinciple:(INTPrinciple *)principle;

@end
