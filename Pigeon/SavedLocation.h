//
//  SavedLocation.h
//  Pigeon
//
//  Created by James Bucanek on 12/11/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "ImageStoring.h"

@class LocationDocument;
@class Refiner;

//
// A saved location
//

@interface SavedLocation : NSObject <ImageStoring,MKAnnotation,NSSecureCoding>

@property (nonatomic) LocationDocument* document;
- (void)subsumeLocation:(SavedLocation*)location;

@property (nonatomic) CLLocation* location;
@property (readonly,nonatomic) CLLocationAccuracy horizontalAccuracy;
@property (readonly,nonatomic) NSDate* date;
@property (readonly,nonatomic) NSString* localizedDate;
- (NSString*)localizedDistance:(CLLocationDistance)distance;
@property (nonatomic) BOOL autoSelect;
@property (readonly,nonatomic) BOOL refining;
@property (weak,nonatomic) Refiner* refiner;

@property (readonly,nonatomic) NSString* identifier;

@property (nonatomic) NSString *name;

- (void)reverseGeocode;
@property (nonatomic) CLPlacemark *placemark;
@property (nonatomic) BOOL geocodingFinished;

@property (nonatomic) NSString *notes;

@end
