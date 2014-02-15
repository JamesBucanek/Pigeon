//
//  LocationTrackingTableViewController.h
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
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
