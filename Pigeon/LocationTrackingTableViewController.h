//
//  LocationTrackingTableViewController.h
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

//
// Same as LocationTrackingViewController, but for table view controllers.
//


@interface LocationTrackingTableViewController : UITableViewController <CLLocationManagerDelegate>
{
	@protected
	CLLocationManager*			locationManager;
	CLLocation*					currentLocation;
}

@end
