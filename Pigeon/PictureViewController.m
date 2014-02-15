//
//  PictureViewController.m
//  Pigeon
//
//  Created by James Bucanek on 12/27/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "PictureViewController.h"

//#define NO_TEST_LOG
#import "Pigeon.h"
#import "PigeonMath.h"
#import "SavedLocation.h"
#import "PictureScrollView.h"


@interface PictureViewController ()

@end


@implementation PictureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// Set up the image and scroll views
	UIImage* image = self.image;
	_scrollView.image = image;
	_scrollView.minimumZoomScale = [_scrollView minimumZoomScaleForImageSize:image.size];
	_scrollView.zoomScale = _scrollView.minimumZoomScale;	// reset zoom and pan when (re)presenting the view
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Properties

- (UIImage*)image
{
	return [_location pictureAtIndex:_pictureIndex];
}

#pragma mark Actions

- (IBAction)trashPicture:(id)sender
{
	[[[UIAlertView alloc] initWithTitle:@"Delete Picture?"
								message:@"Remove this picture from the saved location?"
							   delegate:self
					  cancelButtonTitle:@"Cancel"
					  otherButtonTitles:@"Delete", nil]
	 show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView.cancelButtonIndex!=buttonIndex)
		{
		// User did NOT click the cancel button: delete the image
		[_location removePictureAtIndex:_pictureIndex];
		[self.navigationController popViewControllerAnimated:YES];
		}
}

@end
