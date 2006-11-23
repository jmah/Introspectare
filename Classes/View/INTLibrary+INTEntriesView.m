//
//  INTLibrary+INTEntriesView.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-23.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTLibrary+INTEntriesView.h"
#import "INTConstitution.h"


@implementation INTLibrary (INTEntriesView)

#pragma mark Accessing constitutions

- (unsigned)constitutionCountBeforeDate:(NSDate *)date
{
	// Find the number of constitutions created before or on date
	unsigned count = 0;
	
	NSSortDescriptor *dateDescending = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	NSEnumerator *constitutionEnum = [[[self constitutions] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateDescending]] objectEnumerator];
	INTConstitution *currConstitution;
	while (currConstitution = [constitutionEnum nextObject])
	{
		NSComparisonResult comparison = [[currConstitution creationDate] compare:date];
		if ((comparison == NSOrderedAscending) || (comparison == NSOrderedSame))
			count++;
		else
			break;
	}
	
	[dateDescending release];
	return count;
}


@end
