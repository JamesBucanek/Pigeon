//
//  Refiner.h
//  Pigeon
//
//  Created by James Bucanek on 12/22/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class SavedLocation;

//
// Helper object that manages the process of refining the user's
//	location, immediately after they save it.
//


#define kPreferenceRefinementDuration				@"Pigeon.refine.duration"
#define		kRefinementDurationDefault					40.0		/* 40 sectonds */
#define		kRefinementDurationMax						(5*60)		/* 5 minues */
#define		kNoLocationWaitDuration						60.0		/* 60 seconds */

//#define kLocationRefinementDidEndNotification		@"RefinementDidEnd"


@interface Refiner : NSObject <CLLocationManagerDelegate>

+ (NSTimeInterval)duration;

- (id)initWithSavedLocation:(SavedLocation*)location;

@property (weak,nonatomic) SavedLocation* savedLocation;

- (void)stop;

@end
