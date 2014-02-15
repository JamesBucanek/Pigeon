//
//  AccuracyOverlay.h
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class SavedLocation;

//
// A map overlay defining the region encompassed by the accuracy
//	(or inaccuracy) of the saved location.
//


@interface AccuracyOverlay : NSObject <MKOverlay>

@property (strong,nonatomic) SavedLocation* returnLocation;

@end
