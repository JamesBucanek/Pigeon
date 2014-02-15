//
//  Refiner.m
//  Pigeon
//
//  Created by James Bucanek on 12/22/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "Refiner.h"

#define NO_TEST_LOG
#import "Pigeon.h"
#import "SavedLocation.h"


@interface Refiner () // private
{
	NSTimer*					expirationTimer;	// timer object retains this object and keeps it alive until it's done
	CLLocationManager*			locationManager;
	UIBackgroundTaskIdentifier	taskIdentifier;
}
- (void)refinementExpirationTime:(NSTimer*)timer;
@end

@implementation Refiner

+ (NSTimeInterval)duration
{
	NSNumber* durationNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kPreferenceRefinementDuration];
	return ( durationNumber!=nil ? [durationNumber doubleValue] : kRefinementDurationDefault );
}

- (id)initWithSavedLocation:(SavedLocation*)location
{
    self = [super init];
    if (self)
		{
		NSTimeInterval duration = [Refiner duration];
		if (duration==0)
			return nil;
		
		// Register this as a background task, so it keeps going if the user switches apps or locks the screen
		taskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Refining" expirationHandler:^{
			[self stop];
			}];
		
        self.savedLocation = location;
		location.refiner = self;
		expirationTimer = [NSTimer scheduledTimerWithTimeInterval:duration
														   target:self
														 selector:@selector(refinementExpirationTime:)
														 userInfo:nil
														  repeats:NO];
		locationManager = [CLLocationManager new];
		locationManager.delegate = self;
		[locationManager startUpdatingLocation];
		}
    return self;
}

- (void)stop
{
	TESTLog(@"",nil);
	_savedLocation.refiner = nil;
	[locationManager stopUpdatingLocation];
	[expirationTimer invalidate];

	// No need to keep the app alive any longer
	[[UIApplication sharedApplication] endBackgroundTask:taskIdentifier];
}

- (void)refinementExpirationTime:(NSTimer *)timer
{
	// It's over
	[self stop];
}

#pragma mark <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	// The location was updated: see if it's better than the one we have already
	CLLocation* candidate = [locations lastObject];
	
	// Only consider this location if its horizontal accuracy is better than the one already obtained
	if (candidate.horizontalAccuracy<_savedLocation.horizontalAccuracy)
		{
		// Determine the absolute distance between these two points
		CLLocationDistance distance = [candidate distanceFromLocation:_savedLocation.location];
		// If the distance is less than the difference in the accuracy radius, then it puts
		//	the new circle of accuracy completely inside the old one (+15%), which means it's probably
		//	a more accurate fix on the location, even if it might have moved slightly.
		if (distance<=(_savedLocation.horizontalAccuracy-candidate.horizontalAccuracy)*1.15)
			{
			TESTLog(@"refined location %f,%f(%f) -> %f,%f(%f) = %f",
				  _savedLocation.location.coordinate.latitude,_savedLocation.location.coordinate.longitude,_savedLocation.horizontalAccuracy,
				  candidate.coordinate.latitude,candidate.coordinate.longitude,candidate.horizontalAccuracy,
				  distance);
			_savedLocation.location = candidate;
			}
		else TESTLog(@"location %f,%f(%f) outside previous",candidate.coordinate.latitude,candidate.coordinate.longitude,candidate.horizontalAccuracy);
		}
	else TESTLog(@"location %f,%f(%f) not a refinement",candidate.coordinate.latitude,candidate.coordinate.longitude,candidate.horizontalAccuracy);
}


@end
