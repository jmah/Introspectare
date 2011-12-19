//
//  main.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-04.
//  Copyright Playhaus 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/NSDebug.h>


int main(int argc, char *argv[])
{
#ifndef _RELEASE_
	NSDebugEnabled = YES;
	NSZombieEnabled = YES;
	NSDeallocateZombies = NO;
	NSHangOnUncaughtException = NO;
#endif
	
	return NSApplicationMain(argc, (const char **)argv);
}
