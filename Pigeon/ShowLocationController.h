//
//  ActiveLocationController.h
//  Pigeon
//
//  Created by James Bucanek on 12/22/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@class LocationData;
@class SavedLocation;

//
// Helper class that maintains the annotations and overlays that
//	present a SavedLocation in an MKMapView.
//
// Set either data or showLocation:
//	Setting the data property tracks the active location automatically.
//	Setting just the showLocation property tracks a specific location.
//

@interface ShowLocationController : NSObject <MKMapViewDelegate>

- (id)initWithMapView:(MKMapView*)map;

@property (strong,nonatomic) LocationData*		data;
@property (strong,nonatomic) SavedLocation*		showLocation;

@property (weak,nonatomic) MKMapView*			mapView;
@property (assign,nonatomic) BOOL				pinHasCallout;
@property (assign,nonatomic) BOOL				pinDraggable;

- (void)updateAnnotationsAndOverlays;
- (id<MKAnnotation>)makeAnnotation;
- (NSArray*)makeOverlays;

@end
