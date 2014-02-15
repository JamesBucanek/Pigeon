//
//  LocationTrackingViewController.h
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

//
// A view controller that monitors the user's current location, keeps
//	that information in the currentLocation variable, and broadcasts
//	changes as kLocationChangedNotification notifications, which views
//	and map renderers can observe.
//

#define kLocationChangedNotification	@"LocationChanged"


@interface LocationTrackingViewController : UIViewController <CLLocationManagerDelegate>
{
	@protected
	CLLocationManager*			locationManager;
	CLLocation*					currentLocation;
}

@end
