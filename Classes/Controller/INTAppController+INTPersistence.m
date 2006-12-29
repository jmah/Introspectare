//
//  INTAppController+INTPersistence.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-28.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTAppController+INTPersistence.h"


@implementation INTAppController (INTPersistence)

#pragma mark Persistence

- (NSString *)dataFolderPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *appSupportPath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	return [appSupportPath stringByAppendingPathComponent:@"Introspectare"];
}


- (NSString *)dataFilename
{
	return [NSUserName() stringByAppendingPathExtension:@"intspec"];
}


- (NSString *)dataFilePath
{
	return [[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]];
}


// Attempts to create the data directory (if it does not already exist), and returns YES if creation succeeded and the data file is writable or createable.
- (BOOL)ensureReadableFileAtPath:(NSString *)path error:(NSError **)outError
{
	BOOL success = NO;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *folderPath = [path stringByDeletingLastPathComponent];
	
	// Check that the data folder exists
	BOOL dataFolderIsDirectory = NO;
	BOOL dataFolderExists = [fileManager fileExistsAtPath:folderPath isDirectory:&dataFolderIsDirectory];
	if (!dataFolderExists)
		dataFolderIsDirectory = [fileManager createDirectoryAtPath:folderPath attributes:nil];
	
	if (!dataFolderIsDirectory)
	{
		NSString *errorDescription = NSLocalizedString(@"INTDataFolderCreationErrorDescription", @"Data folder creation error description");
		NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"INTDataFolderCreationErrorRecoverySuggestion", @"Data folder creation error recovery suggestion"), folderPath];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			errorDescription, NSLocalizedDescriptionKey,
			recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
			nil];
		NSError *dataFolderCreationError = [NSError errorWithDomain:INTErrorDomain
															   code:INTDataFolderCreationError
														   userInfo:userInfo];
		if (outError)
			*outError = dataFolderCreationError;
	}
	else
	{
		// There is a directory at folderPath
		BOOL dataFileIsDirectory = NO;
		BOOL dataFileExists = [fileManager fileExistsAtPath:path isDirectory:&dataFileIsDirectory];
		if (dataFileExists && dataFileIsDirectory)
		{
			NSString *errorDescription = NSLocalizedString(@"INTDataFileIsDirectoryErrorDescription", @"Data file is directory error description");
			NSString *failureReason = NSLocalizedString(@"INTDataFileIsDirectoryErrorFailureReason", @"Data file is directory error failure reason");
			NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"INTDataFileIsDirectoryErrorRecoverySuggestion", @"Data file is directory error recovery suggestion"), [path lastPathComponent], folderPath];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				errorDescription, NSLocalizedDescriptionKey,
				failureReason, NSLocalizedFailureReasonErrorKey,
				recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
				nil];
			NSError *dataFileIsDirectoryError = [NSError errorWithDomain:INTErrorDomain
																	code:INTDataFileIsDirectoryError
																userInfo:userInfo];
			if (outError)
				*outError = dataFileIsDirectoryError;
		}
		else
			success = YES;
	}
	
	return success;
}


- (BOOL)loadFromFile:(NSString *)path error:(NSError **)outError
{
	BOOL success = NO;
	
	BOOL dataFileIsReadable = [self ensureReadableFileAtPath:path error:outError];
	if (dataFileIsReadable)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		{
			NSDictionary *savedData = nil;
			BOOL dataFileRaisedLoadError = NO;
			@try
			{
				savedData = [[NSKeyedUnarchiver unarchiveObjectWithFile:path] retain];
			}
			@catch (NSException *e)
			{
				if ([e name] == NSInvalidArgumentException)
					dataFileRaisedLoadError = YES;
				else
					@throw e;
			}
			
			if (dataFileRaisedLoadError)
			{
				NSString *errorDescription = NSLocalizedString(@"INTDataFileLoadErrorDescription", @"Data file load error description");
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					errorDescription, NSLocalizedDescriptionKey,
					nil];
				NSError *dataFileLoadError = [NSError errorWithDomain:INTErrorDomain
																 code:INTDataFileLoadError
															 userInfo:userInfo];
				if (outError)
					*outError = dataFileLoadError;
			}
			else
			{
				[self setLibrary:[savedData objectForKey:@"library"]];
				[INT_objectsChangedSinceLastSync setDictionary:[savedData objectForKey:@"objectsChangedSinceLastSync"]];
				[INT_objectIdentifiersDeletedSinceLastSync setDictionary:[savedData objectForKey:@"objectIdentifiersDeletedSinceLastSync"]];
				[self setValue:[savedData objectForKey:@"lastSyncDate"] forKey:@"lastSyncDate"];
				if ([savedData objectForKey:@"uncommittedEntries"])
					[INT_uncommittedEntries setSet:[savedData objectForKey:@"uncommittedEntries"]];
				success = YES;
			}
		}
		else
		{
			// An empty data file implies an empty library
			INTLibrary *newLibrary = [[INTLibrary alloc] init];
			[self setLibrary:newLibrary];
			success = YES;
			[newLibrary release];
		}
	}
	
	return success;
}


- (BOOL)saveToFile:(NSString *)path error:(NSError **)outError
{
	BOOL success = NO;
	
	BOOL dataFileIsReadable = [self ensureReadableFileAtPath:path error:outError];
	if (dataFileIsReadable)
	{
		NSDictionary *savedData = [NSDictionary dictionaryWithObjectsAndKeys:
			[self library], @"library",
			INT_objectsChangedSinceLastSync, @"objectsChangedSinceLastSync",
			INT_objectIdentifiersDeletedSinceLastSync, @"objectIdentifiersDeletedSinceLastSync",
			INT_uncommittedEntries, @"uncommittedEntries",
			INT_lastSyncDate, @"lastSyncDate",
			nil];
		
		if ([NSKeyedArchiver archiveRootObject:savedData toFile:path])
			success = YES;
		else
		{
			NSString *errorDescription = NSLocalizedString(@"INTDataFileSaveErrorDescription", @"Data file save error description");
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				errorDescription, NSLocalizedDescriptionKey,
				nil];
			NSError *dataFileSaveError = [NSError errorWithDomain:INTErrorDomain
															 code:INTDataFileSaveError
														 userInfo:userInfo];
			if (outError)
				*outError = dataFileSaveError;
		}
	}
	
	return success;
}


@end
