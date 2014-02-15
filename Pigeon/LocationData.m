//
//  LocationData.m
//  Pigeon
//
//  Created by James Bucanek on 12/11/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "LocationData.h"

#import "DocumentController.h"
#import "LocationData+Documents.h"


@implementation LocationData

- (id)init
{
    self = [super init];
    if (self)
		{
        locations = [NSMutableArray array];
		}
    return self;
}

+ (LocationData*)sharedData
{
	// Convienence method to obtain the singleton data model object,
	//	managed by the singleton document manager:
	return DocumentController.sharedController.data;
}

#pragma mark Properties

- (DocumentController*)documentManager
{
	return documentManager;
}

//- (SavedLocation*)activeLocation
//{
//	return activeLocation;
//}

- (void)setActiveLocation:(SavedLocation *)activeLocation
{
	// Set the active location and ensure that its part of the collection
	_activeLocation = activeLocation;
	if (activeLocation!=nil)
		[self addLocation:activeLocation];	// won't add a duplicate
}

- (void)setActiveLocationAtIndex:(NSUInteger)index
{
	self.activeLocation = locations[index];
}

- (NSArray*)locations
{
	if (mirrorLocations==nil)
		mirrorLocations = [NSArray arrayWithArray:locations];
	return mirrorLocations;
}

- (SavedLocation*)locationForIdentifier:(NSString*)identifier
{
	for ( SavedLocation* location in locations )
		{
		if ([location.identifier isEqualToString:identifier])
			return location;
		}
	return nil;
}

- (void)addLocation:(SavedLocation*)location
{
	if ([locations indexOfObjectIdenticalTo:location]==NSNotFound)
		{
		// Insert the location at the top of the list
		[self insertLocation:location atIndex:0];
		
		// Tell the document manager to create a document to store this location, and
		//	connect that document to the new location.
		[[DocumentController sharedController] createDocumentForLocation:location];
		}
}

- (void)removeLocation:(SavedLocation*)location
{
	NSUInteger index = [locations indexOfObjectIdenticalTo:location];
	if (index!=NSNotFound)
		[self removeLocationAtIndex:index];
}

- (void)removeLocationAtIndex:(NSUInteger)index
{
	[self willChangeValueForKey:@"locations"];

	SavedLocation* removeLocation = locations[index];
	[locations removeObjectAtIndex:index];
	mirrorLocations = nil;
	if (_activeLocation==removeLocation)
		self.activeLocation = nil;
	
	[self didChangeValueForKey:@"locations"];
	
	// Tell the document manager to destroy the document associated with this location
	[[DocumentController sharedController] removeDocumentForLocation:removeLocation];
}

- (void)moveLocationAtIndex:(NSUInteger)existingIndex toIndex:(NSUInteger)newIndex
{
	[self willChangeValueForKey:@"locations"];

	SavedLocation* location = [locations objectAtIndex:existingIndex];
	[locations removeObjectAtIndex:existingIndex];
	if (newIndex>existingIndex)
		newIndex -= 1;
	[locations insertObject:location atIndex:newIndex];
	
	[self didChangeValueForKey:@"locations"];
}

@end
