//
//  LocationListViewController.h
//  Pigeon
//
//  Created by James Bucanek on 12/20/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LocationTrackingTableViewController.h"
#import "LocationData.h"

//
// The location list controller
//


@interface LocationListViewController : LocationTrackingTableViewController

// Data model
@property (strong,nonatomic) LocationData*	data;

@end
