//
//  LocationListCell.m
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "LocationListCell.h"

#import "LocationTrackingViewController.h"		// for kLocationChangedNotification
#import "SavedLocation.h"
#import "ShowLocationController.h"
#import "MKMapView+MapPanning.h"


@interface LocationListCell () // private
{
	ShowLocationController*	annotationsController;
}
- (void)locationChangedNotification:(NSNotification*)notification;
@end

@implementation LocationListCell

//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
//{
//    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
//    if (self)
//		{
//		}
//    return self;
//}

- (void)dealloc
{
	self.location = nil;						// stop observing location
}

- (void)setLocation:(SavedLocation *)location
{
	// Set up the annotation and overlay
	if (annotationsController==nil)
		annotationsController = [[ShowLocationController alloc] initWithMapView:_mapView];
	annotationsController.showLocation = location;

	if (location!=nil)
		{
		if (_location==nil)
			// This is the first time the location property is being set: start observing
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(locationChangedNotification:)
														 name:kLocationChangedNotification
													   object:nil];
		
		// Set the fixed fields
		_dateLabel.text = location.localizedDate;
		_titleLabel.text = location.title;
		_distanceLabel.text = nil;
		// Orient the map to show the given location
		[_mapView centerAtLocation:location.location animated:NO];
		}
	else
		{
		// location property being set to nil: stop observing
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		}
	// Update the location property and observe any changes to its title
	[_location removeObserver:self forKeyPath:@"title"];
	_location = location;
	[_location addObserver:self forKeyPath:@"title" options:0 context:NULL];
}

- (void)locationChangedNotification:(NSNotification *)notification
{
	CLLocation* currentLocation = notification.object;
	NSString* localizedDistance = nil;
	CLLocationDistance distance = 0;
	if (currentLocation!=nil)
		{
		distance = [_location.location distanceFromLocation:currentLocation];
		localizedDistance = [_location localizedDistance:distance];
		}
	_distanceLabel.text = localizedDistance;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"title"])
		_titleLabel.text = _location.title;
}

@end
