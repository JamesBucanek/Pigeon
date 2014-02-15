//
//  DocumentController.m
//  Pigeon
//
//  Created by James Bucanek on 1/5/14.
//  Copyright (c) 2014 James Bucanek. See LICENSE.txt.
//

#import "DocumentController.h"

//#define NO_TEST_LOG
#import "Pigeon.h"
#import "LocationData.h"
#import "LocationData+Documents.h"
#import "LocationDocument.h"
#import "LocationDocument+ImageStorage.h"


#define kSavedLocationsDirectoryName		@"Saved Locations"
#define kSavedLocationDocumentExtension		@"savedloc"
#define kSavedLocationFilenameFormat		(@"loc-%@." kSavedLocationDocumentExtension)

#ifndef NO_TEST_LOG
extern NSString* URLSummary( NSURL* url );
#endif



@interface DocumentController () // private
{
//	NSMutableDictionary*	managedLocations;			// identifier->SavedLocation map
	NSURL*					ubiquityContainerURL;
	NSURL*					cloudSavedLocationsURL;
	id						ubiquityIdentityToken;
	NSMetadataQuery*		cloudQuery;
	BOOL					queryComplete;
}
+ (NSURL*)localSavedLocationsURL;
+ (NSURL*)localURLForIdentifier:(NSString*)identifier;
- (NSURL*)cloudSavedLocationsURL;
- (NSURL*)cloudURLForIdentifier:(NSString*)identifier;
- (NSURL*)URLForIdentifier:(NSString*)identifier inCloud:(BOOL*)returnCloud;
- (NSURL*)URLForIdentifier:(NSString*)identifier;
- (void)setup;
- (void)applicationDidEnterBackgroundNotification:(NSNotification*)notification;
- (void)applicationDidReceiveMemoryWarning:(NSNotification*)notification;
- (void)loadDocumentAtURL:(NSURL*)docURL;
- (void)openDocument:(LocationDocument*)document;
- (void)addDocument:(LocationDocument*)document;
- (void)relocateDocumentForLocation:(SavedLocation*)location;
- (void)documentStateDidChangeNotification:(NSNotification*)notification;
- (void)updateStorageLocation;
- (void)setDocumentStorage:(NSURL*)container;
- (void)relocateDocumentStorage;
- (void)createCloudQuery;
- (void)haltCloudQuery;
- (void)ubiquityIdentifierChangedNotification:(NSNotification*)notification;
- (void)metadataQueryDidUpdateNotification:(NSNotification*)notification;
- (void)metadataQueryDidFinishNotification:(NSNotification*)notification;
- (void)processCloudQueryResultsFinal:(BOOL)final;
@end

static NSString* FileNameForIdentifier( NSString* identifier );

@implementation DocumentController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (DocumentController*)sharedController
{
	// Return the singleton document controller
	static DocumentController* sSingletonManager;
	if (sSingletonManager==nil)
		{
		sSingletonManager = [DocumentController new];
		[sSingletonManager setup];
		}
	return  sSingletonManager;
}

+ (NSURL*)localSavedLocationsURL
{
	// Return cached the "Saved Locations" directory URL in local storage
	static NSURL* localURL;
	if (localURL==nil)
		{
		// Lazily locate, or create if necessay, the "Saved Locations" directory in the sandbox
		NSFileManager *fileManager = [NSFileManager defaultManager];
		localURL = [fileManager URLForDirectory:NSApplicationSupportDirectory
									   inDomain:NSUserDomainMask
							  appropriateForURL:nil
										 create:YES
										  error:NULL];
		// Append the directory name of the container folder
		localURL = [localURL URLByAppendingPathComponent:kSavedLocationsDirectoryName];
		// Make sure that all of the directories exist
		[fileManager createDirectoryAtURL:localURL
			  withIntermediateDirectories:YES
							   attributes:nil
									error:NULL];	// This had better work!
		}
	return localURL;
}

+ (NSURL*)localURLForIdentifier:(NSString*)identifier
{
	return [[self localSavedLocationsURL] URLByAppendingPathComponent:FileNameForIdentifier(identifier)];
}

- (NSURL*)cloudSavedLocationsURL
{
	// Return the "Saved Locations" directory inside the ubiquity container, iff there is one
	if (cloudSavedLocationsURL==nil && ubiquityContainerURL!=nil)
		{
		cloudSavedLocationsURL = [ubiquityContainerURL URLByAppendingPathComponent:kSavedLocationsDirectoryName];
		// Make sure that this directory exists
		[[NSFileManager defaultManager] createDirectoryAtURL:cloudSavedLocationsURL
								 withIntermediateDirectories:YES
												  attributes:nil
													   error:NULL];	// This had better work!
		}
	return cloudSavedLocationsURL;
}

- (NSURL*)cloudURLForIdentifier:(NSString*)identifier
{
	return [[self cloudSavedLocationsURL] URLByAppendingPathComponent:FileNameForIdentifier(identifier)];
}

- (NSURL*)URLForIdentifier:(NSString *)identifier
{
	return [self URLForIdentifier:identifier inCloud:NULL];
}

- (NSURL*)URLForIdentifier:(NSString*)identifier inCloud:(BOOL*)returnCloud
{
	// Return file URL for an identifier in the currently active document storage location
	//	and a boolean flag indicating whether the URL is in the ubiquitous storage.
	// This method is thread safe, so the return URL and cloud flags are always consistent.
	NSURL* url;
	@synchronized(self) {
		BOOL inCloud = self.useUbiquitousStore;
		if (inCloud)
			url = [self cloudURLForIdentifier:identifier];
		else
			url = [DocumentController localURLForIdentifier:identifier];
		if (returnCloud!=NULL)
			*returnCloud = inCloud;
		}
	return url;
}

- (void)setup
{
	// Create the data model and connect it to the document manager
	_data = [LocationData new];
	_data.documentManager = self;
	
	// Get the initial ubiquity container identity token
	ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];

	// Observe key notifications
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
						   selector:@selector(ubiquityIdentifierChangedNotification:)
							   name:NSUbiquityIdentityDidChangeNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(applicationDidEnterBackgroundNotification:)
							   name:UIApplicationDidEnterBackgroundNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(applicationDidReceiveMemoryWarning:)
							   name:UIApplicationDidReceiveMemoryWarningNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(documentStateDidChangeNotification:)
							   name:UIDocumentStateChangedNotification
							 object:nil];	// monitor changes for all documents
	
	// Determine where our documents are stored and start loading them
	[self updateStorageLocation];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification*)notification
{
	// Whenever the application enters the background state, take note of the
	//	order of the saved locations. This will be used if the application
	//	is restarted. We want the saved locations to appear in the same order
	//	when the app starts again, which is a little tricky becuase the
	//	documents containing the locations load asynchronously and in
	//	no particular order. This array will be used to re-insert them back
	//	into their original order.
	NSMutableArray* documentOrder = [NSMutableArray array];
	[_data.locations enumerateObjectsUsingBlock:^(id location, NSUInteger idx, BOOL *stop) {
		[documentOrder addObject:((SavedLocation*)location).identifier];
		}];
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:documentOrder forKey:kPreferencesLocationOrder];
	NSString* activeIdentifier = _data.activeLocation.identifier;
	if (activeIdentifier!=nil)
		[userDefaults setObject:activeIdentifier forKey:kPreferencesLocationActive];
	else
		[userDefaults removeObjectForKey:kPreferencesLocationActive];
}

- (void)applicationDidReceiveMemoryWarning:(NSNotification *)notification
{
	// The document controller doesn't have any memory to release, but the individual
	//	documents might; pass this warning on to all of the documents in the manifest.
	[_data.locations enumerateObjectsUsingBlock:^(SavedLocation* location, NSUInteger idx, BOOL *stop) {
		[location.document didReceiveMemoryWarning];
		}];
}

#pragma mark Properties

- (BOOL)useUbiquitousStore
{
	// YES if the app can and should be storing documents in the iCloud ubiquity container
	return ( self.iCloudAvailable && self.syncWithCloud );
}

- (BOOL)iCloudAvailable
{
	return (ubiquityIdentityToken!=nil);
}

- (BOOL)syncWithCloud
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kPreferencesUseICloud];
}

- (void)setSyncWithCloud:(BOOL)syncWithCloud
{
	[[NSUserDefaults standardUserDefaults] setBool:syncWithCloud forKey:kPreferencesUseICloud];
	[self updateStorageLocation];		// switch to using the new storage loction
}

#pragma mark Documents

//- (LocationDocument*)documentForLocation:(SavedLocation*)location
//{
//	return [managedLocations[location.identifier] document];
//}

- (void)loadDocumentAtURL:(NSURL*)docURL
{
	// Read the document at the given URL.
	// Received when a document file is discovered, or rediscovered.
	// There are various reasons why this message might be received for a location
	//	that's already in the data model. To deal with this, there are a couple
	//	of checkpoints where duplicate document objects are weeded out.
	// The first, and simplest, test is to simply ignore a request to open
	//	a document file that already belongs to a document object.
	for ( SavedLocation* location in _data.locations )
		{
		LocationDocument* document = location.document;
		if ([document isStoredAtURL:docURL])
			{
			// An open document at this URL already exists; just ignore the request
			TESTLog(@"ignoring %@; already open in a document%s",
					URLSummary(docURL),
					(document.published?"":" (unpublished)"));
			document.published = YES;	// implies the document has been published
			return;
			}
		}
	// The next step is to create a document object and read its SavedLocation object.
	LocationDocument* newDocument = [[LocationDocument alloc] initWithFileURL:docURL];
	newDocument.storageURL = docURL;
	newDocument.published = YES;		// if we discovered the document, it's public
	[self openDocument:newDocument];
}

- (void)openDocument:(LocationDocument*)document
{
	// Initiate document reading
	[document openWithCompletionHandler:^(BOOL success) {
		if (success)
			// Add the information from the successfully opened document to the data model
			[self addDocument:document];
		else NSLog(@"failed to open document %@",document.fileURL);
	}];
}

- (void)addDocument:(LocationDocument*)document
{
	// Add an (opened) document to the data model.
	SavedLocation* location = document.location;
	NSString* identifier = location.identifier;
	
	SavedLocation* existingLocation = [_data locationForIdentifier:identifier];
	if (existingLocation!=nil)
		{
		// The document represents a saved location that's already in the data model.
		// (i.e. it's a duplicate document)
		// Perform a simple conflict resolution: compare the mod dates and used to most recent data
		LocationDocument* activeDocument = existingLocation.document;
		if ([document.fileModificationDate compare:activeDocument.fileModificationDate]==NSOrderedDescending)
			{
			// document's last modification date is more recent than activeDocument's modification date.
			// Update the location information in the data model with the newer file data.
			[existingLocation subsumeLocation:location];
			TESTLog(@"subsumed newer document %@",URLSummary(document.storageURL));
			}
		else TESTLog(@"ignored duplicate/older document %@",URLSummary(document.storageURL));
		}
	else
		{
		// The document contains a location we don't know about: add it to the data model
		
		// When loading a new location, see if the location was previously
		//	known and try to insert it at the same relative position
		//	in the data model's list.
		TESTLog(@"adding new document %@ to data model",URLSummary(document.storageURL));
		__block NSUInteger insertIndex = NSNotFound;
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		NSArray* documentOrder = [defaults objectForKey:kPreferencesLocationOrder];
		if (documentOrder!=nil)
			{
			// Find the new location in the list of previously known locations
			NSUInteger relativeIndex = [documentOrder indexOfObject:identifier];
			NSArray* locations = _data.locations;
			if (relativeIndex!=NSNotFound)
				{
				// Look forward in the previously known list for that same location
				//	in the data model.
				for ( NSUInteger i=relativeIndex+1; i<documentOrder.count && insertIndex==NSNotFound; i++ )
					{
					NSString* siblingIdentifier = documentOrder[i];
					[locations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						if ([[obj identifier] isEqualToString:siblingIdentifier])
							{
							// A previously known location that was after the new location was
							//	found in the data model. Insert the new location immediately
							//	before the sibling location.
							insertIndex = idx;
							*stop = YES;
							}
					}];
					}
				// Next, look backwards in the known list for the same location in the data model.
				for ( NSUInteger i=relativeIndex; (i--)!=0 && insertIndex==NSNotFound; )
					{
					NSString* siblingIdentifier = documentOrder[i];
					[locations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						if ([[obj identifier] isEqualToString:siblingIdentifier])
							{
							// A previously known location that was before the new location was
							//	found in the data model. Insert the new location immediately
							//	after the sibling location.
							insertIndex = idx+1;
							*stop = YES;
							}
					}];
					}
				}
			}
		if (insertIndex==NSNotFound)
			// Couldn't determine an insertion index; insert it at the beginning of the list
			insertIndex = 0;
		
		// Add the location to the data model
		[_data insertLocation:location atIndex:insertIndex];
		
		if ([[defaults objectForKey:kPreferencesLocationActive] isEqualToString:identifier])
			{
			// The location just loaded was previously the active location.
			if (_data.activeLocation==nil)
				// There isn't an active location, so make this one the active location.
				// (This test prevents a new active location from being usurped by a saved one.)
				_data.activeLocation = location;
			}
		}
}

- (void)createDocumentForLocation:(SavedLocation*)location
{
	// Received when the data model creates a new SavedLocation object
	
	// Create and open a document for the new location
	NSString* identifier = location.identifier;
	// The initial save of the document is performed locally, even for cloud documents, as
	//	per the note in the section "Composing the File URL and Saving the Document File"
	//	of the "Managing the Life Cycle of a Document" chapter.
	NSURL* docURL = [DocumentController localURLForIdentifier:identifier];
	LocationDocument* document = [[LocationDocument alloc] initWithFileURL:docURL];
	document.storageURL = docURL;
	//document.published = NO;		// newly created documents are not immediately public
	// Connect the document to its location and vice versa
	document.location = location;
	// Create the new document file (in the background)
	[document saveToURL:docURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
		if (success && self.useUbiquitousStore)
			// Once the initial save is complete, optionally relocate the document to the cloud.
			// It seems like overkill to relocate *all* of the documents, but -relocateStorageDocuments
			//	takes care of a lot of details, like temporarily suspending the metadata query until
			//	the document has been moved.
			[self relocateDocumentStorage];
		}];
	TESTLog(@"created document file %@",URLSummary(docURL));
}

- (void)removeDocumentForLocation:(SavedLocation*)location
{
	// Received when the data model destroys a SavedLocation object
	//	or when a document is moved and the old file needs to be deleted.
	
	// Close the document, discarding any pending changes, and delete it
	LocationDocument* document = location.document;			// (could be nil)
	[document updateChangeCount:UIDocumentChangeCleared];	// discard any pending changes
	document.location = nil;								// disconnect document from location
	[document closeWithCompletionHandler:^(BOOL success) {	// close the document
		// Once the document is closed, delete it.
		// Perform the delete under the supervision of a file coordinator so it happens cleanly
		//	and the cloud gets notified of the change.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
			NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
			[fileCoordinator coordinateWritingItemAtURL:document.storageURL
												options:NSFileCoordinatorWritingForDeleting
												  error:nil
											 byAccessor:^(NSURL* writingURL) {
												 TESTLog(@"deleting document file %@",URLSummary(writingURL));
												 [[NSFileManager new] removeItemAtURL:writingURL error:nil];
												 }];
			});
		}];
}

static dispatch_queue_t CloudCopyQueue( void )
{
	// Lazily create a serial dispatch queue for the document move operations
	static dispatch_queue_t sCloudCopyQueue;
	if (sCloudCopyQueue==NULL)
		sCloudCopyQueue = dispatch_queue_create("iCloudCopy",DISPATCH_QUEUE_SERIAL);
	return sCloudCopyQueue;
}

- (void)relocateDocumentForLocation:(SavedLocation*)location
{
	// Asynchronously relocate a document to either the ubiquitous storage
	//	location or to local document storage.

	dispatch_async(CloudCopyQueue(), ^{
		// Copy of the document from its current location to wherever its supposed to be (local file or cloud storage),
		//	unless it's already there.
		// Note: Where the document should be is dynamically determined at the moment this block is executed.
		//		 The need to relocate a document is reevaluated following various state changes (the user
		//		 turns iCloud synchronization on/off, the ubiquity container is found, the ubiquity identifier
		//		 changes, and so on). This logic is simple: move the document if it needs to be moved and do nothing
		//		 if it doesn't.
		//		 This logic also prevent the "whiplash" effect that would occur if the user decided to turn
		//		 the iCloud synchronization option on and off in rapid succession. Each change would que up a task
		//		 to copy the document to its new location and reopen it, only to immediatley copy it back
		//		 and reopen it, and so on. By determining the desired location at copy time, multiple requests
		//		 to relocate a document will copy it once to its final location and then do nothing (because
		//		 it's already there).
		LocationDocument* document = location.document;
		BOOL docsInCloud;
		NSURL* whitherURL = [self URLForIdentifier:location.identifier inCloud:&docsInCloud];
		if (![document isStoredAtURL:whitherURL])
			{
			// Document is not stored at its ideal destination
			NSURL* whenceURL = document.storageURL;			// get where the document currently is
			TESTLog(@"moving document from %@ to %@",URLSummary(whenceURL),URLSummary(whitherURL));
			document.storageURL = whitherURL;
			document.published = NO;						// make document immune from being auto-deleted until it
															//	appears in the cloud metadata query (ignored if local)
			NSError* error = nil;
			if ([[NSFileManager new] setUbiquitous:docsInCloud itemAtURL:whenceURL destinationURL:whitherURL error:&error])
				TESTLog(@"moved item to %@",URLSummary(whitherURL));
			else
				NSLog(@"failed to relocate document %@: %@",whenceURL,error);
			}
		else
			{
			TESTLog(@"did not need to relocate %@",URLSummary(document.storageURL));
			}
		});
}

- (void)documentStateDidChangeNotification:(NSNotification*)notification
{
	// Received when a UIDocument detects a change in its state
	LocationDocument* document = notification.object;
	if ([document isKindOfClass:[LocationDocument class]])
		{
		SavedLocation* location = document.location;
		if ([_data locationForIdentifier:location.identifier]==location)
			{
			// The document belongs to the data model of this controller
#ifndef NO_TEST_LOG
			NSString* description = document.description;
			description = [description stringByReplacingOccurrencesOfString:document.fileURL.description
																 withString:URLSummary(document.fileURL)];
			TESTLog(@"document state now %s%s%s%s in %@",
					(document.documentState&UIDocumentStateClosed)?"closed":"open",
					(document.documentState&UIDocumentStateInConflict)?",conflict,":"",
					(document.documentState&UIDocumentStateSavingError)?",error":"",
					(document.documentState&UIDocumentStateEditingDisabled)?",disabled":"",
					description);
#endif
			if ( (document.documentState&UIDocumentStateInConflict)!=0x0 )
				{
				// Document is in conflict; automatically pick the most current version
				NSURL* docURL = document.fileURL;
				NSFileVersion* currentVersion = [NSFileVersion currentVersionOfItemAtURL:docURL];
				TESTLog(@"current version = %@",currentVersion.modificationDate);
				NSArray* conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:docURL];
#ifndef NO_TEST_LOG
				for ( NSUInteger i_=0; i_<conflictVersions.count; i_++ )
					TESTLog(@"conflict version[%u] = %@",(unsigned)i_,[conflictVersions[i_] modificationDate]);
#endif
				// Pick the document with the most recent modification date
				NSFileVersion* winningVersion = currentVersion;
				for ( NSFileVersion* conflict in conflictVersions )
					if ([conflict.modificationDate compare:winningVersion.modificationDate]==NSOrderedDescending)
						winningVersion = conflict;
				NSError* error = nil;
				if (winningVersion!=currentVersion)
					{
					// The current version loses; replace it with the winning version and reload the document
					TESTLog(@"replacing location %@ with version %@",URLSummary(docURL),winningVersion.modificationDate);
					[winningVersion replaceItemAtURL:docURL options:NSFileVersionReplacingByMoving error:&error];
					if (error!=nil)
						NSLog(@"problem replacing document with winning version: %@",error);
					// Clear out the other versions
					error = nil;
					if (![NSFileVersion removeOtherVersionsOfItemAtURL:docURL error:&error])
						NSLog(@"problem removing losing versions: %@",error);
					// Reload the data from the document. (Since the LocationDocument object already has a
					//	location property, reading will update the data model automatically.)
					[document revertToContentsOfURL:docURL completionHandler:nil];
					}
				else
					{
					// The current version is still current; ignore and discard the others
					TESTLog(@"location %@ with version %@ is still current",URLSummary(docURL),currentVersion.modificationDate);
					if (![NSFileVersion removeOtherVersionsOfItemAtURL:docURL error:&error])
						NSLog(@"problem removing losing versions: %@",error);
					}
				// Last step: mark all other versions of this document as "resolved"
				conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:docURL];
				for (NSFileVersion* fileVersion in conflictVersions)
					fileVersion.resolved = YES;
				}
			}
		else
			{
#ifndef NO_TEST_LOG
			NSString* description = document.description;
			description = [description stringByReplacingOccurrencesOfString:document.fileURL.description
																 withString:URLSummary(document.fileURL)];
			TESTLog(@"not our document: %@",description);
#endif
			}
		}
}

#pragma mark Storage Management

- (void)updateStorageLocation
{
	// Asynchronously determine the status of the iCloud ubiquity container.
	// Once determined, -updateUbiquityContainer: is sent to set up either
	//	local or iCloud storage and begin loading, and possibly relocating, documents.
	
	// Stop any running metadata query
	[self haltCloudQuery];
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification object:nil];
	[notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];

	// Query for the iCloud ubiquity container (async) or use local storage (sync)
	if (self.useUbiquitousStore)
		{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
			// Spawn a thread to location the iCloud ubiquity container directory
			NSURL* container = [[NSFileManager new] URLForUbiquityContainerIdentifier:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				// Back on the main thread, set up the document storage
				[self setDocumentStorage:container];
				});
			});
		}
	else
		{
		// iCloud syncing is disabled; set up for local storage only
		[self setDocumentStorage:nil];			// use local storage
		}
}

- (void)setDocumentStorage:(NSURL*)container
{
	// Received when the location/availability of the current documents container is known.
	ubiquityContainerURL = container;	// nil means use local storage
	cloudSavedLocationsURL = nil;		// reset cached location
	if (container!=nil)
		{
		// iCloud is on:

		// Create a metadata query to monitor the state of the container
		[self createCloudQuery];
		
		// Observe the query notifications
		NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self
							   selector:@selector(metadataQueryDidUpdateNotification:)
								   name:NSMetadataQueryDidUpdateNotification
								 object:nil];
		[notificationCenter addObserver:self
							   selector:@selector(metadataQueryDidFinishNotification:)
								   name:NSMetadataQueryDidFinishGatheringNotification
								 object:nil];
		}
	else
		{
		// iCloud off: read the list of local documents and load them immediately
		NSArray* localItems = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[DocumentController localSavedLocationsURL]
															includingPropertiesForKeys:@[NSURLAttributeModificationDateKey]
																			   options:0
																				 error:NULL];
		for ( NSURL* item in localItems )
			{
			if ([item.path hasSuffix:@"." kSavedLocationDocumentExtension])
				{
				TESTLog(@"local item %@",URLSummary(item));
				[self loadDocumentAtURL:item];
				}
			else TESTLog(@"ignored item %@",URLSummary(item));
			}
		}

	// Reevaluate the location of all known documents.
	// Check to see if locally stored documents should now be moved to the cloud (before this we
	//	didn't know where the cloud store was). Ditto for moving any documents still in the
	//	cloud to local storage. If the documents are all where they're supposed to be, this
	//	won't do much.
	[self relocateDocumentStorage];		// will also start/restart the metadata query
}

- (void)relocateDocumentStorage
{
	// Received whenever iCloud synchronization is turned on or off

	// Shutdown the metadata query before the relocation operation(s) start
	dispatch_async(CloudCopyQueue(), ^{
		dispatch_sync(dispatch_get_main_queue(), ^{
			TESTLog(@"cloudQuery %s",(cloudQuery!=nil?(cloudQuery.isStarted?"halted":"idle"):"nil"));
			// if cloudQuery is nil, this will do nothing
			if (cloudQuery.isStarted)
				[cloudQuery stopQuery];
			});
		});

	// Copy all active documents to their new location and reopen them.
	for ( SavedLocation* location in _data.locations )
		[self relocateDocumentForLocation:location];

	// Restart the metadata query once all of the relocation operations are complete
	dispatch_async(CloudCopyQueue(), ^{
		dispatch_sync(dispatch_get_main_queue(), ^{
			queryComplete = NO;
			[cloudQuery startQuery];
			TESTLog(@"cloudQuery %s",(cloudQuery!=nil?"started":"nil"));
		});
	});
}

- (void)haltCloudQuery
{
	// Stop the query and destroy it
	if (cloudQuery.isStarted)
		[cloudQuery stopQuery];
	cloudQuery = nil;
}

- (void)createCloudQuery
{
	if (cloudQuery==nil)
		{
		cloudQuery = [NSMetadataQuery new];
		[cloudQuery setSearchScopes:@[NSMetadataQueryUbiquitousDataScope]];
		// Create a predicate to search for .savedloc packages.
		// Important note: This works, in fact much of the cloud synchronization works, because this
		//				   app declares a document type for .savedloc, and that document type/UTI
		//				   is a package (bundle). Without that, the .savedloc documents would
		//				   be treated as directories full of files. They wouldn't match this predicate,
		//				   and they wouldn't be copied atomically to/from the cloud.
		[cloudQuery setPredicate:[NSPredicate predicateWithFormat:@"%K ENDSWITH %@",
								  NSMetadataItemPathKey,
								  @"." kSavedLocationDocumentExtension]];
		queryComplete = NO;
		TESTLog(@"update interval = %f",cloudQuery.notificationBatchingInterval);
		}
}


#pragma mark iCloud

- (void)ubiquityIdentifierChangedNotification:(NSNotification*)notification
{
	// The ubiquity container identifier has changed.
	// This could be that the user logged in or out of iCloud, or could have switched accounts.
	id newToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
	if (!OBJECTS_EQUAL(newToken,ubiquityIdentityToken))
		{
		ubiquityIdentityToken = newToken;
		[self updateStorageLocation];
		}
}

- (void)metadataQueryDidUpdateNotification:(NSNotification*)notification
{
	[self processCloudQueryResultsFinal:NO];
}

- (void)metadataQueryDidFinishNotification:(NSNotification*)notification
{
	[self processCloudQueryResultsFinal:YES];
}

- (void)processCloudQueryResultsFinal:(BOOL)final
{
	TESTLog(@"%u results, %s",(unsigned int)cloudQuery.resultCount,(final?"finished":(queryComplete?"update(complete)":"update")));
	
	// Briefly pause the metadata query and collect the URLs of the documents
	NSMutableArray* URLs = [NSMutableArray arrayWithCapacity:cloudQuery.resultCount];
	[cloudQuery enumerateResultsUsingBlock:^(NSMetadataItem* result, NSUInteger idx, BOOL *stop) {
		// Obtain the URL of the document
		NSURL* itemURL = [result valueForAttribute:NSMetadataItemURLKey];
		// Open the documents that have downloaded, download documents that haven't
		NSString* status = [result valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
		if ([status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded])
			{
			NSError* error = nil;
			if ([[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:itemURL error:&error])
				TESTLog(@"pulling document %@",URLSummary(itemURL));
			else
				TESTLog(@"problem pulling %@: %@",URLSummary(itemURL),error);
			}
		else
			{
			TESTLog(@"discovered document %@",URLSummary(itemURL));
			[URLs addObject:itemURL];
			}
		}];
	
	// Open each discovered document
	for ( NSURL* url in URLs )
		// -loadDocumentAtURL: will ignore documents already opened or that represent duplicate locations
		[self loadDocumentAtURL:url];
	
	if (final)
		queryComplete = YES;
	if (queryComplete)
		{
		// Once the query is complete, it maintains a complete list of the documents in the cloud.
		// At the end of each update, look for location documents that are no longer in the cloud,
		//	which would indicate that they've been deleted by another device.
		// Note: it's possible that not all of the existing cloud documents have been added to the
		//		 data model yet, but that doesn't matter. We're only looking for locations already
		//		 in the data model that no longer have cloud documents.
		for ( SavedLocation* location in _data.locations )
			{
			LocationDocument* document = location.document;
			for ( NSURL* url in URLs )
				{
				if ([document isStoredAtURL:url])
					{
					document = nil;		// flag that this document is still valid
					break;				// stop searching
					}
				}
			if (document!=nil)
				{
				// document wasn't set to nil, which means it's file was NOT found in the list of existing documents.
				// (Note: _data.locations returns a copy of the array, so it's safe to mutate the data model during the loop)
				if (document.published)
					{
					TESTLog(@"absentee document %@",URLSummary(document.storageURL));
					[document updateChangeCount:UIDocumentChangeCleared];	// discard any pending changes
					location.document = nil;			// disconnect the location from the document before removing it
					[_data removeLocation:location];	//	to prevent -removeLocation: from trying to delete the document's file
					}
				else
					{
					// The document did not have its .published flag set, which means it's a document that was created
					//	by the user and stored in the cloud, but the metadata query has not yet caught up and seen it yet.
					//	As such, ignore that fact that the document does not appear in the query until it appears at least
					//	once. This will set the .published property to YES. Then should it disappear from the query,
					//	that would be grounds to delete it.
					TESTLog(@"(ignoring unpublished document %@)",URLSummary(document.storageURL));
					}
				}
			}
		}
}


@end

static NSString* FileNameForIdentifier( NSString* identifier )
{
	return [NSString stringWithFormat:kSavedLocationFilenameFormat,identifier];
}

#ifndef NO_TEST_LOG
NSString* URLSummary( NSURL* url )
{
	// return a simplified description of the document URL, indicating its name and whether it's
	//	stored in the local file sandbox or in the cloud ubiquity store.
	NSString* path = [url.path stringByStandardizingPath];
	NSString* location = [path stringByDeletingLastPathComponent];
	NSString* localBase = [[[DocumentController localSavedLocationsURL] path] stringByStandardizingPath];
	if ([path hasPrefix:localBase])
		{
		location = @"~/local";
		}
	else
		{
		NSString* cloudBase = [[[[DocumentController sharedController] cloudSavedLocationsURL] path] stringByStandardizingPath];
		if (cloudBase!=nil && [path hasPrefix:cloudBase])
			location = @"{cloud}";
		}
	return [NSString stringWithFormat:@"%@/%@",location,url.lastPathComponent];
}
#endif
