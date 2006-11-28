//
//  INTEntry.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTEntry.h"
#import "INTShared.h"
#import "INTConstitution.h"
#import "INTPrinciple.h"
#import "INTAnnotatedPrinciple.h"
#import "NSCalendarDate+INTAdditions.h"


@implementation INTEntry

#pragma mark Creating entries
- (id)initWithDayOfCommonEra:(int)dayOfCommonEra constitution:(INTConstitution *)constitution // Designated initializer
{
	if ((self = [super init]))
	{
		INT_uuid = [INTGenerateUUID() retain];
		INT_dayOfCommonEra = dayOfCommonEra;
		INT_constitution = [constitution retain];
		INT_note = [[NSString string] retain];
		INT_unread = YES;
		
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
	return self;
}


- (void)dealloc
{
	[INT_uuid release], INT_uuid = nil;
	[INT_note release], INT_note = nil;
	[INT_constitution release], INT_constitution = nil;
	[INT_annotatedPrinciples release], INT_annotatedPrinciples = nil;
	if (INT_cachedDate)
		[INT_cachedDate release], INT_cachedDate = nil;
	
	[super dealloc];
}



#pragma mark Archiving and serialization

- (id)initWithCoder:(NSCoder *)decoder // Designated coding initializer
{
	if ([decoder allowsKeyedCoding])
	{
		if ((self = [super init]))
		{
			INT_uuid = [[decoder decodeObjectForKey:@"uuid"] retain];
			if (!INT_uuid)
				INT_uuid = [INTGenerateUUID() retain];
			INT_dayOfCommonEra = [decoder decodeIntForKey:@"dayOfCommonEra"];
			INT_note = [[decoder decodeObjectForKey:@"note"] retain];
			INT_constitution = [[decoder decodeObjectForKey:@"constitution"] retain];
			INT_unread = [decoder decodeBoolForKey:@"unread"];
			INT_annotatedPrinciples = [[decoder decodeObjectForKey:@"annotatedPrinciples"] retain];
		}
	}
	else
	{
		[self release];
		[NSException raise:NSInvalidArchiveOperationException format:@"INTEntry only supports keyed coding"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ([encoder allowsKeyedCoding])
	{
		[encoder encodeObject:[self uuid] forKey:@"uuid"];
		[encoder encodeInt:[self dayOfCommonEra] forKey:@"dayOfCommonEra"];
		[encoder encodeObject:[self note] forKey:@"note"];
		[encoder encodeObject:[self constitution] forKey:@"constitution"];
		[encoder encodeBool:[self isUnread] forKey:@"unread"];
		[encoder encodeObject:[self annotatedPrinciples] forKey:@"annotatedPrinciples"];
	}
	else
		[NSException raise:NSInvalidArchiveOperationException format:@"INTEntry only supports keyed coding"];
}



#pragma mark Identifying and comparing objects

- (BOOL)isEqual:(id)otherObject
{
	BOOL equal = NO;
	if ([otherObject isMemberOfClass:[self class]] &&
		([otherObject dayOfCommonEra] == [self dayOfCommonEra]) &&
		[[otherObject uuid] isEqual:[self uuid]] &&
		[[otherObject note] isEqual:[self note]] &&
		[[otherObject constitution] isEqual:[self constitution]] &&
		[[otherObject annotatedPrinciples] isEqual:[self annotatedPrinciples]])
		equal = YES;
	return equal;
}


- (unsigned)hash
{
	return ((unsigned)[self dayOfCommonEra] * 23);
}



#pragma mark Accessing the entry's unique identifier

- (NSString *)uuid
{
	return INT_uuid;
}



#pragma mark Accessing the day

- (int)dayOfCommonEra
{
	return INT_dayOfCommonEra;
}


- (NSDate *)date
{
	if (!INT_cachedDate)
		INT_cachedDate = [[NSCalendarDate calendarDateWithDayOfCommonEra:[self dayOfCommonEra]] retain];
	return INT_cachedDate;
}



#pragma mark Accessing the note

- (NSString *)note
{
	return INT_note;
}


- (void)setNote:(NSString *)note
{
	id oldValue = INT_note;
	INT_note = [note copy];
	[oldValue release];
}



#pragma mark Accessing the unread status

- (BOOL)isUnread
{
	return INT_unread;
}


- (void)setUnread:(BOOL)unread
{
	INT_unread = unread;
}



#pragma mark Accessing the constitution

- (INTConstitution *)constitution
{
	return INT_constitution;
}



#pragma mark Accessing principles

- (NSArray *)annotatedPrinciples // NSArray of mutable INTAnnotatedPrinciple objects
{
	return INT_annotatedPrinciples;
}


@end
