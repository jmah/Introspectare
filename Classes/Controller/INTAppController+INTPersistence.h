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
- (BOOL)ensureDataFileReadable:(NSError **)outError;
- (BOOL)loadData:(NSError **)outError;
- (BOOL)saveData:(NSError **)outError;

@end
