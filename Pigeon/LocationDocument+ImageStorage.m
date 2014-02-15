//
//  LocationDocument+ImageStorage.m
//  Pigeon
//
//  Created by James Bucanek on 1/4/14.
//  Copyright (c) 2014 James Bucanek. See LICENSE.txt.
//

#import "LocationDocument+ImageStorage.h"

#import "PigeonMath.h"


// Filewrapper keys
#define kLocationPicturesPreferredName	@"pictures.xml"
#define kImagePreferredNameFormat		@"picture-%u.jpg"
#define kThumbnailPreferredNameFormat	@"thumb-%u.jpg"


// Picture dictionary keys
#define kImageKey			@"image"
#define kImageNameKey		@"image.key"
#define kImageDataKey		@"image.data"
#define kThumbnailKey		@"thumb"
#define kThumbnailNameKey	@"thumb.key"
#define kThumbnailDataKey	@"thumb.data"
#define kSizeKey			@"size"

// Encoding keys
#define kPictureVersionKey		@"picts.version"
#define kPictureVersion				0
#define kPictureCountKey		@"picts.count"
#define kPictureFormat			@"pict%u"
#define kPictureWrapperKey			@".image"
#define kPictureThumbWrapperKey		@".thumb"
#define kPictureThumbSizeKey		@".tsize"



extern void RemoveChildWrapper( NSFileWrapper* directoryWrapper, NSString* key ); // LocationDocument.m


@implementation LocationDocument (ImageStorage)

- (void)storePicturesInDocument
{
	// Store all pending picture data in the document's file wrapper(s)
	// Send by -contentsForType:error:, on the main thread, when the UIDocument
	//	wants to prepare the document data to be written.

	// Add file wrappers for any images that have been added and encoded, but not yet saved.
	for ( NSUInteger i=0; i<self.pictureCount; i++ )
		{
		NSMutableDictionary* dictionary = pictures[i];
		NSData* imageData = dictionary[kImageDataKey];
		if (imageData!=nil)
			{
			// A new image has been encoded and that data was saved in the dictionary, but has
			//	not yet been added to the document package.
			// Create a file wrapper for the data and remember its name.
			NSString* preferredKey = [NSString stringWithFormat:kImagePreferredNameFormat,(unsigned int)i];
			dictionary[kImageNameKey] = [docWrapper addRegularFileWithContents:imageData preferredFilename:preferredKey];
			[dictionary removeObjectForKey:kImageDataKey];	// release the memory used by the encoded data
			}
		imageData = dictionary[kThumbnailDataKey];
		if (imageData!=nil)
			{
			// Ditto for the thumbnail image.
			NSString* preferredKey = [NSString stringWithFormat:kThumbnailPreferredNameFormat,(unsigned int)i];
			dictionary[kThumbnailNameKey] = [docWrapper addRegularFileWithContents:imageData preferredFilename:preferredKey];
			[dictionary removeObjectForKey:kThumbnailDataKey];
			}
		}

	// Serialize and store the picture  data in the package, which includes the wrapper names of the
	//	image data that was just added.
	NSData* pictureMetadataData = [self persistentPictureMetadata];
	RemoveChildWrapper(docWrapper,kLocationPicturesPreferredName);
	[docWrapper addRegularFileWithContents:pictureMetadataData
						 preferredFilename:kLocationPicturesPreferredName];
	
}

- (NSData*)persistentPictureMetadata
{
	// Create a serialized data object representing the persistent picture metadata
	//	for this location document.
	
	// Create a property list that contains *only* the persistent keys of each picture dictionary.
	// This excludes the cached UIImage objects and any encoded image data.
	NSMutableArray* metaArray = [NSMutableArray array];
	NSArray* persistentKeys = @[kImageNameKey,kThumbnailNameKey,kSizeKey];
	for ( NSUInteger i=0; i<self.pictureCount; i++ )
		{
		NSDictionary* dictionary = pictures[i];
		NSMutableDictionary* metaDictionary = [NSMutableDictionary dictionary];
		// Copy just the persistent metadata values from the picture dictionary
		for ( NSString* key in persistentKeys )
			{
			id value = dictionary[key];
			if (value!=nil)
				[metaDictionary setObject:value forKey:key];
			}
		
		[metaArray addObject:metaDictionary];
		}
	
	// Return the array of persistent picture metadata dictionaries as a data blob
	NSError* error = nil;
	return [NSPropertyListSerialization dataWithPropertyList:metaArray
													  format:NSPropertyListXMLFormat_v1_0
													 options:0
													   error:&error];
	if (error!=nil)
		NSLog(@"problem serializing picture metadata: %@",error);
}

- (void)loadPicturesFromDocument
{
	// Read the picture metadata.
	// Send by -loadFromContents:ofType:error: to read the contents of the document.
	// The actual image data is lazily read, as needed.
	NSFileWrapper *dataWrapper = docWrapper.fileWrappers[kLocationPicturesPreferredName];
	if (dataWrapper!=nil)
		[self restorePictureMetadata:dataWrapper.regularFileContents];
}

- (void)restorePictureMetadata:(NSData*)data
{
	// Deserialize the picture metadata from the document.
	// The persistent metadata is in the exact same form (mutable array of mutable dictionaries)
	//	that was used to save the metadata. All we have to do is convert it back into objects.
	NSError* error = nil;
	pictures = [NSPropertyListSerialization propertyListWithData:data
														 options:NSPropertyListMutableContainersAndLeaves
														  format:NULL
														   error:&error];
	if (pictures==nil)
		{
		NSLog(@"problem deserializing picture metadata: %@",error);
		pictures = [NSMutableArray array];
		}
}

#pragma mark <ImageStorage>

- (NSUInteger)pictureCount
{
	return pictures.count;
}

- (NSArray*)pictures
{
	// Returns an array of the picture objects.
	// Since the pictures in a document or lazily loaded from the document's file
	//	wrapper, this propery isn't that useful or even interesting, except for KVO.
	NSMutableArray* array = [NSMutableArray array];
	for ( NSDictionary* dictionary in pictures )
		{
		// Add either the image or the thumbnail, if already in memeory
		id image = dictionary[kImageKey];
		if (image==nil)
			image = dictionary[kThumbnailKey];
		if (image!=nil)
			[array addObject:image];
		}
	return array;
}

- (UIImage*)pictureAtIndex:(NSUInteger)index
{
	UIImage* image = nil;
	if (index<pictures.count)
		{
		NSMutableDictionary* dictionary = pictures[index];
		image = dictionary[kImageKey];
		if (image==nil)
			{
			// Image hasn't been loaded or was purged to free up memory.
			// Recreated the image from either the cached data or the document package
			NSData* imageData = dictionary[kImageDataKey];
			if (imageData==nil)
				{
				NSFileWrapper *imageWrapper = docWrapper.fileWrappers[dictionary[kImageNameKey]];
				if (imageWrapper!=nil)
					imageData = imageWrapper.regularFileContents;
				}
			image = [UIImage imageWithData:imageData];
			if (image!=nil)
				// Cache the reconstructed image
				dictionary[kImageKey] = image;
			}
		}
	return image;
}

- (UIImage*)thumbnailFittingSize:(CGSize)fit forPictureAtIndex:(NSUInteger)index
{
	UIImage* thumbnail = nil;
	if (index<pictures.count)
		{
		NSMutableDictionary* dictionary = pictures[index];
		thumbnail = dictionary[kThumbnailKey];
		NSDictionary* sizeDictionary = dictionary[kSizeKey];
		CGSize size;
		if (sizeDictionary!=nil)
			CGSizeMakeWithDictionaryRepresentation((CFDictionaryRef)sizeDictionary,&size);
		else
			size = CGSizeMake(0.0,0.0);
		BOOL correctSize = (sizeDictionary!=nil && CGSizeEqualToSize(size,fit));
		if (thumbnail==nil || !correctSize)
			{
			// Thumbnail isn't in memory or it isn't the correct size.
			
			NSString* thumbWrapperKey = dictionary[kThumbnailNameKey];
			NSData* thumbData = dictionary[kThumbnailDataKey];
			if (correctSize && (thumbData!=nil || thumbWrapperKey!=nil) )
				{
				// The size was correct and there's a previous saved thumbnail image data
				//	either in the dictionary or it can be read from the document.
				// Load the thumbnail image from the document.
				if (thumbData==nil)
					{
					NSFileWrapper *imageWrapper = docWrapper.fileWrappers[thumbWrapperKey];
					if (imageWrapper!=nil)
						thumbData = imageWrapper.regularFileContents;
					}
				thumbnail = [UIImage imageWithData:thumbData];
				if (thumbnail!=nil)
					// Cache the reconstructed thumbnail
					dictionary[kThumbnailKey] = thumbnail;
				}
			if (thumbnail==nil)
				{
				// There still isn't a thumbnail (either the saved one was the wrong size, or
				//	there wasn't a saved one).

				// Create a scaled thumbnail from the original image.
				UIImage* image = [self pictureAtIndex:index];
				CGSize imageSize = image.size;
				CGFloat scale = CGMin(fit.width/imageSize.width,fit.height/imageSize.height);
				size = CGSizeMake(imageSize.width*scale,imageSize.height*scale);
				UIGraphicsBeginImageContextWithOptions(size,YES,1);
				[image drawInRect:CGRectMake(0,0,size.width,size.height)];
				thumbnail = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
				// Cache the scaled image and its size
				dictionary[kThumbnailKey] = thumbnail;
				dictionary[kSizeKey] = (__bridge_transfer NSDictionary*)CGSizeCreateDictionaryRepresentation(fit);

				// Encode the thumbnail and add it to the document (in the background)
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
					// Encode the image on a background thread
					NSData* jpegData = UIImageJPEGRepresentation(thumbnail,0.8);
					// When the image encoding is finished, save the data in the picture's dictionary (on the main thread)
					// (Eventually, the document will write the encoded data as a file wrapper when it's saved.)
					dispatch_async(dispatch_get_main_queue(), ^{
						[self deleteWrapperWithKey:dictionary[kThumbnailNameKey]];	// replace any existing wrapper
						dictionary[kThumbnailDataKey] = jpegData;					// save the encoded image data
						[self updateChangeCount:UIDocumentChangeDone];				// trigger a document change/save
						});
					});
				}
			}
		}
	return thumbnail;
}

- (void)addPicture:(UIImage*)image
{
	if (pictures==nil)
		// Lazily create the pictures collection
		pictures = [NSMutableArray array];
	
	if (pictures.count<kPicturesMax)
		{
		// Create a new dictionary for the new picture and add it to the collection
		NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObject:image
																			 forKey:kImageKey];
		[pictures addObject:dictionary];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			// Encode the image on a background thread
			NSData* jpegData = UIImageJPEGRepresentation(image,0.6);
			// When the image encoding is finished, save the data in the picture's dictionary (on the main thread)
			// (Eventually, the document will write the encoded data as a file wrapper when it's saved.)
			dispatch_async(dispatch_get_main_queue(), ^{
				[self deleteWrapperWithKey:dictionary[kImageNameKey]];	// replace any existing wrapper
				dictionary[kImageDataKey] = jpegData;					// save the encoded image data
				[self updateChangeCount:UIDocumentChangeDone];			// trigger a document change/save
				});
			});
		}
}

- (void)removePictureAtIndex:(NSUInteger)index
{
	// Remove the file wrappers associated with this picture, eventually
	NSDictionary* dictionary = pictures[index];		// get wrapper IDs that need removing
	[pictures removeObjectAtIndex:index];			// remove the dictionary from the collection
	[self deleteWrapperWithKey:dictionary[kImageNameKey]];		// eventually remove the file wrappers
	[self deleteWrapperWithKey:dictionary[kThumbnailNameKey]];	//	for these images
	[self updateChangeCount:UIDocumentChangeDone];				// queue a document save
}

- (void)didReceiveMemoryWarning
{
	for ( NSMutableDictionary* dictionary in pictures )
		{
		// If there's a wrapper key or data for the image/thumbnail, the cached image/thumbnail
		//	can be discarded, since it can easily be reloaded on demand.
		if (dictionary[kImageNameKey]!=nil || dictionary[kImageDataKey]!=nil)
			[dictionary removeObjectForKey:kImageKey];
		if (dictionary[kThumbnailNameKey]!=nil || dictionary[kThumbnailDataKey]!=nil)
			[dictionary removeObjectForKey:kThumbnailKey];
		}
}

@end
