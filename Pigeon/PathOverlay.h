//
//  PathOverlay.h
//  Pigeon
//
//  Created by James Bucanek on 12/23/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class SavedLocation;

//
// Defines a map region encompassing both the user's
//	current location and the saved location.
//


@interface PathOverlay : NSObject <MKOverlay>

- (id)initWithSavedLocation:(SavedLocation*)location;

@property (readonly,nonatomic) SavedLocation* returnLocation;
@property (strong,nonatomic) CLLocation* userLocation;

@property (readonly,nonatomic) MKMapPoint returnMapPoint;
@property (readonly,nonatomic) MKMapPoint userMapPoint;

@end
