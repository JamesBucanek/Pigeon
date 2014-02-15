//
//  SettingsViewController.m
//  Pigeon
//
//  Created by James Bucanek on 12/14/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "SettingsViewController.h"

#import "DetailsViewController.h"		// kPreferenceSaveToCameraRollKey
#import "Refiner.h"
#import "DocumentController.h"
#import "RefinementViewController.h"


@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
	// Settings view is about to appear.
	// Update the refinement time and current iCloud sync setting.
	
	// Fill in the text for the refinement time.
	// Note that there's nothing that will change this value while this view
	//	is visible, so it only needs to be done once when it first appears.
	_refineTimeCell.detailTextLabel.text = [RefinementViewController localizedRefinementDuration:[Refiner duration]];
	
	// Set the initial state of the iCloud toggle
	DocumentController* documentController = [DocumentController sharedController];
	_synchronizeButton.on = (documentController.useUbiquitousStore);
	
	// Set the initial state of the "save to camera roll" toggle
	_savePicturesButton.on = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceSaveToCameraRollKey];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Actions

- (IBAction)toggleiCloud:(id)sender
{
	DocumentController* documentManager = [DocumentController sharedController];
	if (_synchronizeButton.on==YES && !documentManager.iCloudAvailable)
		{
		// The user is trying to turn iCloud synchronization on, but it's not available
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"iCloud Unavailable"
														message:@"iCloud has not been configured for this device "
																@"or has been disabled for this app. "
															    @"To use iCloud synchronization, first enable iCloud document storage in Settings."
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		}
	else
		{
		documentManager.syncWithCloud = _synchronizeButton.on;
		}
}

- (IBAction)toggleSavePicture:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:_savePicturesButton.on
											forKey:kPreferenceSaveToCameraRollKey];
}

@end
