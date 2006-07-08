//
//  INTLibrary.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTLibrary.h"
#import "INTConstitution.h"
#import "INTPrinciple.h"
#import "INTEntry.h"


@implementation INTLibrary

#pragma mark Creating libraries

- (id)init // Designated initializer
{
	if ((self = [super init]))
	{
		INT_entries = [[NSMutableDictionary alloc] init];
		
		[self setConstitutions:[NSArray array]];
		[self setPrinciples:[NSArray array]];
		[self setEntries:[NSSet set]];
	}
	return self;
}


- (void)dealloc
{
	[INT_constitutions release], INT_constitutions = nil;
	[INT_principles release], INT_principles = nil;
	[INT_entries release], INT_entries = nil;
	
	[super dealloc];
}



#pragma mark Archiving and serialization

- (id)initWithCoder:(NSCoder *)decoder // Designated coding initializer
{
	if ([decoder allowsKeyedCoding])
	{
		if ((self = [super init]))
		{
			[self setConstitutions:[decoder decodeObjectForKey:@"constitutions"]];
			[self setPrinciples:[decoder decodeObjectForKey:@"principles"]];
			[self setEntries:[decoder decodeObjectForKey:@"entries"]];
		}
	}
	else
	{
		[self release];
		[NSException raise:NSInvalidArchiveOperationException format:@"INTLibrary only supports keyed coding"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ([encoder allowsKeyedCoding])
	{
		[encoder encodeObject:[self constitutions] forKey:@"constitutions"];
		[encoder encodeObject:[self principles] forKey:@"principles"];
		[encoder encodeObject:[self entries] forKey:@"entries"];
	}
	else
		[NSException raise:NSInvalidArchiveOperationException format:@"INTLibrary only supports keyed coding"];
}




#pragma mark Accessing constitutions

- (NSArray *)constitutions // NSArray of INTConstitution objects
{
	return INT_constitutions;
}


- (void)setConstitutions:(NSArray *)constitutions
{
	id oldValue = INT_constitutions;
	INT_constitutions = [constitutions copy];
	[oldValue release];
}


- (INTConstitution *)constitutionForDate:(NSDate *)date
{
	// Find the latest constitution created before or on date
	INTConstitution *foundConstitution = nil;
	
	NSSortDescriptor *dateDescending = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	NSEnumerator *constitutionEnum = [[[self constitutions] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateDescending]] objectEnumerator];
	INTConstitution *currConstitution;
	while ((currConstitution = [constitutionEnum nextObject]) && !foundConstitution)
	{
		NSComparisonResult comparison = [[currConstitution creationDate] compare:date];
		if ((comparison == NSOrderedAscending) ||
			(comparison == NSOrderedSame))
		{
			foundConstitution = currConstitution;
		}
	}
	
	return foundConstitution;
}



#pragma mark Accessing principles

- (NSArray *)principles // NSArray of INTPrinciple objects
{
	return INT_principles;
}


- (void)setPrinciples:(NSArray *)principles
{
	id oldValue = INT_principles;
	INT_principles = [principles copy];
	[oldValue release];
}



#pragma mark Accessing entries

- (NSSet *)entries // NSArray of INTEntry objects
{
	return [NSSet setWithArray:[INT_entries allValues]];
}


- (void)setEntries:(NSSet *)entries
{
	[INT_entries removeAllObjects];
	NSEnumerator *entryEnum = [entries objectEnumerator];
	INTEntry *currEntry;
	while ((currEntry = [entryEnum nextObject]))
		[INT_entries setObject:currEntry
						forKey:[NSNumber numberWithInt:[currEntry dayOfCommonEra]]];
}


- (void)addEntriesObject:(INTEntry *)entry
{
	[INT_entries setObject:entry forKey:[NSNumber numberWithInt:[entry dayOfCommonEra]]];
}


- (void)removeEntriesObject:(INTEntry *)entry
{
	[INT_entries removeObjectForKey:[NSNumber numberWithInt:[entry dayOfCommonEra]]];
}


- (INTEntry *)entryForDayOfCommonEra:(int)day
{
	INTEntry *entry = [INT_entries objectForKey:[NSNumber numberWithInt:day]];
	if (!entry)
	{
		// Check that the day is valid
		NSCalendarDate *startOfCommonEra = [NSCalendarDate dateWithYear:1
																  month:1
																	day:1
																   hour:0
																 minute:0
																 second:0
															   timeZone:[NSTimeZone localTimeZone]];
		NSDate *date = [startOfCommonEra dateByAddingYears:0
													months:0
													  days:(day - 1)
													 hours:0
												   minutes:0
												   seconds:0];
		
		INTConstitution *constitution = [self constitutionForDate:date];
		if (constitution)
		{
			entry = [[INTEntry alloc] initWithDayOfCommonEra:day constitution:constitution];
			[self addEntriesObject:entry];
		}
	}
	return entry;
}


@end
