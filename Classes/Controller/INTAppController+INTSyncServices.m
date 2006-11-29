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


@interface INTAppController (INTSyncServicesPrivateMethods)

#pragma mark Synchronization
- (void)setLastSyncDate:(NSDate *)date;
- (void)syncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges displayProgressPanel:(BOOL)displayProgress;
- (void)reallySyncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges;

@end


@implementation INTAppController (INTSyncServices)

#pragma mark Synchronization

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


- (ISyncClient *)syncClient
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


- (void)registerForSyncNotifications
{
	ISyncClient *client = [self syncClient];
	[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeApplication];
	[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeServer];
	[client setSyncAlertHandler:self selector:@selector(syncClient:mightWantToSynEntityNames:)];
}


- (void)syncClient:(ISyncClient *)client mightWantToSynEntityNames:(NSArray *)entityNames
{
	if (![[self lastSyncDate] isEqual:[NSDate distantPast]])
		[self sync];
}


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


- (void)sync
{
	[self syncWithTimeout:2.0 pullChanges:YES displayProgressPanel:YES];
}


- (void)syncBeforeApplicationTerminates
{
	if (![[self lastSyncDate] isEqual:[NSDate distantPast]])
		[self syncWithTimeout:0.0 pullChanges:NO displayProgressPanel:YES];
}


- (void)syncWhileInactive
{
	if (![[self lastSyncDate] isEqual:[NSDate distantPast]])
		[self syncWithTimeout:2.0 pullChanges:NO displayProgressPanel:NO];
}


- (BOOL)isSyncing
{
	return INT_isSyncing;
}


- (void)syncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges displayProgressPanel:(BOOL)displayProgress // INTAppController (INTSyncServicesPrivateMethods)
{
	INT_isSyncing = YES;
	[[self undoManager] disableUndoRegistration];
	
	// Display progress window
	NSWindow *sheet = nil;
	NSModalSession modalSession = NULL;
	if (displayProgress)
	{
		[syncProgressIndicator setIndeterminate:YES];
		if (([[NSApp orderedWindows] count] > 0) && [[[NSApp orderedWindows] objectAtIndex:0] isVisible])
		{
			sheet = syncProgressPanel;
			[NSApp beginSheet:syncProgressPanel
			   modalForWindow:[[NSApp orderedWindows] objectAtIndex:0]
				modalDelegate:nil
			   didEndSelector:NULL
				  contextInfo:NULL];
		}
		else
		{
			modalSession = [NSApp beginModalSessionForWindow:syncProgressPanel];
			[NSApp runModalSession:modalSession];
		}
		[syncProgressPanel display];
		[syncProgressIndicator startAnimation:nil];
	}
		
	// Sync!
	@try
	{
		[self reallySyncWithTimeout:2.0 pullChanges:YES];
	}
	@catch (id e)
	{
		NSLog(@"Caught exception %@", e);
	}
	
	// Close progress window
	if (displayProgress)
	{
		[syncProgressIndicator stopAnimation:nil];
		if (sheet)
			[NSApp endSheet:sheet];
		else
			[NSApp endModalSession:modalSession];
		[syncProgressPanel orderOut:nil];
	}
	
	[[self undoManager] enableUndoRegistration];
	INT_isSyncing = NO;
}


- (void)reallySyncWithTimeout:(NSTimeInterval)timeout pullChanges:(BOOL)pullChanges // INTAppController (INTSyncServicesPrivateMethods)
{
	// Save backup file
	NSString *extension = [[self dataFilename] pathExtension];
	NSString *backupFilename = [[[[self dataFilename] stringByDeletingPathExtension] stringByAppendingString:@".BeforeLastSync"] stringByAppendingPathExtension:extension];
	BOOL didSave = [self saveToFile:[[self dataFolderPath] stringByAppendingPathComponent:backupFilename] error:NULL];
	if (!didSave)
	{
		NSLog(@"Not synching because data was could not be saved");
		return;
	}
	
	if (![[ISyncManager sharedManager] isEnabled])
		return;
	
	ISyncClient *client = [self syncClient];
	if (!client)
	{
		NSLog(@"Not synching because a sync client could not be obtained");
		return;
	}
	
	
	BOOL shouldRefreshSync = NO;
	
	// Refresh sync if the data file doesn't exist
	if (![[NSFileManager defaultManager] fileExistsAtPath:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]])
		shouldRefreshSync = YES;
	
	
	NSDictionary *entityNameToClassNameMapping = [NSDictionary dictionaryWithObjectsAndKeys:
		@"INTEntry", @"org.playhaus.Introspectare.Entry",
		@"INTConstitution", @"org.playhaus.Introspectare.Constitution",
		@"INTPrinciple", @"org.playhaus.Introspectare.Principle",
		@"INTAnnotatedPrinciple", @"org.playhaus.Introspectare.AnnotatedPrinciple",
		nil];
	ISyncSession *session = [ISyncSession beginSessionWithClient:client 
													 entityNames:[entityNameToClassNameMapping allKeys]
													  beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
	if (!session)
	{
		NSLog(@"Timed out while waiting for sync session");
		return;
	}
	
	if (shouldRefreshSync)
		[session clientDidResetEntityNames:[entityNameToClassNameMapping allKeys]];
	else if ([[self lastSyncDate] isEqual:[NSDate distantPast]])
		// Never synced before
		[session clientWantsToPushAllRecordsForEntityNames:[entityNameToClassNameMapping allKeys]];
	
	
	// Push the truth
	{
		// Count the number of records we are pushing to give an accurate progress count
		unsigned totalRecords = 0;
		NSEnumerator *preflightEntityNamesEnumerator = [[entityNameToClassNameMapping allKeys] objectEnumerator];
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
					NSString *targetClassName = [entityNameToClassNameMapping objectForKey:preflightEntityName];
					totalRecords += [[INT_objectsChangedSinceLastSync objectForKey:targetClassName] count];
					totalRecords += [[INT_objectIdentifiersDeletedSinceLastSync objectForKey:targetClassName] count];
				}
			}
		}
		
		[syncProgressIndicator setMaxValue:totalRecords];
		[syncProgressIndicator setDoubleValue:0.0];
		[syncProgressIndicator setIndeterminate:NO];
		
		
		
		// Actually push the records
		NSEnumerator *entityNamesEnumerator = [[entityNameToClassNameMapping allKeys] objectEnumerator];
		NSString *entityName;
		while ((entityName = [entityNamesEnumerator nextObject]))
		{
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
						[session pushChangesFromRecord:record
										withIdentifier:[localObject uuid]];
						[syncProgressIndicator incrementBy:1.0];
						[syncProgressIndicator display];
					}
				}
				else
				{
					// Fast sync
					NSString *targetClassName = [entityNameToClassNameMapping objectForKey:entityName];
					
					NSEnumerator *changedObjects = [[INT_objectsChangedSinceLastSync objectForKey:targetClassName] objectEnumerator];
					id object;
					while ((object = [changedObjects nextObject]))
					{
						NSDictionary *record = [self recordForObject:object entityName:entityName];
						[session pushChangesFromRecord:record
										withIdentifier:[object uuid]];
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
		}
		NSLog(@"Pushed %d records", totalRecords);
	}
	
	
	// Push complete
	[syncProgressIndicator setIndeterminate:YES];
	[syncProgressIndicator startAnimation:nil];
	[self setLastSyncDate:[NSDate date]];
	
	if (!pullChanges)
	{
		[session finishSyncing];
		return;
	}
	
	
	// Prepare to pull
	BOOL canPull = [session prepareToPullChangesForEntityNames:[entityNameToClassNameMapping allKeys]
													beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
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
	/*
	 * Hold unresolved principles in an array. Other unresolved objects will
	 * reside in the unresolvedRelationships array of dictionaries, but
	 * principles have no relationships. Thus there needs to be another way to
	 * obtain a reference to one of these principles.
	 */
	INT_unresolvedPrinciples = [[NSMutableArray alloc] init];
	NSMutableArray *allUnresolvedRelationships = [[NSMutableArray alloc] init];
	NSMutableDictionary *recordIdentifierMapping = [[NSMutableDictionary alloc] init];
	{
		unsigned changeCount = 0;
		NSEnumerator *entityNamesEnumerator = [[entityNameToClassNameMapping allKeys] objectEnumerator];
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
				BOOL success = [self handleSyncChange:change
										forEntityName:entityName
								  newRecordIdentifier:&newRecordIdentifier
							  unresolvedRelationships:&unresolvedRelationships];
				if (success)
				{
					if (unresolvedRelationships)
						[allUnresolvedRelationships addObjectsFromArray:unresolvedRelationships];
					[session clientAcceptedChangesForRecordWithIdentifier:recordIdentifier
														  formattedRecord:nil
													  newRecordIdentifier:newRecordIdentifier];
					[recordIdentifierMapping setObject:newRecordIdentifier
												forKey:recordIdentifier];
				}
				else
					[session clientRefusedChangesForRecordWithIdentifier:recordIdentifier];
			}
		}
		NSLog(@"Pulled %d changes. %d unresolved relationships, %d identifier mappings", changeCount, [allUnresolvedRelationships count], [recordIdentifierMapping count]);
	}
	
	BOOL didResolveAllRelationships = [self resolveRelationships:allUnresolvedRelationships
									 withRecordIdentifierMapping:recordIdentifierMapping];
	if (!didResolveAllRelationships)
		NSLog(@"Unable to resolve all relationships!");
	
	[allUnresolvedRelationships release];
	[recordIdentifierMapping release];
	[INT_unresolvedPrinciples release], INT_unresolvedPrinciples = nil;
	
	BOOL didSaveChanges = [self saveToFile:[[self dataFolderPath] stringByAppendingPathComponent:[self dataFilename]]
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


- (NSArray *)objectsForEntityName:(NSString *)entityName
{
	if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
		return [[[self library] entries] allObjects];
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
		return [[self library] constitutions];
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
	{
		NSArray *constitutionPrinciples = [[[self library] valueForKeyPath:@"constitutions.principles"] flattenedArray];
		if (INT_unresolvedPrinciples)
			return [INT_unresolvedPrinciples arrayByAddingObjectsFromArray:constitutionPrinciples];
		else
			return constitutionPrinciples;
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
		return [[[self library] valueForKeyPath:@"entries.annotatedPrinciples"] flattenedArray];
	else
	{
		NSLog(@"-[INTAppController objectsForEntityName:] Unknown entity name: \"%@\"", entityName);
		return [NSArray array];
	}
}


- (void)removeAllObjectsForEntityName:(NSString *)entityName
{
	if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
	{
		[[self library] setEntries:[NSSet set]];
	}
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
		NSEnumerator *constitutions = [[[self library] constitutions] objectEnumerator];
		INTConstitution *constitution;
		while ((constitution = [constitutions nextObject]))
			[constitution setPrinciples:[NSArray array]];
		
		NSEnumerator *entries = [[[self library] entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
		{
			NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
			INTAnnotatedPrinciple *annotatedPrinciple;
			while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
				[annotatedPrinciple setPrinciple:nil];
		}
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
	{
		NSEnumerator *entries = [[[self library] entries] objectEnumerator];
		INTEntry *entry;
		while ((entry = [entries nextObject]))
			[entry setAnnotatedPrinciples:[NSArray array]];
	}
	else
		NSLog(@"-[INTAppController removeAllObjectsForEntityName:] Unknown entity name: \"%@\"", entityName);
}


- (NSDictionary *)recordForObject:(id)object entityName:(NSString *)entityName // Returns the sync record
{
	NSMutableDictionary *record = [NSMutableDictionary dictionaryWithObject:entityName forKey:@"com.apple.syncservices.RecordEntityName"];
	
	if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
	{
		NSArray *keys = [NSArray arrayWithObjects:
			@"dayOfCommonEra",
			@"unread",
			@"note",
			nil];
		[record addEntriesFromDictionary:[object dictionaryWithValuesForKeys:keys]];
		[record setObject:[NSArray arrayWithObject:[[object constitution] uuid]]
				   forKey:@"constitution"];
		[record setObject:[object valueForKeyPath:@"annotatedPrinciples.uuid"] 
				   forKey:@"annotatedPrinciples"];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
	{
		NSArray *keys = [NSArray arrayWithObjects:
			@"versionLabel",
			@"creationDate",
			@"note",
			nil];
		[record addEntriesFromDictionary:[object dictionaryWithValuesForKeys:keys]];
		[record setObject:[object valueForKeyPath:@"principles.uuid"] 
				   forKey:@"principles"];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
	{
		NSArray *keys = [NSArray arrayWithObjects:
			@"label",
			@"explanation",
			@"creationDate",
			@"note",
			nil];
		[record addEntriesFromDictionary:[object dictionaryWithValuesForKeys:keys]];
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
	{
		NSArray *keys = [NSArray arrayWithObjects:
			@"upheld",
			nil];
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
		{
			NSLog(@"Could not find entry for annotated principle");
			record = nil;
		}
	}
	else
	{
		NSLog(@"-[INTAppController syncRecordForObject:entityName:] Unknown entity name: \"%@\"", entityName);
		record = nil;
	}
	
	return record;
}


- (id)objectWithRecordIdentifier:(NSString *)identifier entityName:(NSString *)entityName
{
	NSEnumerator *enumerator = [[self objectsForEntityName:entityName] objectEnumerator];
	id object = nil;
	while ((object = [enumerator nextObject]))
		if ([[object uuid] isEqual:identifier])
			break;
	
	return object;
}


- (id)objectWithRecordIdentifier:(NSString *)identifier entityName:(NSString *)entityName unresolvedRelationships:(NSArray *)unresolvedRelationships
{
	id object = [self objectWithRecordIdentifier:identifier entityName:entityName];
	if (!object)
	{
		NSEnumerator *unresolvedRelationshipsEnumerator = [unresolvedRelationships objectEnumerator];
		NSDictionary *unresolvedRelationship;
		while (!object && (unresolvedRelationship = [unresolvedRelationshipsEnumerator nextObject]))
		{
			if ([[unresolvedRelationship objectForKey:@"entityName"] isEqual:entityName] &&
				[[[unresolvedRelationship objectForKey:@"object"] uuid] isEqual:identifier])
				object = [unresolvedRelationship objectForKey:@"object"];
		}
	}
	return object;
}


- (BOOL)handleSyncChange:(ISyncChange *)change forEntityName:(NSString *)entityName newRecordIdentifier:(NSString **)outRecordIdentifier unresolvedRelationships:(NSArray **)outUnresolvedRelationships
{
	BOOL success = NO;
	NSMutableArray *unresolved = [NSMutableArray array];
	
	if ([entityName isEqualToString:@"org.playhaus.Introspectare.Entry"])
	{
		// Find or create the entry
		INTEntry *entry = nil;
		if ([change type] == ISyncChangeTypeAdd)
		{
			// Find day of common era
			int dayOfCommonEra = [[[change record] objectForKey:@"dayOfCommonEra"] intValue];
			entry = [[INTEntry alloc] initWithDayOfCommonEra:dayOfCommonEra];
			[[self library] addEntriesObject:entry];
		}
		else
			entry = [self objectWithRecordIdentifier:[change recordIdentifier] entityName:entityName];
		
		if (!entry)
			NSLog(@"Couldn't get entry for change");
		else
		{
			if (outRecordIdentifier)
				*outRecordIdentifier = [entry uuid];
			
			if ([change type] == ISyncChangeTypeDelete)
				[[self library] removeEntriesObject:entry];
			else
			{
				// Process changes
				NSEnumerator *changes = [[change changes] objectEnumerator];
				NSDictionary *currChange;
				while ((currChange = [changes nextObject]))
				{
					NSString *key = [currChange objectForKey:ISyncChangePropertyNameKey];
					id value = [currChange objectForKey:ISyncChangePropertyValueKey];
					
					if ([key isEqual:@"dayOfCommonEra"] && !([value isEqual:[entry valueForKey:key]] && [[currChange objectForKey:ISyncChangePropertyActionKey] isEqual:ISyncChangePropertySet]))
					{
						NSLog(@"Attempted to change day of common era of entry %@ from %d to %d, ignoring this changeset", entry, [entry dayOfCommonEra], [value intValue]);
						return NO;
					}
					
					if ([[currChange objectForKey:ISyncChangePropertyActionKey] isEqual:ISyncChangePropertySet])
					{
						if ([key isEqual:@"unread"] || [key isEqual:@"note"])
							[entry setValue:value forKey:key];
						else if ([key isEqual:@"constitution"] || [key isEqual:@"annotatedPrinciples"])
							[unresolved addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								entry, @"object",
								entityName, @"entityName",
								key, @"key",
								value, @"valueIdentifiers",
								nil]];
						else if (![key isEqual:@"dayOfCommonEra"] && ![key isEqual:@"com.apple.syncservices.RecordEntityName"])
							NSLog(@"Unhandled key for %@: %@", entry, key);
					}
					else
						[entry setValue:nil forKey:key];
				}
			}
			
			success = YES;
		}
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Constitution"])
	{
		// Find or create the constitution
		INTConstitution *constitution = nil;
		if ([change type] == ISyncChangeTypeAdd)
		{
			constitution = [[[INTConstitution alloc] init] autorelease];
			[[[self library] mutableArrayValueForKey:@"constitutions"] addObject:constitution];
		}
		else
			constitution = [self objectWithRecordIdentifier:[change recordIdentifier] entityName:entityName];
		
		if (!constitution)
			NSLog(@"Couldn't get constitution for change");
		else
		{
			if (outRecordIdentifier)
				*outRecordIdentifier = [constitution uuid];
			
			if ([change type] == ISyncChangeTypeDelete)
				[[[self library] mutableArrayValueForKey:@"constitutions"] removeObject:constitution];
			else
			{
				// Process changes
				NSEnumerator *changes = [[change changes] objectEnumerator];
				NSDictionary *currChange;
				while ((currChange = [changes nextObject]))
				{
					NSString *key = [currChange objectForKey:ISyncChangePropertyNameKey];
					if ([[currChange objectForKey:ISyncChangePropertyActionKey] isEqual:ISyncChangePropertySet])
					{
						id value = [currChange objectForKey:ISyncChangePropertyValueKey];
						
						if ([key isEqual:@"versionLabel"] || [key isEqual:@"creationDate"] || [key isEqual:@"note"])
							[constitution setValue:value forKey:key];
						else if ([key isEqual:@"principles"])
							[unresolved addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								constitution, @"object",
								entityName, @"entityName",
								key, @"key",
								value, @"valueIdentifiers",
								nil]];
						else if (![key isEqual:@"com.apple.syncservices.RecordEntityName"])
							NSLog(@"Unhandled key for %@: %@", constitution, key);
					}
					else
						[constitution setValue:nil forKey:key];
				}
			}
			
			success = YES;
		}
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.Principle"])
	{
		// Find or create the principle
		INTPrinciple *principle = nil;
		if ([change type] == ISyncChangeTypeAdd)
		{
			principle = [[[INTPrinciple alloc] init] autorelease];
			[INT_unresolvedPrinciples addObject:principle];
		}
		else
			principle = [self objectWithRecordIdentifier:[change recordIdentifier] entityName:entityName];
		
		if (!principle)
			NSLog(@"Couldn't get principle for change");
		else
		{
			if (outRecordIdentifier)
				*outRecordIdentifier = [principle uuid];
			
			if ([change type] == ISyncChangeTypeDelete)
				[[[self library] mutableArrayValueForKey:@"principles"] removeObject:principle];
			else
			{
				// Process changes
				NSEnumerator *changes = [[change changes] objectEnumerator];
				NSDictionary *currChange;
				while ((currChange = [changes nextObject]))
				{
					NSString *key = [currChange objectForKey:ISyncChangePropertyNameKey];
					if ([[currChange objectForKey:ISyncChangePropertyActionKey] isEqual:ISyncChangePropertySet])
					{
						id value = [currChange objectForKey:ISyncChangePropertyValueKey];
						
						if ([key isEqual:@"label"] || [key isEqual:@"explanation"] || [key isEqual:@"creationDate"] || [key isEqual:@"note"])
							[principle setValue:value forKey:key];
						else if (![key isEqual:@"com.apple.syncservices.RecordEntityName"])
							NSLog(@"Unhandled key for %@: %@", principle, key);
					}
					else
						[principle setValue:nil forKey:key];
				}
			}
			
			success = YES;
		}
	}
	else if ([entityName isEqualToString:@"org.playhaus.Introspectare.AnnotatedPrinciple"])
	{
		// Find or create the annotated principle
		INTAnnotatedPrinciple *annotatedPrinciple = nil;
		INTEntry *entry = nil;
		if ([change type] == ISyncChangeTypeAdd)
			annotatedPrinciple = [[[INTAnnotatedPrinciple alloc] initWithPrinciple:nil] autorelease];
		else
		{
			// Find entry uuid
			NSString *entryIdentifier = [[[change record] objectForKey:@"entry"] lastObject];
			entry = [self objectWithRecordIdentifier:entryIdentifier entityName:@"org.playhaus.Introspectare.Entry"];
			
			// Don't use -objectWithRecordIdentifier:entityName: because it will search _all_ annotated principles. This is much faster
			NSEnumerator *annotatedPrinciples = [[entry annotatedPrinciples] objectEnumerator];
			while ((annotatedPrinciple = [annotatedPrinciples nextObject]))
				if ([[annotatedPrinciple uuid] isEqual:[change recordIdentifier]])
					break;
			
			if (!annotatedPrinciple)
				annotatedPrinciple = [self objectWithRecordIdentifier:entryIdentifier entityName:entityName];
		}
		
		if (!annotatedPrinciple)
			NSLog(@"Couldn't get annotatedPrinciples for change");
		else
		{
			if (outRecordIdentifier)
				*outRecordIdentifier = [annotatedPrinciple uuid];
			
			if ([change type] == ISyncChangeTypeDelete)
				[[entry mutableArrayValueForKey:@"annotatedPrinciples"] removeObject:annotatedPrinciple];
			else
			{
				// Process changes
				NSEnumerator *changes = [[change changes] objectEnumerator];
				NSDictionary *currChange;
				while ((currChange = [changes nextObject]))
				{
					NSString *key = [currChange objectForKey:ISyncChangePropertyNameKey];
					if ([[currChange objectForKey:ISyncChangePropertyActionKey] isEqual:ISyncChangePropertySet])
					{
						id value = [currChange objectForKey:ISyncChangePropertyValueKey];
						
						if ([key isEqual:@"upheld"])
							[annotatedPrinciple setValue:value forKey:key];
						else if ([key isEqual:@"principle"] || [key isEqual:@"entry"])
							[unresolved addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								annotatedPrinciple, @"object",
								entityName, @"entityName",
								key, @"key",
								value, @"valueIdentifiers",
								nil]];
						else if (![key isEqual:@"com.apple.syncservices.RecordEntityName"])
							NSLog(@"Unhandled key for %@: %@", annotatedPrinciple, key);
					}
					else
						[annotatedPrinciple setValue:nil forKey:key];
				}
			}
			
			success = YES;
		}
	}
	else
		NSLog(@"-[INTAppController handleSyncChange:forEntityName:newRecordIdentifier:] Unknown entity name: \"%@\"", entityName);
	
	if (outUnresolvedRelationships)
		*outUnresolvedRelationships = unresolved;
	
	return success;
}


- (BOOL)resolveRelationships:(NSArray *)unresolvedRelationships withRecordIdentifierMapping:(NSDictionary *)recordIdentifierMapping
{
	BOOL success = YES;
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
					// The annotated principle is not yet connected, so it is probably (definitely?) among the unresolved relationships
					INTAnnotatedPrinciple *annotatedPrinciple = [self objectWithRecordIdentifier:annotatedPrincipleIdentifier
																					  entityName:@"org.playhaus.Introspectare.AnnotatedPrinciple"
																		 unresolvedRelationships:unresolvedRelationships];
					if (!annotatedPrinciple)
					{
						NSLog(@"Couldn't locate annotated principle");
						success = NO;
						continue;
					}
					
					[annotatedPrinciples addObject:annotatedPrinciple];
				}
				[entry setAnnotatedPrinciples:annotatedPrinciples];
				[annotatedPrinciples release];
			}
			else
				NSLog(@"Got an unknown unresolved relationship: %@", unresolvedRelationship);
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
					// The principle is not yet connected, so it is probably (definitely?) among the unresolved relationships
					INTPrinciple *principle = [self objectWithRecordIdentifier:principleIdentifier
																	entityName:@"org.playhaus.Introspectare.Principle"
													   unresolvedRelationships:unresolvedRelationships];
					if (!principle)
					{
						NSLog(@"Couldn't locate principle");
						success = NO;
						continue;
					}
					
					[principles addObject:principle];
				}
				[constitution setPrinciples:principles];
				[principles release];
			}
			else
				NSLog(@"Got an unknown unresolved relationship: %@", unresolvedRelationship);
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
				
				// The principle may or may not be connected, so it may be among the unresolved relationships, or in the library
				INTPrinciple *principle = [self objectWithRecordIdentifier:principleIdentifier
																entityName:@"org.playhaus.Introspectare.Principle"
												   unresolvedRelationships:unresolvedRelationships];
				if (principle)
					[annotatedPrinciple setPrinciple:principle];
				else
				{
					NSLog(@"Couldn't locate principle");
					success = NO;
				}
			}
			else
				NSLog(@"Got an unknown unresolved relationship: %@", unresolvedRelationship);
		}
		else
			NSLog(@"-[INTAppController resolveRelationships:] Unknown entity name: \"%@\"", entityName);
	}
	
	return success;
}


@end
