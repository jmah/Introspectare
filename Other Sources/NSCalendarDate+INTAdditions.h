//
//  NSCalendarDate+INTAdditions.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSCalendarDate (INTAdditions)

#pragma mark Creating an NSCalendarDate instance
+ (id)calendarDateWithDayOfCommonEra:(int)day;
+ (id)tomorrow;

@end
