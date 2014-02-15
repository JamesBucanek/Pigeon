//
//  LocationData.h
//  Pigeon
//
//  Created by James Bucanek on 12/11/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <Foundation/Foundation.h>

#import "SavedLocation.h"

@class DocumentController;

//
// The data model
//

#define kMaxLocations	6


@interface LocationData : NSObject
{
	@private
	NSMutableArray*		locations;
	NSArray*			mirrorLocations;	// cached, immutable, shallow copy of locations
	DocumentController*	documentManager;
}

+ (LocationData*)sharedData;
@property (readonly,nonatomic) DocumentController* documentManager;

@property (strong,nonatomic) SavedLocation *activeLocation;
- (void)setActiveLocationAtIndex:(NSUInteger)index;

@property (readonly,nonatomic) NSArray *locations;
- (SavedLocation*)locationForIdentifier:(NSString*)identifier;

- (void)addLocation:(SavedLocation*)location;
- (void)removeLocation:(SavedLocation*)location;
- (void)removeLocationAtIndex:(NSUInteger)index;
- (void)moveLocationAtIndex:(NSUInteger)existingIndex
					toIndex:(NSUInteger)newIndex;

@end
