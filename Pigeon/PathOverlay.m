//
//  PathOverlay.m
//  Pigeon
//
//  Created by James Bucanek on 12/23/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "PathOverlay.h"

#import "SavedLocation.h"


@interface PathOverlay () // private
{
	MKMapRect				overlayRect;
	CLLocationCoordinate2D	centerCoordinate;
}
- (void)calculateOverlayRegion;
@end


@implementation PathOverlay

- (id)initWithSavedLocation:(SavedLocation*)location
{
    self = [super init];
    if (self)
		{
        _returnLocation = location;
		[self calculateOverlayRegion];
		}
    return self;
}

- (void)setUserLocation:(CLLocation *)userLocation
{
	_userLocation = userLocation;
	[self calculateOverlayRegion];
}

- (void)calculateOverlayRegion
{
	// Calculate a region rectangle that encompasses both the user's location and
	//	the return point.
	// Create small rects around the return point and the user's location
	MKMapRect returnRect;
	CLLocationCoordinate2D coordinate = _returnLocation.coordinate;
	returnRect.origin = _returnMapPoint = MKMapPointForCoordinate(coordinate);
	returnRect.size.height = returnRect.size.width = 1.0;
	
	if (_userLocation!=nil)
		{
		// Calculate the region and center of the area between the two points
		MKMapRect userRect;
		coordinate = _userLocation.coordinate;
		userRect.origin = _userMapPoint = MKMapPointForCoordinate(coordinate);
		userRect.size.height = userRect.size.width = 1.0;
		
		// Now create rect that encompasses both
		overlayRect = MKMapRectUnion(returnRect,userRect);
		
		// The centerpoint for the region is the center of the overlayRect
		MKMapPoint centerMapPoint = MKMapPointMake(MKMapRectGetMidX(overlayRect),
												   MKMapRectGetMidY(overlayRect));
		centerCoordinate = MKCoordinateForMapPoint(centerMapPoint);
		}
	else
		{
		// There's no user location: make the return location the region to draw
		//	(just so the properties return reasonable values).
		overlayRect = returnRect;
		centerCoordinate = coordinate;
		}
}

- (CLLocationCoordinate2D)coordinate
{
	return centerCoordinate;
}

- (MKMapRect)boundingMapRect
{
	return overlayRect;
}

@end
