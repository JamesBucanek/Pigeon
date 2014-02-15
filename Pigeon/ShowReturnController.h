//
//  ShowReturnController.h
//  Pigeon
//
//  Created by James Bucanek on 12/24/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "ShowLocationController.h"

//
// A subclass of ShowLocationController that maintains a second overlay that
//	draws the path from the user's current location back to the saved location.
//

@interface ShowReturnController : ShowLocationController

@property (nonatomic) BOOL lightPath;

@end
