//
//  INTAnnotatedPrinciple.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTAnnotatedPrinciple.h"
#import "INTShared.h"
#import "INTPrinciple.h"


@implementation INTAnnotatedPrinciple

#pragma mark Creating annotated principles

- (id)initWithPrinciple:(INTPrinciple *)principle
{
	if ((self = [super init]))
	{
		INT_uuid = [INTGenerateUUID() retain];
		INT_principle = [principle retain];
		[self setUpheld:YES];
	}
	return self;
}


- (void)dealloc
{
	[INT_uuid release], INT_uuid = nil;
	[INT_principle release], INT_principle = nil;
	
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
			INT_principle = [decoder decodeObjectForKey:@"principle"];
			[self setUpheld:[decoder decodeBoolForKey:@"upheld"]];
		}
	}
	else
	{
		[self release];
		[NSException raise:NSInvalidArchiveOperationException format:@"INTAnnotatedPrinciple only supports keyed coding"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ([encoder allowsKeyedCoding])
	{
		[encoder encodeObject:[self uuid] forKey:@"uuid"];
		[encoder encodeObject:[self principle] forKey:@"principle"];
		[encoder encodeBool:[self isUpheld] forKey:@"upheld"];
	}
	else
		[NSException raise:NSInvalidArchiveOperationException format:@"INTAnnotatedPrinciple only supports keyed coding"];
}



#pragma mark Identifying and comparing objects

- (BOOL)isEqual:(id)otherObject
{
	BOOL equal = NO;
	if ([otherObject isMemberOfClass:[self class]] &&
		[[otherObject uuid] isEqual:[self uuid]] &&
		[[otherObject principle] isEqual:[self principle]] &&
		([otherObject isUpheld] == [self isUpheld]))
		equal = YES;
	return equal;
}


- (unsigned)hash
{
	unsigned xorMask = 0;
	if ([self isUpheld])
		xorMask = 7;
	return ([[self principle] hash] ^ xorMask);
}



#pragma mark Accessing the annotated principles's unique identifier

- (NSString *)uuid
{
	return INT_uuid;
}



#pragma mark Accessing the principle

- (INTPrinciple *)principle
{
	return INT_principle;
}



#pragma mark Managing annotations

- (BOOL)isUpheld
{
	return INT_upheld;
}


- (void)setUpheld:(BOOL)upheld
{
	INT_upheld = upheld;
}


@end
