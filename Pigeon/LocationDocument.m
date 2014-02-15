//
//  LocationDocument.m
//  Pigeon
//
//  Created by James Bucanek on 12/28/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <Foundation/FoundationErrors.h>

//#define NO_TEST_LOG
#import "Pigeon.h"
#import "LocationDocument.h"
#import "LocationDocument+ImageStorage.h"

#import "SavedLocation.h"


#define kLocationDocumentType		@"data"
#define kLocationDocumentBasename	@"Location"
#define kLocationDocumentFormat		(kLocationDocumentBasename @"-%@." kLocationDocumentType)

#ifndef NO_TEST_LOG
extern NSString* URLSummary( NSURL* url );	// debugging aide defined in DocumentController
#endif


void RemoveChildWrapper( NSFileWrapper* directoryWrapper, NSString* key );


@interface LocationDocument () // private
{
}

@end


@implementation LocationDocument

+ (LocationDocument*)documentAtURL:(NSURL*)url
{
	// Return a UIDocument for the existing package at |url|, or create a new one
	NSFileManager *fileManager = [NSFileManager defaultManager];
	LocationDocument *document = [[LocationDocument alloc] initWithFileURL:url];
	if ([fileManager fileExistsAtPath:url.path])
		{
		// Document package already exists: open it
		[document openWithCompletionHandler:nil];
		}
	else
		{
		// Document package does not exit: create it
		// Save the file, specifying that it should create the package
		[document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
		}
	
	// Return the opened/created document
	return document;
}

- (void)dealloc
{
    self.location = nil;			// stop observing the SavedLocation object
}

#pragma mark Properties

- (NSString*)filename
{
	return [NSString stringWithFormat:kLocationDocumentFormat,_location.identifier];
}

- (void)setLocation:(SavedLocation*)location
{
	static NSArray* sMutablePropertyKeys;
	if (sMutablePropertyKeys==nil)
		sMutablePropertyKeys = @[@"location",@"name",@"placemark",@"notes"];
	
	// Stop observing changes to the current SavedLocation object
	[sMutablePropertyKeys enumerateObjectsWithOptions:0
										   usingBlock:^(id key, NSUInteger idx, BOOL *stop) {
											   [_location removeObserver:self forKeyPath:key];
										   }];
	
	_location.document = nil;		// the old location is no longer associated with this document
	_location = location;
	location.document = self;		// this document is now bound to the new location object
	
	// Begin observing any interesting changes in this document's data model values
	[sMutablePropertyKeys enumerateObjectsWithOptions:0
										   usingBlock:^(id key, NSUInteger idx, BOOL *stop) {
											   [location addObserver:self forKeyPath:key options:0 context:NULL];
											   }];
}

#pragma mark Tests

- (BOOL)isStoredAtURL:(NSURL*)url
{
	// See if the storageURL matches the given URL.
	// The code converts both URLs to filesystem paths and then compares those paths.
	// This has to be done becuase sometimes URLs to directories have a trailing '/',
	//	and sometimes they don't, and two otherwise identical URLs that differ only
	//	in a trailing '/' will return NO if sent -isEqual:. (lame)
	return [_storageURL.path isEqualToString:url.path];
}

#pragma mark UIDocument

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	// Sent by UIDocument when it wants to save a document.
	
	if (docWrapper==nil)
		{
		// Document has never been opened or saved
		// Create the (empty) directory wrapper the will contain all of the component file wrappers
		docWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
		}

	// First remove any filewrappers that need to be deleted
	for ( NSString* removeKey in deletedWrappers )
		RemoveChildWrapper(docWrapper,removeKey);
	deletedWrappers = nil;
	
	// Archive (serialize) the location information and add it to the package.
	TESTLog(@"writing %@",_location.identifier);
	NSData* locationData = [NSKeyedArchiver archivedDataWithRootObject:_location];
	RemoveChildWrapper(docWrapper,kLocationDataPreferredName);
	[docWrapper addRegularFileWithContents:locationData
						 preferredFilename:kLocationDataPreferredName];
	
	// Archive (serialize) the persistent picture metadata and image data.
	// This is the only place where new file wrappers are added to the package (adding a new
	//	image differs adding a new wrapper until this moment). This insures that the
	//	file wrapper is never modified while the document is being written  and also insures
	//	that the contents of the package is never changed outside of save operation, which
	//	is corrdinated so the cloud synchronization works atomically.
	[self storePicturesInDocument];
	
	// Return the root file wrapper, which UIDocument will use to write the document.
	return docWrapper;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	// Sent by UIDocument when it wants to load the data in a document.
	// |contents| contains the package's directory wrapper.
	
	// Remember the root directory wrapper for additional data and future saves.
	docWrapper = contents;
	
	// Immediatley unarchive the picture metadata and location data objects from the data in the file wrappers.
	NSFileWrapper* dataWrapper = docWrapper.fileWrappers[kLocationDataPreferredName];
	NSData *locationData = dataWrapper.regularFileContents;
	if (locationData!=nil)
		{
		SavedLocation* location = [NSKeyedUnarchiver unarchiveObjectWithData:locationData];
		TESTLog(@"loaded %@",location.identifier);
		if (_location!=nil)
			{
			// This document already has a location object; update the existing object's properties (on the main thread)
			dispatch_async(dispatch_get_main_queue(), ^{
				[_location subsumeLocation:location];
				});
			}
		else
			{
			// The deserialized location becomes this document's new location object
			self.location = location;
			}
		
		// Also load the picture metadata.
		// The picture data is stored in the LocationDocument, not the SavedLocation object,
		//	so loading the picture data implicitly sets pictures in _location.
		[self loadPicturesFromDocument];
		}

	return (_location!=nil);
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
	NSLog(@"error %@",error);
}

#pragma mark Utilities

- (void)deleteWrapperWithKey:(NSString*)key
{
	// Note a filewrapper that will be deleted the next time the document is saved
	if (key!=nil)
		{
		if (deletedWrappers==nil)
			deletedWrappers = [NSMutableSet set];
		[deletedWrappers addObject:key];
		}
}

#pragma mark <NSKeyValueObservingProtocol>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// We don't care what changed, just note that something did change and the document needs to be re-saved
	[self updateChangeCount:UIDocumentChangeDone];
}

@end

void RemoveChildWrapper( NSFileWrapper* directoryWrapper, NSString* key )
{
	// Remove a child wrapper for the given key, if it exists
	NSFileWrapper *imageWrapper = directoryWrapper.fileWrappers[key];
	if (imageWrapper!=nil)
		[directoryWrapper removeFileWrapper:imageWrapper];
}
