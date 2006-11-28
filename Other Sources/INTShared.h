//
//  INTShared.h
//  Introspectare
//
//  Created by Jonathon Mah on 2006-07-08.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark Errors

extern NSString *INTErrorDomain;

// INTErrorDomain error codes
enum {
	INTDataFolderCreationError = 1,
	INTDataFileIsDirectoryError,
	INTDataFileLoadError,
	INTDataFileSaveError,
};



#pragma mark Pasteboard types

extern NSString *INTPrincipleArrayDataType;


#pragma mark Functions

NSString *INTGenerateUUID(void);
