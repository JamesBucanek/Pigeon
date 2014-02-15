//
//  LocationData+Documents.m
//  Pigeon
//
//  Created by James Bucanek on 1/5/14.
//  Copyright (c) 2014 Dawn to Dusk Software. All rights reserved.
//

#import "LocationData+Documents.h"

@implementation LocationData (Documents)

- (void)setDocumentManager:(DocumentController *)manager
{
	documentManager = manager;
}

- (void)insertLocation:(SavedLocation *)location atIndex:(NSUInteger)index
{
	// Received when the document manager discovers an existing saved location
	//	document and wants to add it back into the data model without
	//	the data model trying to create a new document for it (since it already
	//	has one).
	// Also used internally to insert a new SavedLocation object.
	[self willChangeValueForKey:@"locations"];
	[locations insertObject:location atIndex:index];
	mirrorLocations = nil;
	[self didChangeValueForKey:@"locations"];
}

- (void)replaceLocation:(SavedLocation*)stale withLocation:(SavedLocation*)location
{
	// Replaces one existing location with another.
	// Received when a document for a SavedLocation object is reloaded, presumably
	//	because the document has been updated externally.
	// If the stale location isn't already in the data model
	//	this method preforms a simple insert.
	NSUInteger existingIndex = [locations indexOfObject:stale];
	if (existingIndex!=NSNotFound)
		{
		[self willChangeValueForKey:@"locations"];
		[locations replaceObjectAtIndex:existingIndex withObject:location];
		mirrorLocations = nil;
		[self didChangeValueForKey:@"locations"];
		if (self.activeLocation==stale)
			self.activeLocation = location;
		}
	else
		{
		[self insertLocation:location atIndex:0];
		}
}


@end
