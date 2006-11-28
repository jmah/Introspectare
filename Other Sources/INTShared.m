//
//  INTShared.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTShared.h"


#pragma mark Errors

NSString *INTErrorDomain = @"INTErrorDomain";



#pragma mark Patseboard types

NSString *INTPrincipleArrayDataType = @"INTPrincipleArrayDataType";


#pragma mark Functions

NSString *INTGenerateUUID()
{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidCFString = CFUUIDCreateString(NULL, uuidRef);
	NSString *uuidString = [NSString stringWithString:(NSString *)uuidCFString];
	CFRelease(uuidRef);
	CFRelease(uuidCFString);
	
	return uuidString;
}
