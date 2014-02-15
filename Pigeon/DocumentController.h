//
//  DocumentController.h
//  Pigeon
//
//  Created by James Bucanek on 1/5/14.
//  Copyright (c) 2014 James Bucanek. See LICENSE.txt.
//

#import <Foundation/Foundation.h>

@class LocationData;
@class SavedLocation;

//
// Singleton document and iCloud manager
//

#define kPreferencesUseICloud		@"Pigeon.icloud.sync"
#define kPreferencesUbiquityToken	@"Pigeon.icloud.token"
#define kPreferencesLocationOrder	@"Pigeon.locations.order"
#define kPreferencesLocationActive	@"Pigeon.locations.active"


@interface DocumentController : NSObject

+ (DocumentController*)sharedController;

@property (readonly,nonatomic) LocationData* data;

@property (readonly,nonatomic) BOOL useUbiquitousStore;	// (iCloudAvailable && syncWithCloud)
@property (readonly,nonatomic) BOOL	iCloudAvailable;	// cloud service status
@property (assign,nonatomic) BOOL	syncWithCloud;		// user preference

- (void)createDocumentForLocation:(SavedLocation*)location;
- (void)removeDocumentForLocation:(SavedLocation*)location;

@end
