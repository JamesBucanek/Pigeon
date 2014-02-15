//
//  ActiveLocationController.m
//  Pigeon
//
//  Created by James Bucanek on 12/22/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "ShowLocationController.h"

#define NO_TEST_LOG
#import "Pigeon.h"
#import "LocationData.h"
#import "SavedLocation.h"
#import "AccuracyOverlay.h"
#import "AccuracyOverlayRenderer.h"


// This annotations controller centralizes the work required to keep the annotation
//	and overlays that represent the active saved location displayed on a map.
// It monitors for changes in the activeLocation of the singleton data model,
//	and also for changes in the coordinates and accuracty of that active location.
// The SaveLocation object acts as its own annotation object, so the activeLocation
//	is added as an annotation and replaced whenever the activeLocation object changes.
// If the coordintes or accuracy of the active location changes, the overlay that
//	displays that is recreated/replaced in the map. The overlay does not observe
//	changes nor does it dynamically recalculate its region. The only
//	way to update it is to create a new overlay object. This sounds like a lot of
//	work, but it's actually simplier and it's a rare event, because the coordinates
//	and accuracy information for a saved location hardly ever change.

@interface ShowLocationController () // private
{
	id<MKAnnotation>	activeAnnotation;
	NSArray*			activeOverlays;
	
	AccuracyOverlay*	accuracyOverlay;
}
- (void)setShowLocation:(SavedLocation *)location;
- (void)setAnnotation:(id<MKAnnotation>)annotation overlays:(NSArray*)overlays;
@end

@implementation ShowLocationController

- (id)initWithMapView:(MKMapView*)map
{
    self = [super init];
    if (self)
		{
        _mapView = map;
		if (_mapView.delegate==nil)
			// If the map view doesn't have a delegate, become its delegate automatically
			_mapView.delegate = self;
		}
    return self;
}
- (void)dealloc
{
	// Stop observing data
    [_showLocation removeObserver:self forKeyPath:@"location"];
	[_data removeObserver:self forKeyPath:@"activeLocation"];
	// Remove all active annotations and overlays from the map
	[self setAnnotation:nil overlays:@[]];
}

- (void)setData:(LocationData *)data
{
	[_data removeObserver:self forKeyPath:@"activeLocation"];
	_data = data;
	[_data addObserver:self forKeyPath:@"activeLocation" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (void)setShowLocation:(SavedLocation *)location
{
	[_showLocation removeObserver:self forKeyPath:@"location"];
	_showLocation = location;
	[location addObserver:self forKeyPath:@"location" options:NSKeyValueObservingOptionInitial context:NULL];
	[self savedLocationDidChange];
}

- (void)savedLocationDidChange
{
	// Something about the saved location changed; it's either been updated or replaced
	accuracyOverlay = nil;					// generate a new overlay
	[self updateAnnotationsAndOverlays];
}

#pragma mark Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object==_data && [keyPath isEqualToString:@"activeLocation"])
		{
		// The data model's activeLocation property changed.
		// Update showLocation, which will trigger a location change
		[self setShowLocation:_data.activeLocation];
		}
	else if (object==_showLocation && [keyPath isEqualToString:@"location"])
		{
		// The coordinate or accuracy of the active location has changed.
		[self savedLocationDidChange];
		}
}

#pragma mark Map Maintenance

- (void)updateAnnotationsAndOverlays
{
	// Update the map's annotation and overlay objects.
	[self setAnnotation:[self makeAnnotation]
			   overlays:[self makeOverlays]];
}

- (void)setAnnotation:(id<MKAnnotation>)annotation overlays:(NSArray*)overlays
{
	// Add/remove/update/replace the overlay objects maintained by this controller
	NSSet* activeSet = [NSSet setWithArray:activeOverlays];
	NSSet* newSet = [NSSet setWithArray:overlays];
	// The overlays that are NOT in the new set will be removed
	NSMutableSet* removeSet = [NSMutableSet setWithSet:activeSet];
	[removeSet minusSet:newSet];
	// The overlays that are NOT already active will be added
	NSMutableSet* addSet = [NSMutableSet setWithSet:newSet];
	[addSet minusSet:activeSet];
	// Performs the updates
	activeOverlays = overlays;
#ifndef NO_TEST_LOG
	if (removeSet.count!=0 || addSet.count!=0)
		{
		TESTLog(@"removing %u overlays, adding %u overlays (%u now active)",
				(unsigned)removeSet.count,(unsigned)addSet.count,(unsigned)newSet.count);
		}
#endif
	if (removeSet.count!=0)
		[_mapView removeOverlays:removeSet.allObjects];
	if (addSet.count!=0)
		[_mapView addOverlays:addSet.allObjects level:MKOverlayLevelAboveRoads];
	
	// Update/add/remove/replace the one and only annotation
	if (activeAnnotation!=annotation)
		{
		if (activeAnnotation!=nil)
			[_mapView removeAnnotation:activeAnnotation];
		activeAnnotation = annotation;
		if (annotation!=nil)
			{
			[_mapView addAnnotation:annotation];
			if (_pinHasCallout && [annotation respondsToSelector:@selector(autoSelect)] && [(id)annotation autoSelect])
				[_mapView selectAnnotation:annotation animated:YES];
			}
		}
}

- (id<MKAnnotation>)makeAnnotation
{
	// The annotation object is always the active location object (which is an annotation object)
	return _showLocation;
}

- (NSArray*)makeOverlays
{
	if (accuracyOverlay==nil)
		{
		// Base class creates a single overlay, displaying the position and accuracy of the location
		accuracyOverlay = [AccuracyOverlay new];
		accuracyOverlay.returnLocation = _showLocation;
		}
	return @[accuracyOverlay];
}

#pragma mark <MKMapViewDelegate>

// This object adopts the MKMapViewDelegate and can be used in one of two ways:
// It can be made the delegate for an MKMapView, if updating the active location is the only task required.
// Alternatively, the map's actual delegate can forward its viewForAnnotation: and rendererForOverlay: messages
//	to this object.

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	if (annotation==activeAnnotation)
		{
		MKPinAnnotationView* pinView =
			(MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:_showLocation.identifier];
		if (pinView==nil)
			{
			pinView = [[MKPinAnnotationView alloc] initWithAnnotation:_showLocation
													  reuseIdentifier:_showLocation.identifier];
			pinView.pinColor = MKPinAnnotationColorRed;
			pinView.animatesDrop = _showLocation.autoSelect;
			pinView.canShowCallout = _pinHasCallout;
			pinView.draggable = _pinDraggable;
			pinView.enabled = (_pinDraggable|_pinHasCallout);
			if (_pinHasCallout)
				pinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			}
		pinView.animatesDrop = _showLocation.autoSelect;
		return pinView;
		}
	
	// For all other annotations (i.e. the user's location) return nil
	return nil;
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	if (overlay==accuracyOverlay)
		return [[AccuracyOverlayRenderer alloc] initWithOverlay:overlay];
	return nil;
}


@end
