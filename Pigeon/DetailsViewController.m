//
//  DetailsViewController.m
//  Pigeon
//
//  Created by James Bucanek on 12/15/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <MobileCoreServices/UTCoreTypes.h>

#import "DetailsViewController.h"

#import <AddressBookUI/AddressBookUI.h>
#import "MapViewController.h"
#import "ShowLocationController.h"
#import "PictureViewController.h"
#import "Refiner.h"
#import "MKMapView+MapPanning.h"
#import "DocumentController.h"
#import "LocationDocument.h"			// (for max number of pictures)


#define kAddPictureButtonImageName		@"PictureAddButton"
#define kTakePictureButtonImageName		@"PictureTakeButton"

@interface DetailsViewController ()
{
	ShowLocationController*		annotationsController;
	CGRect						editTextRect;			// rect of active text editing
}
- (void)focusMapAnimated:(BOOL)animate;
- (void)updateCancelButton;
- (void)fillDateLabel;
- (void)fillTitleField;
- (void)fillNotesField;
- (void)fillDistanceLabel;
- (void)layoutPictures;
- (void)presentImagePickerUsingCamera:(BOOL)useCamera;
- (void)dismissImagePicker;
- (void)keyboardWillShowNotification:(NSNotification*)notification;
- (void)keyboardWillHideNotification:(NSNotification*)notification;
- (void)openMapsWithDirections:(NSString*)directionStyle;
@end

@implementation DetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.location = nil;		// make sure we're still not observing the data model
}

//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Reset the view so it presents the current _location information
	// (this can't be done when _location is set, because not all of the
	//	outlet connections have been made)
	[self focusMapAnimated:NO];
	
	// Fill in the various details
	[self layoutPictures];
	[self updateCancelButton];
	[self fillDateLabel];
	[self fillTitleField];
	[self fillNotesField];
	[self fillDistanceLabel];
	
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
						   selector:@selector(keyboardWillShowNotification:)
							   name:UIKeyboardWillShowNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(keyboardWillHideNotification:)
							   name:UIKeyboardWillHideNotification
							 object:nil];

	// Set up the annotation and overlays controller
	annotationsController = [[ShowLocationController alloc] initWithMapView:_mapView];
	annotationsController.showLocation = _location;
}

- (void)viewWillDisappear:(BOOL)animated
{
//	self.location = nil;			// clear the data model, disconnecting the observer
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Discard and disable the annotation controller
	annotationsController = nil;

	[super viewWillDisappear:animated];
}

//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

#pragma mark Properties

- (void)setLocation:(SavedLocation *)location
{
	NSArray* volatileKeys = @[@"placemark",@"date",@"refining",@"name",@"notes"];
	// Stop observing changes to the previous location object
	for ( NSString* key in volatileKeys )
		[_location removeObserver:self forKeyPath:key];
	
	// Set the saved location object for the detail view
	_location = location;
	
	// Begin observing changes to this location object
	for ( NSString* key in volatileKeys )
		[location addObserver:self forKeyPath:key options:0 context:NULL];
}

#pragma mark Picture Maintenance

#define kPictureViewCollapsedHeight		((CGFloat)32)
#define kPictureViewExpandedHeight		((CGFloat)64)
#define kPictureViewIndividualWidth		((CGFloat)64)

- (void)layoutPictures
{
	NSUInteger pictureCount = _location.pictureCount;
	
	NSString* addButtonTitle = nil;
	UIImage* addButtonImage = nil;
	NSString* takeButtonTitle = nil;
	UIImage* takeButtonImage = nil;
	switch (pictureCount) {
		case 0:
			// No pictures: there's plenty of room for button titles and images
			addButtonTitle = @"Add Picture";
			takeButtonTitle = @"Take Picture";
			// fall through and set images too

		default:
			// 1-3 pictures: room for button images, but no titles
			addButtonImage = [UIImage imageNamed:kAddPictureButtonImageName];
			takeButtonImage = [UIImage imageNamed:kTakePictureButtonImageName];
			break;
			
		case kPicturesMax:
			// 4 pictures: no room for buttons
			break;
		}

	// Blank and disable the buttons that can't be used
	BOOL hasPhotoLibrary = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	if (!hasPhotoLibrary)
		{
		addButtonImage = nil;
		addButtonTitle = nil;
		}
	if (!hasCamera)
		{
		takeButtonImage = nil;
		takeButtonTitle = nil;
		}
	
	[_addPictureButton setTitle:addButtonTitle forState:UIControlStateNormal];
	[_addPictureButton setImage:addButtonImage forState:UIControlStateNormal];
	_addPictureButton.enabled = hasPhotoLibrary;
	[_takePictureButton setTitle:takeButtonTitle forState:UIControlStateNormal];
	[_takePictureButton setImage:takeButtonImage forState:UIControlStateNormal];
	_takePictureButton.enabled = hasCamera;
	
	// Set the content and the width constraints for each of the four image views
	for ( NSUInteger i=0; i<kPicturesMax; i++ )
		{
		UIImageView* pictureView = [self valueForKey:[NSString stringWithFormat:@"picture%uView",(unsigned)i]];
		NSLayoutConstraint* widthConstraint = [self valueForKey:[NSString stringWithFormat:@"picture%uWidthConstraint",(unsigned)i]];
		if (i<pictureCount)
			{
			CGSize thumbSize = CGSizeMake(kPictureViewIndividualWidth*pictureView.contentScaleFactor,
										  kPictureViewExpandedHeight*pictureView.contentScaleFactor);
			pictureView.image = [_location thumbnailFittingSize:thumbSize forPictureAtIndex:i];
			widthConstraint.constant = 80;
			}
		else
			{
			pictureView.image = nil;
			widthConstraint.constant = 0;
			}
		}
	
	// Collapse the album view to kPictureViewCollapsedHeight if there are no pictures, or expand to kPictureViewExpandedHeight if there are
	_albumHeightConstraint.constant = ( pictureCount==0 ? kPictureViewCollapsedHeight : kPictureViewExpandedHeight );
}

- (void)presentImagePickerUsingCamera:(BOOL)useCamera
{
//	imagePopoverController = nil;		-- for later, if there's ever an iPad version ...
	
	// Create the image picker controller
	UIImagePickerController *cameraUI = [UIImagePickerController new];
	// Set the source type to either the camera or the photo library
	cameraUI.sourceType = ( useCamera ? UIImagePickerControllerSourceTypeCamera
									  : UIImagePickerControllerSourceTypePhotoLibrary );
	
	cameraUI.mediaTypes = @[(NSString*)kUTTypeImage];		// only interested in still pictures
	cameraUI.delegate = self;
//	if (useCamera || UIDevice.currentDevice.userInterfaceIdiom==UIUserInterfaceIdiomPhone)
//        {
		// Presenting the camera interface OR this is an iPhone: user full screen controller
		[self presentViewController:cameraUI animated:YES completion:nil];
//        }
//	else
//        {
//		// Presenting the photo library picker on an iPad: must use a pop-over
//		imagePopoverController = [[UIPopoverController alloc] initWithContentViewController:cameraUI];
//		[imagePopoverController presentPopoverFromRect:self.imageView.frame
//												inView:self.view
//							  permittedArrowDirections:UIPopoverArrowDirectionAny
//											  animated:YES];
//        }
}

- (void)dismissImagePicker
{
	// Dismiss the image picker interface and return to the detail view controller.
//	if (imagePopoverController!=nil)
//		{
//		// Picker was presented using a popover controller: dismiss the popover
//		[imagePopoverController dismissPopoverAnimated:YES];
//		imagePopoverController = nil;
//		}
//	else
//		{
		// Else, picker was presented in a full screen controller
		[self dismissViewControllerAnimated:YES completion:nil];
//		}
}

#pragma mark <UIImagePickerConrollerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSString *mediaType = info[UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:(NSString*)kUTTypeImage])
        {
		// First try to get the edited image (cropped, rotated, whatever)
		UIImage *newImage = info[UIImagePickerControllerEditedImage];
		if (newImage==nil)
			// There was no edited image: use the original
			newImage = info[UIImagePickerControllerOriginalImage];
		
		// If the user used the camera to take a new picture, they will
		//	expect that (original or cropped) image to be added
		//	to their camera roll.
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceSaveToCameraRollKey]
			&& picker.sourceType==UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(newImage,nil,nil,nil);
		
		// Add the image to the location and update the details
		[_location addPicture:newImage];
        }
    
	// Dismiss the camera/photo picker interface and discard it
	[self dismissImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	// Close the image picker interface and return to the detail view controller
	//	without making any changes to the selected image.
	[self dismissImagePicker];
}

#pragma mark Detail Maintenance

- (void)focusMapAnimated:(BOOL)animate
{
	// set up the map view
	[_mapView removeAnnotations:_mapView.annotations];	// remove all annotations
	[_mapView addAnnotation:_location];					// add this location as the only annotation
	[_mapView centerAtLocation:_location.location
					  animated:animate];
}

- (void)updateCancelButton
{
	[_updateButton setTitle:( _location.refining ? @"Stop Refining" : @"Update" )
				   forState:UIControlStateNormal];
}

- (void)fillDateLabel
{
	_dateLabel.text = _location.localizedDate;
}

- (void)fillTitleField
{
	// Fill the title field with
	//	(a) the user's title (black)
	//	(b) the geolocation information (dark grey or black)
	//	(c) a placeholder message
	NSString* userName = _location.name;
	if (userName.length!=0)
		{
		// User has supplied a title: use that
		_titleField.text = userName;
		_titleField.textColor = [UIColor darkTextColor];
		return;
		}

	CLPlacemark* placemark = _location.placemark;
	if (placemark!=nil)
		{
		// User has not supplied a title; fill in with placemark information
		NSString* name = placemark.name;
		NSString* address = ABCreateStringWithAddressDictionary(placemark.addressDictionary,NO);
		if (address==nil)
			address = @"";
		if (name.length==0 || [address hasPrefix:name])
			// no name or address begins with name: use address
			_titleField.text = address;
		else
			// combine name and address
			_titleField.text = [NSString stringWithFormat:@"%@\r%@",name,address];
		_titleField.textColor = [UIColor darkGrayColor];
		return;
		}

	if (_location.geocodingFinished)
		{
		_titleField.text = @"Unknown Location";
		}
	else
		{
		CLLocationCoordinate2D raw = _location.coordinate;
		_titleField.text = [NSString stringWithFormat:@"Looking up location %f, %f",raw.latitude,raw.longitude];
		}
	_titleField.textColor = [UIColor lightGrayColor];
}

- (void)fillNotesField
{
	// Fill the notes field with either ther user's notes, or a placeholder message
	NSString* notes = _location.notes;
	if (notes.length!=0)
		{
		_notesField.text = notes;
		_notesField.textColor = [UIColor darkTextColor];
		return;
		}
	
	_notesField.text = @"Any details that might help you find your way back.";
	_notesField.textColor = [UIColor lightGrayColor];
}

- (void)fillDistanceLabel
{
	NSString* localizedDistance = nil;
	CLLocationDistance distance = 0;
	if (currentLocation!=nil)
		{
		distance = [_location.location distanceFromLocation:currentLocation];
		localizedDistance = [_location localizedDistance:distance];
		}
	_distanceLabel.text = localizedDistance;
	
	// Enable the directions button when the user is an apropriate distance away
	_walkButton.enabled = (distance>=50.0);
	_driveButton.enabled = (distance>=100.0);
}

#pragma mark <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	[super locationManager:manager didUpdateLocations:locations];
	[self fillDistanceLabel];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	[super locationManager:manager didFailWithError:error];
	[self fillDistanceLabel];
}

#pragma mark <MKMapViewDelegate>

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	return [annotationsController mapView:mapView viewForAnnotation:annotation];
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	return [annotationsController mapView:mapView rendererForOverlay:overlay];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	// This don't do anything, but weird things were happening when the delegate didn't implement it.
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
	// This don't do anything, but weird things were happening when the delegate didn't implement it.
}

#pragma mark Keyboard Notifications

#define kVisibleFieldVerticalMargin	8.0		// make sure there's at least 8 pixels above and below the text field

- (void)keyboardWillShowNotification:(NSNotification*)notification
{
	// The keyboard is about to appear: make sure the editable text field is still
	//	visible once the keyboard appears.
	NSDictionary* info = notification.userInfo;
	CGRect keyboardRect = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0,0,keyboardRect.size.height,0);
	_scrollView.contentInset = contentInsets;
	_scrollView.scrollIndicatorInsets = contentInsets;
	
	// Find out if the text field is being covered up by the keyboard.
	
	// Step one is to determine the top edge of the keyboard relative to the scroll view
	UIView* rootView = self.view;
	keyboardRect = [rootView convertRect:[rootView.window convertRect:keyboardRect fromWindow:nil]
								fromView:nil];
	// Now see if the text field will fit in the top portion of the scroll view
	CGRect scrollFrame = _scrollView.frame;
	CGFloat textFieldBottomLimit = CGRectGetMinY(scrollFrame)+editTextRect.size.height+2*kVisibleFieldVerticalMargin;
	if ( textFieldBottomLimit > CGRectGetMinY(keyboardRect) )
		{
		// Measuring from the scroll view's top edge, there's not enough screen space between
		//	that and the top of the keyboard to fit the text field and a little margin. We're going to
		//	have to move the whole thing up by temporarily shoving the map view above the navigation bar.
		[rootView layoutIfNeeded];
		[UIView animateWithDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
						 animations:^{
							 _mapTopConstraint.constant = CGRectGetMinY(keyboardRect)-textFieldBottomLimit;
							 [rootView layoutIfNeeded];
							 }];
		}
	// At the same time, make the text field visible in the scroll view
	[_scrollView scrollRectToVisible:editTextRect animated:YES];
}

- (void)keyboardWillHideNotification:(NSNotification*)notification
{
	_scrollView.contentInset = UIEdgeInsetsZero;
	_scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
	
	if (_mapTopConstraint.constant!=0)
		{
		// The map view was moved up to make room; put it back (nicely)
		NSDictionary* info = notification.userInfo;
		UIView* rootView = self.view;
		[rootView layoutIfNeeded];
		[UIView animateWithDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
						 animations:^{
							 _mapTopConstraint.constant = 0;
							 [rootView layoutIfNeeded];
						 }];
		}
}

#pragma mark <UITextViewDelegate>

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	// Save the frame of the field, in scroll view coordinates, so we can
	//	later make sure the keyboard doesn't obscure it.
	editTextRect = [textView convertRect:textView.bounds toView:_scrollView];
	
	return YES;	// of course
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// The user is about to edit one of the text views
	
	if (textView==_titleField)
		{
		// User is editing the title field
		if (_location.name.length==0)
			{
			// The user has not assigned a name to the location.
			// The field contains either the geolocation information or a placeholder.
			// In the former case, select the text and let the user decide how much to use.
			// In the later, clear the field.
			// In both cases, reset the font and color to the ones used for the user's name
			textView.textColor = [UIColor darkTextColor];
			if (!_location.geocodingFinished)
				textView.text = @"";
			else
				//textView = NSMakeRange(0,_titleField.text.length);
				[textView selectAll:self];
			}
		}
	if (textView==_notesField)
		{
		// User is editing the notes field
		if (_location.notes.length==0)
			{
			// The user notes were empty, which means the text field contains a placeholder.
			// Clear it before allowing editing to commence.
			textView.text = @"";
			textView.textColor = [UIColor darkTextColor];
			}
		}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if (textView==_titleField)
		{
		// Editing of the location's name has concluded. Update the value.
		_location.name = [_titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		// Based on the updated value, re-fill the title view
		[self fillTitleField];
		}
	if (textView==_notesField)
		{
		// Save the notes in the data model
		_location.notes = [_notesField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[self fillNotesField];
		}
}

#pragma mark Key-Value Observing

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context
{
	if (object==_location)
		{
		if ([keyPath isEqualToString:@"placemark"] || [keyPath isEqualToString:@"name"])
			{
			if (!_titleField.isFirstResponder)
				[self fillTitleField];
			}
		else if ([keyPath isEqualToString:@"date"])
			{
			[self fillDateLabel];
			}
		else if ([keyPath isEqualToString:@"refining"])
			{
			[self updateCancelButton];
			}
		else if ([keyPath isEqualToString:@"notes"])
			{
			if (!_notesField.isFirstResponder)
				[self fillNotesField];
			}
		}
}

#pragma mark Actions

- (IBAction)addPicture:(id)sender
{
    // We're going to present an interface; dismiss the keyboard first
    [self dismissKeyboard:self];
    
	// The device has either a camera or a photo library, but not both.
	// Start the image picker interface immediately with what they have.
	[self presentImagePickerUsingCamera:NO];
}

- (IBAction)takePicture:(id)sender;
{
    [self dismissKeyboard:self];
	[self presentImagePickerUsingCamera:YES];
}

- (IBAction)viewPicture:(id)sender
{
	// Create the picture view controller
	UINavigationController* navigationController = self.navigationController;
	PictureViewController* pictureController = [self.storyboard instantiateViewControllerWithIdentifier:@"picture"];
	pictureController.location = _location;
	pictureController.pictureIndex = [[(UITapGestureRecognizer*)sender view] tag];
	[navigationController pushViewController:pictureController animated:YES];
}

- (IBAction)drivingDirections:(id)sender
{
	[self openMapsWithDirections:MKLaunchOptionsDirectionsModeDriving];
}

- (IBAction)walkingDirections:(id)sender
{
	[self openMapsWithDirections:MKLaunchOptionsDirectionsModeWalking];
}

- (void)openMapsWithDirections:(NSString*)directionStyle
{
	MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate:_location.coordinate
												   addressDictionary:_location.placemark.addressDictionary];
	MKMapItem* mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
	MKMapType mapType = [[NSUserDefaults standardUserDefaults] integerForKey:kPreferenceMapTypeKey];
	[mapItem openInMapsWithLaunchOptions:@{ MKLaunchOptionsDirectionsModeKey: directionStyle,
											MKLaunchOptionsMapTypeKey : @(mapType) }];
}

static enum {
	kForgetLocationAlert,
	kUpdateLocationAlert
} WhichAlert;

- (IBAction)forgetLocation:(id)sender
{
	NSString* message = (  [[DocumentController sharedController] syncWithCloud]
						 ? @"This location will be removed from this device, and all other synchronized devices."
						 : @"This location will be discard." );
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Delete Location?"
													message:message
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"Delete", nil];
	WhichAlert = kForgetLocationAlert;
	[alert show];
}

- (IBAction)resetLocation:(id)sender
{
	if (_location.refining)
		{
		// Stop refining
		[_location.refiner stop];
		}
	else
		{
		// Put up a dialog asking if they want to replace the location with their current one
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Update Location?"
														message:@"Move this saved location to your current location?"
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Set Location", nil];
		WhichAlert = kUpdateLocationAlert;
		[alert show];
		}
}

- (IBAction)dismissKeyboard:(id)sender
{
	// Action message to stop editing the current text field, which
	//	dismisses the keyboard.
	[self.view endEditing:NO];
}

#pragma mark <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (WhichAlert) {
		case kForgetLocationAlert:
			if (buttonIndex!=alertView.cancelButtonIndex)
				{
				// User tapped the button that was not the cancel button
				// Delete this saved location and dismiss the view controller
				[[LocationData sharedData] removeLocation:_location];
				[self.navigationController popViewControllerAnimated:YES];
				}
			break;
			
		case kUpdateLocationAlert:
			if (buttonIndex!=alertView.cancelButtonIndex && currentLocation!=nil)
				{
				// User tapped the button that was not the cancel button
				// Get the current location and change the saved location
				_location.location = currentLocation;
				
				// Refocus the map and update the date
				[self focusMapAnimated:YES];
				[self fillDateLabel];
				// The rest of the details either don't change or will update themselves
				}
			break;
	}
}

@end
