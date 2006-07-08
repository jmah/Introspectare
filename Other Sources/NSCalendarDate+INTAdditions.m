//
//  NSCalendarDate+INTAdditions.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "NSCalendarDate+INTAdditions.h"


@implementation NSCalendarDate (INTAdditions)

#pragma mark Creating an NSCalendarDate instance

+ (id)calendarDateWithDayOfCommonEra:(int)day
{
	NSCalendarDate *startOfCommonEra = [NSCalendarDate dateWithYear:1  month:1    day:1
															   hour:0 minute:0 second:0
														   timeZone:[NSTimeZone localTimeZone]];
	return [startOfCommonEra dateByAddingYears:0  months:0    days:(day - 1)
										 hours:0 minutes:0 seconds:0];
}


+ (id)tomorrow
{
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	return [NSCalendarDate dateWithYear:[now yearOfCommonEra]
								  month:[now monthOfYear]
									day:[now dayOfMonth] + 1
								   hour:0
								 minute:0
								 second:0
							   timeZone:[now timeZone]];
}


@end
