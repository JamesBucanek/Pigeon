//
//  ShowReturnController.m
//  Pigeon
//
//  Created by James Bucanek on 12/24/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "ShowReturnController.h"

#define NO_TEST_LOG
#import "Pigeon.h"
#import "PigeonMath.h"
#import "SavedLocation.h"
#import "PathOverlay.h"
#import "PathOverlayRenderer.h"
#import "LocationTrackingViewController.h"		// for kLocationChangedNotification


#define kPositionErrorTolerance		40.0		// allow up to 40 pixels/update positioning error


@interface ShowReturnController () // private
{
	PathOverlay*	pathOverlay;
	CLLocation*		currentLocation;
	CGFloat			accumulatedPositionError;
}
- (void)locationChangedNotification:(NSNotification*)notification;
@end


@implementation ShowReturnController

- (id)initWithMapView:(MKMapView*)map
{
    self = [super initWithMapView:map];
    if (self)
		{
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(locationChangedNotification:)
													 name:kLocationChangedNotification
												   object:nil];
		}
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Properties

- (void)setLightPath:(BOOL)lightPath
{
	_lightPath = lightPath;
	if (pathOverlay!=nil)
		{
		MKOverlayRenderer* renderer = [self.mapView rendererForOverlay:pathOverlay];
		if ([renderer respondsToSelector:@selector(setLightPath:)])
			[(PathOverlayRenderer*)renderer setLightPath:lightPath];
		}
}

#pragma mark Map Maintenance

- (NSArray*)makeOverlays
{
	SavedLocation* activeLocation = self.showLocation;
	if (activeLocation!=nil && currentLocation!=nil)
		{
		// The return path overlay can only be created when there's a valid return location
		if ( pathOverlay==nil || !CoordinatesEqual(pathOverlay.coordinate,self.showLocation.coordinate) )
			{
			TESTLog(@"%s Creating new path overlay (%f,%f)->(%f,%f) (discarding %@)",__func__,
					activeLocation.location.coordinate.longitude,activeLocation.location.coordinate.latitude,
					currentLocation.coordinate.longitude,currentLocation.coordinate.latitude,
					pathOverlay);
			// The path overlay has not been created or its return location has changed: create a new one
			pathOverlay = [[PathOverlay alloc] initWithSavedLocation:activeLocation];
			pathOverlay.userLocation = currentLocation;
			accumulatedPositionError = 0.0;					// new overlay is spot-on
			}
		// Return the accuracy overlay and the path overlay
		return [[super makeOverlays] arrayByAddingObject:pathOverlay];
		}

	// There's no overlay object: return just the accuracy overlay
	return [super makeOverlays];
}

#pragma mark <MKMapViewDelegate>

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	if (overlay==pathOverlay)
		{
		PathOverlayRenderer* renderer = [[PathOverlayRenderer alloc] initWithOverlay:overlay];
		renderer.lightPath = _lightPath;		// configure the drawing mode
		return renderer;
		}
	return [super mapView:mapView rendererForOverlay:overlay];
}

#pragma mark Notifications

- (void)locationChangedNotification:(NSNotification *)notification
{
	// The user location changed
	currentLocation = notification.object;
	if (currentLocation!=nil)
		{
		if (pathOverlay!=nil)
			{
			// There's a new user location and there's already an overlay that's displaying
			//	the previous user location. Find out how much off the new location is.
			
			// Determine the distance (in view points) from the user's location to the user'location
			//	currently being displayed by the return path overlay.
			MKMapView* mapView = self.mapView;
			CGPoint userPoint = [mapView convertCoordinate:currentLocation.coordinate toPointToView:mapView];
			CGPoint pathPoint = [mapView convertCoordinate:pathOverlay.userLocation.coordinate toPointToView:mapView];
			CGFloat error = CGHypot(userPoint.x-pathPoint.x,userPoint.y-pathPoint.y);
			accumulatedPositionError += error;
			if (accumulatedPositionError<kPositionErrorTolerance)
				{
				// The accumulated error isn't that bad; don't update anything just yet
				TESTLog(@"supressing return path region update: error=%f, accumulated=%f",
						error,accumulatedPositionError);
				return;
				}
			}
		}
	
	// In all other cases, discard the existing overlay (forcing a new one to be created)
	//	and update the annotation and overlays in the map view. In the cases where there
	//	is no return path overlay, the net effect will be no change at all.
	pathOverlay = nil;
	[self updateAnnotationsAndOverlays];
}



@end
