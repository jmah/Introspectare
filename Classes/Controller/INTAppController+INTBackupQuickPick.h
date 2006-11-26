//
//  INTAppController+INTBackupQuickPick.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-27.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INTAppController.h"


@interface INTAppController (INTBackupQuickPick)

#pragma mark Managing the Backup QuickPick
- (BOOL)installIntrospetareBackupQuickPick;
- (NSString *)backupQuickPicksPath;
- (NSString *)introspectareBackupQuickPickFilename;
- (NSString *)introspectareBackupQuickPickSourcePath;
- (NSString *)introspectareBackupQuickPickDestinationPath;

@end
