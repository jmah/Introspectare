//
//  INTEntry+INTSyncServices.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-29.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntry+INTSyncServices.h"
#import "INTConstitution.h"
#import "INTPrinciple.h"
#import "INTAnnotatedPrinciple.h"
#import "INTShared.h"


@implementation INTEntry (INTSyncServices)

#pragma mark Creating entries

- (id)initWithDayOfCommonEra:(int)dayOfCommonEra
{
	if ((self = [super init]))
	{
		INT_uuid = [INTGenerateUUID() retain];
		INT_dayOfCommonEra = dayOfCommonEra;
		INT_constitution = nil;
		INT_note = [[NSString string] retain];
		INT_unread = YES;
		INT_annotatedPrinciples = [[NSArray alloc] init];
	}
	return self;
}



#pragma mark Accessing the constitution

- (void)setConstitution:(INTConstitution *)constitution creatingAnnotatedPrinciples:(BOOL)createAnnotatedPrinciples
{
	if (!constitution)
		constitution = [NSArray array];
	id oldValue = INT_constitution;
	INT_constitution = [constitution retain];
	[oldValue release];
	
	if (createAnnotatedPrinciples)
	{
		// Create annotated principles
		NSMutableArray *annotatedPrinciples = [[NSMutableArray alloc] initWithCapacity:[[constitution principles] count]];
		
		NSEnumerator *principleEnum = [[constitution principles] objectEnumerator];
		INTPrinciple *currPrinciple;
		while ((currPrinciple = [principleEnum nextObject]))
		{
			INTAnnotatedPrinciple *annotatedPrinciple = [[INTAnnotatedPrinciple alloc] initWithPrinciple:currPrinciple];
			[annotatedPrinciples addObject:annotatedPrinciple];
			[annotatedPrinciple release];
		}
		
		INT_annotatedPrinciples = [[NSArray alloc] initWithArray:annotatedPrinciples];
		[annotatedPrinciples release];
	}
	else
		INT_annotatedPrinciples = [[NSArray alloc] init];
}



#pragma mark Accessing principles

- (void)setAnnotatedPrinciples:(NSArray *)annotatedPrinciples
{
	if (!annotatedPrinciples)
		annotatedPrinciples = [NSArray array];
	id oldValue = INT_annotatedPrinciples;
	INT_annotatedPrinciples = [annotatedPrinciples copy];
	[oldValue release];
}


@end
