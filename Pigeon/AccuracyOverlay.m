//
//  AccuracyOverlay.h
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "AccuracyOverlay.h"

#import "SavedLocation.h"


@interface AccuracyOverlay () // private
{
	MKMapRect				overlayRect;
}
- (void)calculateOverlayRegion;
@end


@implementation AccuracyOverlay

- (void)setReturnLocation:(SavedLocation *)returnLocation
{
	_returnLocation = returnLocation;
	[self calculateOverlayRegion];
}

- (void)calculateOverlayRegion
{
	// Calculate a rect for the saved location, centered at that coordinate and encompassing
	//	the accuracy of the location.
	
	// Begin by creating an empty rect at the location
	CLLocationCoordinate2D returnCoordinate = _returnLocation.coordinate;
	overlayRect.origin = MKMapPointForCoordinate(returnCoordinate);
	overlayRect.size.height = overlayRect.size.width = 0.0;
	// Expand the rect, in both directions, by the distance of the accuracy
	CLLocationDistance accuracy = _returnLocation.horizontalAccuracy;
	double pointsPerMeter = MKMapPointsPerMeterAtLatitude(returnCoordinate.latitude);
	overlayRect = MKMapRectInset(overlayRect,-pointsPerMeter*accuracy,-pointsPerMeter*accuracy);
}

- (CLLocationCoordinate2D)coordinate
{
	return _returnLocation.coordinate;
}

- (MKMapRect)boundingMapRect
{
	return overlayRect;
}

@end
