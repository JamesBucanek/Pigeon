//
//  MKMapView+MapPanning.h
//  Pigeon
//
//  Created by James Bucanek on 12/15/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <MapKit/MapKit.h>

//
// Category of MKMapView that adds methods that simplify the zooming
//	and panning of the map.
//

extern CLLocationDegrees MapLongitudeDifference( CLLocationDegrees long1,
												 CLLocationDegrees long2 );
extern CLLocationDegrees MapLatitudeDifference( CLLocationDegrees lat1,
											    CLLocationDegrees lat2 );


@interface MKMapView (MapPanning)

- (void)centerAtLocation:(CLLocation*)location /*includeUserWithin:(CLLocationDistance)reach*/ animated:(BOOL)animated;
- (void)zoomInToDistance:(CLLocationDistance)showDistance animated:(BOOL)animated;

@end
