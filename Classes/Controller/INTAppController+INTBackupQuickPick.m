//
//  INTAppController+INTBackupQuickPick.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-27.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTAppController+INTBackupQuickPick.h"


static BOOL createDirectoryAndParents(NSString *path)
{
	if (!path)
		return NO;
	if ([path length] == 0)
		return YES;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
	BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
	if (!exists)
	{
		NSString *parentPath = [path stringByDeletingLastPathComponent];
		BOOL parentExists = createDirectoryAndParents(parentPath);
		if (!parentExists)
			return NO;
		
		BOOL success = [fileManager createDirectoryAtPath:path attributes:nil];
		return success;
	}
	else if (!isDirectory)
		return NO;
	else
		return YES;
}


@implementation INTAppController (INTBackupQuickPick)

#pragma mark Managing the Backup QuickPick

- (BOOL)installIntrospetareBackupQuickPick
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	BOOL sourceIsDirectory = NO;
	BOOL sourceExists = [fileManager fileExistsAtPath:[self introspectareBackupQuickPickSourcePath]
										  isDirectory:&sourceIsDirectory];
	if (!(sourceExists && sourceIsDirectory))
		return NO;
	
	
	BOOL destinationParentIsDirectory = NO;
	BOOL destinationParentExists = [fileManager fileExistsAtPath:[self backupQuickPicksPath]
													 isDirectory:&destinationParentIsDirectory];
	
	if (destinationParentExists && !destinationParentIsDirectory)
		return NO;
	else if (!destinationParentExists)
	{
		BOOL success = createDirectoryAndParents([self backupQuickPicksPath]);
		if (!success)
			return NO;
	}
	
	// The destination parent directory exists
	return [fileManager copyPath:[self introspectareBackupQuickPickSourcePath]
						  toPath:[self introspectareBackupQuickPickDestinationPath]
						 handler:nil];
}


- (NSString *)backupQuickPicksPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *appSupportPath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	return [[appSupportPath stringByAppendingPathComponent:@"Backup"] stringByAppendingPathComponent:@"QuickPicks"];
}


- (NSString *)introspectareBackupQuickPickFilename
{
	return [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingPathExtension:@"quickpick"];
}


- (NSString *)introspectareBackupQuickPickSourcePath
{
	NSString *basename = [[self introspectareBackupQuickPickFilename] stringByDeletingPathExtension];
	NSString *extension = [[self introspectareBackupQuickPickFilename] pathExtension];
	return [[NSBundle mainBundle] pathForResource:basename ofType:extension];
}


- (NSString *)introspectareBackupQuickPickDestinationPath
{
	return [[self backupQuickPicksPath] stringByAppendingPathComponent:[self introspectareBackupQuickPickFilename]];
}


@end
