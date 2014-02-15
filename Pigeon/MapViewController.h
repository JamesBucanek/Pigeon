//
//  ViewController.h
//  Pigeon
//
//  Created by James Bucanek on 11/22/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "LocationTrackingViewController.h"
#import "LocationData.h"

@class RoundedRectView;

//
// The root map scene controller
//

#define kPreferenceMapTypeKey		@"Pigeon.map.type"			// MKMapType
#define kPreferenceMapTrackingKey	@"Pigeon.map.tracking"		// MKUserTrackingMode
#define kPreferenceMapCameraKey		@"Pigeon.map.camera"		// MKMapCamera


typedef enum
{
	kTrackingNone = MKUserTrackingModeNone,
	kTrackingFollow = MKUserTrackingModeFollow,
	kTrackingFollowWithHeading = MKUserTrackingModeFollowWithHeading,
	kTrackingAutoZoom
} TrackingMode;


@interface MapViewController : LocationTrackingViewController <UINavigationControllerDelegate,
															   MKMapViewDelegate>

// Data model
@property (strong,nonatomic) LocationData*	data;

// View objects
@property (weak,nonatomic) IBOutlet MKMapView*		mapView;
@property (weak,nonatomic) IBOutlet UIButton*		addButton;
@property (weak,nonatomic) IBOutlet UIButton*		listButton;
@property (weak,nonatomic) IBOutlet UIButton*		detailsButton;
@property (weak,nonatomic) IBOutlet UIButton*		mapTypeButton;
@property (weak,nonatomic) IBOutlet UIButton*		mapTrackingButton;
@property (weak,nonatomic) IBOutlet UIButton*		settingsButton;
@property (weak,nonatomic) IBOutlet UIButton*		helpButton;

// Actions
- (IBAction)addLocation:(id)sender;
- (IBAction)showDetails:(id)sender;
- (IBAction)changeMapType:(id)sender;
- (IBAction)changeTrackingMode:(id)sender;
- (IBAction)showHelp:(id)sender;

// Location Unavailable "dialog"
@property (strong,nonatomic) IBOutlet RoundedRectView*	noSignalView;
@property (weak,nonatomic) IBOutlet UILabel*			noSignalText;
- (IBAction)cancelNoSignal:(id)sender;

@end
