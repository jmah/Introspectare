//
//  INTAnnotatedPrinciple+INTSyncServices.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTAnnotatedPrinciple+INTSyncServices.h"
#import "INTPrinciple.h"


@implementation INTAnnotatedPrinciple (INTSyncServices)

#pragma mark Accessing the principle

- (void)setPrinciple:(INTPrinciple *)principle
{
	id oldValue = INT_principle;
	INT_principle = [principle retain];
	[oldValue release];
}


@end
