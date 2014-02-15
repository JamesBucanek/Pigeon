//
//  PathOverlayRenderer.h
//  Pigeon
//
//  Created by James Bucanek on 12/23/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <MapKit/MapKit.h>

//
// Map overlay renderer that draws a line from the user's current
//	location back to the saved location.
//

@interface PathOverlayRenderer : MKOverlayRenderer

@property (nonatomic) BOOL lightPath;

@end
