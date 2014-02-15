//
//  LocationDocument+ImageStorage.h
//  Pigeon
//
//  Created by James Bucanek on 1/4/14.
//  Copyright (c) 2014 Dawn to Dusk Software. All rights reserved.
//

#import "LocationDocument.h"

#import "ImageStoring.h"

// A category of LocationDocument that manages all of the image
//	storage, encoding, and caching.


@interface LocationDocument (ImageStorage) <ImageStoring>

- (void)storePicturesInDocument;
- (NSData*)persistentPictureMetadata;
- (void)loadPicturesFromDocument;
- (void)restorePictureMetadata:(NSData*)data;

- (void)didReceiveMemoryWarning;

@end
