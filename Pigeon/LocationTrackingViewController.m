//
//  LocationTrackingViewController.m
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "LocationTrackingViewController.h"

@interface LocationTrackingViewController ()

@end

@implementation LocationTrackingViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

	locationManager = [CLLocationManager new];
	locationManager.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
	// Immediately start gathering location data
	[locationManager startUpdatingLocation];

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// Don't gather location data while the view isn't visible
	[locationManager stopUpdatingLocation];

	[super viewWillDisappear:animated];
}

//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

#pragma mark <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	// An updated location is available
	currentLocation = locations.lastObject;
	[[NSNotificationCenter defaultCenter] postNotificationName:kLocationChangedNotification
														object:currentLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	// TODO: case out heading vs. location errors
	currentLocation = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:kLocationChangedNotification
														object:currentLocation];
}

@end
