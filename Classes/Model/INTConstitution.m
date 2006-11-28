//
//  INTConstitution.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-07.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTConstitution.h"
#import "INTShared.h"


@interface INTConstitution (INTPrivateMethods)

#pragma mark Accessing attributes
- (void)setCreationDate:(NSDate *)creationDate;

@end


@implementation INTConstitution

#pragma mark Creating principles

- (id)init // Designated initializer
{
	if ((self = [super init]))
	{
		INT_uuid = [INTGenerateUUID() retain];
		[self setCreationDate:[NSDate date]];
		[self setVersionLabel:[NSString string]];
		[self setNote:[NSString string]];
		[self setPrinciples:[NSArray array]];
	}
	return self;
}


- (void)dealloc
{
	[INT_uuid release], INT_uuid = nil;
	[INT_creationDate release], INT_creationDate = nil;
	[INT_versionLabel release], INT_versionLabel = nil;
	[INT_note release], INT_note = nil;
	[INT_principles release], INT_principles = nil;
	
	[super dealloc];
}



#pragma mark Archiving and serialization

- (id)initWithCoder:(NSCoder *)decoder
{
	if ([decoder allowsKeyedCoding])
	{
		if ((self = [super init]))
		{
			INT_uuid = [[decoder decodeObjectForKey:@"uuid"] retain];
			if (!INT_uuid)
				INT_uuid = [INTGenerateUUID() retain];
			[self setCreationDate:[decoder decodeObjectForKey:@"creationDate"]];
			[self setVersionLabel:[decoder decodeObjectForKey:@"versionLabel"]];
			[self setNote:[decoder decodeObjectForKey:@"note"]];
			[self setPrinciples:[decoder decodeObjectForKey:@"principles"]];
		}
	}
	else
	{
		[self release];
		[NSException raise:NSInvalidArchiveOperationException format:@"INTConstitution only supports keyed coding"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ([encoder allowsKeyedCoding])
	{
		[encoder encodeObject:[self uuid] forKey:@"uuid"];
		[encoder encodeObject:[self creationDate] forKey:@"creationDate"];
		[encoder encodeObject:[self versionLabel] forKey:@"versionLabel"];
		[encoder encodeObject:[self note] forKey:@"note"];
		[encoder encodeObject:[self principles] forKey:@"principles"];
	}
	else
		[NSException raise:NSInvalidArchiveOperationException format:@"INTConstitution only supports keyed coding"];
}



#pragma mark Identifying and comparing objects

- (BOOL)isEqual:(id)otherObject
{
	BOOL equal = NO;
	if ([otherObject isMemberOfClass:[self class]] &&
		[[otherObject uuid] isEqual:[self uuid]] &&
		[[otherObject creationDate] isEqual:[self creationDate]] &&
		[[otherObject versionLabel] isEqual:[self versionLabel]] &&
		[[otherObject note] isEqual:[self note]] &&
		[[otherObject principles] isEqual:[self principles]])
		equal = YES;
	return equal;
}


- (unsigned)hash
{
	return ([[self creationDate] hash] ^ [[self versionLabel] hash]);
}



#pragma mark Accessing the constitution's unique identifier

- (NSString *)uuid
{
	return INT_uuid;
}



#pragma mark Accessing attributes

- (NSDate *)creationDate
{
	return INT_creationDate;
}


- (void)setCreationDate:(NSDate *)creationDate // INTConstitution (INTPrivateMethods)
{
	id oldValue = INT_creationDate;
	INT_creationDate = [creationDate copy];
	[oldValue release];
}


- (NSString *)versionLabel
{
	return INT_versionLabel;
}


- (void)setVersionLabel:(NSString *)versionLabel
{
	if (!versionLabel)
		versionLabel = [NSString string];
	id oldValue = INT_versionLabel;
	INT_versionLabel = [versionLabel copy];
	[oldValue release];
}


- (NSString *)note
{
	return INT_note;
}


- (void)setNote:(NSString *)note
{
	if (!note)
		note = [NSString string];
	id oldValue = INT_note;
	INT_note = [note copy];
	[oldValue release];
}


- (NSArray *)principles
{
	return INT_principles;
}


- (void)setPrinciples:(NSArray *)principles
{
	if (!principles)
		principles = [NSArray array];
	id oldValue = INT_principles;
	INT_principles = [principles mutableCopy];
	[oldValue release];
}


@end
