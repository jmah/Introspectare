//
//  INTConstitutionsController.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-06.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTConstitutionsController.h"


@implementation INTConstitutionsController

#pragma mark Persistence

- (NSManagedObjectContext *)managedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}


@end
