//
//  LocationData+Documents.h
//  Pigeon
//
//  Created by James Bucanek on 1/5/14.
//  Copyright (c) 2014 Dawn to Dusk Software. All rights reserved.
//

#import "LocationData.h"

//
// Private interface for use by DocumentManager
//

@interface LocationData (Documents)

@property (strong,nonatomic) DocumentController* documentManager;	// r+w in category

- (void)insertLocation:(SavedLocation*)location atIndex:(NSUInteger)index;
- (void)replaceLocation:(SavedLocation*)stale withLocation:(SavedLocation*)location;

@end
