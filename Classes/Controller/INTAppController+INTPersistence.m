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


// Attempts to create the data directory (if it does not already exist), and returns YES if creation succeeded and the data file is writable or createable.
- (BOOL)ensureDataFileReadable:(NSError **)outError
{
	BOOL success = NO;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *dataFolderPath = [self dataFolderPath];
	NSString *dataFilePath = [dataFolderPath stringByAppendingPathComponent:[self dataFilename]];
	
	// Check that the data folder exists
	BOOL dataFolderIsDirectory = NO;
	BOOL dataFolderExists = [fileManager fileExistsAtPath:dataFolderPath isDirectory:&dataFolderIsDirectory];
	if (!dataFolderExists)
		dataFolderIsDirectory = [fileManager createDirectoryAtPath:dataFolderPath attributes:nil];
	
	if (!dataFolderIsDirectory)
	{
		NSString *errorDescription = NSLocalizedString(@"INTDataFolderCreationErrorDescription", @"Data folder creation error description");
		NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"INTDataFolderCreationErrorRecoverySuggestion", @"Data folder creation error recovery suggestion"), dataFolderPath];
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
		// There is a directory at dataFolderPath
		BOOL dataFileIsDirectory = NO;
		BOOL dataFileExists = [fileManager fileExistsAtPath:dataFilePath isDirectory:&dataFileIsDirectory];
		if (dataFileExists && dataFileIsDirectory)
		{
			NSString *errorDescription = NSLocalizedString(@"INTDataFileIsDirectoryErrorDescription", @"Data file is directory error description");
			NSString *failureReason = NSLocalizedString(@"INTDataFileIsDirectoryErrorFailureReason", @"Data file is directory error failure reason");
			NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"INTDataFileIsDirectoryErrorRecoverySuggestion", @"Data file is directory error recovery suggestion"), [self dataFilename], dataFilePath];
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


- (BOOL)loadData:(NSError **)outError
{
	BOOL success = NO;
	
	BOOL dataFileIsReadable = [self ensureDataFileReadable:outError];
	if (dataFileIsReadable)
	{
		NSString *dataFilePath = [[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:dataFilePath])
		{
			INTLibrary *newLibrary = nil;
			BOOL dataFileRaisedLoadError = NO;
			@try
			{
				newLibrary = [[NSKeyedUnarchiver unarchiveObjectWithFile:dataFilePath] retain];
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
				[self setLibrary:newLibrary];
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


- (BOOL)saveData:(NSError **)outError
{
	BOOL success = NO;
	
	NSString *dataFilePath = [[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]];
	BOOL dataFileIsReadable = [self ensureDataFileReadable:outError];
	if (dataFileIsReadable)
	{
		if ([NSKeyedArchiver archiveRootObject:[self library] toFile:dataFilePath])
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
