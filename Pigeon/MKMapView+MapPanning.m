//
//  MKMapView+MapPanning.m
//  Pigeon
//
//  Created by James Bucanek on 12/15/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "MKMapView+MapPanning.h"

#import "PigeonMath.h"


#define kComfortableZoomOutMargin		(0.875)		// when zooming in, shoot to get the location just inside a 12.5% margin
#define kComfortableZoomInMargin		(0.7)		// when zooming out, don't zoom so the location get's pushed past a 30% margin

#define kMetersPerDegreeLatitude		111132.0	// ~111.132 km
#define kDefaultMapSpanMeters			500			// 1/2 km
#define kMinimumMapSpanMeters			100			// ~300 ft


@implementation MKMapView (MapPanning)


- (void)centerAtLocation:(CLLocation*)location /*includeUserWithin:(CLLocationDistance)reach*/ animated:(BOOL)animated
{
	// Center the map over the coordinate and zoom so the user's location is visible,
	//	assuming the user's location is known and isn't too far away.

	CLLocationCoordinate2D centerCoord = location.coordinate;
	self.centerCoordinate = centerCoord;
	
	// Obtain the adjusted region after the centerCoordinate is modified.
	// Moving the center coordinate could alter that ratio between the longitude and latitude.
	// By changing the center first, the ratio should be updated before we get the region.
	MKCoordinateRegion region = self.region;

	// Find the user's location
	MKUserLocation* user = self.userLocation;
	if (user!=nil)
		{
		// User is within reach: zoom the map so it includes the user
		CLLocationCoordinate2D userCoord = user.location.coordinate;
		
		// Calculate how far (horizontally and vertially) the user's location is from the center coordinate
		//	center point in graphic units.
		CLLocationDegrees latDist = MapLatitudeDifference(userCoord.latitude,centerCoord.latitude);
		CLLocationDegrees longDist = MapLongitudeDifference(userCoord.longitude,centerCoord.longitude);
		
		// Determine if the user's location is outside the map, and zoom out if it is
		double respan = 1.0;
		CLLocationDegrees latSpan = region.span.latitudeDelta/2*kComfortableZoomOutMargin;
		CLLocationDegrees longSpan = region.span.longitudeDelta/2*kComfortableZoomOutMargin;
		if (latDist>latSpan || longDist>longSpan)
			{
			respan = fmax(latDist/latSpan,longDist/longSpan);
			}
		else
			{
			// Calculate a slightly tighter margin and see if the user's location is inside
			//	that bounds, zooming in to so the detail between the two
			latSpan = region.span.latitudeDelta/2*kComfortableZoomInMargin;
			longSpan = region.span.longitudeDelta/2*kComfortableZoomInMargin;
			if (latDist<=latSpan && longDist<=longSpan)
				{
				respan = fmax(latDist/latSpan,longDist/longSpan);
				}
			}
		
		if (respan!=1.0)
			{
			// A zoom (in or out) was calculated for the region
			// Apply the zoom factor equally to both longitute and latitude,
			//	but don't allow a zoom in to exceed kMinimumMapSpanMeters.
			CLLocationDegrees minZoomDegrees = fmax(kMinimumMapSpanMeters,location.horizontalAccuracy)/kMetersPerDegreeLatitude;
			if (respan<1.0 && region.span.latitudeDelta*respan<minZoomDegrees)
				respan = minZoomDegrees/region.span.latitudeDelta;
			region.span.latitudeDelta *= respan;
			region.span.longitudeDelta *= respan;
			[self setRegion:region animated:animated];
			}
		// map should now show the user's location
		return;
		}
	
	// In all other cases (no user location, user out of range, etc.) zoom the
	//	map in so it show the detail around the item.
	[self zoomInToDistance:fmax(kDefaultMapSpanMeters,location.horizontalAccuracy)
				  animated:animated];
}

- (void)zoomInToDistance:(CLLocationDistance)showDistance animated:(BOOL)animated
{
	MKCoordinateRegion region = self.region;
	CLLocationDegrees latitudeDegrees = showDistance/kMetersPerDegreeLatitude;
	if (region.span.latitudeDelta>latitudeDegrees)
		{
		region.span.longitudeDelta *= latitudeDegrees/region.span.latitudeDelta;
		region.span.latitudeDelta = latitudeDegrees;
		[self setRegion:region animated:animated];
		}
}

@end


CLLocationDegrees MapLongitudeDifference( CLLocationDegrees long1, CLLocationDegrees long2 )
{
	// Return the absolute difference, in degrees, between long1 and long2
	//	taking into consideration that one, or the other, might be on the
	//	other side of the 180th meridian.
	if ( long1<0.0 && long2>=(long1+180.0) )
		long2 -= 360.0;
	else if ( long1>0.0 && long2<=(long1-180.0) )
		long2 += 360.0;
	return fabs(long1-long2);
}

CLLocationDegrees MapLatitudeDifference( CLLocationDegrees lat1, CLLocationDegrees lat2 )
{
	return fabs(lat1-lat2);
}
