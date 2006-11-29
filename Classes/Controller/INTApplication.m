//
//  INTApplication.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-30.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTApplication.h"


@implementation INTApplication

#pragma mark Handling user attention requests

- (BOOL)ignoresUserAttentionRequests
{
	return INT_ignoresUserAttentionRequests;
}


- (void)setIgnoresUserAttentionRequests:(BOOL)ignores
{
	INT_ignoresUserAttentionRequests = ignores;
}


- (int)requestUserAttention:(NSRequestUserAttentionType)requestType // NSApplication
{
	if ([self ignoresUserAttentionRequests])
		return 0;
	else
		return [super requestUserAttention:requestType];
}


@end
