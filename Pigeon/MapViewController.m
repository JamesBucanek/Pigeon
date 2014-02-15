//
//  ViewController.m
//  Pigeon
//
//  Created by James Bucanek on 11/22/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "MapViewController.h"

#define NO_TEST_LOG
#import "Pigeon.h"
#import "AppDelegate.h"
#import "Refiner.h"
#import "DetailsViewController.h"
#import "ModeChangeController.h"
#import "ShowReturnController.h"
#import "RoundedRectView.h"
#import "MKMapView+MapPanning.h"
#import "HelpBubbleController.h"
#import "PigeonMath.h"


#define kMapTypeSettingNIBName		@"MapTypeView"
#define kMapTrackingSettingNIBName	@"MapTrackingView"
#define kNoSignalNIBName			@"NoSignalView"

#define kOffMapMargin		0.03		/* Points within %3 margin of map are considered "off the map" */
#define kTooClose			0.15		/* Points within 15% of the map's visible region are considered "too close" */


@interface MapViewController () // private
{
	ShowReturnController*		annotationsController;
	ModeChangeController*		mapTypeModeChangeController;
	ModeChangeController*		mapTrackingModeChangeController;
	BOOL						autoZoomMode;
	NSTimer*					autoZoomTimer;
	NSTimer*					noSignalUpdateTimer;
	NSDate*						noSignalDeadline;
	UIBackgroundTaskIdentifier	noSignalTaskIdentifier;
	HelpBubbleController*		helpBubbleController;
	NSInteger					helpBubbleIndex;
}
- (void)showDetailsForLocation:(SavedLocation*)location;
- (void)setMapType:(MKMapType)type;
@property (nonatomic) TrackingMode trackingMode;
- (void)checkAutoZoom;
- (void)autoZoomTime:(NSTimer*)timer;
- (void)appDidEnterBackgroundNotification:(NSNotification*)notification;
- (void)retractHelp;
- (void)nextBubbleTime:(NSTimer*)timer;
- (void)startNoSignalWait;
- (void)stopNoSignalWait;
- (void)fillSignalWaitMessage;
- (void)waitForSignalTime:(NSTimer*)timer;
@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Grab a copy of the global data model object
	_data = [LocationData sharedData];
	// Observe when the active location changes
	[_data addObserver:self forKeyPath:@"activeLocation" options:NSKeyValueObservingOptionInitial context:NULL];
	
	// The map view controller is the root view for the navigation view controller, and becomes its delegate
	self.navigationController.delegate = self;
//	self.navigationItem.title = @"Map";	-- I managed to configure this in Interface Builder, even though
//											the layout in the editor doesn't show the navigation bar.
	
	// Setup/restore the map view
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[self setMapType:[defaults integerForKey:kPreferenceMapTypeKey]];
	_mapView.showsBuildings = YES;
	[self setTrackingMode:(TrackingMode)[defaults integerForKey:kPreferenceMapTrackingKey]];
	NSData* cameraStateData = [defaults objectForKey:kPreferenceMapCameraKey];
	if (cameraStateData!=nil)
		_mapView.camera = [NSKeyedUnarchiver unarchiveObjectWithData:cameraStateData];
	
	// Create the controller objects for animating the setting changes
	mapTypeModeChangeController = [[ModeChangeController alloc] initWithName:kMapTypeSettingNIBName];
	mapTrackingModeChangeController = [[ModeChangeController alloc] initWithName:kMapTrackingSettingNIBName];

	// Clear the "no signal" task identifier
	noSignalTaskIdentifier = UIBackgroundTaskInvalid;
	
	// Observe when the app get pushed to the background
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidEnterBackgroundNotification:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
}

//- (void)viewWillAppear:(BOOL)animated
//{
//	[super viewWillAppear:animated];
//}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	// Create and activate the active location controller.
	annotationsController = [[ShowReturnController alloc] initWithMapView:_mapView];
	annotationsController.pinHasCallout = YES;
	annotationsController.pinDraggable = YES;
	annotationsController.data = _data;		// connect to data model, automatically track _data.activeLocation
	annotationsController.lightPath = (_mapView.mapType!=MKMapTypeStandard);

	// Whenever the view appears, reevaluate the auto-zoom as any number of things could have changed
	[self checkAutoZoom];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Cancel any pending auto-zoom
	[autoZoomTimer invalidate];
	autoZoomTimer = nil;
	
	// Disable and deactivate the annotation controller
	annotationsController = nil;
	
	// Stop the help bubbles, if they were running
	[self retractHelp];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark <UINavigationControllerDelegate>

- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated
{
	// Received just before a new view controller is presented
	// If the new view is this (the root) controller, hide the navigation bar.
	// For all other controllers, show the navigation bar.
	navigationController.navigationBarHidden = (viewController==self);
}

//- (void)navigationController:(UINavigationController *)navigationController
//	   didShowViewController:(UIViewController *)viewController
//					animated:(BOOL)animated
//{
//	// Received immediately after a new view controller has been presented
//}

#pragma mark Map

- (void)showDetailsForLocation:(SavedLocation*)location
{
	if (location!=nil)
		{
		// Create the details view controller
		UINavigationController* navigationController = self.navigationController;
		DetailsViewController* detailsController = [self.storyboard instantiateViewControllerWithIdentifier:@"details"];
		location.autoSelect = NO;
		detailsController.location = location;
		[navigationController pushViewController:detailsController animated:YES];
		}
}

- (void)setMapType:(MKMapType)type
{
	static NSString* mapTypeButtonNames[] = {
		@"MapTypeStandard",
		@"MapTypeSat",
		@"MapTypeHybrid"
	};
	_mapView.mapType = type;
	[_mapTypeButton setImage:[UIImage imageNamed:mapTypeButtonNames[type]]
					forState:UIControlStateNormal];
	// Update the kind of line drawn by the return path overlay, so it's easily visible
	//	on the selected map type
	annotationsController.lightPath = (type!=MKMapTypeStandard);
}

- (TrackingMode)trackingMode
{
	return ( autoZoomMode ? kTrackingAutoZoom : (TrackingMode)_mapView.userTrackingMode );
}

- (void)setTrackingMode:(TrackingMode)mode
{
	if (mode==self.trackingMode)
		return;
	
	MKUserTrackingMode newMapMode;
	if (mode<=kTrackingFollowWithHeading)
		{
		// use one of the standard map tracking modes
		autoZoomMode = NO;
		newMapMode = (MKUserTrackingMode)mode;
		}
	else
		{
		// Use the special tracking mode
		autoZoomMode = YES;
		newMapMode = MKUserTrackingModeNone;
		}
	
	// Change the map mode (if necessary) and make sure the delegate knows about it
	MKUserTrackingMode mapMode = _mapView.userTrackingMode;
	if (newMapMode!=mapMode)
		{
		// Change the map kit view; this will automatically notify the delegate
		[_mapView setUserTrackingMode:newMapMode animated:YES];
		}
	else
		{
		// The map kit view isn't changing, but ours is: notify the delegate manually
		if ([_mapView.delegate respondsToSelector:@selector(mapView:didChangeUserTrackingMode:animated:)])
			 [_mapView.delegate mapView:_mapView didChangeUserTrackingMode:mapMode animated:NO];
		}
}

- (void)checkAutoZoom
{
	// Check the auto-zoom state
	// Determine if either the target or user has moved outside the map and pan or zoom out to show both.
	//	Also check to see if both are now so close together on the map that the map could be zoomed in.
	// The pan/zoom is not performed immediately. A timer is started when a pan/zoom is needed.
	//	If the condition persists, and the timer fires, an automatic pan/zoom is performed.
	//	If the condition changes, the timer is canceled.
	
	BOOL needsZoom = NO;
	if (autoZoomMode)
		{
		// Get the set of annotations are visible on the map, and not too close to the edge
		MKMapRect onMapRect = _mapView.visibleMapRect;
		onMapRect = MKMapRectInset(onMapRect,onMapRect.size.width*kOffMapMargin,onMapRect.size.height*kOffMapMargin);
		NSSet* visibleAnnos = [_mapView annotationsInMapRect:onMapRect];
		// Sort out which one is the saved location and which one is the user's location
		SavedLocation*	visibleLocation= nil;
		MKUserLocation*	visibleUser = nil;
		for ( id<MKAnnotation> anno in visibleAnnos )
			{
			if ([anno isKindOfClass:[SavedLocation class]])
				visibleLocation = (SavedLocation*)anno;
			else if ([anno isKindOfClass:[MKUserLocation class]])
				visibleUser = anno;
			}
		if (visibleLocation!=nil)
			{
			// The saved location is visible on the map
			if (visibleUser!=nil)
				{
				// Both the saved location and the user are visible
				// See if they're really close together (less than 15% of the map height/wide)
				CLLocationCoordinate2D savedCoord = visibleLocation.coordinate;
				CLLocationCoordinate2D userCoord = visibleUser.coordinate;
				CLLocationDegrees latDist = MapLatitudeDifference(userCoord.latitude,savedCoord.latitude);
				CLLocationDegrees longDist = MapLongitudeDifference(userCoord.longitude,savedCoord.longitude);
				MKCoordinateRegion region = _mapView.region;
				if (latDist<=region.span.latitudeDelta*kTooClose && longDist<=region.span.longitudeDelta*kTooClose)
					{
					// The vertical and horizontal differences are both very close together.
					needsZoom = YES;
					TESTLog(@"YES zoom in (%.1f%%/%.1f%%)",
							100*latDist/region.span.latitudeDelta,100*longDist/region.span.longitudeDelta);
					}
				}
			else
				{
				// The saved location is visible, but the user's location isn't.
				// If the user location is available, then zoom the map so both are shown
				needsZoom = (currentLocation!=nil);
				if (needsZoom) TESTLog(@"YES user location off map",nil);
				}
			}
		else
			{
			// The saved location is not visible on the map
			if (_data.activeLocation!=nil)
				{
				// There is a saved location: we want to see it, so zoom to pull it into view
				needsZoom = YES;
				TESTLog(@"YES saved location off map",nil);
				}
			else
				{
				// There is no saved location.
				if (visibleUser==nil)
					{
					// The user location is not visible: if it's known, pull it into view
					needsZoom = (currentLocation!=nil);
					TESTLog(@"YES only user location known, and it is off map",nil);
					}
				// else { the user location is already visible, so there's nothing to do }
				}
			}
		}
	
#ifndef NO_TEST_LOG
	if (!needsZoom) TESTLog(@"%s","NO");
#endif
	if (needsZoom)
		{
		// Schedule a zoom
		if (autoZoomTimer==nil)
			{
			autoZoomTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
															 target:self
														   selector:@selector(autoZoomTime:)
														   userInfo:nil
															repeats:NO];
			}
		}
	else
		{
		[autoZoomTimer invalidate];
		autoZoomTimer = nil;
		}
}

- (void)autoZoomTime:(NSTimer *)timer
{
	autoZoomTimer = nil;
	
	NSMutableArray* pointsOfInterest = [NSMutableArray array];
	id<MKAnnotation> annotation = _data.activeLocation;
	if (annotation!=nil)
		[pointsOfInterest addObject:annotation];
	annotation = _mapView.userLocation;
	if (annotation!=nil)
		[pointsOfInterest addObject:annotation];
	
	TESTLog(@"showing %@",pointsOfInterest);
	if (pointsOfInterest.count!=0)
		[_mapView showAnnotations:pointsOfInterest animated:YES];
}

- (void)appDidEnterBackgroundNotification:(NSNotification*)notification
{
	// The application entered the background.
	
	// Save the camera state of the map
	NSData* cameraStateData = [NSKeyedArchiver archivedDataWithRootObject:_mapView.camera];
	[[NSUserDefaults standardUserDefaults] setObject:cameraStateData
											  forKey:kPreferenceMapCameraKey];
}

#pragma mark <MKMapViewDelegate>

//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
//{
//	// The user's location was updated
//}

//- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
//{
//	// The user's location can not be determined
//}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	// Let the active location controller supply it
	return [annotationsController mapView:mapView viewForAnnotation:annotation];
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	// Let the active location controller supply it
	return [annotationsController mapView:mapView rendererForOverlay:overlay];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	// The user tapped the map pin callout: push the location's detail view into view
	[self showDetailsForLocation:_data.activeLocation];
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
	static NSString* mapTrackingButtonNames[] = {
		@"MapTrackingNone",
		@"MapTrackingFollow",
		@"MapTrackingHeading",
		@"MapTrackingAuto"
	};
	NSString* trackingImageName = mapTrackingButtonNames[self.trackingMode];
	[_mapTrackingButton setImage:[UIImage imageNamed:trackingImageName]
						forState:UIControlStateNormal];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	// Whenever the region changes, test for auto-zoom
	[self checkAutoZoom];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	[self checkAutoZoom];
}

#pragma mark Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object==_data && [keyPath isEqualToString:@"activeLocation"])
		{
		// The active location has changed
		SavedLocation* activeLoction = _data.activeLocation;
		_detailsButton.hidden = (activeLoction==nil);		// update the visibility of the alternate info button
		annotationsController.showLocation = activeLoction;	// update the location on the map
		}
}

#pragma mark Actions

- (IBAction)addLocation:(id)sender
{
	if (currentLocation==nil)
		{
		// There's no signal: put up the "no signal" message and wait
		[self startNoSignalWait];
		return;
		}
	
	// Create the initial location and fill in the defaults
	SavedLocation* newLocation = [SavedLocation new];
	newLocation.location = currentLocation;
	newLocation.autoSelect = YES;
	
	// start location refinement task (Refiner retains itself until it finishes)
	(void)[[Refiner alloc] initWithSavedLocation:newLocation];
	
	// Add the new location to the set of locations and make it the active location
	_data.activeLocation = newLocation;
	[self showDetailsForLocation:newLocation];				// push the details view controller
}

- (IBAction)showDetails:(id)sender
{
	[self showDetailsForLocation:_data.activeLocation];
}

- (IBAction)changeMapType:(id)sender
{
	MKMapType type = _mapView.mapType;
	MKMapType nextType = ( type==MKMapTypeHybrid ? MKMapTypeStandard : type+1 );
	CGRect bounds = self.view.bounds;
	[mapTypeModeChangeController animateSwitchFrom:type
													to:nextType
												inView:self.view
											centeredAt:CenterOfRect(bounds)];
	[self setMapType:nextType];
	[[NSUserDefaults standardUserDefaults] setInteger:nextType
											   forKey:kPreferenceMapTypeKey];
}

- (IBAction)changeTrackingMode:(id)sender
{
	TrackingMode mode = self.trackingMode;
	TrackingMode nextMode = ( mode==kTrackingAutoZoom ? kTrackingNone : mode+1 );
	CGRect bounds = self.view.bounds;
	[mapTrackingModeChangeController animateSwitchFrom:mode
												to:nextMode
											inView:self.view
										centeredAt:CenterOfRect(bounds)];
	self.trackingMode = nextMode;
	[[NSUserDefaults standardUserDefaults] setInteger:nextMode
											   forKey:kPreferenceMapTrackingKey];
}

#pragma mark Help

#define kDetailsBubbleIndex	2	/* "Help_2_Details" */
static NSString* helpBubbleNibName[] = {
	@"Help_0_Save",
	@"Help_1_List",
	@"Help_2_Details",
	@"Help_3_Tracking",
	@"Help_4_Type",
//	@"Help_5_Settings"
};
static NSString* helpButtonViewName[] = {
	@"addButton",
	@"listButton",
	@"detailsButton",
	@"mapTrackingButton",
	@"mapTypeButton",
//	@"settingsButton"
};
static NSTimeInterval helpButtonReadInterval[] = {
	3.5,
	3.0,
	4.0,
	5.0,
	2.5,
//	2.5
};
#define kHelpBubbleCount (sizeof(helpBubbleNibName)/sizeof(NSString*))

- (IBAction)showHelp:(id)sender
{
	if (helpBubbleController==nil)
		{
		// Help bubbles not showing: create the first bubble controller
		helpBubbleIndex = -1;
		[self nextBubbleTime:nil];
		}
	else
		{
		// A bubble sequence is in progress.
		[self retractHelp];
		}
}

- (void)retractHelp
{
	// Retract the current help bubble (if any) and cancel help mode
	[helpBubbleController retract];
	helpBubbleController = nil;
	helpBubbleIndex = kHelpBubbleCount;
	// Special: Reset the visibility of the details button
	_detailsButton.hidden = (_data.activeLocation==nil);
}

- (void)nextBubbleTime:(NSTimer*)timer
{
	// Dismiss the current bubble and start the next
	[helpBubbleController dismiss];
	
	helpBubbleIndex += 1;
	if (helpBubbleIndex<kHelpBubbleCount)
		{
		helpBubbleController = [[HelpBubbleController alloc] initWithNib:helpBubbleNibName[helpBubbleIndex]];
		id targetView = [self valueForKey:helpButtonViewName[helpBubbleIndex]];
		[helpBubbleController presentForView:targetView fromView:_helpButton];
		// Start a timer to move to the next bubble
		[NSTimer scheduledTimerWithTimeInterval:helpButtonReadInterval[helpBubbleIndex]
										 target:self
									   selector:_cmd
									   userInfo:nil
										repeats:NO];
		}
	else
		{
		// Last bubble; discard the helper
		helpBubbleController = nil;
		}
	
	// Special: Force the details button to be visible while showing the details help bubble
	_detailsButton.hidden = ( helpBubbleIndex==kDetailsBubbleIndex ? NO : (_data.activeLocation==nil) );
}

#pragma mark No Signal "dialog"

- (void)startNoSignalWait
{
	if (_noSignalView==nil)
		{
		// Load the "no signal" view and place it over the map view
		[[NSBundle mainBundle] loadNibNamed:kNoSignalNIBName owner:self options:nil];
		
		// Center the view and place it 1/3 from the top
		CGRect noSignalFrame = _noSignalView.bounds;
		CGRect viewBounds = self.view.bounds;
		noSignalFrame.origin.x = viewBounds.origin.x+(viewBounds.size.width-noSignalFrame.size.width)/2;
		noSignalFrame.origin.y = viewBounds.origin.y+(viewBounds.size.height-noSignalFrame.size.height)/3;
		[self.view insertSubview:_noSignalView aboveSubview:_mapView];
		_noSignalView.frame = noSignalFrame;
		
		// Start a timer to update the wait time message and ultimately cancel it
		noSignalUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
															   target:self
															 selector:@selector(waitForSignalTime:)
															 userInfo:nil
															  repeats:YES];
		}

	// Signal wait expires in either kNoLocationWaitDuration or the refine location time,
	//	whichever comes later. Note: calling -startNoSignalWait again restarts the timer.
	NSTimeInterval waitTime = fmax(kNoLocationWaitDuration,Refiner.duration);
	noSignalDeadline = [NSDate dateWithTimeIntervalSinceNow:waitTime];
	
	// Update the text to say how long we're waiting
	[self fillSignalWaitMessage];
	
	if (noSignalTaskIdentifier==UIBackgroundTaskInvalid)
		{
		// Register this as a background task, so it keeps going if the user switches apps or locks the screen
		noSignalTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Waiting"
																			  expirationHandler:^{
																				[self stopNoSignalWait];
																				}];
		}
}

- (void)stopNoSignalWait
{
	TESTLog(@"",nil);
	[noSignalUpdateTimer invalidate];
	noSignalUpdateTimer = nil;
	
	[_noSignalView removeFromSuperview];
	_noSignalView = nil;
	
	[[UIApplication sharedApplication] endBackgroundTask:noSignalTaskIdentifier];
}

- (void)fillSignalWaitMessage
{
	unsigned int remaining = (unsigned int)noSignalDeadline.timeIntervalSinceNow;
	_noSignalText.text = [NSString stringWithFormat:
						  @"Location will be saved if it becomes available in the next %u seconds.",
						  remaining];
}

- (IBAction)cancelNoSignal:(id)sender
{
	[self stopNoSignalWait];
}

- (void)waitForSignalTime:(NSTimer*)timer
{
	TESTLog(@"%u remaining",(unsigned int)noSignalDeadline.timeIntervalSinceNow);

	// Time to check for a location
	if (currentLocation!=nil)
		{
		// We're found!
		[self stopNoSignalWait];
		[self addLocation:self];
		return;
		}
	
	if (noSignalDeadline.timeIntervalSinceNow>0)
		[self fillSignalWaitMessage];
	else
		[self stopNoSignalWait];
}

@end
