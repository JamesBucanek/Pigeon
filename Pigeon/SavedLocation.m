//
//  SavedLocation.m
//  Pigeon
//
//  Created by James Bucanek on 12/11/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "SavedLocation.h"

#import "AppDelegate.h"
#import "LocationDocument.h"
#import "LocationDocument+ImageStorage.h"


#define TESTING 1	// TODO: Turn off TESTING


@interface SavedLocation () // private
{
	NSString*				identifier;
}

@end

@implementation SavedLocation

#pragma KVO

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet* dependentKeys = [super keyPathsForValuesAffectingValueForKey:key];
	NSSet* additionalKeys = nil;
	
	if ([key isEqualToString:@"title"])
		// title could change if either the name or placemark properties are modified
		additionalKeys = [NSSet setWithObjects:@"name",@"placemark",nil];
	else if ([key isEqualToString:@"subtitle"])
		// The subtitle property is currently derived from the date property
		additionalKeys = [NSSet setWithObject:@"date"];
	else if ([key isEqualToString:@"date"])
		// The date property is extracted from the location
		additionalKeys = [NSSet setWithObject:@"location"];
	else if ([key isEqualToString:@"horizontalAccuracy"])
		// The horizontal accuracy is extracted from the location
		additionalKeys = [NSSet setWithObject:@"location"];
	else if ([key isEqualToString:@"refining"])
		// The refining flag is determined by the refiner property
		additionalKeys = [NSSet setWithObject:@"refiner"];
	else if ([key isEqualToString:@"pictureCount"] || [key isEqualToString:@"pictures"])
		// The pictures are actually stored in the document object; changing
		//	the document changes the pictures.
		additionalKeys = [NSSet setWithObject:@"document"];
	
	if (additionalKeys!=nil)
		{
		if (dependentKeys!=nil)
			dependentKeys = [dependentKeys setByAddingObjectsFromSet:additionalKeys];
		else
			dependentKeys = additionalKeys;
		}
	
	return dependentKeys;
}

#pragma mark <NSSecureCoding>

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self!=nil)
		{
		_location =		[decoder decodeObjectOfClass:[CLLocation class]		forKey:@"location"];
		_name =			[decoder decodeObjectOfClass:[NSString class]		forKey:@"name"];
		_placemark =	[decoder decodeObjectOfClass:[CLPlacemark class]	forKey:@"placemark"];
		_notes =		[decoder decodeObjectOfClass:[NSString class]		forKey:@"notes"];
		identifier =	[decoder decodeObjectOfClass:[NSString class]		forKey:@"id"];
		}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:_location			forKey:@"location"];
	[encoder encodeObject:_name				forKey:@"name"];
	[encoder encodeObject:_placemark		forKey:@"placemark"];
	[encoder encodeObject:_notes			forKey:@"notes"];
	[encoder encodeObject:self.identifier	forKey:@"id"];
}

- (void)subsumeLocation:(SavedLocation *)location
{
	// Replace all of the values of this saved location from the given location.
	// Typically received when a document has been re-opened/updated and the new values
	//	should replace those of an existing location.
	if (location!=nil)
		{
		// Update properties in a manner that will notify any observers
		// TODO: make assignments smart so non-changes don't trigger notifications?
		identifier = location->identifier;	// superfluous: both locations should have the same ID
		self.location = location->_location;
		self.autoSelect = location->_autoSelect;
		//_refiner = nil;					-- a loaded location can't still be refining
		self.name = location->_name;
		self.placemark = location->_placemark;
		_geocodingFinished = YES;			// assume placemark has finished geocoding
		self.notes = location->_notes;
		}
}

#pragma mark Properties

- (void)setLocation:(CLLocation *)location
{
	// Update the location
	if (_location!=location)
		{
		_location = location;
		
		// Start a reverse geocoding request
		if (location!=nil)
			[self reverseGeocode];
		}
}

- (CLLocationAccuracy)horizontalAccuracy
{
	return _location.horizontalAccuracy;
}

- (NSDate*)date
{
	return _location.timestamp;
}

- (NSString*)localizedDate
{
	static NSDateFormatter* formatter = nil;
	if (formatter==nil)
		{
		formatter = [NSDateFormatter new];
		formatter.dateStyle = NSDateFormatterMediumStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;
		formatter.doesRelativeDateFormatting = YES;
		}
	
	return [formatter stringFromDate:self.date];
}

- (NSString*)localizedDistance:(CLLocationDistance)distance
{
	// Return a localized distance from this location to the given map coordinate.
	static MKDistanceFormatter* formatter;
	if (formatter==nil)
		{
		formatter = [MKDistanceFormatter new];
		formatter.unitStyle = MKDistanceFormatterUnitStyleAbbreviated;
		}
	return [formatter stringFromDistance:distance];
}

- (BOOL)refining
{
	return (_refiner!=nil);
}

- (NSString*)identifier
{
	// Return a unique identifier string.
	// This is used to pair the location with an annotation, generate a unique
	//	document URL, compare SavedLocation objects, etc.
	// For now, it's a string generated from the exact time the identity was
	//	first requested. The chances of creating duplicate identifiers on
	//	two devices sharing the same iCloud account are essentially zero.
	// The identity is persistant (preserved via serialization)
	if (identifier==nil)
		{
		// Use the hexadecimal floating point notation to avoid periods and other
		//	characters that could complicate using it as part of a filename.
		identifier = [NSString stringWithFormat:@"%a",[[NSDate date] timeIntervalSinceReferenceDate]];
		}
	return identifier;
}

#pragma mark <MKAnnotation>

- (CLLocationCoordinate2D)coordinate
{
	return _location.coordinate;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoord
{
	self.location = [[CLLocation alloc] initWithLatitude:newCoord.latitude
											   longitude:newCoord.longitude];
}

- (NSString*)title
{
	if (_name!=nil)
		return _name;
	if (_placemark!=nil)
		return _placemark.name;
	return @"Saved Location";
}

- (NSString*)subtitle
{
	return self.localizedDate;
}

#pragma mark Geocoding

- (void)reverseGeocode
{
	// Start a reverse geocoding task to convert the coordinate into something readable
	
	// There can only be one geocoding request in progress at any one time.
	// A semephore condition is created to prevent more than one request from being started
	//	simultaniously. (Note: a sequential operation queue won't, by itself, solve this
	//	problem becuase the request message is asynchronious. The next request has to
	//	block until the previous request has finished.)
	static CLGeocoder*			sSharedGeocoder;
	static dispatch_queue_t		sGeocodingQueue;
	static NSCondition*			sGeocodingCondition;
	static BOOL					sGeocodingInProgress;
	if (sGeocodingQueue==NULL)
		{
		// Create a singleton geocoder object
		sSharedGeocoder = [CLGeocoder new];
		// Create an dispatch queue that initiates reverse goecoding requests, one at a time
		sGeocodingQueue = dispatch_queue_create("pigeon.location.geocoding",DISPATCH_QUEUE_SERIAL);
		// Create a condition semephore to suspend a geocoding task until the previous one has finished
		sGeocodingCondition = [NSCondition new];
		}
	
	// Start by clearing any previous gathered placemark information
	self.geocodingFinished = NO;
	self.placemark = nil;
	
	// The request code is added to an operation queue. The requests will execute one at a time.
	//	When the code begins, the first thing is does is suspend until the previous request
	//	(if any) has completed. This accomplishes two things: it waits for the previous request
	//	to finish before starting another and it blocks the dispatch queue from starting any
	//	subsequent requests.
	dispatch_async(sGeocodingQueue,^{
		// This code executes on a background thread.
		
		// Suspend until the in-progress geocoding request has completed
		[sGeocodingCondition lock];
		while (sGeocodingInProgress)
			[sGeocodingCondition wait];
		// The geocoder is idle and a the request is now ready to start.

		// Flag that a new request is in progress.
		sGeocodingInProgress = YES;
		
#if TESTING
		[NSThread sleepForTimeInterval:3.5];	// pretend it takes a long to to complete (for testing)
#endif
		
		// Start the reverse geocoding request
		[sSharedGeocoder reverseGeocodeLocation:_location
							  completionHandler:^(NSArray *placemarks, NSError *error) {
								  // This block executes when the request has completed, on the main thread.
								  // If a placemark object was returned, save it in the SavedLocation object
								  if (placemarks.count>0)
									  self.placemark = placemarks[0];
								  else
									  self.placemark = nil;		// (there could have been multiple requests)
								  // Signal that goecoding for this object has finished
								  self.geocodingFinished = YES;
								  
								  // Annouce that the goecoding process has completed and the next one can begin
								  [sGeocodingCondition lock];
								  sGeocodingInProgress = NO;
								  [sGeocodingCondition signal];		// wake up any pending request(s)
								  [sGeocodingCondition unlock];
								  }];
		
		// Unlock the condition and conclude the dispatch block; the geocoding request is now running
		//	in another thread, and will signal sGeocodingCondition when it completes.
		[sGeocodingCondition unlock];
		});
}

#pragma mark <ImageStorage>

// The document object for this saved location manages all of the image storage and retrieval.
// This class adopts <ImageStorage> and passes all picture-related messages along to the document.

- (NSUInteger)pictureCount
{
	return _document.pictureCount;
}

- (NSArray*)pictures
{
	return _document.pictures;
}

- (UIImage*)pictureAtIndex:(NSUInteger)index
{
	return [_document pictureAtIndex:index];
}

- (UIImage*)thumbnailFittingSize:(CGSize)size forPictureAtIndex:(NSUInteger)index
{
	return [_document thumbnailFittingSize:size forPictureAtIndex:index];
}

- (void)addPicture:(UIImage*)image
{
	[_document addPicture:image];
}

- (void)removePictureAtIndex:(NSUInteger)index
{
	[_document removePictureAtIndex:index];
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
	return ( self==object || ([object isKindOfClass:[SavedLocation class]] && [self.identifier isEqualToString:[object identifier]]) );
}

- (NSUInteger)hash
{
	return self.identifier.hash;
}

@end
