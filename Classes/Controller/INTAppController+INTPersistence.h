//
//  INTAppController+INTPersistence.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-28.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INTAppController.h"


@interface INTAppController (INTPersistence)

#pragma mark Persistence
- (NSString *)dataFolderPath;
- (NSString *)dataFilename;
- (NSString *)dataFilePath;
- (BOOL)ensureReadableFileAtPath:(NSString *)path error:(NSError **)outError;
- (BOOL)loadFromFile:(NSString *)path error:(NSError **)outError;
- (BOOL)saveToFile:(NSString *)path error:(NSError **)outError;

@end
