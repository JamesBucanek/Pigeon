//
//  DetailsViewController.h
//  Pigeon
//
//  Created by James Bucanek on 12/15/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LocationTrackingViewController.h"
#import "SavedLocation.h"

//
// The controller for the location details scene
//

#define kPreferenceSaveToCameraRollKey		@"Pigeon.camera.save"	// BOOL


@interface DetailsViewController : LocationTrackingViewController <MKMapViewDelegate,
																   UITextViewDelegate,
																   UIAlertViewDelegate,
																   UINavigationControllerDelegate,
																   UIImagePickerControllerDelegate>

@property (strong,nonatomic) SavedLocation*				location;	// data model

@property (weak,nonatomic) IBOutlet MKMapView*			mapView;
@property (weak,nonatomic) IBOutlet NSLayoutConstraint*	mapTopConstraint;
@property (weak,nonatomic) IBOutlet UIScrollView*		scrollView;
@property (weak,nonatomic) IBOutlet UILabel*			dateLabel;
@property (weak,nonatomic) IBOutlet UIButton*			updateButton;
@property (weak,nonatomic) IBOutlet UITextView*			titleField;
@property (weak,nonatomic) IBOutlet UITextView*			notesField;
@property (weak,nonatomic) IBOutlet UILabel*			distanceLabel;
@property (weak,nonatomic) IBOutlet UIButton*			driveButton;
@property (weak,nonatomic) IBOutlet UIButton*			walkButton;
//@property (weak,nonatomic) IBOutlet UIButton*			otherButton;

@property (weak,nonatomic) IBOutlet UIView*				albumView;
@property (weak,nonatomic) IBOutlet NSLayoutConstraint*	albumHeightConstraint;
@property (weak,nonatomic) IBOutlet UIButton*			addPictureButton;
@property (weak,nonatomic) IBOutlet UIButton*			takePictureButton;
@property (weak,nonatomic) IBOutlet UIImageView*		picture0View;
@property (weak,nonatomic) IBOutlet NSLayoutConstraint*	picture0WidthConstraint;
@property (weak,nonatomic) IBOutlet UIImageView*		picture1View;
@property (weak,nonatomic) IBOutlet NSLayoutConstraint*	picture1WidthConstraint;
@property (weak,nonatomic) IBOutlet UIImageView*		picture2View;
@property (weak,nonatomic) IBOutlet NSLayoutConstraint*	picture2WidthConstraint;
@property (weak,nonatomic) IBOutlet UIImageView*		picture3View;
@property (weak,nonatomic) IBOutlet NSLayoutConstraint*	picture3WidthConstraint;

- (IBAction)addPicture:(id)sender;
- (IBAction)takePicture:(id)sender;
- (IBAction)viewPicture:(id)sender;

- (IBAction)resetLocation:(id)sender;
- (IBAction)forgetLocation:(id)sender;

- (IBAction)drivingDirections:(id)sender;
- (IBAction)walkingDirections:(id)sender;

- (IBAction)dismissKeyboard:(id)sender;

@end
