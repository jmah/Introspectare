//
//  INTPrinciple.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTPrinciple.h"


@interface INTPrinciple (INTPrivateMethods)

#pragma mark Accessing attributes
- (void)setCreationDate:(NSDate *)creationDate;

@end


@implementation INTPrinciple

#pragma mark Creating principles

- (id)init // Designated initializer
{
	if ((self = [super init]))
	{
		[self setCreationDate:[NSDate date]];
		[self setLabel:[NSString string]];
		[self setExplanation:[NSString string]];
		[self setNote:[NSString string]];
	}
	return self;
}


- (void)dealloc
{
	[INT_creationDate release], INT_creationDate = nil;
	[INT_label release], INT_label = nil;
	[INT_explanation release], INT_explanation = nil;
	[INT_note release], INT_note = nil;
	
	[super dealloc];
}



#pragma mark Archiving and serialization

- (id)initWithCoder:(NSCoder *)decoder // Designated coding initializer
{
	if ([decoder allowsKeyedCoding])
	{
		if ((self = [super init]))
		{
			[self setCreationDate:[decoder decodeObjectForKey:@"creationDate"]];
			[self setLabel:[decoder decodeObjectForKey:@"label"]];
			[self setExplanation:[decoder decodeObjectForKey:@"explanation"]];
			[self setNote:[decoder decodeObjectForKey:@"note"]];
		}
	}
	else
	{
		[self release];
		[NSException raise:NSInvalidArchiveOperationException format:@"INTPrinciple only supports keyed coding"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ([encoder allowsKeyedCoding])
	{
		[encoder encodeObject:[self creationDate] forKey:@"creationDate"];
		[encoder encodeObject:[self label] forKey:@"label"];
		[encoder encodeObject:[self explanation] forKey:@"explanation"];
		[encoder encodeObject:[self note] forKey:@"note"];
	}
	else
		[NSException raise:NSInvalidArchiveOperationException format:@"INTPrinciple only supports keyed coding"];
}



#pragma mark Identifying and comparing objects

- (BOOL)isEqual:(id)otherObject
{
	BOOL equal = NO;
	if ([otherObject isMemberOfClass:[self class]] &&
		[[otherObject creationDate] isEqual:[self creationDate]] &&
		[[otherObject label] isEqual:[self label]] &&
		[[otherObject explanation] isEqual:[self explanation]] &&
		[[otherObject note] isEqual:[self note]])
		equal = YES;
	return equal;
}


- (unsigned)hash
{
	return ([[self creationDate] hash] ^ [[self label] hash]);
}



#pragma mark Accessing attributes

- (NSDate *)creationDate
{
	return INT_creationDate;
}


- (void)setCreationDate:(NSDate *)creationDate // INTPrinciple (INTPrivateMethods)
{
	id oldValue = INT_creationDate;
	INT_creationDate = [creationDate copy];
	[oldValue release];
}


- (NSString *)label
{
	return INT_label;
}


- (void)setLabel:(NSString *)label
{
	id oldValue = INT_label;
	INT_label = [label copy];
	[oldValue release];
}


- (NSString *)explanation
{
	return INT_explanation;
}


- (void)setExplanation:(NSString *)explanation
{
	id oldValue = INT_explanation;
	INT_explanation = [explanation copy];
	[oldValue release];
}


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


@end
