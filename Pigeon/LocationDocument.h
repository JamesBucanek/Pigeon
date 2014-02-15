//
//  LocationDocument.h
//  Pigeon
//
//  Created by James Bucanek on 12/28/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SavedLocation;

#define kLocationDataPreferredName		@"location.data"

#define kPicturesMax					4	// allow up to four pictures to be added

//
// A single location document
//

@interface LocationDocument : UIDocument
{
	@private
	NSFileWrapper*		docWrapper;
	NSMutableArray*		pictures;
	NSMutableSet*		deletedWrappers;	// keys of wrappers to be deleted
}

+ (LocationDocument*)documentAtURL:(NSURL*)url;

@property (readonly,nonatomic) NSString* filename;

// storageURL is, more or less, fileURL but is (a) static, so it's thread safe and
//	(b) indicates where the document *intends* to store its data, not necessary
//	where it *is* storing its data. This helps avoid ambiguities when relocating
//	documents to/from the cloud.
@property (nonatomic) NSURL* storageURL;
- (BOOL)isStoredAtURL:(NSURL*)url;

// published indicates that a document has appeared in the cloud, as reported by
//	the metadata query. This is needed because there's sometimes a delay between
//	the time a document is written to the cloud and it appears in the metadata
//	query results. Because of this, we don't want to use the absense of a
//	document in the query results to imply that the document has been deleted
//	until the document first appears in the results.
@property BOOL published;

@property (strong,nonatomic) SavedLocation* location;

- (void)deleteWrapperWithKey:(NSString*)key;

@end
