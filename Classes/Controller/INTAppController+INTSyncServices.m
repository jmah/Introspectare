//
//  INTAppController+INTSyncServices.m
//  Introspectare
//
//  Created by Jonathon Mah on 2006-11-28.
//  Copyright 2006 Playhaus. All rights reserved.
//

#import "INTAppController+INTSyncServices.h"
#import "INTAppController+INTPersistence.h"
#import "INTFlattening.h"
#import "INTLibrary.h"
#import "INTEntry.h"
#import "INTEntry+INTSyncServices.h"
#import "INTConstitution.h"
#import "INTPrinciple.h"
#import "INTAnnotatedPrinciple.h"
#import "INTAnnotatedPrinciple+INTSyncServices.h"


static NSDictionary *INTEntityNameToClassNameMapping = nil;


@interface INTAppController (INTSyncServicesPrivateMethods)

#pragma mark Accessing sync status
- (void)setLastSyncDate:(NSDate *)date;

#pragma mark Sync notification handlers
- (void)syncClient:(ISyncClient *)client mightWantToSyncEntityNames:(NSArray *)entityNames;

#pragma mark Getting the sync client
- (ISyncClient *)syncClient;

#pragma mark Performing sync operations
- (void)syncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges forceSlowSync:(BOOL)slowSync displayProgressPanel:(BOOL)displayProgress;
- (void)_syncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges forceSlowSync:(BOOL)slowSync;

#pragma mark Sync helper methods
- (NSArray *)objectsForEntityName:(NSString *)entityName;
- (NSDictionary *)objectsForEntityNames:(NSArray *)entityNames;
- (void)removeAllObjectsForEntityName:(NSString *)entityName;
- (NSDictionary *)recordForObject:(id)object entityName:(NSString *)entityName;
- (id)objectWithRecordIdentifier:(NSString *)identifier entityName:(NSString *)entityName;
- (void)handleSyncChange:(ISyncChange *)change forEntityName:(NSString *)entityName newRecordIdentifier:(NSString **)outRecordIdentifier unresolvedRelationships:(NSArray **)outUnresolvedRelationships;
- (void)resolveRelationships:(NSArray *)unresolvedRelationships withRecordIdentifierMapping:(NSDictionary *)recordIdentifierMapping;

@end


@implementation INTAppController (INTSyncServices)

#pragma mark Initialization

+ (void)initialize
{
	if (!INTEntityNameToClassNameMapping)
		INTEntityNameToClassNameMapping = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"INTEntry", @"org.playhaus.Introspectare.Entry",
			@"INTConstitution", @"org.playhaus.Introspectare.Constitution",
			@"INTPrinciple", @"org.playhaus.Introspectare.Principle",
			@"INTAnnotatedPrinciple", @"org.playhaus.Introspectare.AnnotatedPrinciple",
			nil];
}



#pragma mark Registering for sync

- (BOOL)registerSyncSchema
{
	NSString *schemaPath = [[NSBundle mainBundle] pathForResource:@"Introspectare"
														   ofType:@"syncschema"];
	
	BOOL success = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:schemaPath])
#warning The return value of this method is not documented. I'm assuming it's a "success" indicator.
		success = [[ISyncManager sharedManager] registerSchemaWithBundlePath:schemaPath];
	
	return success;
}


- (void)registerForSyncNotifications
{
	ISyncClient *client = [self syncClient];
	[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeApplication];
	[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeServer];
	[client setSyncAlertHandler:self selector:@selector(syncClient:mightWantToSyncEntityNames:)];
}



#pragma mark Accessing sync status

- (NSDate *)lastSyncDate
{
	return INT_lastSyncDate;
}


- (void)setLastSyncDate:(NSDate *)date // INTAppController (INTSyncServicesPrivateMethods)
{
	if (!date)
		date = [NSDate distantPast];
	id oldValue = INT_lastSyncDate;
	INT_lastSyncDate = [date copy];
	[oldValue release];
}


- (BOOL)isSyncing
{
	return INT_isSyncing;
}



#pragma mark Initiating sync actions

- (void)sync
{
	[self syncWithTimeout:2.0 pullChanges:YES forceSlowSync:NO displayProgressPanel:YES];
}


- (void)slowSync
{
	[self syncWithTimeout:2.0 pullChanges:YES forceSlowSync:YES displayProgressPanel:YES];
}


- (void)syncBeforeApplicationTerminates
{
	if (![[self lastSyncDate] isEqual:[NSDate distantPast]])
		[self syncWithTimeout:0.0 pullChanges:NO forceSlowSync:NO displayProgressPanel:NO];
}


- (void)syncWhileInactive
{
	if (![[self lastSyncDate] isEqual:[NSDate distantPast]])
		[self syncWithTimeout:2.0 pullChanges:NO forceSlowSync:NO displayProgressPanel:NO];
}



#pragma mark Sync notification handlers

- (void)syncClient:(ISyncClient *)client mightWantToSyncEntityNames:(NSArray *)entityNames // INTAppController (INTSyncServicesPrivateMethods)
{
	[self sync];
}



#pragma mark Getting the sync client

- (ISyncClient *)syncClient // INTAppController (INTSyncServicesPrivateMethods)
{
	NSString *clientIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	ISyncClient *client = [[ISyncManager sharedManager] clientWithIdentifier:clientIdentifier];
	
	if (!client)
	{
		NSString *clientDescriptionPath = [[NSBundle mainBundle] pathForResource:@"ClientDescription"
																		  ofType:@"plist"];
		client = [[ISyncManager sharedManager] registerClientWithIdentifier:clientIdentifier
														descriptionFilePath:clientDescriptionPath];
	}
	
	return client;
}



#pragma mark Performing sync operations

- (void)syncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges forceSlowSync:(BOOL)slowSync displayProgressPanel:(BOOL)displayProgress // INTAppController (INTSyncServicesPrivateMethods)
{
	INT_isSyncing = YES;
	[[self undoManager] disableUndoRegistration];
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"Syncing"]];
	
	// Display progress window
	NSModalSession modalSession = NULL;
	if (displayProgress)
	{
		[syncProgressIndicator setIndeterminate:YES];
		modalSession = [NSApp beginModalSessionForWindow:syncProgressPanel];
		[syncProgressPanel makeKeyAndOrderFront:nil];
		[NSApp runModalSession:modalSession];
		[syncProgressIndicator startAnimation:nil];
	}
	
	// Store all objects that might be synced
	INT_syncObjectsByEntities = [self objectsForEntityNames:[INTEntityNameToClassNameMapping allKeys]];
		
	// Sync!
	@try
	{
		[self _syncWithTimeout:2.0 pullChanges:YES forceSlowSync:slowSync];
	}
	@catch (id e)
	{
		NSLog(@"Exception while syncing: %@", e);
	}
	
	INT_syncObjectsByEntities = nil;
	
	// Close progress window
	if (displayProgress)
	{
		[syncProgressIndicator stopAnimation:nil];
		[NSApp endModalSession:modalSession];
		[syncProgressPanel orderOut:nil];
	}
	
	// Have to change icon back on next run loop cycle
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"Introspectare"]];
	[[self undoManager] enableUndoRegistration];
	INT_isSyncing = NO;
}


- (void)_syncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges forceSlowSync:(BOOL)slowSync // INTAppController (INTSyncServicesPrivateMethods)
{
	// Save backup file
	NSString *extension = [[self dataFilename] pathExtension];
	NSString *backupFilename = [[[[self dataFilename] stringByDeletingPathExtension] stringByAppendingString:@".BeforeLastSync"] stringByAppendingPathExtension:extension];
	BOOL didSave = [self saveToFile:[[self dataFolderPath] stringByAppendingPathComponent:backupFilename] error:NULL];
	if (!didSave)
	{
		NSLog(@"Not synching because data backup could not be saved");
		return;
	}
	
	if (![[ISyncManager sharedManager] isEnabled])
	{
		NSLog(@"Not synching because sync server is unavailable");
		return;
	}
	
	ISyncClient *client = [self syncClient];
	if (!client)
	{
		NSLog(@"Not synching because a sync client could not be obtained");
		return;
	}
	
	
	// Refresh sync if the data file doesn't extyist
	BOOL shouldRefreshSync = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]])
		shouldRefreshSync = YES;
	
	ISyncSession *session = [ISyncSession beginSessionWithClient:client 
													 entityNames:[INTEntityNameToClassNameMapping allKeys]
													  beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
	if (!session)
	{
		NSLog(@"Timed out while waiting for sync session");
		return;
	}
	
	if (shouldRefreshSync)
		[session clientDidResetEntityNames:[INTEntityNameToClassNameMapping allKeys]];
	else if (slowSync)
		[session clientWantsToPushAllRecordsForEntityNames:[INTEntityNameToClassNameMapping allKeys]];
	else if ([[self lastSyncDate] isEqual:[NSDate distantPast]])
		// Never synced before
		[session clientWantsToPushAllRecordsForEntityNames:[INTEntityNameToClassNameMapping allKeys]];
	
	
	// Push the truth
	{
		// Count the number of records we are pushing to give an accurate progress count
		unsigned totalRecords = 0;
		NSEnumerator *preflightEntityNamesEnumerator = [[INTEntityNameToClassNameMapping allKeys] objectEnumerator];
		NSString *preflightEntityName;
		while ((preflightEntityName = [preflightEntityNamesEnumerator nextObject]))
		{
			if ([session shouldPushChangesForEntityName:preflightEntityName])
			{
				if ([session shouldPushAllRecordsForEntityName:preflightEntityName])
					// Slow sync
					totalRecords += [[self objectsForEntityName:preflightEntityName] count];
				else
				{
					// Fast sync
					NSString *targetClassName = [INTEntityNameToClassNameMapping objectForKey:preflightEntityName];
					totalRecords += [[INT_objectsChangedSinceLastSync objectForKey:targetClassName] count];
					totalRecords += [[INT_objectIdentifiersDeletedSinceLastSync objectForKey:targetClassName] count];
				}
			}
		}
		
		[syncProgressIndicator setMaxValue:totalRecords];
		[syncProgressIndicator setDoubleValue:0.0];
		[syncProgressIndicator setIndeterminate:NO];
		[syncProgressIndicator display];
		
		
		// Actually push the records
		NSEnumerator *entityNamesEnumerator = [[INTEntityNameToClassNameMapping allKeys] objectEnumerator];
		NSString *entityName;
		while ((entityName = [entityNamesEnumerator nextObject]))
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			if ([session shouldPushChangesForEntityName:entityName])
			{
				if ([session shouldPushAllRecordsForEntityName:entityName])
				{
					// Slow sync
					NSEnumerator *localObjects = [[self objectsForEntityName:entityName] objectEnumerator];
					id localObject;
					while ((localObject = [localObjects nextObject]))
					{
						NSDictionary *record = [self recordForObject:localObject entityName:entityName];
						[session pushChangesFromRecord:record withIdentifier:[localObject uuid]];
						[syncProgressIndicator incrementBy:1.0];
						[syncProgressIndicator display];
					}
				}
				else
				{
					// Fast sync
					NSString *targetClassName = [INTEntityNameToClassNameMapping objectForKey:entityName];
					
					NSEnumerator *changedObjects = [[INT_objectsChangedSinceLastSync objectForKey:targetClassName] objectEnumerator];
					id object;
					while ((object = [changedObjects nextObject]))
					{
						NSDictionary *record = [self recordForObject:object entityName:entityName];
						[session pushChangesFromRecord:record withIdentifier:[object uuid]];
						[syncProgressIndicator incrementBy:1.0];
						[syncProgressIndicator display];
					}
					
					NSEnumerator *deletedIdentifiers = [[INT_objectIdentifiersDeletedSinceLastSync objectForKey:targetClassName] objectEnumerator];
					NSString *deletedIdentifier;
					while ((deletedIdentifier = [deletedIdentifiers nextObject]))
					{
						[session deleteRecordWithIdentifier:deletedIdentifier];
						[syncProgressIndicator incrementBy:1.0];
						[syncProgressIndicator display];
					}
					
					[[INT_objectsChangedSinceLastSync objectForKey:targetClassName] removeAllObjects];
					[[INT_objectIdentifiersDeletedSinceLastSync objectForKey:targetClassName] removeAllObjects];
				}
			}
			[pool release];
		}
		NSLog(@"Pushed %d records", totalRecords);
	}
	
	
	// Push complete
	[syncProgressIndicator setIndeterminate:YES];
	[syncProgressIndicator display];
	[syncProgressIndicator startAnimation:nil];
	[self setLastSyncDate:[NSDate date]];
	
	if ([session isCancelled])
		return;
	else if (!pullChanges)
	{
		[session finishSyncing];
		return;
	}
	
	
	// Prepare to pull
	BOOL canPull = NO;
	@try
	{
		canPull = [session prepareToPullChangesForEntityNames:[INTEntityNameToClassNameMapping allKeys]
												   beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
	}
	@catch (id e)
	{
	}
	if ([session isCancelled])
	{
		NSLog(@"Sync session cancelled while waiting to pull changes");
		return;
	}
	else if (!canPull)
	{
		NSLog(@"Sync timed out while waiting to pull changes");
		[session finishSyncing];
		return;
	}
	
	
	// Pull the truth
	NSMutableArray *allUnresolvedRelationships = [NSMutableArray array];
	NSMutableDictionary *recordIdentifierMapping = [NSMutableDictionary dictionary];
	{
		unsigned changeCount = 0;
		NSEnumerator *entityNamesEnumerator = [[INTEntityNameToClassNameMapping allKeys] objectEnumerator];
		NSString *entityName;
		while ((entityName = [entityNamesEnumerator nextObject]))
		{
			if (![session shouldPullChangesForEntityName:entityName])
				continue;
			
			if ([session shouldReplaceAllRecordsOnClientForEntityName:entityName])
				[self removeAllObjectsForEntityName:entityName];
			
			// Handle changes for the current entity
			NSEnumerator *changeEnumerator = [session changeEnumeratorForEntityNames:[NSArray arrayWithObject:entityName]];
			ISyncChange *change;
			while ((change = [changeEnumerator nextObject]))
			{
				// Process change
				changeCount++;
				NSString *recordIdentifier = [change recordIdentifier];
				NSString *newRecordIdentifier = recordIdentifier;
				NSArray *unresolvedRelationships = nil;
				BOOL success = NO;
				@try
				{
					[self handleSyncChange:change
							 forEntityName:entityName
					   newRecordIdentifier:&newRecordIdentifier
				   unresolvedRelationships:&unresolvedRelationships];
					success = YES;
				}
				@catch (id e)
				{
					NSLog(@"Exception while handing sync change: %@", e);
				}
				
				if (success)
				{
					if (unresolvedRelationships)
						[allUnresolvedRelationships addObjectsFromArray:unresolvedRelationships];
					[recordIdentifierMapping setObject:newRecordIdentifier
												forKey:recordIdentifier];
					[session clientAcceptedChangesForRecordWithIdentifier:recordIdentifier
														  formattedRecord:nil
													  newRecordIdentifier:newRecordIdentifier];
				}
				else
					[session clientRefusedChangesForRecordWithIdentifier:recordIdentifier];
			}
		}
		NSLog(@"Pulled %d changes. %d unresolved relationships, %d identifier mappings", changeCount, [allUnresolvedRelationships count], [recordIdentifierMapping count]);
	}
	
	BOOL didResolveAllRelationships = NO;
	@try
	{
		[self resolveRelationships:allUnresolvedRelationships withRecordIdentifierMapping:recordIdentifierMapping];
		didResolveAllRelationships = YES;
	}
	@catch (id e)
	{
		NSLog(@"Exception while resolving relationships: %@", e);
	}
	
	BOOL didSaveChanges = NO;
	if (didResolveAllRelationships)
	{
		didSaveChanges = [self saveToFile:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]
									error:NULL];
		if (didSaveChanges)
		{
			[session clientCommittedAcceptedChanges];
			[session finishSyncing];
		}
		else
		{
			NSLog(@"Could not save synchronized changes");
			[session cancelSyncing];
		}
	}
	else
	{
		NSLog(@"Failed to resolve all relationships. Reverting to backup of data before sync");
		[session cancelSyncing];
		[self loadFromFile:backupFilename error:NULL];
	}
}



#pragma mark Sync helper methods

- (NSArray *)objectsForEntityName:(NSString *)entityName // INTAppController (INTSyncServicesPrivateMethods)
{
	NSArray *objects = nil;
	
	if (INT_syncObjectsByEntities)
		objects = [INT_syncObjectsByEntities objectForKey:entityName];
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
		objects = [[[self library] entries] allObjects];
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
		objects = [[self library] constitutions];
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
		objects = [[[self library] valueForKeyPath:@"constitutions.principles"] flattenedArray];
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
		objects = [[[self library] valueForKeyPath:@"entries.annotatedPrinciples"] flattenedArray];
	else
		[NSException raise:NSInvalidArgumentException
					format:@"-[INTAppController objectsForEntityName:] Unknown entity name: \"%@\"", entityName];
	return objects;
}


- (NSDictionary *)objectsForEntityNames:(NSArray *)entityNames // INTAppController (INTSyncServicesPrivateMethods)
{
	NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithCapacity:[entityNames count]];
	NSEnumerator *entityNamesEnumerator = [entityNames objectEnumerator];
	NSString *entityName;
	while ((entityName = [entityNamesEnumerator nextObject]))
		[objects setObject:[[[self objectsForEntityName:entityName] mutableCopy] autorelease] forKey:entityName];
	return objects;
}


- (void)removeAllObjectsForEntityName:(NSString *)entityName // INTAppController (INTSyncServicesPrivateMethods)
{
	if (INT_syncObjectsByEntities)
		[[INT_syncObjectsByEntities objectForKey:entityName] removeAllObjects];
	
	if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
		[[self library] setEntries:[NSSet set]];
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
	{
		[[self library] setConstitutions:[NSArray array]];
		NSEnumerator *entries = [[[self library] entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
			[entry setConstitution:nil creatingAnnotatedPrinciples:NO];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
	{
		[[[self library] constitutions] makeObjectsPerformSelector:@selector(setPrinciples:) withObject:[NSArray array]];
		[[[[self library] valueForKeyPath:@"entries.annotatedPrinciples"] flattenedArray] makeObjectsPerformSelector:@selector(setPrinciple:) withObject:nil];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
		[[[self library] entries] makeObjectsPerformSelector:@selector(setAnnotatedPrinciples:) withObject:[NSArray array]];
	else
		[NSException raise:NSInvalidArgumentException
					format:@"-[INTAppController removeAllObjectsForEntityName:] Unknown entity name: \"%@\"", entityName];
}


- (NSDictionary *)recordForObject:(id)object entityName:(NSString *)entityName // INTAppController (INTSyncServicesPrivateMethods)
{
	NSMutableDictionary *record = [NSMutableDictionary dictionaryWithObject:entityName forKey:@"com.apple.syncservices.RecordEntityName"];
	
	if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
	{
		NSArray *keys = [NSArray arrayWithObjects:@"dayOfCommonEra", @"unread", @"note", nil];
		[record addEntriesFromDictionary:[object dictionaryWithValuesForKeys:keys]];
		[record setObject:[NSArray arrayWithObject:[[object constitution] uuid]]
				   forKey:@"constitution"];
		[record setObject:[object valueForKeyPath:@"annotatedPrinciples.uuid"] 
				   forKey:@"annotatedPrinciples"];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
	{
		NSArray *keys = [NSArray arrayWithObjects:@"versionLabel", @"creationDate", @"note", nil];
		[record addEntriesFromDictionary:[object dictionaryWithValuesForKeys:keys]];
		[record setObject:[object valueForKeyPath:@"principles.uuid"] 
				   forKey:@"principles"];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
	{
		NSArray *keys = [NSArray arrayWithObjects:@"label", @"explanation", @"creationDate", @"note", nil];
		[record addEntriesFromDictionary:[object dictionaryWithValuesForKeys:keys]];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
	{
		NSArray *keys = [NSArray arrayWithObjects:@"upheld", nil];
		[record addEntriesFromDictionary:[object dictionaryWithValuesForKeys:keys]];
		[record setObject:[NSArray arrayWithObject:[[object principle] uuid]]
				   forKey:@"principle"];
		
		NSEnumerator *entries = [[[self library] entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
			if ([[entry annotatedPrinciples] containsObject:object])
				break;
		
		if (entry)
			[record setObject:[NSArray arrayWithObject:[entry uuid]]
					   forKey:@"entry"];
		else
			[NSException raise:NSInternalInconsistencyException format:@"Could not find entry containing annotated principle"];
	}
	else
		[NSException raise:NSInvalidArgumentException
					format:@"-[INTAppController syncRecordForObject:entityName:] Unknown entity name: \"%@\"", entityName];
	
	return record;
}


- (id)objectWithRecordIdentifier:(NSString *)identifier entityName:(NSString *)entityName // INTAppController (INTSyncServicesPrivateMethods)
{
	NSEnumerator *enumerator = [[self objectsForEntityName:entityName] objectEnumerator];
	id object = nil;
	while ((object = [enumerator nextObject]))
		if ([[object uuid] isEqual:identifier])
			break;
	
	return object;
}


- (void)handleSyncChange:(ISyncChange *)change forEntityName:(NSString *)entityName newRecordIdentifier:(NSString **)outRecordIdentifier unresolvedRelationships:(NSArray **)outUnresolvedRelationships // INTAppController (INTSyncServicesPrivateMethods)
{
	NSMutableArray *unresolved = [NSMutableArray array];
	
	id object = nil;
	
	if ([change type] == ISyncChangeTypeAdd)
	{
		// Create the object
		if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
		{
			int dayOfCommonEra = [[[change record] objectForKey:@"dayOfCommonEra"] intValue];
			object = [[[INTEntry alloc] initWithDayOfCommonEra:dayOfCommonEra] autorelease];
			[[self library] addEntriesObject:object];
		}
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
		{
			object = [[[INTConstitution alloc] init] autorelease];
			[[[self library] mutableArrayValueForKey:@"constitutions"] addObject:object];
		}
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
			object = [[[INTPrinciple alloc] init] autorelease];
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
			object = [[[INTAnnotatedPrinciple alloc] initWithPrinciple:nil] autorelease];
		
		[[INT_syncObjectsByEntities objectForKey:entityName] addObject:object];
	}
	else
		object = [self objectWithRecordIdentifier:[change recordIdentifier] entityName:entityName];
	
	NSAssert(object != nil, @"Couldn't get object for change");
	
	// We now have the object in question
	if ([change type] == ISyncChangeTypeDelete)
	{
		if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
			[[self library] removeEntriesObject:object];
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
			[[[self library] mutableArrayValueForKey:@"constitutions"] removeObject:object];
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
			; // No action
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
		{
			NSString *entryIdentifier = [[[change record] objectForKey:@"entry"] lastObject];
			INTEntry *entry = [self objectWithRecordIdentifier:entryIdentifier entityName:@"org.playhaus.Introspectare.Entry"];
			[[entry mutableArrayValueForKey:@"annotatedPrinciples"] removeObject:object];
		}
		
		if (outRecordIdentifier)
			*outRecordIdentifier = nil;
		[[INT_syncObjectsByEntities objectForKey:entityName] removeObject:object];
	}
	else
	{
		if (outRecordIdentifier)
			*outRecordIdentifier = [object uuid];
		
		// Assign expected keys
		NSArray *attributeKeys = [NSArray array];
		NSArray *relationshipKeys = [NSArray array];
		NSArray *ignoredKeys = [NSArray array];
		
		if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
		{
			attributeKeys = [NSArray arrayWithObjects:@"unread", @"note", nil];
			relationshipKeys = [NSArray arrayWithObjects:@"constitution", @"annotatedPrinciples", nil];
			ignoredKeys = [NSArray arrayWithObject:@"dayOfCommonEra"];
		}
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
		{
			attributeKeys = [NSArray arrayWithObjects:@"versionLabel", @"creationDate", @"note", nil];
			relationshipKeys = [NSArray arrayWithObject:@"principles"];
		}
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
			attributeKeys = [NSArray arrayWithObjects:@"label", @"explanation", @"creationDate", @"note", nil];
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
		{
			attributeKeys = [NSArray arrayWithObject:@"upheld"];
			relationshipKeys = [NSArray arrayWithObject:@"principle"];
		}
		
		
		// Process changes
		NSEnumerator *changes = [[change changes] objectEnumerator];
		NSDictionary *currChange;
		while ((currChange = [changes nextObject]))
		{
			NSString *key = [currChange objectForKey:ISyncChangePropertyNameKey];
			id value = [currChange objectForKey:ISyncChangePropertyValueKey];
			
			if ([[currChange objectForKey:ISyncChangePropertyActionKey] isEqual:ISyncChangePropertySet])
			{
				if ([attributeKeys containsObject:key])
					[object setValue:value forKey:key];
				else if ([relationshipKeys containsObject:key])
					[unresolved addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						object, @"object",
						entityName, @"entityName",
						key, @"key",
						value, @"valueIdentifiers",
						nil]];
				else if ([ignoredKeys containsObject:key])
					; // No action
				else if ([key isEqual:@"com.apple.syncservices.RecordEntityName"])
					; // No action
				else
					[NSException raise:NSGenericException
								format:@"Unhandled key for %@: %@", object, key];
			}
			else
			{
				if ([attributeKeys containsObject:key])
					[object setValue:nil forKey:key];
				else if ([relationshipKeys containsObject:key])
					// TODO Is this the best way to clear a relationship?
					[object setValue:nil forKey:key];
				else if ([ignoredKeys containsObject:key])
					; // No action
				else
					[NSException raise:NSGenericException
								format:@"Unhandled key for %@: %@", object, key];
			}
		}
	}
	
	if (outUnresolvedRelationships)
		*outUnresolvedRelationships = unresolved;
}


- (void)resolveRelationships:(NSArray *)unresolvedRelationships withRecordIdentifierMapping:(NSDictionary *)recordIdentifierMapping // INTAppController (INTSyncServicesPrivateMethods)
{
	NSEnumerator *unresolvedRelationshipsEnumerator = [unresolvedRelationships objectEnumerator];
	NSDictionary *unresolvedRelationship;
	while ((unresolvedRelationship = [unresolvedRelationshipsEnumerator nextObject]))
	{
		id object = [unresolvedRelationship objectForKey:@"object"];
		NSString *entityName = [unresolvedRelationship objectForKey:@"entityName"];
		NSString *key = [unresolvedRelationship objectForKey:@"key"];
		NSArray *initialValueIdentifiers = [unresolvedRelationship objectForKey:@"valueIdentifiers"];
		
		// Map from initial value identifiers to actual identifiers
		NSMutableArray *valueIdentifiers = [NSMutableArray arrayWithCapacity:[initialValueIdentifiers count]];
		NSEnumerator *initialValueIdentifiersEnumerator = [initialValueIdentifiers objectEnumerator];
		NSString *initialValueIdentifier;
		while ((initialValueIdentifier = [initialValueIdentifiersEnumerator nextObject]))
		{
			NSString *actualValueIdentifier = [recordIdentifierMapping objectForKey:initialValueIdentifier];
			if (actualValueIdentifier)
				[valueIdentifiers addObject:actualValueIdentifier];
			else
				[valueIdentifiers addObject:initialValueIdentifier];
		}
		
		
		// Connect the related objects
		if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
		{
			INTEntry *entry = object;
			if ([key isEqual:@"constitution"])
			{
				NSString *constitutionIdentifier = [valueIdentifiers lastObject];
				INTConstitution *constitution = [self objectWithRecordIdentifier:constitutionIdentifier
																	  entityName:@"org.playhaus.Introspectare.Constitution"];
				[entry setConstitution:constitution creatingAnnotatedPrinciples:NO];
			}
			else if ([key isEqual:@"annotatedPrinciples"])
			{
				NSMutableArray *annotatedPrinciples = [[NSMutableArray alloc] initWithCapacity:[valueIdentifiers count]];
				NSEnumerator *annotatedPrincipleIdentifiers = [valueIdentifiers objectEnumerator];
				NSString *annotatedPrincipleIdentifier;
				while ((annotatedPrincipleIdentifier = [annotatedPrincipleIdentifiers nextObject]))
				{
					INTAnnotatedPrinciple *annotatedPrinciple = [self objectWithRecordIdentifier:annotatedPrincipleIdentifier
																					  entityName:@"org.playhaus.Introspectare.AnnotatedPrinciple"];
					NSAssert(annotatedPrinciple != nil, @"Couldn't locate annotated principle");
					
					[annotatedPrinciples addObject:annotatedPrinciple];
				}
				[entry setAnnotatedPrinciples:annotatedPrinciples];
				[annotatedPrinciples release];
			}
			else
				[NSException raise:NSGenericException
							format:@"Got an unknown unresolved relationship: %@", unresolvedRelationship];
		}
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
		{
			INTConstitution *constitution = object;
			if ([key isEqual:@"principles"])
			{
				NSMutableArray *principles = [[NSMutableArray alloc] initWithCapacity:[valueIdentifiers count]];
				NSEnumerator *principleIdentifiers = [valueIdentifiers objectEnumerator];
				NSString *principleIdentifier;
				while ((principleIdentifier = [principleIdentifiers nextObject]))
				{
					INTPrinciple *principle = [self objectWithRecordIdentifier:principleIdentifier
																	entityName:@"org.playhaus.Introspectare.Principle"];
					NSAssert(principle != nil, @"Couldn't locate principle");
					
					[principles addObject:principle];
				}
				[constitution setPrinciples:principles];
				[principles release];
			}
			else
				[NSException raise:NSGenericException
							format:@"Got an unknown unresolved relationship: %@", unresolvedRelationship];
		}
		else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
		{
			INTAnnotatedPrinciple *annotatedPrinciple = object;
			if ([key isEqual:@"entry"])
			{
				// Do nothing
			}
			else if ([key isEqual:@"principle"])
			{
				NSString *principleIdentifier = [valueIdentifiers lastObject];
				INTPrinciple *principle = [self objectWithRecordIdentifier:principleIdentifier
																entityName:@"org.playhaus.Introspectare.Principle"];
				NSAssert(principle != nil, @"Couldn't locate principle");
				
				[annotatedPrinciple setPrinciple:principle];
			}
			else
				[NSException raise:NSGenericException
							format:@"Got an unknown unresolved relationship: %@", unresolvedRelationship];
		}
		else
			[NSException raise:NSGenericException
						format:@"-[INTAppController resolveRelationships:] Unknown entity name: \"%@\"", entityName];
	}
}


@end
